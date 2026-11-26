// 全局：接口地址、token 存储、request 封装
//
// ============ 两种连法，改这里就行 ============
//
// 【A】连自己电脑（开发 / 演示用）
//   · 开发者工具模拟器 → http://127.0.0.1:8000
//   · 手机真机调试     → http://电脑局域网IP:8000（同 WiFi）
//   · 公网隧道         → https://xxx.trycloudflare.com
//   把 CLOUD_ENV 留空，走下面的 BASE。
//
// 【B】连微信云托管（正式部署，免域名免备案）
//   把 CLOUD_ENV 填成云托管的环境 ID，BASE 就不用了。
//   原理：callContainer 不走 DNS，微信直接按 env + 服务名把请求送到容器，
//   所以不需要配置「服务器域名」，也不需要备案。
//
const BASE = "https://miss-pond-neighborhood-bias.trycloudflare.com";

// 填了就走云托管；留空走 BASE
const CLOUD_ENV = "prod-d3g67jq314aacf35b";
// 云托管里那个「服务名」（新建服务时填的，默认 adc）
const CLOUD_SVC = "django-5j5b";

App({
  globalData: {
    baseUrl: BASE,
    cloudEnv: CLOUD_ENV,
    token: "",
    patients: [],
    me: null
  },

  onLaunch() {
    const t = wx.getStorageSync("token") || "";
    if (t) {
      this.globalData.token = t;
    }
    if (CLOUD_ENV && wx.cloud) {
      wx.cloud.init({ env: CLOUD_ENV, traceUser: false });
    }
  },

  setToken(t) {
    this.globalData.token = t || "";
    if (t) {
      wx.setStorageSync("token", t);
    } else {
      wx.removeStorageSync("token");
    }
  },

  // 统一的请求封装：自动带 token、自动处理 401、自动把 err 弹出来
  // 云端和本机走同一个出口，页面代码一行都不用改。
  req(path, data, method) {
    const self = this;
    method = method || (data ? "POST" : "GET");
    const header = self.globalData.token
      ? { Authorization: "Bearer " + self.globalData.token }
      : {};

    return new Promise(function (resolve, reject) {
      function done(res) {
        const d = res.data || {};
        if (res.statusCode === 401) {
          self.setToken("");
          wx.showToast({ title: "请重新登录", icon: "none" });
          wx.reLaunch({ url: "/pages/login/login" });
          return reject(new Error("未登录"));
        }
        if (d.ok) {
          return resolve(d);
        }
        const msg = d.err || ("请求失败 " + res.statusCode);
        wx.showToast({ title: msg, icon: "none", duration: 2200 });
        reject(new Error(msg));
      }

      function boom(e) {
        wx.showModal({
          title: "连不上服务",
          content: CLOUD_ENV
            ? "云托管环境没起来，或者服务名填错了。\n\n" + (e.errMsg || "")
            : "确认电脑上 run.bat 正在运行，且手机与电脑在同一个 WiFi。" +
              "真机调试要在「详情 → 本地设置」里勾上「不校验合法域名」。\n\n" +
              (e.errMsg || ""),
          showCancel: false
        });
        reject(e);
      }

      if (CLOUD_ENV) {
        // 走微信专线：请求里没有域名，不需要备案
        wx.cloud.callContainer({
          config: { env: CLOUD_ENV },
          path: path,
          method: method,
          data: data || {},
          header: Object.assign({ "X-WX-SERVICE": CLOUD_SVC }, header),
          timeout: 15000,
          success: done,
          fail: boom
        });
      } else {
        wx.request({
          url: BASE + path,
          method: method,
          data: data || {},
          header: header,
          timeout: 15000,
          success: done,
          fail: boom
        });
      }
    });
  }
});
