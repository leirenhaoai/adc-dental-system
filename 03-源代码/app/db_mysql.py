# -*- coding: utf-8 -*-
"""MySQL 接入层：让业务代码用 sqlite3 的写法跑在 MySQL 上。

三件事：
1. 连接：pymysql，参数从环境变量取（云托管自动注入 MYSQL_*，本地用 ADC_MYSQL_*）
2. 占位符：业务代码写的是 `?`，pymysql 要 `%s`，在执行前统一替换
3. 结果行：sqlite3.Row 支持 r["col"] 与 r[0]，且时间列是字符串；
   pymysql 返回 datetime/date 对象，直接切片会崩 —— 这里统一转成字符串
"""
import datetime as _dt
import decimal
import os
import re
import sys

# pymysql 打进了 app/_vendor，这样镜像构建不需要联网 pip install
# （云托管构建机访问 PyPI 很慢，之前一次构建卡在 update-ca-certificates 十分钟）
_HERE = os.path.dirname(os.path.abspath(__file__))
_VENDOR = os.path.join(_HERE, "_vendor")
if os.path.isdir(_VENDOR) and _VENDOR not in sys.path:
    sys.path.insert(0, _VENDOR)

import pymysql
import pymysql.cursors

_STRFTIME_KEYS = ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d")


def _cfg():
    """优先读云托管注入的 MYSQL_*，否则读本地 ADC_MYSQL_*。"""
    env = os.environ.get
    host = env("MYSQL_ADDRESS") or env("ADC_MYSQL_HOST") or "127.0.0.1"
    port = 3306
    if ":" in host:                      # 云托管给的是 "host:port"
        host, p = host.rsplit(":", 1)
        port = int(p)
    port = int(env("MYSQL_PORT") or env("ADC_MYSQL_PORT") or port)
    return {
        "host": host,
        "port": port,
        "user": env("MYSQL_USER") or env("ADC_MYSQL_USER") or "root",
        "password": env("MYSQL_PASSWORD") or env("ADC_MYSQL_PASSWORD") or "",
        "database": env("MYSQL_DATABASE") or env("ADC_MYSQL_DB") or "adc",
        "charset": "utf8mb4",
        "cursorclass": pymysql.cursors.Cursor,   # 自己包 Row，不用 DictCursor
        "autocommit": False,
    }


class Row(dict):
    """既支持 r["col"] 也支持 r[0]，且把 datetime/date/time 转成字符串。"""

    __slots__ = ()

    def __init__(self, cols, vals):
        super().__init__((c, _norm(v)) for c, v in zip(cols, vals))

    def __getitem__(self, k):
        if isinstance(k, (int, slice)):
            return list(self.values())[k]
        return dict.__getitem__(self, k)

    def __iter__(self):
        # sqlite3.Row 解包得到的是「值」，dict 解包得到的是「键」。
        # 业务代码到处写 `a, b = con.execute(...).fetchone()`，必须按值迭代。
        return iter(list(self.values()))

    def __len__(self):
        return dict.__len__(self)

    def __repr__(self):
        return "Row(%r)" % (dict(self),)

    def keys(self):
        return list(dict.keys(self))


def _norm(v):
    if isinstance(v, _dt.datetime):
        return v.strftime("%Y-%m-%d %H:%M:%S")
    if isinstance(v, _dt.date):
        return v.strftime("%Y-%m-%d")
    if isinstance(v, _dt.time):
        return v.strftime("%H:%M:%S")
    if isinstance(v, bytes):
        return v.decode("utf-8", "replace")
    # DECIMAL 列在 pymysql 里是 decimal.Decimal，SQLite 那边是 float。
    # 业务代码到处直接做算术与比较，混用会抛 TypeError，统一成 float。
    if isinstance(v, decimal.Decimal):
        return float(v)
    return v


_Q = re.compile(r"'[^']*'|\"[^\"]*\"|\?")


def _to_pyformat(sql):
    """把 `?` 换成 `%s`。

    两个坑：
      1. 字符串字面量里的问号不能换（'?' 是数据，不是占位符）
      2. SQL 里本来就有的 `%`（strftime('%Y-%m')、LIKE '%x%'）会被 pymysql 当成
         格式符，必须转义成 `%%`，否则报 "not enough arguments for format string"
    """
    if "?" not in sql and "%" not in sql:
        return sql

    out, last = [], 0
    for m in _Q.finditer(sql):
        tok = m.group(0)
        if tok == "?":
            out.append(sql[last:m.start()])
            out.append("\x00")          # 占位标记，避免和后面的 % 转义冲突
            last = m.end()
    out.append(sql[last:])
    s = "".join(out)

    # 字面量里出现的 % 已经不在 _Q 覆盖范围内的问题：统一把 % 转义，再把标记换回 %s
    if "%" in s:
        s = s.replace("%", "%%")
    return s.replace("\x00", "%s")


