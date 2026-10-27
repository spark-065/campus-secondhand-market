export class C {
  static readonly primary: string = '#1B6E9C'
  static readonly primarySoft: string = '#E3F1F8'
  static readonly primaryDeep: string = '#155A82'
  static readonly bg: string = '#F4F7FC'
  static readonly card: string = '#FFFFFF'
  static readonly ink: string = '#1A2332'
  static readonly ink2: string = '#5A6B80'
  static readonly ink3: string = '#9AA8B8'
  static readonly line: string = '#E8EEF5'
  static readonly danger: string = '#FF5A5F'
}

export interface GradientInfo {
  from: string
  to: string
}

export const GRADIENTS: GradientInfo[] = [
  { from: '#667EEA', to: '#764BA2' },
  { from: '#F093FB', to: '#F5576C' },
  { from: '#4FACFE', to: '#00F2FE' },
  { from: '#43E97B', to: '#38F9D7' },
  { from: '#FA709A', to: '#FEE140' },
  { from: '#30CFD0', to: '#330867' },
  { from: '#A8EDEA', to: '#FED6E2' },
  { from: '#FF9A9E', to: '#FECFEF' },
  { from: '#5EE7DF', to: '#B490CA' },
  { from: '#F6D365', to: '#FDA085' }
]

export interface GoodsItem {
  name: string
  price: number
  emoji: string
  grad: number
  seller: string
  sellerAvatar: string
  sellerGrad: number
  publishTime: string
  desc: string
  condition: string
  category: string
  region: string
  tradeType: string
}

