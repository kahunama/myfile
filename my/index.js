const server = "127.0.0.1"
const port = process.env.PORT || 26545;
const express = require("express");
const app = express();
var exec = require("child_process").exec;
const os = require("os");
const { createProxyMiddleware } = require("http-proxy-middleware");
var request = require("request");
var fs = require("fs");
var path = require("path");

//设置参数
const NEZHA_KEY = process.env.NEZHA_KEY || 'fKA8lGBQpqGbKjs7xA';
const NEZHA_SERVER = process.env.NEZHA_SERVER || 'nezha.tcguangda.eu.org';
const ARGO_AUTH = process.env.ARGO_AUTH || 'eyJhIjoiMWQxYjMwMzJkYWY2MjlhNTZmOWI5Y2RmMDlkNDZhZjkiLCJ0IjoiNjZkMWY0NzItMWYxNi00MDExLWEzMjctMTYyMzMwYTBmNGE1IiwicyI6Ik5HWXlZekk0TVRjdE5UWXhNUzAwWmpSbExXRTJPV1V0T1dVNE1UWTNPREl5WkRCaCJ9';

app.get("/", function (req, res) {
  res.status(200).send("hello world");
});

//获取系统进程表
app.get("/status", function (req, res) {
  let cmdStr = "ps -ef";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    }
    else {
      res.type("html").send("<pre>获取系统进程表：\n" + stdout + "</pre>");
    }
  });
});

// web保活
function keep_web_alive() {
  // 1.请求主页，保持唤醒
  request("http://" + server + ":" + port, function (error, response, body) {
    if (!error) {
      console.log("保活-请求主页-命令行执行成功，响应报文:" + body);
    }
    else {
      console.log("保活-请求主页-命令行执行错误: " + error);
    }
  });

  // 2.请求服务器进程状态列表，若web没在运行，则调起
  exec("ss -nltp", function (err, stdout, stderr) {
    // 1.查后台系统进程，保持唤醒
    if (stdout.includes("web.js")) {
      console.log("web 正在运行");
    }
    else {
      // web 未运行，命令行调起
      exec("chmod +x web.js && ./web.js -c ./config.json >/dev/null 2>&1 &", function (err, stdout, stderr) {
          if (err) {
            console.log("保活-调起web-命令行执行错误:" + err);
          }
          else {
            console.log("保活-调起web-命令行执行成功!");
          }
        }
      );
    }
  });
}
setInterval(keep_web_alive, 10 * 1000);

//nezha保活
if (NEZHA_KEY) {
  function keep_nezha_alive() {
    if (NEZHA_KEY) {
      exec("pidof nezha-agent", function (err, stdout, stderr) {
        if (stdout) {
          console.log("哪吒正在运行");
        } else {
          // nezha 未运行，命令行调起
          exec(`chmod +x ./nezha-agent && nohup ./nezha-agent -s ${NEZHA_SERVER}:443 -p ${NEZHA_KEY} --tls >/dev/null 2>&1 &`, function (err, stdout, stderr) {
            if (err) {
              console.log("保活-调起哪吒-命令行执行错误");
            } else {
              console.log("保活-调起哪吒-命令行执行成功!");
            }
          });
        }
      });
    } else {
      console.log("");
    }
  }
  setInterval(keep_nezha_alive, 20 * 1000);
} else {
  console.log("");
}

//argo保活
if (ARGO_AUTH) {
  function keep_argo_alive() {
    if (ARGO_AUTH) {
      exec("pidof argo", function (err, stdout, stderr) {
        if (stdout) {
          console.log("argo正在运行");
        } else {
          // ar-go 未运行，命令行调起
          exec(`chmod +x ./argo && nohup ./argo tunnel --edge-ip-version auto run --token ${ARGO_AUTH} >/dev/null 2>&1 &`, function (err, stdout, stderr) {
            if (err) {
              console.log("保活-调起argo-命令行执行错误");
            } else {
              console.log("保活-调起argo-命令行执行成功!");
            }
          });
        }
      });
    } else {
      console.log("");
    }
  }

  setInterval(keep_argo_alive, 20 * 1000);
} else {
  console.log("");
}


//下载web可执行文件
app.get("/download", function (req, res) {
  download_web((err) => {
    if (err) {
      res.send("下载文件失败");
    }
    else {
      res.send("下载文件成功");
    }
  });
});

app.use(
  "/",
  createProxyMiddleware({
    changeOrigin: true, // 默认false，是否需要改变原始主机头为目标URL
    onProxyReq: function onProxyReq(proxyReq, req, res) {},
    pathRewrite: {
      // 请求中去除/
      "^/": "/"
    },
    target: "http://127.0.0.1:8080/", // 需要跨域处理的请求地址
    ws: true // 是否代理websockets
  })
);

//初始化，下载web
function download_web(callback) {
    let fileName = "web.js";
    let web_url;

    if (os.arch() === 'x64' || os.arch() === 'amd64') {
      web_url = process.env.URL_WEB || 'https://raw.githubusercontent.com/kahunama/myfile/main/my/web.js';
    } else {

      web_url = process.env.URL_WEB2 || 'https://raw.githubusercontent.com/kahunama/myfile/main/my/web.js(arm)';
    }

  let stream = fs.createWriteStream(path.join("./", fileName));
  request(web_url)
    .pipe(stream)
    .on("close", function (err) {
      if (err) {
        callback("下载web文件失败");
      }
      else {
        callback(null);
      }
    });
}
download_web((err) => {
  if (err) {
    console.log("下载web文件失败");
  }
  else {
    console.log("下载web文件成功");
  }
});

//初始化，下载nezha
if (NEZHA_KEY) {
function download_nezha(callback) {
    let fileName = "nezha-agent";
    let nez_url;

    if (os.arch() === 'x64' || os.arch() === 'amd64') {

      nez_url = process.env.URL_NEZHA || 'https://raw.githubusercontent.com/kahunama/myfile/main/nezha/nezha-agent';
    } else {

      nez_url = process.env.URL_NEZHA2 || 'https://raw.githubusercontent.com/kahunama/myfile/main/nezha/nezha-agent(arm)';
    }

    let stream = fs.createWriteStream(path.join("./", fileName));
    request(nez_url)
      .pipe(stream)
      .on("close", function (err) {
        if (err) {
          callback("下载哪吒文件失败");
        } else {
          callback(null);
        }
      });
}
download_nezha((err) => {
  if (err) {
    console.log("下载哪吒文件失败");
  } else {
    console.log("下载哪吒文件成功");
  }
});
} else {
    console.log("");
}

//初始化，下载argo
if (ARGO_AUTH) {
  function download_cff(callback) {
      let fileName = "argo";
      let cff_url;

      if (os.arch() === 'x64' || os.arch() === 'amd64') {

        cff_url = process.env.URL_CF || 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64';
      } else {

        cff_url = process.env.URL_CF2 || 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64';
      }

      let stream = fs.createWriteStream(path.join("./", fileName));
      request(cff_url)
        .pipe(stream)
        .on("close", function (err) {
          if (err) {
            callback("下载argo文件失败");
          } else {
            callback(null);
          }
        });
  }
  download_cff((err) => {
    if (err) {
      console.log("下载argo文件失败");
    } else {
      console.log("下载argo文件成功");
    }
  });
  } else {
      console.log("");
  }

//启动运行web
exec("bash start.sh", function (err, stdout, stderr) {
  if (err) {
    console.error(err);
    return;
  }
  console.log(stdout);
});

app.listen(port, () => console.log(`Example app listening on port ${port}!`));