class Cursor(object):
    """包一层 pymysql 的游标，提供 sqlite3 风格的 execute/fetch*。"""

    def __init__(self, cur):
        self._c = cur
        self._cols = [d[0] for d in (cur.description or [])]

    def execute(self, sql, args=()):  # noqa: A003
        self._c.execute(_to_pyformat(sql), args or ())
        self._cols = [d[0] for d in (self._c.description or [])]
        return self

    def executemany(self, sql, seq):
        self._c.executemany(_to_pyformat(sql), seq)
        return self

    def fetchone(self):
        r = self._c.fetchone()
        return None if r is None else Row(self._cols, r)

    def fetchall(self):
        return [Row(self._cols, r) for r in self._c.fetchall()]

    def fetchmany(self, n):
        return [Row(self._cols, r) for r in self._c.fetchmany(n)]

    def __iter__(self):
        for r in self._c:
            yield Row(self._cols, r)

    @property
    def lastrowid(self):
        return self._c.lastrowid

    @property
    def rowcount(self):
        return self._c.rowcount

    def close(self):
        self._c.close()


class Conn(object):
    """sqlite3.Connection 的最小等价物。"""

    def __init__(self, raw):
        self._raw = raw
        self._cur = Cursor(raw.cursor())

    def execute(self, sql, args=()):
        cur = Cursor(self._raw.cursor())
        try:
            cur.execute(sql, args)
        finally:
            pass
        return cur

    def executescript(self, script):
        cur = self._raw.cursor()
        for stmt in _split_sql(script):
            cur.execute(stmt)

    def executemany(self, sql, seq):
        cur = Cursor(self._raw.cursor())
        cur.executemany(sql, seq)
        return cur

    def cursor(self):
        return Cursor(self._raw.cursor())

    def commit(self):
        self._raw.commit()

    def rollback(self):
        self._raw.rollback()

    def close(self):
        try:
            self._raw.close()
        except Exception:
            pass

    def __enter__(self):
        return self

    def __exit__(self, *a):
        if a and a[0]:
            self.rollback()
        else:
            self.commit()


def _split_sql(script):
    """按分号切语句，跳过注释与字符串里的分号。

    两个必须照顾到的转义：
      · SQL 标准用 '' 表示一个单引号（我们的 q() 就是这么写的）
      · 反斜杠转义 \\' 也要认
    不处理 '' 会错位：第一个引号被当成结束、第二个又当成开始，
    后面整段语句的边界全乱，导入时表现为「表建好了但数据少一大半」。
    """
    out, buf, i, n = [], [], 0, len(script)
    quote = None
    while i < n:
        ch = script[i]
        if quote:
            buf.append(ch)
            if ch == quote:
                if i + 1 < n and script[i + 1] == quote:   # '' 或 "" 转义
                    buf.append(script[i + 1])
                    i += 2
                    continue
                if i > 0 and script[i - 1] == "\\":
                    pass                                    # \' 不断
                else:
                    quote = None
            i += 1
            continue
        if ch in ("'", '"'):
            quote = ch
            buf.append(ch)
            i += 1
            continue
        if ch == "-" and script[i:i + 2] == "--":
            j = script.find("\n", i)
            if j < 0:
                break
            i = j + 1
            continue
        if ch == ";":
            stmt = "".join(buf).strip()
            if stmt:
                out.append(stmt)
            buf = []
            i += 1
            continue
        buf.append(ch)
        i += 1
    stmt = "".join(buf).strip()
    if stmt:
        out.append(stmt)
    return out


def connect(**kw):
    cfg = _cfg()
    cfg.update(kw or {})
    try:
        raw = pymysql.connect(**cfg)
    except pymysql.err.OperationalError as e:
        # 云托管上库名未必就是我们要的：环境里注入的 MYSQL_DATABASE 可能是模板
        # 自带的（django 之类），也可能压根没注入、默认落成 adc。
        # 1049 = Unknown database，遇到就先建出来再连，免得部署时直接挂。
        if e.args and e.args[0] == 1049:
            dbname = cfg.pop("database")
            raw0 = pymysql.connect(**cfg)
            cur0 = raw0.cursor()
            cur0.execute("CREATE DATABASE IF NOT EXISTS `%s`"
                         " DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
                         % dbname)
            raw0.commit()
            raw0.close()
            cfg["database"] = dbname
            raw = pymysql.connect(**cfg)
        else:
            raise
    return Conn(raw)


def available():
    """能不能连上（用于启动时判断走 MySQL 还是 SQLite）。"""
    if not (os.environ.get("MYSQL_ADDRESS") or os.environ.get("ADC_MYSQL_HOST")):
        return False
    try:
        c = connect()
        c.execute("SELECT 1")
        c.close()
        return True
    except Exception:
        return False
