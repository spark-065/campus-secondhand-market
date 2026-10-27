-- ============================================================
-- 校园二手交易平台 MySQL DDL（全量）
-- 数据库: campus_flea_market
-- 字符集: utf8mb4 / utf8mb4_unicode_ci
-- 软删除: 所有业务表含 deleted_at，NULL=未删除
-- ============================================================

CREATE DATABASE IF NOT EXISTS campus_flea_market
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE campus_flea_market;

-- ============================================================
-- 1. 用户表 users
-- ============================================================
CREATE TABLE users (
  id              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  openid          VARCHAR(64)      NOT NULL                COMMENT '微信openid（唯一）',
  unionid         VARCHAR(64)      DEFAULT NULL            COMMENT '微信unionid',
  nickname        VARCHAR(32)      NOT NULL DEFAULT ''     COMMENT '昵称',
  avatar_url      VARCHAR(512)     DEFAULT NULL            COMMENT '头像URL',
  phone_encrypted VARCHAR(128)     DEFAULT NULL            COMMENT '手机号（AES加密存储）',
  phone_hash      CHAR(64)         DEFAULT NULL            COMMENT '手机号SHA256哈希（用于唯一索引查找）',
  id_card_encrypted VARCHAR(256)   DEFAULT NULL            COMMENT '身份证号（AES加密存储）',
  real_name       VARCHAR(32)      DEFAULT NULL            COMMENT '真实姓名',
  school          VARCHAR(64)      DEFAULT NULL            COMMENT '学校名称',
  student_no      VARCHAR(32)      DEFAULT NULL            COMMENT '学号',
  verify_status   TINYINT          NOT NULL DEFAULT 0      COMMENT '学籍认证状态:0未认证1审核中2已认证3未通过',
  credit_score    INT              NOT NULL DEFAULT 100    COMMENT '信用分（初始100，违规扣分）',
  status          TINYINT          NOT NULL DEFAULT 1      COMMENT '账号状态:0封禁1正常',
  last_login_at   DATETIME         DEFAULT NULL            COMMENT '最后登录时间',
  created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  deleted_at      DATETIME         DEFAULT NULL            COMMENT '软删除时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_openid (openid),
  UNIQUE KEY uk_phone_hash (phone_hash),
  KEY idx_school (school),
  KEY idx_verify_status (verify_status),
  KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ============================================================
-- 2. 分类表 categories
-- ============================================================
CREATE TABLE categories (
  id          INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  name        VARCHAR(32)   NOT NULL                COMMENT '分类名称',
  icon        VARCHAR(32)   DEFAULT NULL            COMMENT '分类图标',
  sort_order  INT           NOT NULL DEFAULT 0      COMMENT '排序（越小越靠前）',
  status      TINYINT       NOT NULL DEFAULT 1      COMMENT '状态:0禁用1启用',
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at  DATETIME      DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_sort (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品分类表';

-- ============================================================
-- 3. 商品表 goods
-- ============================================================
CREATE TABLE goods (
  id            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  seller_id     BIGINT UNSIGNED  NOT NULL                COMMENT '卖家用户ID',
  category_id   INT UNSIGNED     NOT NULL                COMMENT '分类ID',
  title         VARCHAR(64)      NOT NULL                COMMENT '商品标题',
  description   TEXT             NOT NULL                COMMENT '商品描述',
  price         DECIMAL(10,2)    NOT NULL                COMMENT '售价',
  original_price DECIMAL(10,2)   DEFAULT NULL            COMMENT '原价（参考）',
  condition     VARCHAR(16)      NOT NULL DEFAULT '九成新' COMMENT '成色:全新/九成新/八成新/七成新/有使用痕迹',
  stock         INT              NOT NULL DEFAULT 1      COMMENT '库存数量',
  trade_type    VARCHAR(16)      NOT NULL DEFAULT '出售'  COMMENT '交易类型:出售/长期租借/短期租借',
  region        VARCHAR(32)      DEFAULT NULL            COMMENT '交易地区',
  status        TINYINT          NOT NULL DEFAULT 0      COMMENT '状态:0在售1已售2下架3审核中4违规',
  view_count    INT              NOT NULL DEFAULT 0      COMMENT '浏览量',
  fav_count     INT              NOT NULL DEFAULT 0      COMMENT '收藏数',
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at    DATETIME         DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_seller (seller_id),
  KEY idx_category (category_id),
  KEY idx_status (status),
  KEY idx_price (price),
  KEY idx_created_at (created_at),
  FULLTEXT KEY ft_title_desc (title, description) WITH PARSER ngram
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品表';

-- ============================================================
-- 4. 商品图片表 goods_images
-- ============================================================
CREATE TABLE goods_images (
  id          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  goods_id    BIGINT UNSIGNED  NOT NULL                COMMENT '商品ID',
  image_url   VARCHAR(512)    NOT NULL                COMMENT '图片URL',
  sort_order  INT             NOT NULL DEFAULT 0      COMMENT '排序',
  created_at  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_goods (goods_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品图片表';

-- ============================================================
-- 5. 收藏表 favorites
-- ============================================================
CREATE TABLE favorites (
  id          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  user_id     BIGINT UNSIGNED  NOT NULL                COMMENT '用户ID',
  goods_id    BIGINT UNSIGNED  NOT NULL                COMMENT '商品ID',
  created_at  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_goods (user_id, goods_id),
  KEY idx_user (user_id),
  KEY idx_goods (goods_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收藏表';

-- ============================================================
-- 6. 浏览历史表 browse_history
-- ============================================================
CREATE TABLE browse_history (
  id          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  user_id     BIGINT UNSIGNED  NOT NULL                COMMENT '用户ID',
  goods_id    BIGINT UNSIGNED  NOT NULL                COMMENT '商品ID',
  viewed_at   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '浏览时间',
  PRIMARY KEY (id),
  KEY idx_user_time (user_id, viewed_at),
  KEY idx_goods (goods_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='浏览历史表';

-- ============================================================
-- 7. 收货地址表 addresses
-- ============================================================
CREATE TABLE addresses (
  id            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  user_id       BIGINT UNSIGNED  NOT NULL                COMMENT '用户ID',
  receiver      VARCHAR(32)      NOT NULL                COMMENT '收货人姓名',
  phone_encrypted VARCHAR(128)   NOT NULL                COMMENT '收货人手机号（AES加密）',
  province      VARCHAR(32)      NOT NULL                COMMENT '省',
  city          VARCHAR(32)      NOT NULL                COMMENT '市',
  district      VARCHAR(32)      NOT NULL                COMMENT '区',
  detail        VARCHAR(128)     NOT NULL                COMMENT '详细地址',
  is_default    TINYINT          NOT NULL DEFAULT 0      COMMENT '是否默认地址',
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at    DATETIME         DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收货地址表';

-- ============================================================
-- 8. 订单表 orders
-- ============================================================
CREATE TABLE orders (
  id              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  order_no        VARCHAR(32)      NOT NULL                COMMENT '订单编号（唯一）',
  buyer_id        BIGINT UNSIGNED  NOT NULL                COMMENT '买家用户ID',
  seller_id       BIGINT UNSIGNED  NOT NULL                COMMENT '卖家用户ID',
  goods_id        BIGINT UNSIGNED  NOT NULL                COMMENT '商品ID',
  goods_title     VARCHAR(64)      NOT NULL                COMMENT '商品标题快照',
  goods_image     VARCHAR(512)     DEFAULT NULL           COMMENT '商品图片快照',
  price           DECIMAL(10,2)    NOT NULL                COMMENT '成交价',
  quantity        INT              NOT NULL DEFAULT 1      COMMENT '数量',
  address_id      BIGINT UNSIGNED  DEFAULT NULL            COMMENT '收货地址ID',
  status          TINYINT          NOT NULL DEFAULT 0      COMMENT '状态:0待付款1已付款待发货2已发货3已收货4已完成5已取消6退款中7已退款',
  pay_time        DATETIME         DEFAULT NULL            COMMENT '付款时间',
  ship_time       DATETIME         DEFAULT NULL            COMMENT '发货时间',
  receive_time    DATETIME         DEFAULT NULL            COMMENT '收货时间',
  finish_time     DATETIME         DEFAULT NULL            COMMENT '完成时间',
  cancel_time     DATETIME         DEFAULT NULL            COMMENT '取消时间',
  created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      DATETIME         DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_order_no (order_no),
  KEY idx_buyer (buyer_id),
  KEY idx_seller (seller_id),
  KEY idx_goods (goods_id),
  KEY idx_status (status),
  KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单表';

-- ============================================================
-- 9. 订单状态流水表 order_status_log
-- ============================================================
CREATE TABLE order_status_log (
  id            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  order_id      BIGINT UNSIGNED  NOT NULL                COMMENT '订单ID',
  from_status   TINYINT          DEFAULT NULL            COMMENT '原状态',
  to_status     TINYINT          NOT NULL                COMMENT '新状态',
  operator_id   BIGINT UNSIGNED  NOT NULL                COMMENT '操作人ID（用户或管理员）',
  operator_type TINYINT          NOT NULL DEFAULT 0      COMMENT '操作人类型:0用户1管理员2系统',
  remark        VARCHAR(128)     DEFAULT NULL            COMMENT '备注',
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_order (order_id),
  KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单状态流水表';

-- ============================================================
-- 10. 物流表 logistics
-- ============================================================
CREATE TABLE logistics (
  id              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  order_id        BIGINT UNSIGNED  NOT NULL                COMMENT '订单ID',
  company         VARCHAR(32)      NOT NULL                COMMENT '物流公司',
  tracking_no     VARCHAR(64)      NOT NULL                COMMENT '物流单号',
  status          TINYINT          NOT NULL DEFAULT 0      COMMENT '状态:0已寄出1运输中2已签收',
  sender_address  VARCHAR(256)     DEFAULT NULL            COMMENT '寄件地址',
  receiver_address VARCHAR(256)    DEFAULT NULL            COMMENT '收件地址',
  created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_order (order_id),
  KEY idx_tracking (tracking_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='物流表';

-- ============================================================
-- 11. 评价表 reviews
-- ============================================================
CREATE TABLE reviews (
  id          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  order_id    BIGINT UNSIGNED  NOT NULL                COMMENT '订单ID',
  goods_id    BIGINT UNSIGNED  NOT NULL                COMMENT '商品ID',
  from_user   BIGINT UNSIGNED  NOT NULL                COMMENT '评价人ID',
  to_user     BIGINT UNSIGNED  NOT NULL                COMMENT '被评价人ID',
  rating      TINYINT          NOT NULL DEFAULT 5      COMMENT '评分1-5星',
  content     VARCHAR(256)     DEFAULT NULL            COMMENT '评价内容',
  images      JSON             DEFAULT NULL            COMMENT '评价图片URL数组',
  is_anonymous TINYINT         NOT NULL DEFAULT 0      COMMENT '是否匿名',
  created_at  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at  DATETIME         DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_order_from (order_id, from_user),
  KEY idx_goods (goods_id),
  KEY idx_to_user (to_user),
  KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评价表';

-- ============================================================
-- 12. 会话表 sessions
-- ============================================================
CREATE TABLE sessions (
  id            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  user_a_id     BIGINT UNSIGNED  NOT NULL                COMMENT '用户A ID',
  user_b_id     BIGINT UNSIGNED  NOT NULL                COMMENT '用户B ID',
  goods_id      BIGINT UNSIGNED  DEFAULT NULL            COMMENT '关联商品ID',
  last_msg      VARCHAR(256)     DEFAULT NULL            COMMENT '最后一条消息摘要',
  last_msg_at   DATETIME         DEFAULT NULL            COMMENT '最后消息时间',
  unread_a      INT              NOT NULL DEFAULT 0      COMMENT 'A未读数',
  unread_b      INT              NOT NULL DEFAULT 0      COMMENT 'B未读数',
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_pair_goods (user_a_id, user_b_id, goods_id),
  KEY idx_user_a (user_a_id),
  KEY idx_user_b (user_b_id),
  KEY idx_last_msg (last_msg_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会话表';

-- ============================================================
-- 13. 消息表 messages（含已读回执、撤回留痕）
-- ============================================================
CREATE TABLE messages (
  id            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  session_id    BIGINT UNSIGNED  NOT NULL                COMMENT '会话ID',
  sender_id    BIGINT UNSIGNED  NOT NULL                COMMENT '发送者ID',
  receiver_id  BIGINT UNSIGNED  NOT NULL                COMMENT '接收者ID',
  type         TINYINT          NOT NULL DEFAULT 0      COMMENT '消息类型:0文本1图片2商品卡片3系统4AI回复',
  content      TEXT             NOT NULL                COMMENT '消息内容',
  extra        JSON             DEFAULT NULL            COMMENT '附加数据（图片URL/商品ID等）',
  is_read      TINYINT          NOT NULL DEFAULT 0      COMMENT '已读回执:0未读1已读',
  read_at      DATETIME         DEFAULT NULL            COMMENT '已读时间',
  is_recalled  TINYINT          NOT NULL DEFAULT 0      COMMENT '撤回留痕:0正常1已撤回',
  recalled_at  DATETIME         DEFAULT NULL            COMMENT '撤回时间',
  created_at   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_session (session_id),
  KEY idx_sender (sender_id),
  KEY idx_receiver_read (receiver_id, is_read),
  KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='消息表';

-- ============================================================
-- 14. 举报表 reports
-- ============================================================
CREATE TABLE reports (
  id            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  reporter_id   BIGINT UNSIGNED  NOT NULL                COMMENT '举报人ID',
  target_type   TINYINT         NOT NULL                COMMENT '举报对象类型:0商品1用户2消息3评价',
  target_id     BIGINT UNSIGNED  NOT NULL                COMMENT '举报对象ID',
  reason        VARCHAR(64)     NOT NULL                COMMENT '举报原因',
  description   VARCHAR(512)    DEFAULT NULL            COMMENT '详细描述',
  evidence      JSON            DEFAULT NULL            COMMENT '证据图片URL数组',
  status        TINYINT         NOT NULL DEFAULT 0      COMMENT '状态:0待处理1处理中2已处理-驳回3已处理-封禁',
  handler_id    BIGINT UNSIGNED  DEFAULT NULL            COMMENT '处理人（管理员）ID',
  handle_remark VARCHAR(256)    DEFAULT NULL            COMMENT '处理备注',
  handled_at    DATETIME        DEFAULT NULL            COMMENT '处理时间',
  created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_target (target_type, target_id),
  KEY idx_status (status),
  KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='举报表';

-- ============================================================
-- 15. 通知表 notifications
-- ============================================================
CREATE TABLE notifications (
  id          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  user_id     BIGINT UNSIGNED  NOT NULL                COMMENT '接收用户ID',
  type        VARCHAR(16)      NOT NULL                COMMENT '类型:order/system/like/comment/report',
  title       VARCHAR(64)      NOT NULL                COMMENT '通知标题',
  content     VARCHAR(256)     NOT NULL                COMMENT '通知内容',
  extra       JSON             DEFAULT NULL            COMMENT '附加数据（订单号/商品ID等）',
  is_read     TINYINT          NOT NULL DEFAULT 0      COMMENT '是否已读',
  created_at  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_user_read (user_id, is_read),
  KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知表';

-- ============================================================
-- 16. 敏感词表 sensitive_words
-- ============================================================
CREATE TABLE sensitive_words (
  id          INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  word        VARCHAR(64)   NOT NULL                COMMENT '敏感词',
  level       TINYINT       NOT NULL DEFAULT 1      COMMENT '级别:1替换2拦截',
  status      TINYINT       NOT NULL DEFAULT 1      COMMENT '状态:0禁用1启用',
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_word (word),
  KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='敏感词表';

-- ============================================================
-- 17. 管理员表 admins
-- ============================================================
CREATE TABLE admins (
  id          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  username    VARCHAR(32)      NOT NULL                COMMENT '登录用户名',
  password    VARCHAR(128)     NOT NULL                COMMENT '密码（bcrypt哈希）',
  role        TINYINT          NOT NULL DEFAULT 1      COMMENT '角色:0超管1运营2审核',
  real_name   VARCHAR(32)      DEFAULT NULL            COMMENT '真实姓名',
  status      TINYINT          NOT NULL DEFAULT 1      COMMENT '状态:0禁用1启用',
  last_login_at DATETIME       DEFAULT NULL            COMMENT '最后登录时间',
  created_at  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at  DATETIME         DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员表';

-- ============================================================
-- 18. 管理员操作日志表 admin_logs
-- ============================================================
CREATE TABLE admin_logs (
  id          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  admin_id    BIGINT UNSIGNED  NOT NULL                COMMENT '管理员ID',
  action      VARCHAR(32)      NOT NULL                COMMENT '操作类型:login/goods_audit/ban_user/handle_report等',
  target_type VARCHAR(32)      DEFAULT NULL            COMMENT '操作对象类型',
  target_id   BIGINT UNSIGNED  DEFAULT NULL            COMMENT '操作对象ID',
  detail      JSON             DEFAULT NULL            COMMENT '操作详情',
  ip          VARCHAR(45)      DEFAULT NULL            COMMENT '操作IP',
  created_at  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_admin (admin_id),
  KEY idx_action (action),
  KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员操作日志表';

-- ============================================================
-- 外键约束
-- ============================================================
ALTER TABLE goods        ADD CONSTRAINT fk_goods_seller   FOREIGN KEY (seller_id)   REFERENCES users(id);
ALTER TABLE goods        ADD CONSTRAINT fk_goods_category FOREIGN KEY (category_id) REFERENCES categories(id);
ALTER TABLE goods_images ADD CONSTRAINT fk_img_goods     FOREIGN KEY (goods_id)    REFERENCES goods(id) ON DELETE CASCADE;
ALTER TABLE favorites    ADD CONSTRAINT fk_fav_user      FOREIGN KEY (user_id)     REFERENCES users(id);
ALTER TABLE favorites    ADD CONSTRAINT fk_fav_goods     FOREIGN KEY (goods_id)    REFERENCES goods(id);
ALTER TABLE browse_history ADD CONSTRAINT fk_bh_user    FOREIGN KEY (user_id)     REFERENCES users(id);
ALTER TABLE browse_history ADD CONSTRAINT fk_bh_goods   FOREIGN KEY (goods_id)    REFERENCES goods(id);
ALTER TABLE addresses    ADD CONSTRAINT fk_addr_user    FOREIGN KEY (user_id)     REFERENCES users(id);
ALTER TABLE orders       ADD CONSTRAINT fk_order_buyer   FOREIGN KEY (buyer_id)    REFERENCES users(id);
ALTER TABLE orders       ADD CONSTRAINT fk_order_seller  FOREIGN KEY (seller_id)   REFERENCES users(id);
ALTER TABLE orders       ADD CONSTRAINT fk_order_goods   FOREIGN KEY (goods_id)     REFERENCES goods(id);
ALTER TABLE order_status_log ADD CONSTRAINT fk_sl_order FOREIGN KEY (order_id)     REFERENCES orders(id);
ALTER TABLE logistics    ADD CONSTRAINT fk_log_order    FOREIGN KEY (order_id)    REFERENCES orders(id);
ALTER TABLE reviews      ADD CONSTRAINT fk_rev_order    FOREIGN KEY (order_id)     REFERENCES orders(id);
ALTER TABLE reviews      ADD CONSTRAINT fk_rev_goods    FOREIGN KEY (goods_id)     REFERENCES goods(id);
ALTER TABLE messages     ADD CONSTRAINT fk_msg_session  FOREIGN KEY (session_id)   REFERENCES sessions(id);
ALTER TABLE admin_logs   ADD CONSTRAINT fk_log_admin    FOREIGN KEY (admin_id)     REFERENCES admins(id);

-- ============================================================
-- 初始数据
-- ============================================================
INSERT INTO categories (name, icon, sort_order) VALUES
('书籍','📚',1),('交通工具','🚲',2),('电子数码','📱',3),('运动器材','🏸',4),
('生活用品','💡',5),('美妆护肤','💄',6),('文创文具','📔',7),('乐器','🎸',8),
('食品','🍜',9),('其他','📦',10);

INSERT INTO sensitive_words (word, level) VALUES
('诈骗',2),('假货',2),('黄牛',2),('刷单',2),('代写论文',2),('考试答案',2),
('枪',2),('管制刀具',2),('电子烟',2),('违禁',2);

INSERT INTO admins (username, password, role, real_name) VALUES
('admin','$2b$10$placeholder_bcrypt_hash_here',0,'超级管理员');