export const GOODS: GoodsItem[] = [
  { name: '高等数学第七版', price: 15, emoji: '📚', grad: 0, seller: '陈同学', sellerAvatar: '🧑', sellerGrad: 3, publishTime: '2 小时前', desc: '高等数学第七版同济版，笔记不多，封面整洁，考研复习利器，可面交或寄送。', condition: '八成新', category: '书籍', region: '一期', tradeType: '出售' },
  { name: '山地自行车九成新', price: 280, emoji: '🚲', grad: 1, seller: '老张学长', sellerAvatar: '👨', sellerGrad: 5, publishTime: '5 小时前', desc: '捷安特山地车，27.5 轮径，变速顺畅，毕业出，支持试骑，东校区可自提。', condition: '九成新', category: '交通工具', region: '东校区', tradeType: '出售' },
  { name: 'iPad Air 64G', price: 1200, emoji: '📱', grad: 2, seller: '阿杰', sellerAvatar: '🧑‍🎓', sellerGrad: 7, publishTime: '1 天前', desc: 'iPad Air 第三代 64G WiFi 版，无拆无修，屏幕完美，配原装充电器，澎湖苑面交。', condition: '九成新', category: '电子数码', region: '澎湖苑', tradeType: '出售' },
  { name: '羽毛球拍尤尼克斯', price: 90, emoji: '🏸', grad: 3, seller: '小美', sellerAvatar: '👩', sellerGrad: 0, publishTime: '3 小时前', desc: '尤尼克斯天斧88，线还新，打感扎实，送拍包，二期体育馆可试打。', condition: '八成新', category: '运动器材', region: '二期', tradeType: '出售' },
  { name: '小米台灯护眼', price: 35, emoji: '💡', grad: 4, seller: '苏苏', sellerAvatar: '👧', sellerGrad: 4, publishTime: '6 小时前', desc: '小米米家台灯，可调色温亮度，USB 供电，宿舍神器，几乎没用过。', condition: '九成新', category: '生活用品', region: '一期', tradeType: '出售' },
  { name: '兰蔻小样套装', price: 60, emoji: '💄', grad: 5, seller: '小鹿', sellerAvatar: '🦌', sellerGrad: 6, publishTime: '8 小时前', desc: '兰蔻小样7件套，精华+眼霜+面霜，正品专柜赠品，未拆封，打包出。', condition: '全新', category: '美妆护肤', region: '二期', tradeType: '出售' },
  { name: '手帐本+胶带', price: 25, emoji: '📔', grad: 6, seller: '苏苏', sellerAvatar: '👧', sellerGrad: 4, publishTime: '4 小时前', desc: 'tn 手帐本一本 + 和纸胶带十卷，记录生活好伙伴，文具控入。', condition: '全新', category: '文创文具', region: '一期', tradeType: '出售' },
  { name: '民谣吉他41寸', price: 360, emoji: '🎸', grad: 7, seller: '阿杰', sellerAvatar: '🧑‍🎓', sellerGrad: 7, publishTime: '2 天前', desc: '卡马 D1C 41寸民谣吉他，音色温暖，送琴包+变调夹+拨片，新手入门首选。', condition: '八成新', category: '乐器', region: '东校区', tradeType: '出售' },
  { name: '自热火锅整箱', price: 45, emoji: '🍜', grad: 8, seller: '小美', sellerAvatar: '👩', sellerGrad: 0, publishTime: '1 天前', desc: '自热火锅整箱12盒，多种口味，期末囤货出，日期新鲜，宿舍夜宵必备。', condition: '全新', category: '食品', region: '二期', tradeType: '出售' },
  { name: '机械键盘茶轴', price: 150, emoji: '⌨', grad: 9, seller: '陈同学', sellerAvatar: '🧑', sellerGrad: 3, publishTime: '7 小时前', desc: 'IKBC 茶轴机械键盘，PBT 键帽，手感温润，无打油，写代码利器。', condition: '九成新', category: '电子数码', region: '一期', tradeType: '出售' },
  { name: '考研政治资料', price: 20, emoji: '📖', grad: 0, seller: '老张学长', sellerAvatar: '👨', sellerGrad: 5, publishTime: '10 小时前', desc: '肖秀荣全套 + 徐涛笔记，已上岸，资料完整，传给下一届考研人。', condition: '七成新', category: '书籍', region: '东校区', tradeType: '出售' },
  { name: '滑板陆地冲浪', price: 220, emoji: '🛹', grad: 1, seller: '小鹿', sellerAvatar: '🦌', sellerGrad: 6, publishTime: '5 小时前', desc: 'YOW 陆地冲浪板，桥灵活，刷街利器，玩了几次，适合代步刷街。', condition: '八成新', category: '运动器材', region: '澎湖苑', tradeType: '出售' },
  { name: '空气炸锅3.5L', price: 130, emoji: '🍳', grad: 2, seller: '苏苏', sellerAvatar: '👧', sellerGrad: 4, publishTime: '1 天前', desc: '美的空气炸锅3.5L，无油低脂，做鸡翅薯条一绝，搬家出，配件齐。', condition: '九成新', category: '生活用品', region: '一期', tradeType: '出售' },
  { name: 'JK制服格子裙', price: 75, emoji: '👗', grad: 3, seller: '小美', sellerAvatar: '👩', sellerGrad: 0, publishTime: '3 小时前', desc: '中牌 JK 制服格子裙 M 码，穿过两次，无污渍，配领结，甜美风。', condition: '九成新', category: '生活用品', region: '二期', tradeType: '出售' },
  { name: '索尼降噪耳机', price: 480, emoji: '🎧', grad: 4, seller: '阿杰', sellerAvatar: '🧑‍🎓', sellerGrad: 7, publishTime: '6 小时前', desc: '索尼 WH-1000XM3 降噪耳机，降噪一绝，耳罩无磨损，配原装盒线。', condition: '八成新', category: '电子数码', region: '东校区', tradeType: '出售' },
  { name: '尤克里里入门', price: 110, emoji: '🪕', grad: 5, seller: '小鹿', sellerAvatar: '🦌', sellerGrad: 6, publishTime: '4 小时前', desc: '歌瑞拉23寸尤克里里，桃花心木，音色亮，送教程书+调音器，可租。', condition: '九成新', category: '乐器', region: '澎湖苑', tradeType: '长期租借' },
  { name: '咖啡手冲套装', price: 95, emoji: '☕', grad: 6, seller: '陈同学', sellerAvatar: '🧑', sellerGrad: 3, publishTime: '8 小时前', desc: '手冲咖啡套装：滤杯+分享壶+电子秤+滤纸，宿舍手冲入门全套。', condition: '九成新', category: '生活用品', region: '一期', tradeType: '出售' },
  { name: '乐高街景散件', price: 200, emoji: '🧩', grad: 7, seller: '苏苏', sellerAvatar: '👧', sellerGrad: 4, publishTime: '2 天前', desc: '乐高街景系列散件约800块，含人仔6个，说明书电子版，拼搭党入。', condition: '有使用痕迹', category: '文创文具', region: '二期', tradeType: '出售' },
  { name: '电钢琴88键', price: 880, emoji: '🎹', grad: 8, seller: '老张学长', sellerAvatar: '👨', sellerGrad: 5, publishTime: '3 天前', desc: '罗兰 FP30 电钢琴88键全配重，带琴架+踏板+耳机，毕业出，音质好。', condition: '九成新', category: '乐器', region: '东校区', tradeType: '出售' },
  { name: '露营天幕帐篷', price: 260, emoji: '⛺', grad: 9, seller: '小美', sellerAvatar: '👩', sellerGrad: 0, publishTime: '1 天前', desc: '挪客天幕3x4米+地钉风绳，露营遮阳利器，用两次，可短租试玩。', condition: '九成新', category: '运动器材', region: '澎湖苑', tradeType: '短期租借' }
]

