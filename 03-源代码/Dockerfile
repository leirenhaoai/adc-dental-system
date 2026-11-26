# ADC 诊疗管理系统 —— 微信云托管镜像
#
# 用标准库 http.server + pymysql，不依赖任何 Web 框架。
# pymysql 已经 vendor 进 app/_vendor，构建过程不需要联网装包。
#
# 数据库：云托管的 Serverless MySQL 只给内网地址、密码走微信服务通知，
# 「手动上传代码包」部署的服务拿不到这些凭证，所以这里用 SQLite，
# 并把灌好演示数据的库放在 /app/rt/adc.db —— 刻意避开 /app/data，
# 因为平台很可能给 data 挂空卷，镜像里 COPY 进去的文件会被盖掉。
FROM python:3.12-slim

ENV ADC_FORCE_SQLITE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    TZ=Asia/Shanghai \
    PORT=80

WORKDIR /app

COPY app/ ./app/

# 演示数据：放到不被挂载的 rt 目录，构建期一次到位
RUN mkdir -p /app/rt && cp /app/app/seed_adc.db /app/rt/adc.db

EXPOSE 80

# 端口必须显式传 80：云托管的健康检查打的是容器的 80。
CMD ["python", "app/server.py", "--port", "80"]
