# 校园二手交易平台 后端设计方案

> Node.js(Express) + MySQL | 微信小程序后端 | 纯后端方案，不含前端代码

---

## 一、全量 MySQL DDL

见 `server/sql/schema.sql`，共 **18 张表**：

| # | 表名 | 说明 | 软删除 |
|---|------|------|--------|
| 1 | users | 用户（openid/手机号AES/学籍认证/信用分） | ✅ deleted_at |
| 2 | categories | 商品分类 | ✅ |
| 3 | goods | 商品（分类/多图/成色/库存/全文索引） | ✅ |
| 4 | goods_images | 商品图片（一对多） | — |
| 5 | favorites | 收藏 | — |
| 6 | browse_history | 浏览历史 | — |
| 7 | addresses | 收货地址（手机号AES） | ✅ |
| 8 | orders | 订单（8种状态） | ✅ |
| 9 | order_status_log | 订单状态流水 | — |
| 10 | logistics | 物流 | — |
| 11 | reviews | 评价（图片JSON/匿名） | ✅ |
| 12 | sessions | 会话（未读数双向） | — |
| 13 | messages | 消息（已读回执/撤回留痕） | — |
| 14 | reports | 举报 | — |
| 15 | notifications | 通知 | — |
| 16 | sensitive_words | 敏感词 | — |
| 17 | admins | 管理员（bcrypt） | ✅ |
| 18 | admin_logs | 管理员操作日志 | — |

**关键设计：**
- 手机号/身份证 **AES-256-CBC 加密**存储，另存 SHA256 哈希用于唯一索引查找
- goods 表含 `FULLTEXT ... WITH PARSER ngram` 中文全文索引
- messages 含 `is_read`/`read_at` 已读回执 + `is_recalled`/`recalled_at` 撤回留痕
- sessions 含 `unread_a`/`unread_b` 双向未读计数
- 所有业务表含 `created_at`/`updated_at`/`deleted_at`

---

## 二、完整 REST API 清单

**鉴权级别：** 🟢公开 🔵用户(JWT) 🔴管理员(JWT)

### 2.1 用户模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| POST | /api/user/login | 🟢 | `{code}` 微信code | `{token, userId, isNew}` |
| GET | /api/user/profile | 🔵 | — | `{id,nickname,avatar,phone,creditScore,verifyStatus}` |
| PUT | /api/user/profile | 🔵 | `{nickname,avatar,bio}` | `{code:0}` |
| POST | /api/user/verify | 🔵 | `{realName,idCardNo,studentNo,school}` | `{code:0,status:"审核中"}` |
| GET | /api/user/:id | 🔵 | — | `{id,nickname,avatar,creditScore}` |

### 2.2 商品模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| GET | /api/goods | 🟢 | `?category&region&tradeType&priceMin&priceMax&keyword&page&size` | `{list,total,page}` |
| GET | /api/goods/:id | 🟢 | — | `{goods,images,seller}` |
| POST | /api/goods | 🔵 | `{title,desc,price,categoryId,condition,stock,tradeType,region,images[]}` | `{code:0,goodsId}` |
| PUT | /api/goods/:id | 🔵 | 同上部分字段 | `{code:0}` |
| DELETE | /api/goods/:id | 🔵 | — | `{code:0}` |
| PUT | /api/goods/:id/shelf | 🔵 | `{action:"on"/"off"}` | `{code:0}` |
| GET | /api/goods/my/published | 🔵 | `?page&size` | `{list,total}` |

### 2.3 分类模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| GET | /api/categories | 🟢 | — | `{list:[{id,name,icon}]}` |

### 2.4 收藏模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| GET | /api/favorites | 🔵 | `?page&size` | `{list,total}` |
| POST | /api/favorites | 🔵 | `{goodsId}` | `{code:0}` |
| DELETE | /api/favorites/:goodsId | 🔵 | — | `{code:0}` |

### 2.5 浏览历史

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| GET | /api/history | 🔵 | `?page&size` | `{list,total}` |
| DELETE | /api/history | 🔵 | — | `{code:0}` |

### 2.6 收货地址

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| GET | /api/addresses | 🔵 | — | `{list}` |
| POST | /api/addresses | 🔵 | `{receiver,phone,province,city,district,detail,isDefault}` | `{code:0,addressId}` |
| PUT | /api/addresses/:id | 🔵 | 同上 | `{code:0}` |
| DELETE | /api/addresses/:id | 🔵 | — | `{code:0}` |

