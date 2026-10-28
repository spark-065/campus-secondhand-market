const fs = require('fs');
const path = require('path');

const DB_DIR = path.join(__dirname, 'db');
if (!fs.existsSync(DB_DIR)) fs.mkdirSync(DB_DIR, { recursive: true });

const TABLES = {
  ai_session: path.join(DB_DIR, 'ai_session.json'),
  ai_message: path.join(DB_DIR, 'ai_message.json'),
  ai_tool_call: path.join(DB_DIR, 'ai_tool_call.json'),
  ai_feedback: path.join(DB_DIR, 'ai_feedback.json')
};

const caches = {};
function load(table) {
  if (caches[table]) return caches[table];
  const file = TABLES[table];
  if (!fs.existsSync(file)) {
    caches[table] = [];
    atomicWrite(file, '[]');
  } else {
    caches[table] = JSON.parse(fs.readFileSync(file, 'utf-8'));
  }
  return caches[table];
}
function atomicWrite(file, content) {
  var tmp = file + '.tmp';
  fs.writeFileSync(tmp, content);
  fs.renameSync(tmp, file);
}
function persist(table) {
  atomicWrite(TABLES[table], JSON.stringify(caches[table] || [], null, 2));
}
function nextId(table) {
  const rows = load(table);
  return rows.length > 0 ? Math.max(...rows.map(r => r.id || 0)) + 1 : 1;
}

const db = {
  session: {
    create(userId, entry, context) {
      const s = { id: nextId('ai_session'), userId, entry, context: context || null, createdAt: Date.now() };
      load('ai_session').push(s);
      persist('ai_session');
      return s;
    },
    get(id) { return load('ai_session').find(s => s.id === id); },
    listByUser(userId) { return load('ai_session').filter(s => s.userId === userId); }
  },
  message: {
    add(sessionId, role, content, card) {
      const m = { id: nextId('ai_message'), sessionId, role, content, card: card || null, createdAt: Date.now() };
      load('ai_message').push(m);
      persist('ai_message');
      return m;
    },
    listBySession(sessionId) { return load('ai_message').filter(m => m.sessionId === sessionId); }
  },
  toolCall: {
    add(sessionId, tool, args, result) {
      const t = { id: nextId('ai_tool_call'), sessionId, tool, args, result, createdAt: Date.now() };
      load('ai_tool_call').push(t);
      persist('ai_tool_call');
      return t;
    },
    listBySession(sessionId) { return load('ai_tool_call').filter(t => t.sessionId === sessionId); }
  },
  feedback: {
    add(sessionId, messageId, userId, rating, comment) {
      const f = { id: nextId('ai_feedback'), sessionId, messageId, userId, rating, comment: comment || '', createdAt: Date.now() };
      load('ai_feedback').push(f);
      persist('ai_feedback');
      return f;
    }
  }
};

const INDEX_FILE = path.join(DB_DIR, 'goods_index.json');
let goodsIndex = {};
function buildIndex(goods) {
  goodsIndex = {};
  goods.forEach(g => {
    const tokens = (g.name + ' ' + (g.desc || '') + ' ' + (g.cate || '') + ' ' + (g.seller || '')).toLowerCase().split(/[\s,，。、]+/).filter(t => t.length > 0);
    tokens.forEach(tok => {
      if (!goodsIndex[tok]) goodsIndex[tok] = [];
      if (!goodsIndex[tok].includes(g.id)) goodsIndex[tok].push(g.id);
    });
  });
  atomicWrite(INDEX_FILE, JSON.stringify(goodsIndex, null, 2));
}
function levenshteinDistance(a, b) {
  const m = a.length, n = b.length;
  if (m === 0) return n;
  if (n === 0) return m;
  const dp = Array.from({ length: m + 1 }, () => Array(n + 1).fill(0));
  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      dp[i][j] = Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost);
    }
  }
  return dp[m][n];
}

function searchGoods(query, goods, limit) {
  const qTokens = query.toLowerCase().split(/[\s,，。、]+/).filter(t => t.length > 0);
  const scores = {};
  qTokens.forEach(qt => {
    Object.keys(goodsIndex).forEach(idxTok => {
      if (idxTok.indexOf(qt) >= 0 || qt.indexOf(idxTok) >= 0) {
        goodsIndex[idxTok].forEach(gid => {
          scores[gid] = (scores[gid] || 0) + (idxTok === qt ? 3 : 1);
        });
      } else {
        const dist = levenshteinDistance(idxTok, qt);
        const maxLen = Math.max(idxTok.length, qt.length);
        if (dist <= Math.ceil(maxLen * 0.3)) {
          goodsIndex[idxTok].forEach(gid => {
            scores[gid] = (scores[gid] || 0) + (dist <= 1 ? 2 : 1);
          });
        }
      }
    });
  });
  const sorted = Object.keys(scores).map(gid => ({ gid: Number(gid), score: scores[gid] })).sort((a, b) => b.score - a.score).slice(0, limit || 6);
  return sorted.map(s => goods.find(g => g.id === s.gid)).filter(Boolean);
}
function getPriceStats(goods, cate) {
  const same = goods.filter(g => g.cate === cate);
  if (!same.length) return null;
  const prices = same.map(g => g.price).sort((a, b) => a - b);
  return {
    category: cate,
    sampleSize: same.length,
    min: prices[0],
    max: prices[prices.length - 1],
    median: prices[Math.floor(prices.length / 2)],
    avg: Math.round(prices.reduce((s, p) => s + p, 0) / prices.length),
    p25: prices[Math.floor(prices.length * 0.25)],
    p75: prices[Math.floor(prices.length * 0.75)]
  };
}

module.exports = { db, buildIndex, searchGoods, getPriceStats };