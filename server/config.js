const fs = require('fs');
const path = require('path');

const CONFIG_FILE = path.join(__dirname, 'config.json');
const ENV_FILE = path.join(__dirname, '.env');
const DEFAULT_API_URL = 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';

if (fs.existsSync(ENV_FILE)) {
  fs.readFileSync(ENV_FILE, 'utf-8').split('\n').forEach(function (line) {
    var m = line.match(/^\s*([\w]+)\s*=\s*(.*)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  });
}

function getConfig() {
  var fileCfg = {};
  try { fileCfg = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf-8')); } catch (e) {}
  return {
    apiKey: process.env.DASHSCOPE_API_KEY || fileCfg.apiKey || '',
    model: process.env.AI_MODEL || fileCfg.model || 'qwen-turbo',
    apiUrl: DEFAULT_API_URL
  };
}

function saveModel(model) {
  var fileCfg = {};
  try { fileCfg = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf-8')); } catch (e) {}
  fileCfg.model = model;
  var tmp = CONFIG_FILE + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(fileCfg, null, 2));
  fs.renameSync(tmp, CONFIG_FILE);
}

module.exports = { getConfig, saveModel };