### 2.7 订单模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| POST | /api/orders | 🔵 | `{goodsId,addressId,quantity}` | `{code:0,orderNo}` |
| GET | /api/orders | 🔵 | `?role=buyer/seller&status&page&size` | `{list,total}` |
| GET | /api/orders/:id | 🔵 | — | `{order,statusLog}` |
| POST | /api/orders/:id/pay | 🔵 | — | `{code:0}` |
| POST | /api/orders/:id/ship | 🔵 | `{company,trackingNo}` | `{code:0}` |
| POST | /api/orders/:id/receive | 🔵 | — | `{code:0}` |
| POST | /api/orders/:id/cancel | 🔵 | `{reason}` | `{code:0}` |
| POST | /api/orders/:id/refund | 🔵 | `{reason}` | `{code:0}` |

### 2.8 物流模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| GET | /api/logistics/:orderId | 🔵 | — | `{company,trackingNo,status}` |

### 2.9 评价模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| POST | /api/reviews | 🔵 | `{orderId,rating,content,images,isAnonymous}` | `{code:0}` |
| GET | /api/reviews/goods/:goodsId | 🟢 | `?page&size` | `{list,total}` |
| GET | /api/reviews/user/:userId | 🟢 | `?page&size` | `{list,total}` |

### 2.10 会话与消息模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| GET | /api/sessions | 🔵 | — | `{list:[{sessionId,peerInfo,goodsInfo,lastMsg,unread}]}` |
| GET | /api/sessions/:id/messages | 🔵 | `?page&size&before` | `{list,total}` |
| POST | /api/sessions/:id/messages | 🔵 | `{type,content,extra}` | `{code:0,msgId}` |
| PUT | /api/sessions/:id/read | 🔵 | — | `{code:0}` 清未读 |
| DELETE | /api/messages/:id | 🔵 | — | `{code:0}` 撤回(留痕) |

### 2.11 举报模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| POST | /api/reports | 🔵 | `{targetType,targetId,reason,description,evidence[]}` | `{code:0}` |
| GET | /api/reports/mine | 🔵 | `?page&size` | `{list,total}` |

### 2.12 通知模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| GET | /api/notifications | 🔵 | `?page&size` | `{list,total}` |
| PUT | /api/notifications/:id/read | 🔵 | — | `{code:0}` |
| PUT | /api/notifications/read-all | 🔵 | — | `{code:0}` |

### 2.13 管理员模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| POST | /api/admin/login | 🟢 | `{username,password}` | `{token,role}` |
| GET | /api/admin/goods/pending | 🔴 | `?page&size` | `{list,total}` |
| PUT | /api/admin/goods/:id/audit | 🔴 | `{pass:bool,reason}` | `{code:0}` |
| PUT | /api/admin/users/:id/ban | 🔴 | `{reason}` | `{code:0}` |
| GET | /api/admin/reports | 🔴 | `?status&page&size` | `{list,total}` |
| PUT | /api/admin/reports/:id | 🔴 | `{status,remark}` | `{code:0}` |
| GET | /api/admin/logs | 🔴 | `?action&page&size` | `{list,total}` |

### 2.14 AI智能体模块

| 方法 | 路径 | 鉴权 | 入参 | 返回示例 |
|------|------|------|------|---------|
| POST | /api/ai/session | 🔵 | `{entry,context}` | `{sessionId}` |
| POST | /api/ai/chat | 🔵 | `{sessionId,message,history}` | SSE流式 |
| POST | /api/ai/estimate | 🔵 | `{category,condition}` | `{min,max,avg,median,p25,p75}` |
| POST | /api/ai/search | 🔵 | `{query}` | `{list:[goods]}` |
| POST | /api/ai/copywrite | 🔵 | `{name,cate,cond,imageDesc}` | `{title,desc,price,tags}` |
| GET | /api/ai/inspect | 🔵 | — | `{list:[{item,tip}]}` |
| GET | /api/ai/rules | 🔵 | — | `{list:[{q,a}]}` |
| POST | /api/ai/precheck | 🔵 | `{text}` | `{pass,issues}` |
| POST | /api/ai/feedback | 🔵 | `{sessionId,messageId,rating,comment}` | `{code:0}` |

---

## 三、JWT 鉴权与越权校验

### 3.1 JWT 结构

```json
{
  "userId": 123,
  "role": "user",         // user | admin
  "openid": "wx_xxx",
  "iat": 1698000000,
  "exp": 1698604800       // 7天有效期
}
```

### 3.2 中间件实现

