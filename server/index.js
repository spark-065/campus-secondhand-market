const express = require('express');
const fs = require('fs');
const path = require('path');
const http = require('http');
const WebSocket = require('ws');
const mysql = require('mysql2/promise');
const { getConfig, saveModel } = require('./config');

const app = express();
const PORT = 3000;

const pool = mysql.createPool({
  host: 'localhost', port: 3306, user: 'root', password: '',
  database: 'shop_db', waitForConnections: true,
  connectionLimit: 10, queueLimit: 0, charset: 'utf8mb4'
});

app.use(express.json({ limit: '10mb' }));

const TOKEN = process.env.APP_TOKEN || 'dev-token';
// 允许所有本机来源（localhost / 127.0.0.1 任意端口）以及 file:// 的 'null'，方便本地调试与 IDE 内置预览
function isAllowedOrigin(origin) {
  if (!origin) return false;
  if (origin === 'null') return true;
  try {
    const u = new URL(origin);
    return u.hostname === 'localhost' || u.hostname === '127.0.0.1';
  } catch (e) { return false; }
}

app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (isAllowedOrigin(origin)) {
    res.header('Access-Control-Allow-Origin', origin);
    res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type,x-app-token');
  }
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

app.use('/api', (req, res, next) => {
  if (req.method === 'OPTIONS') return next();
  if (req.headers['x-app-token'] === TOKEN) return next();
  return res.status(401).json({ code: 401, msg: '未授权' });
});

function SAFE_KEY(k) {
  return typeof k === 'string' && k.length > 0 && k.length <= 64 && !['__proto__', 'constructor', 'prototype'].includes(k);
}
function pick(obj, keys) {
  const r = {};
  keys.forEach(k => { if (obj[k] !== undefined) r[k] = obj[k]; });
  return r;
}

function mapGoodsRow(r) {
  if (!r) return null;
  return {
    id: r.id, name: r.name, price: Number(r.price), emoji: r.emoji || '📦',
    grad: r.grad || 0, seller: r.seller, sellerAvatar: r.seller_avatar || '🧑',
    sellerGrad: r.seller_grad || 0, publishTime: r.publish_time || '刚刚',
    desc: r.description || '', condition: r.condition || '九成新',
    category: r.category || '其他', region: r.region || '一期',
    tradeType: r.trade_type || '出售', image: r.image || null,
    seller_id: r.seller_id || null
  };
}

async function getAllGoods() {
  const [rows] = await pool.query('SELECT * FROM goods ORDER BY id');
  return rows.map(mapGoodsRow);
}

const wsClients = new Map();
function broadcastWS(type, data, excludeUserId) {
  for (const [uid, client] of wsClients) {
    if (uid !== excludeUserId && client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify({ type, data }));
    }
  }
}

// ========== 注册/登录 ==========
app.post('/api/register', async (req, res) => {
  const { userId, password, nickName } = req.body;
  if (!SAFE_KEY(userId)) return res.json({ code: 1, msg: '无效用户ID' });
  if (!password || !/^\d{6}$/.test(password)) return res.json({ code: 1, msg: '密码必须为6位数字' });
  try {
    const [exist] = await pool.query('SELECT user_id FROM users WHERE user_id = ?', [userId]);
    if (exist.length > 0) return res.json({ code: 1, msg: '该用户ID已存在' });
    await pool.execute(
      'INSERT INTO users (user_id, nick_name, bio, avatar, password) VALUES (?, ?, ?, NULL, ?)',
      [userId, nickName || userId, '这个人很懒，什么都没留下～', password]
    );
    const [rows] = await pool.query('SELECT user_id, nick_name, bio, avatar FROM users WHERE user_id = ?', [userId]);
    res.json({ code: 0, data: rows[0] });
  } catch (e) {
    res.json({ code: 1, msg: '注册失败: ' + e.message });
  }
});

