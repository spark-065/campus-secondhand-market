const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

const DB_CONFIG = {
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: '',
  database: 'shop_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

const TABLES = [
  `CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(64) PRIMARY KEY,
    nick_name VARCHAR(64) NOT NULL DEFAULT '',
    bio VARCHAR(256) DEFAULT '这个人很懒，什么都没留下～',
    avatar TEXT,
    password VARCHAR(6) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`,
  `CREATE TABLE IF NOT EXISTS goods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    emoji VARCHAR(16) DEFAULT '📦',
    grad INT DEFAULT 0,
    seller VARCHAR(64) NOT NULL,
    seller_avatar VARCHAR(16) DEFAULT '🧑',
    seller_grad INT DEFAULT 0,
    publish_time VARCHAR(32) DEFAULT '刚刚',
    description TEXT,
    \`condition\` VARCHAR(16) DEFAULT '九成新',
    category VARCHAR(32) DEFAULT '其他',
    region VARCHAR(32) DEFAULT '一期',
    trade_type VARCHAR(16) DEFAULT '出售',
    image TEXT,
    seller_id VARCHAR(64),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`,
  `CREATE TABLE IF NOT EXISTS favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    goods_id INT NOT NULL,
    UNIQUE KEY uk_user_goods (user_id, goods_id)
  )`,
  `CREATE TABLE IF NOT EXISTS follows (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    seller_name VARCHAR(64) NOT NULL,
    UNIQUE KEY uk_user_seller (user_id, seller_name)
  )`,
  `CREATE TABLE IF NOT EXISTS reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    goods_name VARCHAR(128) NOT NULL,
    goods_id INT NOT NULL,
    seller VARCHAR(64) NOT NULL,
    content TEXT,
    review_time VARCHAR(32) DEFAULT '刚刚',
    rating INT DEFAULT 5
  )`,
  `CREATE TABLE IF NOT EXISTS chats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    contact VARCHAR(64) NOT NULL,
    message_text TEXT,
    is_me TINYINT DEFAULT 1,
    msg_time VARCHAR(32) DEFAULT '刚刚',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`,
  `CREATE TABLE IF NOT EXISTS comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    goods_id INT NOT NULL,
    name VARCHAR(64) NOT NULL,
    avatar VARCHAR(16) DEFAULT '🧑',
    grad INT DEFAULT 0,
    content TEXT,
    comment_time VARCHAR(32) DEFAULT '刚刚',
    is_seller TINYINT DEFAULT 0
  )`,
  `CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    goods_id INT NOT NULL,
    buyer_id VARCHAR(64) NOT NULL,
    seller_id VARCHAR(64) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    order_time VARCHAR(32) DEFAULT '刚刚',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`
];

async function main() {
  let conn;
  try {
    conn = await mysql.createConnection({
      host: DB_CONFIG.host,
      port: DB_CONFIG.port,
      user: DB_CONFIG.user,
      password: DB_CONFIG.password
    });
    console.log('✓ 已连接 MySQL');

    await conn.query('CREATE DATABASE IF NOT EXISTS shop_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    await conn.query('USE shop_db');
    console.log('✓ 数据库 shop_db 已就绪');

    const [existTables] = await conn.query(`SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='shop_db'`);
    const existing = existTables.map(r => r.TABLE_NAME);
    const needCols = { goods: 'emoji', users: 'password', favorites: 'goods_id', follows: 'seller_name', reviews: 'goods_id', chats: 'message_text', comments: 'goods_id' };
    for (const tbl of Object.keys(needCols)) {
      if (existing.includes(tbl)) {
        const [cols] = await conn.query(`SHOW COLUMNS FROM \`${tbl}\``);
        const colNames = cols.map(c => c.Field);
        if (!colNames.includes(needCols[tbl])) {
          await conn.query(`DROP TABLE \`${tbl}\``);
          console.log('ℹ 旧表 ' + tbl + ' 结构不匹配，已删除重建');
        }
      }
    }

    for (let i = 0; i < TABLES.length; i++) {
      await conn.query(TABLES[i]);
    }
    console.log('✓ 已创建 ' + TABLES.length + ' 张表');

    const [rows] = await conn.query('SELECT COUNT(*) AS cnt FROM goods');
    const goodsCount = rows[0].cnt;

    if (goodsCount > 0) {
      console.log('ℹ goods 表已有 ' + goodsCount + ' 条数据，跳过导入');
    } else {
      const dataFile = path.join(__dirname, 'data.json');
      const data = JSON.parse(fs.readFileSync(dataFile, 'utf-8'));
      const goods = data.goods || [];

      const insertSql = `INSERT INTO goods (name, price, emoji, grad, seller, seller_avatar, seller_grad, publish_time, description, \`condition\`, category, region, trade_type, image, seller_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

      let imported = 0;
      for (let i = 0; i < goods.length; i++) {
        const g = goods[i];
        await conn.query(insertSql, [
          g.name || '',
          g.price || 0,
          g.emoji || '📦',
          g.grad || 0,
          g.seller || '',
          g.sellerAvatar || '🧑',
          g.sellerGrad || 0,
          g.publishTime || '刚刚',
          g.desc || '',
          g.condition || '九成新',
          g.category || '其他',
          g.region || '一期',
          g.tradeType || '出售',
          g.image || null,
          g.sellerId || null
        ]);
        imported++;
      }
      console.log('✓ 已导入 ' + imported + ' 件商品数据');
    }

    const [trows] = await conn.query(`
      SELECT 'users' AS t, COUNT(*) AS c FROM users
      UNION ALL SELECT 'goods', COUNT(*) FROM goods
      UNION ALL SELECT 'favorites', COUNT(*) FROM favorites
      UNION ALL SELECT 'follows', COUNT(*) FROM follows
      UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
      UNION ALL SELECT 'chats', COUNT(*) FROM chats
      UNION ALL SELECT 'comments', COUNT(*) FROM comments
    `);
    console.log('\n========== 数据统计 ==========');
    trows.forEach(function (r) {
      console.log('  ' + r.t + ': ' + r.c + ' 条');
    });
    console.log('==============================');

    console.log('\n✓ 数据库初始化完成');
  } catch (e) {
    console.error('✗ 初始化失败:', e.message);
    process.exit(1);
  } finally {
    if (conn) await conn.end();
  }
}

main();