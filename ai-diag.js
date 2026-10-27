const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');

function req(method, path, headers, body) {
  return new Promise((resolve, reject) => {
    const opts = { hostname: 'localhost', port: 3000, path, method, headers: headers || {} };
    const r = http.request(opts, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => resolve({ status: res.statusCode, body: d }));
    });
    r.on('error', reject);
    if (body) r.write(body);
    r.end();
  });
}

(async () => {
  const out = [];
  const log = (...a) => out.push(a.join(' '));

  // 直接测试通义千问 API
  const cfg = require('./server/config').getConfig();
  log('=== 配置检查 ===');
  log('apiKey 前20字符:', cfg.apiKey.slice(0, 20) + '...');
  log('apiKey 长度:', cfg.apiKey.length);
  log('model:', cfg.model);
  log('apiUrl:', cfg.apiUrl);

  log('\n=== 直接调用通义千问 ===');
  try {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 15000);
    const resp = await fetch(cfg.apiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + cfg.apiKey },
      body: JSON.stringify({
        model: cfg.model,
        messages: [{ role: 'user', content: '你好，说一句话' }],
        max_tokens: 50
      }),
      signal: ctrl.signal
    });
    clearTimeout(timer);
    log('HTTP 状态:', resp.status);
    log('resp.ok:', resp.ok);
    const data = await resp.json();
    if (data.choices) {
      log('AI 回复:', data.choices[0].message.content);
    } else {
      log('返回体:', JSON.stringify(data).slice(0, 300));
    }
  } catch (e) {
    log('调用失败:', e.message);
  }

  // 测试通过服务器调用
  log('\n=== 通过服务器 /api/chat/ai ===');
  const srv = spawn('node', ['index.js'], { cwd: __dirname + '/server', stdio: 'pipe' });
  let srvLog = '';
  srv.stdout.on('data', d => srvLog += d.toString());
  srv.stderr.on('data', d => srvLog += d.toString());
  await new Promise(r => setTimeout(r, 2000));

  try {
    let r1 = await req('POST', '/api/chat/ai', { 'x-app-token': 'dev-token', 'Content-Type': 'application/json' }, JSON.stringify({ message: '你好', context: [] }));
    let d1 = JSON.parse(r1.body);
    log('状态:', r1.status);
    log('回复:', d1.reply);
    log('AI:', d1.ai);
    if (d1.error) log('错误:', d1.error);

    // 测试 AI 智能体
    log('\n=== 通过服务器 /api/ai/chat (SSE) ===');
    let r2 = await req('POST', '/api/ai/chat', { 'x-app-token': 'dev-token', 'Content-Type': 'application/json' }, JSON.stringify({ sessionId: 0, message: '你好', history: [] }));
    log('状态:', r2.status);
    log('SSE 数据前300字符:', r2.body.slice(0, 300));
  } catch (e) {
    log('出错:', e.message);
  } finally {
    srv.kill();
    fs.writeFileSync(__dirname + '/ai-diag.txt', out.join('\n'));
    process.exit(0);
  }
})();