```javascript
// JWT验证中间件
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET;

// 用户鉴权
function authUser(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ code: 401, msg: '未登录' });
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    if (payload.role !== 'user' && payload.role !== 'admin')
      return res.status(403).json({ code: 403, msg: '无权限' });
    req.userId = payload.userId;
    req.role = payload.role;
    next();
  } catch (e) {
    return res.status(401).json({ code: 401, msg: 'token已过期' });
  }
}

// 管理员鉴权
function authAdmin(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ code: 401, msg: '未登录' });
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    if (payload.role !== 'admin')
      return res.status(403).json({ code: 403, msg: '需要管理员权限' });
    req.adminId = payload.userId;
    next();
  } catch (e) {
    return res.status(401).json({ code: 401, msg: 'token已过期' });
  }
}

// 越权校验：只能操作自己的资源
async function checkOwnership(req, res, next) {
  const goods = await GoodsModel.findById(req.params.id);
  if (!goods) return res.status(404).json({ code: 404, msg: '商品不存在' });
  if (goods.seller_id !== req.userId && req.role !== 'admin')
    return res.status(403).json({ code: 403, msg: '无权操作他人商品' });
  req.goods = goods;
  next();
}
```

### 3.3 路由鉴权绑定

```javascript
router.get('/api/goods', publicCtrl.list);                    // 🟢 公开
router.post('/api/goods', authUser, goodsCtrl.create);        // 🔵 用户
router.put('/api/goods/:id', authUser, checkOwnership, goodsCtrl.update); // 🔵+越权校验
router.put('/api/admin/goods/:id/audit', authAdmin, adminCtrl.audit);      // 🔴 管理员
```

---

## 四、安全要求

### 4.1 手机号与身份证 AES 加密

```javascript
const crypto = require('crypto');
const AES_KEY = process.env.AES_KEY;       // 32字节密钥
const AES_IV = process.env.AES_IV;         // 16字节IV

// AES-256-CBC 加密
function encrypt(plaintext) {
  const cipher = crypto.createCipheriv('aes-256-cbc', AES_KEY, AES_IV);
  let encrypted = cipher.update(plaintext, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
}

// AES-256-CBC 解密
function decrypt(ciphertext) {
  const decipher = crypto.createDecipheriv('aes-256-cbc', AES_KEY, AES_IV);
  let decrypted = decipher.update(ciphertext, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

// 存储手机号
function storePhone(phone) {
  return {
    encrypted: encrypt(phone),         // AES加密存储
    hash: crypto.createHash('sha256').update(phone).digest('hex') // 哈希用于查找
  };
}
```

### 4.2 参数预处理防注入

```javascript
// 使用 mysql2 参数化查询（杜绝SQL注入）
const pool = mysql.createPool({ /* ... */ });

// ✅ 正确：参数化查询
pool.execute(
  'SELECT * FROM goods WHERE category_id = ? AND status = ?',
  [categoryId, status]
);

// ❌ 禁止：字符串拼接
// pool.query(`SELECT * FROM goods WHERE id = ${req.params.id}`);

// XSS过滤中间件
const xss = require('xss');
function sanitizeInput(req, res, next) {
  for (const key in req.body) {
    if (typeof req.body[key] === 'string')
      req.body[key] = xss(req.body[key]);
  }
  next();
}
app.use(sanitizeInput);
```

### 4.3 上传校验

