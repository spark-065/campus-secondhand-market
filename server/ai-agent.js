const { db, searchGoods, getPriceStats } = require('./db');
const { getConfig } = require('./config');

const TOOLS = [
  {
    type: 'function',
    function: {
      name: 'estimate_price',
      description: '智能估价：依据本校近三月真实成交价给出价格区间，禁止编造',
      parameters: {
        type: 'object',
        properties: {
          category: { type: 'string', description: '商品类别' },
          condition: { type: 'string', description: '成色新旧' }
        },
        required: ['category']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'search_goods',
      description: '自然语言找货：检索校内商品库，返回匹配商品',
      parameters: {
        type: 'object',
        properties: {
          query: { type: 'string', description: '用户搜索词' }
        },
        required: ['query']
      }
    }
  }
];

function executeTool(name, args, goods) {
  if (name === 'estimate_price') {
    const stats = getPriceStats(goods, args.category);
    if (!stats) return { error: '暂无该类别成交数据' };
    return stats;
  }
  if (name === 'search_goods') {
    const results = searchGoods(args.query, goods, 6);
    return results.map(g => ({ id: g.id, name: g.name, price: g.price, emoji: g.emoji, seller: g.seller, cond: g.cond, cate: g.cate }));
  }
  return { error: '未知工具' };
}

const BANNED_WORDS = ['违禁', '假货', '黄牛', '刷单', '代写论文', '考试答案', '管制刀具', '电子烟'];
function contentSafety(text) {
  for (const w of BANNED_WORDS) {
    if (text.indexOf(w) >= 0) return { safe: false, word: w };
  }
  return { safe: true };
}

const FUNCTIONS = {
  estimate: '智能估价',
  copywrite: '一键生成文案',
  search: '自然语言找货',
  inspect: '验货防骗清单',
  rule: '交易规则客服',
  precheck: '发布违规预检'
};

async function chatAI(messages, goods, sessionId, streamCallback) {
  const sysMsg = {
    role: 'system',
    content: '你是校园二手交易小程序的AI助手"小集"。回答必须结构化（用【卡片】格式），带操作按钮，禁止大段纯文字。涉及价格必须调用estimate_price工具查真实数据，禁止编造。找货必须调用search_goods工具。每次回答末尾标注"AI生成仅供参考"。不做交易担保。回复简短，像卡片消息。'
  };

  let reqMessages = [sysMsg, ...messages];

  const resp1 = await callQwen(reqMessages, TOOLS);
  let choice = resp1.choices[0];

  if (choice.message.tool_calls && choice.message.tool_calls.length) {
    reqMessages.push(choice.message);
    for (const tc of choice.message.tool_calls) {
      let args = {};
      try { args = JSON.parse(tc.function.arguments || '{}'); } catch (e) { args = {}; }
      const result = executeTool(tc.function.name, args, goods);
      db.toolCall.add(sessionId, tc.function.name, args, result);

      if (streamCallback) streamCallback({ type: 'tool_call', tool: tc.function.name, args, result });

      reqMessages.push({ role: 'tool', content: JSON.stringify(result), tool_call_id: tc.id });
    }
    const resp2 = await callQwen(reqMessages, null);
    choice = resp2.choices[0];
  }

  const reply = choice.message.content;
  const safety = contentSafety(reply);
  if (!safety.safe) {
    return { reply: '⚠️检测到敏感内容，请规范提问。AI生成仅供参考。', safe: false, blocked: safety.word };
  }
  return { reply, safe: true };
}

async function callQwen(messages, tools) {
  const cfg = getConfig();
  const body = { model: cfg.model, messages, temperature: 0.8, max_tokens: 800 };
  if (tools) body.tools = tools;
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 20000);
  try {
    const resp = await fetch(cfg.apiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + cfg.apiKey },
      body: JSON.stringify(body),
      signal: ctrl.signal
    });
    if (!resp.ok) throw new Error('HTTP ' + resp.status);
    return resp.json();
  } finally {
    clearTimeout(timer);
  }
}