export interface CommentItem {
  name: string
  avatar: string
  grad: number
  content: string
  time: string
  isSeller: boolean
}

export const COMMENTS: CommentItem[] = [
  { name: '陈同学', avatar: '🧑', grad: 3, content: '还在吗？能小刀一点吗～', time: '1 小时前', isSeller: false },
  { name: '苏苏', avatar: '👧', grad: 4, content: '可以小刀5块，面交的话', time: '50 分钟前', isSeller: true },
  { name: '小鹿', avatar: '🦌', grad: 6, content: '请问东校区可以送过来吗', time: '30 分钟前', isSeller: false },
  { name: '苏苏', avatar: '👧', grad: 4, content: '东校区有点远，一期门口可以吗', time: '25 分钟前', isSeller: true },
  { name: '阿杰', avatar: '🧑‍🎓', grad: 7, content: '成色怎么样，有细节图吗', time: '10 分钟前', isSeller: false }
]

export interface CircleItem {
  seller: string
  time: string
  avatarEmoji: string
  avatarGrad: number
  text: string
  coverEmoji: string
  coverGrad: number
}

export const CIRCLE: CircleItem[] = [
  { seller: '陈同学', time: '2 分钟前', avatarEmoji: '🧑', avatarGrad: 3, text: '出九成新 Switch 续航增强版，带两个游戏卡带，可面交～', coverEmoji: '🎮', coverGrad: 5 },
  { seller: '苏苏的杂货铺', time: '15 分钟前', avatarEmoji: '👧', avatarGrad: 4, text: '整理出一批手账文具，斑马、百乐笔都有，打包出更划算', coverEmoji: '✏️', coverGrad: 6 },
  { seller: '老张学长', time: '1 小时前', avatarEmoji: '👨', avatarGrad: 5, text: '毕业甩卖：电吹风 + 烧水壶 + 台灯，三件套一口价 50', coverEmoji: '💡', coverGrad: 7 },
  { seller: '小鹿要毕业', time: '3 小时前', avatarEmoji: '🦌', avatarGrad: 6, text: '舞蹈练功服两套，只穿过两次，码数 S，需要的姐妹来', coverEmoji: '💃', coverGrad: 8 }
]

export interface MsgItem {
  name: string
  last: string
  time: string
  emoji: string
  grad: number
  badge: number
}

export const MSGS: MsgItem[] = [
  { name: '陈同学', last: '好的，那就明天下午图书馆门口见～', time: '刚刚', emoji: '🧑', grad: 2, badge: 2 },
  { name: '苏苏的杂货铺', last: '笔的话打包价 35 包邮哦', time: '10:24', emoji: '👧', grad: 3, badge: 0 },
  { name: '老张学长', last: '三件套还在的，先到先得', time: '昨天', emoji: '👨', grad: 4, badge: 1 },
  { name: '小鹿要毕业', last: '码数是 S，你看看合适不', time: '昨天', emoji: '🦌', grad: 5, badge: 0 },
  { name: '校园驿站', last: '你的包裹已到 3 号柜，取件码 8842', time: '周四', emoji: '📦', grad: 6, badge: 0 },
  { name: '系统通知', last: '你发布的商品有 3 条新浏览记录', time: '周三', emoji: '🔔', grad: 7, badge: 0 }
]

export interface MenuItem {
  icon: string
  label: string
  sub: string
}

export const MENU: MenuItem[] = [
  { icon: '📦', label: '我的发布', sub: '12 件在售' },
  { icon: '♡', label: '我的收藏', sub: '36 件' },
  { icon: '📜', label: '历史订单', sub: '查看全部' },
  { icon: '💰', label: '我的钱包', sub: '余额 ¥128.50' },
  { icon: '⭐', label: '我的评价', sub: '待评价 2' },
  { icon: '⚙️', label: '设置', sub: '' }
]

export const CATEGORIES: string[] = ['书籍', '交通工具', '电子数码', '运动器材', '生活用品', '美妆护肤', '文创文具', '乐器', '食品', '其他']
export const PRICES: string[] = ['0-30', '30-50', '50-100', '100-200', '200-500', '500-1000', '1000+']
export const REGIONS: string[] = ['一期', '二期', '东校区', '澎湖苑']
export const TYPES: string[] = ['出售', '长期租借', '短期租借']

export function priceInRange(price: number, range: string): boolean {
  if (range === '1000+') return price >= 1000
  const parts = range.split('-')
  const lo = parseInt(parts[0], 10)
  const hi = parseInt(parts[1], 10)
  return price >= lo && price < hi
}