app.post('/api/login', async (req, res) => {
  const { userId, password } = req.body;
  if (!SAFE_KEY(userId)) return res.json({ code: 1, msg: '无效用户ID' });
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE user_id = ?', [userId]);
    if (rows.length === 0) return res.json({ code: 1, msg: '该用户未注册' });
    if (rows[0].password !== password) return res.json({ code: 1, msg: '密码错误' });
    const u = rows[0];
    const [favs] = await pool.query('SELECT goods_id FROM favorites WHERE user_id = ?', [userId]);
    const [fols] = await pool.query('SELECT seller_name FROM follows WHERE user_id = ?', [userId]);
    const [pubs] = await pool.query('SELECT id FROM goods WHERE seller_id = ?', [userId]);
    res.json({
      code: 0, data: {
        nickName: u.nick_name, bio: u.bio, avatar: u.avatar,
        published: pubs.map(p => p.id), favorites: favs.map(f => f.goods_id),
        follows: fols.map(f => f.seller_name)
      }
    });
  } catch (e) {
    res.json({ code: 1, msg: '登录失败: ' + e.message });
  }
});

// ========== 商品 ==========
app.get('/api/goods', async (req, res) => {
  const { category, region, tradeType, priceMin, priceMax, keyword } = req.query;
  let sql = 'SELECT * FROM goods WHERE 1=1';
  const params = [];
  if (category) { sql += ' AND category IN (?)'; params.push(category.split(',')); }
  if (region) { sql += ' AND region IN (?)'; params.push(region.split(',')); }
  if (tradeType) { sql += ' AND trade_type = ?'; params.push(tradeType); }
  if (priceMin !== undefined) { sql += ' AND price >= ?'; params.push(Number(priceMin)); }
  if (priceMax !== undefined) { sql += ' AND price < ?'; params.push(Number(priceMax)); }
  if (keyword) { sql += ' AND (name LIKE ? OR description LIKE ?)'; params.push(`%${keyword}%`, `%${keyword}%`); }
  sql += ' ORDER BY id';
  try {
    const [rows] = await pool.query(sql, params);
    const list = rows.map(mapGoodsRow);
    res.json({ code: 0, data: list, total: list.length });
  } catch (e) {
    res.json({ code: 1, msg: '查询失败: ' + e.message });
  }
});