async function chatAIStream(messages, goods, sessionId, onChunk) {
  try {
    const result = await chatAI(messages, goods, sessionId, onChunk);
    const text = result.reply;
    const chunks = text.match(/.{1,3}/g) || [text];
    for (const chunk of chunks) {
      if (onChunk) onChunk({ type: 'text', content: chunk });
      await new Promise(r => setTimeout(r, 20));
    }
    if (onChunk) onChunk({ type: 'done', safe: result.safe });
    return result;
  } catch (e) {
    if (onChunk) onChunk({ type: 'error', message: e.message });
    return { reply: 'AI服务暂时不可用，请稍后再试。AI生成仅供参考。', safe: true };
  }
}

async function generateCopywrite(goodsInfo, goods) {
  const cate = goodsInfo.cate || '其他';
  const stats = getPriceStats(goods, cate);
  const priceHint = stats ? `该类别本校成交价区间${stats.min}-${stats.max}元，均价${stats.avg}元` : '无历史数据';
  const messages = [
    { role: 'system', content: '你是校园二手交易文案助手。根据商品信息生成：标题(15字内)、描述(50字内生动口语化)、建议价(参考本校成交价)、3个标签。用JSON格式返回：{"title":"","desc":"","price":0,"tags":["","",""]}' },
    { role: 'user', content: `商品：${goodsInfo.name || '未知'}，类别：${cate}，成色：${goodsInfo.cond || '九成新'}，图片描述：${goodsInfo.imageDesc || '无'}。${priceHint}` }
  ];
  try {
    const resp = await callQwen(messages, null);
    const text = resp.choices[0].message.content;
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) return JSON.parse(jsonMatch[0]);
    return { title: goodsInfo.name, desc: goodsInfo.desc || '九成新闲置转让', price: stats ? stats.avg : 50, tags: [cate, goodsInfo.cond || '九成新', '包邮'] };
  } catch (e) {
    return { title: goodsInfo.name || '闲置转让', desc: '九成新闲置，低价转让，需要的来', price: stats ? stats.avg : 50, tags: [cate, '九成新', '面交'] };
  }
}

function precheckContent(text) {
  const safety = contentSafety(text);
  const issues = [];
  if (!safety.safe) issues.push(`检测到敏感词"${safety.word}"`);
  if (text.indexOf('微信') >= 0 || text.indexOf('QQ') >= 0) issues.push('建议不要在描述中留联系方式');
  if (text.indexOf('全新') >= 0 && text.indexOf('低价') >= 0) issues.push('全新低价可能涉嫌售假');
  if (text.length < 5) issues.push('描述过短，建议补充成色和交易方式');
  return { pass: issues.length === 0, issues, safety };
}

const INSPECT_CHECKLIST = [
  { item: '核对实物与图片是否一致', tip: '当面检查成色、配件、功能' },
  { item: '验证商品真伪', tip: '电子产品查序列号，品牌商品查防伪码' },
  { item: '选择安全交易地点', tip: '校内公共场所，避免偏僻地点' },
  { item: '使用平台担保交易', tip: '不要私下转账，走平台支付' },
  { item: '保留聊天记录', tip: '截图保存沟通内容作为凭证' },
  { item: '警惕过低价格', tip: '远低于市场价可能是骗局' }
];

const TRADE_RULES = [
  { q: '如何交易', a: '线上沟通→约定面交地点→当面验货→平台付款→确认收货' },
  { q: '退款', a: '收货前可申请退款，收货后24小时内可申诉' },
  { q: '纠纷', a: '可发起平台仲裁，上传聊天记录和商品照片' },
  { q: '违规', a: '禁止发布违禁品、虚假商品、校外广告' }
];

module.exports = { chatAI, chatAIStream, generateCopywrite, precheckContent, INSPECT_CHECKLIST, TRADE_RULES, FUNCTIONS, contentSafety };