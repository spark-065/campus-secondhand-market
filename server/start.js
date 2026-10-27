const net = require('net');
const path = require('path');
const { spawn } = require('child_process');
const fs = require('fs');

const MYSQL_HOME = process.env.MYSQL_HOME || 'D:\\DevTools\\mysql';
const MYSQLD = path.join(MYSQL_HOME, 'bin', 'mysqld.exe');
const MYSQL_INI = path.join(MYSQL_HOME, 'my.ini');

function sleep(ms) {
  return new Promise(function (r) { setTimeout(r, ms); });
}

function portOpen(port, host) {
  return new Promise(function (resolve) {
    const sock = net.createConnection({ port: port, host: host || '127.0.0.1' });
    let done = false;
    function finish(v) {
      if (done) return;
      done = true;
      try { sock.destroy(); } catch (e) {}
      resolve(v);
    }
    sock.on('connect', function () { finish(true); });
    sock.on('error', function () { finish(false); });
    setTimeout(function () { finish(false); }, 1500);
  });
}

async function waitFor(port, seconds, label) {
  for (let i = 0; i < seconds; i++) {
    if (await portOpen(port)) return true;
    await sleep(1000);
  }
  return await portOpen(port);
}

(async function main() {
  console.log('');
  console.log('  校园集市 · 一键启动');
  console.log('  ----------------------------------');

  if (await portOpen(3000)) {
    console.log('  后端已在运行，直接访问: http://localhost:3000');
    console.log('  （要先停止请先按 Ctrl+C 关掉占用 3000 的进程）');
    console.log('');
    process.exit(0);
  }

  if (await portOpen(3306)) {
    console.log('  [1/2] MySQL 已在运行，跳过启动');
  } else {
    if (!fs.existsSync(MYSQLD)) {
      console.error('  [1/2] 找不到 MySQL: ' + MYSQLD);
      console.error('        请确认 D:\\DevTools\\mysql 存在，或设置环境变量 MYSQL_HOME');
      process.exit(1);
    }
    console.log('  [1/2] MySQL 未运行，正在启动 ...');
    const child = spawn(MYSQLD, ['--defaults-file=' + MYSQL_INI], {
      detached: true,
      stdio: 'ignore',
      windowsHide: true
    });
    child.unref();
    const ok = await waitFor(3306, 30, 'MySQL');
    if (!ok) {
      console.error('  [1/2] MySQL 启动超时（30 秒）。可手动运行:');
      console.error('        ' + MYSQLD + ' --defaults-file=' + MYSQL_INI);
      process.exit(1);
    }
    console.log('  [1/2] MySQL 已就绪');
  }

  console.log('  [2/2] 启动后端服务 ...');
  console.log('');

  setInterval(async function () {
    if (await portOpen(3306)) return;
    console.log('  [watchdog] MySQL 掉线，正在重新启动 ...');
    try {
      const c = spawn(MYSQLD, ['--defaults-file=' + MYSQL_INI], {
        detached: true, stdio: 'ignore', windowsHide: true
      });
      c.unref();
    } catch (e) {}
  }, 5000);

  require('./index.js');
})();