```javascript
const multer = require('multer');

const upload = multer({
  storage: multer.diskStorage({
    destination: './uploads/',
    filename: (req, file, cb) => {
      const ext = file.originalname.split('.').pop();
      cb(null, `${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`);
    }
  }),
  limits: { fileSize: 5 * 1024 * 1024 },  // 5MB限制
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    if (allowed.includes(file.mimetype)) cb(null, true);
    else cb(new Error('仅支持JPG/PNG/WebP格式'));
  }
});
app.post('/api/goods', authUser, upload.array('images', 9), goodsCtrl.create);
```

### 4.4 接口限流

```javascript
const rateLimit = require('express-rate-limit');

// 全局限流：每IP每分钟60次
app.use(rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  message: { code: 429, msg: '请求过于频繁' }
}));

// 登录限流：每IP每分钟5次
const loginLimiter = rateLimit({ windowMs: 60*1000, max: 5 });
app.post('/api/user/login', loginLimiter, userCtrl.login);

// AI对话限流：每用户每分钟10次
const aiLimiter = rateLimit({
  windowMs: 60*1000, max: 10,
  keyGenerator: (req) => req.userId || req.ip
});
app.post('/api/ai/chat', authUser, aiLimiter, aiCtrl.chat);
```

---

## 五、部署步骤

### 5.1 环境准备

```bash
# 1. 安装 Node.js 18+ 和 MySQL 8.0+
node -v   # >= 18
mysql --version  # >= 8.0

# 2. 克隆项目
cd server
npm install

# 3. 配置环境变量 .env
cat > .env << EOF
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=campus_flea_market
JWT_SECRET=your_jwt_secret_min_32_chars
AES_KEY=your_32_byte_aes_key_here!!
AES_IV=your_16byte_iv!!
WX_APPID=your_wechat_appid
WX_SECRET=your_wechat_secret
AI_API_KEY=your_qwen_api_key
PORT=3000
EOF
```

### 5.2 数据库初始化

```bash
# 导入DDL
mysql -u root -p < sql/schema.sql

# 验证表创建
mysql -u root -p -e "USE campus_flea_market; SHOW TABLES;"
# 应显示18张表
```

### 5.3 启动服务

```bash
# 开发模式
npm run dev    # nodemon 热重载

# 生产模式
npm start

# PM2守护进程
pm2 start index.js --name campus-market
pm2 save
pm2 startup
```

### 5.4 Nginx反向代理（生产）

```nginx
server {
  listen 443 ssl;
  server_name api.example.com;

  ssl_certificate     /path/to/cert.pem;
  ssl_certificate_key /path/to/key.pem;

  location /api/ {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    # SSE流式支持（AI对话）
    proxy_buffering off;
    proxy_cache off;
    proxy_read_timeout 300s;
  }

  # 文件上传大小限制
  client_max_body_size 10m;
}
```

---

## 六、验收标准

### 6.1 数据库验收

| 验收项 | 标准 |
|--------|------|
| 表结构 | 18张表全部创建成功 |
| 字符集 | 所有表 utf8mb4 |
| 外键 | 15个外键约束生效 |
| 索引 | 主键/唯一/普通/全文索引就位 |
| 软删除 | 业务表含 deleted_at |
| 初始数据 | 10个分类 + 10个敏感词 + 1个管理员 |

### 6.2 API验收

| 验收项 | 标准 |
|--------|------|
| 公开接口 | 商品列表/详情/分类/评价可匿名访问 |
| 用户接口 | 无token返回401，有token正常访问 |
| 越权校验 | 用户A不能修改用户B的商品（返回403） |
| 管理员接口 | 普通用户访问返回403，管理员可访问 |
| 参数校验 | 缺少必填字段返回400+错误信息 |
| 分页 | page/size参数生效，返回total |
| 软删除 | DELETE后记录deleted_at，查询自动过滤 |

### 6.3 安全验收

| 验收项 | 标准 |
|--------|------|
| 手机号加密 | 数据库存储为密文，接口返回脱敏(138****8888) |
| 身份证加密 | 数据库存储为密文 |
| SQL注入 | 参数化查询，拼接SQL被拦截 |
| XSS | 输入内容经过xss过滤 |
| 文件上传 | 非图片类型被拒，>5MB被拒 |
| 限流 | 超限返回429 |
| JWT过期 | 过期token返回401 |

### 6.4 AI模块验收

| 验收项 | 标准 |
|--------|------|
| 对话流式 | SSE逐字输出 |
| 估价Function Calling | 调用estimate_price查真实数据 |
| 找货Function Calling | 调用search_goods返回商品 |
| 内容安全 | 敏感词被拦截 |
| AI标注 | 回复含"AI生成仅供参考" |
| 会话存储 | ai_session/ai_message表有记录 |

### 6.5 性能验收

| 验收项 | 标准 |
|--------|------|
| 商品列表 | 1000条数据 < 200ms |
| 商品详情 | < 100ms |
| 全文搜索 | < 300ms |
| 消息发送 | < 50ms |
| AI对话首字 | < 2s |

---

## 附录：技术栈

| 组件 | 选型 |
|------|------|
| 运行时 | Node.js 18+ |
| Web框架 | Express 4 |
| 数据库 | MySQL 8.0 (utf8mb4) |
| ORM | mysql2 (参数化查询) |
| 鉴权 | jsonwebtoken (JWT) |
| 加密 | crypto (AES-256-CBC) |
| 密码 | bcrypt |
| 上传 | multer |
| 限流 | express-rate-limit |
| XSS | xss |
| AI | 通义千问 (Function Calling) |
| 进程管理 | PM2 |
| 反向代理 | Nginx |