app.get('/api/goods/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM goods WHERE id = ?', [Number(req.params.id)]);
    if (rows.length === 0) return res.status(404).json({ code: 1, msg: '商品不存在' });
    const g = mapGoodsRow(rows[0]);
    const [sim] = await pool.query('SELECT * FROM goods WHERE category = ? AND id != ? LIMIT 6', [rows[0].category, rows[0].id]);
    res.json({ code: 0, data: g, similar: sim.map(mapGoodsRow) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.post('/api/goods', async (req, res) => {
  const b = req.body;
  try {
    const [result] = await pool.execute(
      'INSERT INTO goods (name, price, emoji, grad, seller, seller_avatar, seller_grad, publish_time, description, `condition`, category, region, trade_type, image, seller_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [b.name || '', b.price || 0, b.emoji || '📦', b.grad || 0, b.seller || '', b.sellerAvatar || b.sa || '🧑', b.sellerGrad || b.sg || 0, b.publishTime || b.time || '刚刚', b.desc || b.description || '', b.condition || b.cond || '九成新', b.category || b.cate || '其他', b.region || '一期', b.tradeType || b.type || '出售', b.image || null, b.seller_id || null]
    );
    const [rows] = await pool.query('SELECT * FROM goods WHERE id = ?', [result.insertId]);
    broadcastWS('goods_new', mapGoodsRow(rows[0]));
    res.json({ code: 0, data: mapGoodsRow(rows[0]) });
  } catch (e) {
    res.json({ code: 1, msg: '创建失败: ' + e.message });
  }
});

app.put('/api/goods/:id', async (req, res) => {
  const b = req.body;
  try {
    await pool.execute(
      'UPDATE goods SET name=?, price=?, description=?, `condition`=?, category=?, region=?, trade_type=?, emoji=?, image=?, grad=? WHERE id=?',
      [b.name, b.price, b.desc || b.description, b.cond || b.condition, b.cate || b.category, b.region, b.type || b.tradeType, b.emoji, b.image, b.grad, Number(req.params.id)]
    );
    const [rows] = await pool.query('SELECT * FROM goods WHERE id = ?', [Number(req.params.id)]);
    res.json({ code: 0, data: mapGoodsRow(rows[0]) });
  } catch (e) {
    res.status(404).json({ code: 1, msg: e.message });
  }
});

app.delete('/api/goods/:id', async (req, res) => {
  try {
    await pool.execute('DELETE FROM goods WHERE id = ?', [Number(req.params.id)]);
    await pool.execute('DELETE FROM comments WHERE goods_id = ?', [Number(req.params.id)]);
    await pool.execute('DELETE FROM favorites WHERE goods_id = ?', [Number(req.params.id)]);
    res.json({ code: 0, msg: '已删除' });
  } catch (e) {
    res.status(404).json({ code: 1, msg: e.message });
  }
});

// ========== 用户数据 ==========
app.get('/api/user/:userId', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    const [rows] = await pool.query('SELECT user_id, nick_name, bio, avatar FROM users WHERE user_id = ?', [req.params.userId]);
    if (rows.length === 0) return res.status(404).json({ code: 1, msg: '用户不存在' });
    const u = rows[0];
    const [favs] = await pool.query('SELECT goods_id FROM favorites WHERE user_id = ?', [req.params.userId]);
    const [fols] = await pool.query('SELECT seller_name FROM follows WHERE user_id = ?', [req.params.userId]);
    const [pubs] = await pool.query('SELECT id FROM goods WHERE seller_id = ?', [req.params.userId]);
    const [revs] = await pool.query('SELECT * FROM reviews WHERE user_id = ?', [req.params.userId]);
    res.json({ code: 0, data: {
      nickName: u.nick_name, bio: u.bio, avatar: u.avatar,
      published: pubs.map(p => p.id), favorites: favs.map(f => f.goods_id),
      follows: fols.map(f => f.seller_name),
      reviews: revs.map(r => ({ id: r.id, goods: r.goods_name, gid: r.goods_id, seller: r.seller, content: r.content, time: r.review_time, rating: r.rating }))
    }});
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.post('/api/user/:userId', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    await pool.execute(
      'INSERT IGNORE INTO users (user_id, nick_name, bio, avatar, password) VALUES (?, ?, ?, NULL, ?)',
      [req.params.userId, req.body.nickName || req.params.userId, '这个人很懒，什么都没留下～', '000000']
    );
    const [rows] = await pool.query('SELECT user_id, nick_name, bio, avatar FROM users WHERE user_id = ?', [req.params.userId]);
    const [favs] = await pool.query('SELECT goods_id FROM favorites WHERE user_id = ?', [req.params.userId]);
    const [fols] = await pool.query('SELECT seller_name FROM follows WHERE user_id = ?', [req.params.userId]);
    const [pubs] = await pool.query('SELECT id FROM goods WHERE seller_id = ?', [req.params.userId]);
    const [revs] = await pool.query('SELECT * FROM reviews WHERE user_id = ?', [req.params.userId]);
    res.json({ code: 0, data: {
      nickName: rows[0].nick_name, bio: rows[0].bio, avatar: rows[0].avatar,
      published: pubs.map(p => p.id), favorites: favs.map(f => f.goods_id),
      follows: fols.map(f => f.seller_name),
      reviews: revs.map(r => ({ id: r.id, goods: r.goods_name, gid: r.goods_id, seller: r.seller, content: r.content, time: r.review_time, rating: r.rating }))
    } });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.put('/api/user/:userId', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  const b = pick(req.body, ['nickName', 'bio', 'avatar']);
  try {
    await pool.execute(
      'UPDATE users SET nick_name = ?, bio = ?, avatar = ? WHERE user_id = ?',
      [b.nickName || null, b.bio || null, b.avatar || null, req.params.userId]
    );
    const [rows] = await pool.query('SELECT user_id, nick_name, bio, avatar FROM users WHERE user_id = ?', [req.params.userId]);
    res.json({ code: 0, data: { nickName: rows[0].nick_name, bio: rows[0].bio, avatar: rows[0].avatar } });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

// ========== 用户发布 ==========
app.get('/api/user/:userId/published', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    const [rows] = await pool.query('SELECT * FROM goods WHERE seller_id = ? ORDER BY id', [req.params.userId]);
    res.json({ code: 0, data: rows.map(mapGoodsRow) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.post('/api/user/:userId/published', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  const b = req.body;
  try {
    const [urows] = await pool.query('SELECT nick_name FROM users WHERE user_id = ?', [req.params.userId]);
    const nick = urows.length > 0 ? urows[0].nick_name : req.params.userId;
    const [result] = await pool.execute(
      'INSERT INTO goods (name, price, emoji, grad, seller, seller_avatar, seller_grad, publish_time, description, `condition`, category, region, trade_type, image, seller_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [b.name || '', b.price || 0, b.emoji || '📦', b.grad || 0, nick, '🦊', 0, '刚刚', b.desc || '', b.cond || '九成新', b.cate || '其他', b.region || '一期', b.type || '出售', b.image || null, req.params.userId]
    );
    const [rows] = await pool.query('SELECT * FROM goods WHERE id = ?', [result.insertId]);
    const g = mapGoodsRow(rows[0]);
    broadcastWS('goods_new', g);
    res.json({ code: 0, data: g });
  } catch (e) {
    res.json({ code: 1, msg: '发布失败: ' + e.message });
  }
});

app.put('/api/user/:userId/published/:goodsId', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  const b = req.body;
  try {
    await pool.execute(
      'UPDATE goods SET name=?, price=?, description=?, `condition`=?, category=?, region=?, trade_type=?, emoji=?, image=?, grad=? WHERE id=? AND seller_id=?',
      [b.name, b.price, b.desc || b.description, b.cond || b.condition, b.cate || b.category, b.region, b.type || b.tradeType, b.emoji, b.image, b.grad, Number(req.params.goodsId), req.params.userId]
    );
    const [rows] = await pool.query('SELECT * FROM goods WHERE id = ?', [Number(req.params.goodsId)]);
    res.json({ code: 0, data: mapGoodsRow(rows[0]) });
  } catch (e) {
    res.status(404).json({ code: 1, msg: e.message });
  }
});

app.delete('/api/user/:userId/published/:goodsId', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    await pool.execute('DELETE FROM goods WHERE id = ? AND seller_id = ?', [Number(req.params.goodsId), req.params.userId]);
    await pool.execute('DELETE FROM comments WHERE goods_id = ?', [Number(req.params.goodsId)]);
    await pool.execute('DELETE FROM favorites WHERE goods_id = ?', [Number(req.params.goodsId)]);
    res.json({ code: 0, msg: '已删除' });
  } catch (e) {
    res.status(404).json({ code: 1, msg: e.message });
  }
});

// ========== 收藏 ==========
app.get('/api/user/:userId/favorites', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    const [rows] = await pool.query('SELECT g.* FROM goods g INNER JOIN favorites f ON g.id = f.goods_id WHERE f.user_id = ? ORDER BY g.id', [req.params.userId]);
    res.json({ code: 0, data: rows.map(mapGoodsRow) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.post('/api/user/:userId/favorites', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  const gid = Number(req.body.goodsId);
  try {
    await pool.execute('INSERT IGNORE INTO favorites (user_id, goods_id) VALUES (?, ?)', [req.params.userId, gid]);
    const [rows] = await pool.query('SELECT goods_id FROM favorites WHERE user_id = ?', [req.params.userId]);
    res.json({ code: 0, data: rows.map(r => r.goods_id) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.delete('/api/user/:userId/favorites/:goodsId', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    await pool.execute('DELETE FROM favorites WHERE user_id = ? AND goods_id = ?', [req.params.userId, Number(req.params.goodsId)]);
    const [rows] = await pool.query('SELECT goods_id FROM favorites WHERE user_id = ?', [req.params.userId]);
    res.json({ code: 0, data: rows.map(r => r.goods_id) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

// ========== 关注 ==========
app.get('/api/user/:userId/follows', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    const [rows] = await pool.query('SELECT seller_name FROM follows WHERE user_id = ?', [req.params.userId]);
    res.json({ code: 0, data: rows.map(r => r.seller_name) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.post('/api/user/:userId/follows', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  const name = req.body.sellerName;
  if (typeof name !== 'string' || name.length > 64) return res.json({ code: 1, msg: '无效卖家名' });
  try {
    await pool.execute('INSERT IGNORE INTO follows (user_id, seller_name) VALUES (?, ?)', [req.params.userId, name]);
    const [rows] = await pool.query('SELECT seller_name FROM follows WHERE user_id = ?', [req.params.userId]);
    res.json({ code: 0, data: rows.map(r => r.seller_name) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.delete('/api/user/:userId/follows/:sellerName', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    await pool.execute('DELETE FROM follows WHERE user_id = ? AND seller_name = ?', [req.params.userId, req.params.sellerName]);
    const [rows] = await pool.query('SELECT seller_name FROM follows WHERE user_id = ?', [req.params.userId]);
    res.json({ code: 0, data: rows.map(r => r.seller_name) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

// ========== 订单 ==========
app.get('/api/user/:userId/orders', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    const base = 'SELECT o.id, o.goods_id, o.price, o.order_time, g.name, g.emoji, g.image, g.grad, g.category, g.`condition` AS cond, g.trade_type, g.seller AS seller_name, g.seller_avatar, u.nick_name AS buyer_name FROM orders o LEFT JOIN goods g ON o.goods_id = g.id LEFT JOIN users u ON o.buyer_id = u.user_id';
    const [bought] = await pool.query(base + ' WHERE o.buyer_id = ? ORDER BY o.id DESC', [req.params.userId]);
    const [sold] = await pool.query(base + ' WHERE o.seller_id = ? ORDER BY o.id DESC', [req.params.userId]);
    const map = r => ({
      id: r.id, goodsId: r.goods_id, price: Number(r.price), time: r.order_time,
      goods: r.name ? { id: r.goods_id, name: r.name, price: Number(r.price), emoji: r.emoji || '📦', image: r.image, grad: r.grad || 0, cate: r.category || '其他', cond: r.cond || '九成新', type: r.trade_type || '出售' } : null,
      buyerName: r.buyer_name || r.buyer_id, sellerName: r.seller_name || ''
    });
    res.json({ code: 0, data: { bought: bought.map(map), sold: sold.map(map) } });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.post('/api/user/:userId/orders', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  const gid = Number(req.body.goodsId);
  if (!gid) return res.json({ code: 1, msg: '无效商品' });
  try {
    const [rows] = await pool.query('SELECT * FROM goods WHERE id = ?', [gid]);
    if (rows.length === 0) return res.json({ code: 1, msg: '商品不存在' });
    const g = rows[0];
    if (g.seller_id === req.params.userId) return res.json({ code: 1, msg: '不能购买自己的商品' });
    const [dup] = await pool.query('SELECT id FROM orders WHERE goods_id = ? AND buyer_id = ?', [gid, req.params.userId]);
    if (dup.length > 0) return res.json({ code: 1, msg: '已购买过该商品' });
    await pool.execute(
      'INSERT INTO orders (goods_id, buyer_id, seller_id, price, order_time) VALUES (?, ?, ?, ?, ?)',
      [gid, req.params.userId, g.seller_id, g.price, '刚刚']
    );
    const [os] = await pool.query('SELECT * FROM orders WHERE goods_id = ? AND buyer_id = ?', [gid, req.params.userId]);
    broadcastWS('order_new', { goodsId: gid, buyerId: req.params.userId, sellerId: g.seller_id, goodsName: g.name }, req.params.userId);
    res.json({ code: 0, data: { id: os[0].id, goodsId: gid, price: Number(g.price) } });
  } catch (e) {
    res.json({ code: 1, msg: '下单失败: ' + e.message });
  }
});

// ========== 评价 ==========
app.get('/api/user/:userId/reviews', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    const [rows] = await pool.query('SELECT * FROM reviews WHERE user_id = ? ORDER BY id', [req.params.userId]);
    res.json({ code: 0, data: rows.map(r => ({ id: r.id, goods: r.goods_name, gid: r.goods_id, seller: r.seller, content: r.content, time: r.review_time, rating: r.rating })) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.post('/api/user/:userId/reviews', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  const b = pick(req.body, ['goods', 'gid', 'seller', 'content', 'time', 'rating']);
  try {
    const [result] = await pool.execute(
      'INSERT INTO reviews (user_id, goods_name, goods_id, seller, content, review_time, rating) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [req.params.userId, b.goods || '', Number(b.gid) || 0, b.seller || '', b.content || '', b.time || '刚刚', b.rating || 5]
    );
    res.json({ code: 0, data: { id: result.insertId, ...b } });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

// ========== 聊天 ==========
app.get('/api/user/:userId/chats', async (req, res) => {
  if (!SAFE_KEY(req.params.userId)) return res.status(400).json({ code: 1, msg: '无效用户ID' });
  try {
    const [rows] = await pool.query('SELECT contact, message_text, is_me, msg_time FROM chats WHERE user_id = ? ORDER BY id', [req.params.userId]);
    const chats = {};
    rows.forEach(r => {
      if (!chats[r.contact]) chats[r.contact] = [];
      chats[r.contact].push({ t: r.message_text, me: r.is_me, time: r.msg_time });
    });
    res.json({ code: 0, data: chats });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.get('/api/user/:userId/chats/:contact', async (req, res) => {
  if (!SAFE_KEY(req.params.userId) || !SAFE_KEY(req.params.contact)) return res.status(400).json({ code: 1, msg: '无效参数' });
  try {
    const [rows] = await pool.query('SELECT message_text, is_me, msg_time FROM chats WHERE user_id = ? AND contact = ? ORDER BY id', [req.params.userId, req.params.contact]);
    res.json({ code: 0, data: rows.map(r => ({ t: r.message_text, me: r.is_me, time: r.msg_time })) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.post('/api/user/:userId/chats/:contact', async (req, res) => {
  if (!SAFE_KEY(req.params.userId) || !SAFE_KEY(req.params.contact)) return res.status(400).json({ code: 1, msg: '无效参数' });
  const m = { t: req.body.text, me: req.body.me || 1, time: '刚刚' };
  try {
    await pool.execute(
      'INSERT INTO chats (user_id, contact, message_text, is_me, msg_time) VALUES (?, ?, ?, ?, ?)',
      [req.params.userId, req.params.contact, m.t, m.me, m.time]
    );
    broadcastWS('chat_new', { userId: req.params.userId, contact: req.params.contact }, req.params.userId);
    res.json({ code: 0, data: m });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.delete('/api/user/:userId/chats/:contact', async (req, res) => {
  if (!SAFE_KEY(req.params.userId) || !SAFE_KEY(req.params.contact)) return res.status(400).json({ code: 1, msg: '无效参数' });
  try {
    await pool.execute('DELETE FROM chats WHERE user_id = ? AND contact = ?', [req.params.userId, req.params.contact]);
    res.json({ code: 0, msg: '聊天记录已清空' });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

// ========== 评论 ==========
app.get('/api/goods/:id/comments', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM comments WHERE goods_id = ? ORDER BY id', [Number(req.params.id)]);
    res.json({ code: 0, data: rows.map(r => ({ id: r.id, name: r.name, avatar: r.avatar, grad: r.grad, content: r.content, time: r.comment_time, isSeller: r.is_seller })) });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.post('/api/goods/:id/comments', async (req, res) => {
  try {
    const [result] = await pool.execute(
      'INSERT INTO comments (goods_id, name, avatar, grad, content, comment_time, is_seller) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [Number(req.params.id), req.body.name || '', req.body.avatar || '🧑', req.body.grad || 0, req.body.content || '', '刚刚', req.body.isSeller || 0]
    );
    res.json({ code: 0, data: { id: result.insertId, name: req.body.name, avatar: req.body.avatar, grad: req.body.grad || 0, content: req.body.content, time: '刚刚', isSeller: req.body.isSeller || 0 } });
  } catch (e) {
    res.status(500).json({ code: 1, msg: e.message });
  }
});

app.delete('/api/goods/:id/comments/:cid', async (req, res) => {
  try {
    await pool.execute('DELETE FROM comments WHERE id = ? AND goods_id = ?', [Number(req.params.cid), Number(req.params.id)]);
    res.json({ code: 0, msg: '评论已删除' });
  } catch (e) {
    res.status(404).json({ code: 1, msg: e.message });
  }
});

// ========== 圈子/消息/统计 ==========
app.get('/api/circle', async (req, res) => {
  try {
    const fs2 = require('fs');
    const d = JSON.parse(fs2.readFileSync(path.join(__dirname, 'data.json'), 'utf-8'));
    res.json({ code: 0, data: d.circle || [] });
  } catch (e) { res.json({ code: 0, data: [] }); }
});
app.get('/api/messages', async (req, res) => {
  try {
    const fs2 = require('fs');
    const d = JSON.parse(fs2.readFileSync(path.join(__dirname, 'data.json'), 'utf-8'));
    res.json({ code: 0, data: d.messages || [] });
  } catch (e) { res.json({ code: 0, data: [] }); }
});
app.get('/api/stats', async (req, res) => {
  try {
    const [g] = await pool.query('SELECT COUNT(*) AS c FROM goods');
    const [u] = await pool.query('SELECT COUNT(*) AS c FROM users');
    res.json({ code: 0, data: { goods: g[0].c, users: u[0].c } });
  } catch (e) { res.json({ code: 0, data: { goods: 0, users: 0 } }); }
});

// ========== AI 配置 ==========
app.get('/api/ai/config', (req, res) => {
  const cfg = getConfig();
  res.json({ code: 0, data: { model: cfg.model, hasKey: !!cfg.apiKey } });
});
app.put('/api/ai/config', (req, res) => {
  if (req.body.model) saveModel(req.body.model);
  res.json({ code: 0, msg: '配置已保存' });
});

// ========== AI 简单对话 ==========
app.post('/api/chat/ai', async (req, res) => {
  const { message, context } = req.body;
  const cfg = getConfig();
  if (!cfg.apiKey) {
    const fallback = ['你好，在的～', '可以的', '嗯嗯', '好的，收到～', '没问题'][Math.floor(Math.random() * 5)];
    return res.json({ code: 0, reply: fallback, ai: false });
  }
  try {
    const messages = [{ role: 'system', content: '你是校园二手交易平台的卖家，友好自然地回复买家咨询。回复简短口语化，像真人微信聊天，不超过50字。' }];
    if (context && context.length) {
      context.slice(-10).forEach(c => messages.push({ role: c.role, content: c.content }));
    }
    messages.push({ role: 'user', content: message });
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 20000);
    try {
      const resp = await fetch(cfg.apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + cfg.apiKey },
        body: JSON.stringify({ model: cfg.model, messages, temperature: 0.8, max_tokens: 100 }),
        signal: ctrl.signal
      });
      if (!resp.ok) throw new Error('HTTP ' + resp.status);
      const result = await resp.json();
      const reply = result.choices && result.choices[0] ? result.choices[0].message.content : '好的';
      res.json({ code: 0, reply, ai: true });
    } finally {
      clearTimeout(timer);
    }
  } catch (e) {
    const fallback = ['好的，收到～', '嗯嗯', '可以的', '没问题'][Math.floor(Math.random() * 4)];
    res.json({ code: 0, reply: fallback, ai: false, error: e.message });
  }
});

// ========== AI 智能体路由 ==========
const { db, buildIndex, searchGoods, getPriceStats } = require('./db');
const ai = require('./ai-agent');

let cachedGoods = [];
async function ensureTables() {
  await pool.query(`CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    goods_id INT NOT NULL,
    buyer_id VARCHAR(64) NOT NULL,
    seller_id VARCHAR(64) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    order_time VARCHAR(32) DEFAULT '刚刚',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);
}
async function refreshGoodsCache() {
  cachedGoods = await getAllGoods();
  buildIndex(cachedGoods);
}
ensureTables().then(refreshGoodsCache).catch(e => console.error('DB init error:', e.message));

app.post('/api/ai/session', (req, res) => {
  const { userId, entry, context } = req.body;
  const s = db.session.create(userId || 'guest', entry || 'float', context);
  res.json({ code: 0, data: s });
});

app.get('/api/ai/session/:id/messages', (req, res) => {
  res.json({ code: 0, data: db.message.listBySession(Number(req.params.id)) });
});

app.post('/api/ai/chat', async (req, res) => {
  const { sessionId, message, history } = req.body;
  const messages = (history || []).map(h => ({ role: h.role, content: h.content }));
  messages.push({ role: 'user', content: message });
  db.message.add(sessionId, 'user', message);
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  let closed = false;
  res.on('close', () => { closed = true; });
  function safeWrite(d) { if (!closed && !res.writableEnded) res.write(d); }
  try {
    if (cachedGoods.length === 0) await refreshGoodsCache();
    const result = await ai.chatAIStream(messages, cachedGoods, sessionId, (chunk) => {
      safeWrite('data: ' + JSON.stringify(chunk) + '\n\n');
    });
    db.message.add(sessionId, 'assistant', result.reply);
    safeWrite('data: ' + JSON.stringify({ type: 'final', reply: result.reply }) + '\n\n');
  } catch (e) {
    safeWrite('data: ' + JSON.stringify({ type: 'error', message: e.message }) + '\n\n');
  }
  if (!res.writableEnded) res.end();
});

app.post('/api/ai/estimate', async (req, res) => {
  const { category, condition } = req.body;
  if (cachedGoods.length === 0) await refreshGoodsCache();
  const stats = getPriceStats(cachedGoods, category);
  if (!stats) return res.json({ code: 1, msg: '暂无该类别成交数据' });
  const condFactor = { '全新': 1.0, '九成新': 0.85, '八成新': 0.7, '七成新': 0.55, '有使用痕迹': 0.4 };
  const factor = condFactor[condition] || 0.8;
  res.json({ code: 0, data: { ...stats, suggestedMin: Math.round(stats.p25 * factor), suggestedMax: Math.round(stats.p75 * factor), suggestedAvg: Math.round(stats.avg * factor), factor } });
});

app.post('/api/ai/search', async (req, res) => {
  const { query } = req.body;
  if (cachedGoods.length === 0) await refreshGoodsCache();
  const results = searchGoods(query, cachedGoods, 6);
  res.json({ code: 0, data: results });
});

app.post('/api/ai/copywrite', async (req, res) => {
  if (cachedGoods.length === 0) await refreshGoodsCache();
  const result = await ai.generateCopywrite(req.body, cachedGoods);
  res.json({ code: 0, data: result });
});

app.get('/api/ai/inspect', (req, res) => res.json({ code: 0, data: ai.INSPECT_CHECKLIST }));
app.get('/api/ai/rules', (req, res) => res.json({ code: 0, data: ai.TRADE_RULES }));
app.post('/api/ai/precheck', (req, res) => {
  const { text } = req.body;
  res.json({ code: 0, data: ai.precheckContent(text) });
});
app.post('/api/ai/feedback', (req, res) => {
  const { sessionId, messageId, userId, rating, comment } = req.body;
  const f = db.feedback.add(sessionId, messageId, userId, rating, comment);
  res.json({ code: 0, data: f });
});
app.get('/api/ai/functions', (req, res) => res.json({ code: 0, data: ai.FUNCTIONS }));

app.get('/', (req, res) => { res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate'); res.sendFile(path.join(__dirname, '..', 'index.html')); });

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws, req) => {
  let userId = null;
  ws.on('message', (msg) => {
    try {
      const d = JSON.parse(msg);
      if (d.type === 'auth' && d.userId) {
        userId = d.userId;
        wsClients.set(userId, ws);
      }
    } catch (e) {}
  });
  ws.on('close', () => {
    if (userId) wsClients.delete(userId);
  });
});

server.listen(PORT, () => {
  console.log(`\n  校园二手交易后端服务已启动（MySQL + WebSocket）`);
  console.log(`  地址: http://localhost:${PORT}`);
  console.log(`  前端: http://localhost:${PORT}/`);
  console.log(`  商品: http://localhost:${PORT}/api/goods`);
  console.log(`  WebSocket: ws://localhost:${PORT}\n`);

});