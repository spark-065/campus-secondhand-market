(function () {
  "use strict";

  var GRAD = [
    "linear-gradient(135deg,#667eea,#764ba2)",
    "linear-gradient(135deg,#f093fb,#f5576c)",
    "linear-gradient(135deg,#4facfe,#00f2fe)",
    "linear-gradient(135deg,#43e97b,#38f9d7)",
    "linear-gradient(135deg,#fa709a,#fee140)",
    "linear-gradient(135deg,#30cfd0,#330867)",
    "linear-gradient(135deg,#a8edea,#fed6e2)",
    "linear-gradient(135deg,#ff9a9e,#fecfef)",
    "linear-gradient(135deg,#5ee7df,#b490ca)",
    "linear-gradient(135deg,#f6d365,#fda085)"
  ];
  function g(i) { return GRAD[i % GRAD.length]; }

  /* ===== 推荐页商品 ===== */
  var GOODS = [
    ["高等数学第七版", 15, "📚"], ["山地自行车九成新", 280, "🚲"],
    ["iPad Air 64G", 1200, "📱"], ["羽毛球拍尤尼克斯", 90, "🏸"],
    ["小米台灯护眼", 35, "💡"], ["兰蔻小样套装", 60, "💄"],
    ["手帐本+胶带", 25, "📔"], ["民谣吉他41寸", 360, "🎸"],
    ["自热火锅整箱", 45, "🍜"], ["机械键盘茶轴", 150, "⌨"],
    ["考研政治资料", 20, "📖"], ["滑板陆地冲浪", 220, "🛹"],
    ["空气炸锅3.5L", 130, "🍳"], ["JK制服格子裙", 75, "👗"],
    ["索尼降噪耳机", 480, "🎧"], ["尤克里里入门", 110, "🪕"],
    ["咖啡手冲套装", 95, "☕"], ["乐高街景散件", 200, "🧩"],
    ["电钢琴88键", 880, "🎹"], ["露营天幕帐篷", 260, "⛺"]
  ];

  function renderGoods() {
    var box = document.getElementById("goodsGrid");
    var html = "";
    GOODS.forEach(function (it, idx) {
      html +=
        '<div class="goods-card">' +
          '<div class="goods-cover" style="background:' + g(idx) + '">' + it[2] + '</div>' +
          '<div class="goods-meta">' +
            '<div class="goods-name">' + it[0] + '</div>' +
            '<div class="goods-price"><small>¥</small>' + it[1] + '</div>' +
          '</div>' +
        '</div>';
    });
    box.innerHTML = html;
  }

  /* ===== 圈子页 ===== */
  var CIRCLE = [
    ["陈同学", "2 分钟前", "🧑", "出九成新 Switch 续航增强版，带两个游戏卡带，可面交～", "🎮"],
    ["苏苏的杂货铺", "15 分钟前", "👧", "整理出一批手账文具，斑马、百乐笔都有，打包出更划算", "✏️"],
    ["老张学长", "1 小时前", "👨", "毕业甩卖：电吹风 + 烧水壶 + 台灯，三件套一口价 50", "💡"],
    ["小鹿要毕业", "3 小时前", "🦌", "舞蹈练功服两套，只穿过两次，码数 S，需要的姐妹来", "💃"]
  ];
  function renderCircle() {
    var box = document.getElementById("circleBody");
    var html = "";
    CIRCLE.forEach(function (it, idx) {
      html +=
        '<div class="circle-card">' +
          '<div class="circle-head">' +
            '<div class="seller-avatar" style="background:' + g(idx + 3) + '">' + it[2] + '</div>' +
            '<div><div class="seller-name">' + it[0] + '</div>' +
            '<div class="seller-time">' + it[1] + '</div></div>' +
          '</div>' +
          '<div class="circle-cover" style="background:' + g(idx + 5) + '">' + it[4] + '</div>' +
          '<div class="circle-text">' + it[3] + '</div>' +
        '</div>';
    });
    box.innerHTML = html;
  }

  /* ===== 消息页 ===== */
  var MSGS = [
    ["陈同学", "好的，那就明天下午图书馆门口见～", "刚刚", "🧑", 2],
    ["苏苏的杂货铺", "笔的话打包价 35 包邮哦", "10:24", "👧", 0],
    ["老张学长", "三件套还在的，先到先得", "昨天", "👨", 1],
    ["小鹿要毕业", "码数是 S，你看看合适不", "昨天", "🦌", 0],
    ["校园驿站", "你的包裹已到 3 号柜，取件码 8842", "周四", "📦", 0],
    ["系统通知", "你发布的商品有 3 条新浏览记录", "周三", "🔔", 0]
  ];
  function renderMessage() {
    var box = document.getElementById("messageBody");
    var html = "";
    MSGS.forEach(function (it, idx) {
      html +=
        '<div class="msg-card">' +
          (it[4] ? '<div class="msg-badge">' + it[4] + '</div>' : '') +
          '<div class="msg-avatar" style="background:' + g(idx + 2) + '">' + it[3] + '</div>' +
          '<div class="msg-info">' +
            '<div class="msg-name">' + it[0] + '</div>' +
            '<div class="msg-last">' + it[1] + '</div>' +
          '</div>' +
          '<div class="msg-time">' + it[2] + '</div>' +
        '</div>';
    });
    box.innerHTML = html;
  }

  /* ===== 我的页菜单 ===== */
  var MENU = [
    ["📦", "我的发布", "12 件在售"],
    ["♡", "我的收藏", "36 件"],
    ["📜", "历史订单", "查看全部"],
    ["💰", "我的钱包", "余额 ¥128.50"],
    ["⭐", "我的评价", "待评价 2"],
    ["⚙️", "设置", ""]
  ];
  function renderMenu() {
    var box = document.getElementById("mineMenu");
    var html = "";
    MENU.forEach(function (it) {
      html +=
        '<div class="menu-item">' +
          '<div class="menu-ico">' + it[0] + '</div>' +
          '<div class="menu-label">' + it[1] + '</div>' +
          (it[2] ? '<span style="font-size:12px;color:var(--ink-3)">' + it[2] + '</span>' : '') +
          '<svg class="menu-arrow" viewBox="0 0 24 24" width="16" height="16"><path d="M9 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>' +
        '</div>';
    });
    box.innerHTML = html;
  }

  /* ===== 页面切换 ===== */
  var PAGES = ["recommend", "category", "circle", "message", "mine"];
  function showPage(name) {
    PAGES.forEach(function (p) {
      var el = document.getElementById("page-" + p);
      if (p === name) el.classList.add("is-active");
      else el.classList.remove("is-active");
    });
    document.querySelectorAll(".tab").forEach(function (t) {
      t.classList.toggle("is-active", t.dataset.page === name);
    });
  }

  document.querySelectorAll(".tab").forEach(function (t) {
    t.addEventListener("click", function () { showPage(t.dataset.page); });
  });

  document.getElementById("goCategory").addEventListener("click", function () { showPage("category"); });
  document.getElementById("backFromCategory").addEventListener("click", function () { showPage("recommend"); });

  /* ===== 回到顶部 ===== */
  var recBody = document.getElementById("recommendBody");
  var backTop = document.getElementById("backToTop");
  recBody.addEventListener("scroll", function () {
    if (recBody.scrollTop > 240) backTop.classList.add("show");
    else backTop.classList.remove("show");
  });
  backTop.addEventListener("click", function () {
    recBody.scrollTo({ top: 0, behavior: "smooth" });
  });

  /* ===== 筛选 ===== */
  var FILTERS = {
    category: { multi: true, items: ["书籍", "交通工具", "电子数码", "运动器材", "生活用品", "美妆护肤", "文创文具", "乐器", "食品", "其他"] },
    price:    { multi: false, items: ["0-30", "30-50", "50-100", "100-200", "200-500", "500-1000", "1000+"] },
    region:   { multi: true, items: ["一期", "二期", "东校区", "澎湖苑"] },
    type:     { multi: false, items: ["出售", "长期租借", "短期租借"] }
  };
  var state = { category: [], price: [], region: [], type: [] };

  function renderChips(key) {
    var cfg = FILTERS[key];
    var box = document.getElementById("filter" + key.charAt(0).toUpperCase() + key.slice(1));
    var html = "";
    cfg.items.forEach(function (label) {
      var on = state[key].indexOf(label) >= 0;
      var dotClass = cfg.multi ? "dot square" : "dot";
      html +=
        '<button class="chip' + (on ? " is-on" : "") + '" data-key="' + key + '" data-val="' + label + '">' +
          '<span class="' + dotClass + '"></span>' + label +
        '</button>';
    });
    box.innerHTML = html;
  }
  function renderAllChips() { Object.keys(FILTERS).forEach(renderChips); }

  document.getElementById("categoryBody").addEventListener("click", function (e) {
    var chip = e.target.closest(".chip");
    if (!chip) return;
    var key = chip.dataset.key, val = chip.dataset.val;
    var cfg = FILTERS[key];
    var idx = state[key].indexOf(val);
    if (cfg.multi) {
      if (idx >= 0) state[key].splice(idx, 1);
      else state[key].push(val);
    } else {
      state[key] = (idx >= 0) ? [] : [val];
    }
    renderChips(key);
  });

  function showToast(text) {
    var t = document.getElementById("toast");
    t.textContent = text;
    t.classList.add("show");
    clearTimeout(showToast._t);
    showToast._t = setTimeout(function () { t.classList.remove("show"); }, 2000);
  }

  document.getElementById("btnReset").addEventListener("click", function () {
    state = { category: [], price: [], region: [], type: [] };
    renderAllChips();
    showToast("已重置筛选条件");
  });

  document.getElementById("btnRecommend").addEventListener("click", function () {
    var total = state.category.length + state.price.length + state.region.length + state.type.length;
    if (total === 0) { showToast("请至少选择一个筛选条件"); return; }
    showToast("正在为你智能推荐…");
    setTimeout(function () {
      showPage("recommend");
      recBody.scrollTo({ top: 0, behavior: "smooth" });
    }, 900);
  });

  /* ===== 我的页编辑 ===== */
  function buildEditMask() {
    var mask = document.createElement("div");
    mask.className = "edit-mask";
    mask.innerHTML =
      '<div class="edit-dialog">' +
        '<h3>编辑个人资料</h3>' +
        '<div class="edit-field"><label>昵称</label><input id="editName" type="text" maxlength="12" /></div>' +
        '<div class="edit-field"><label>个人简介</label><input id="editBio" type="text" maxlength="30" /></div>' +
        '<div class="edit-actions">' +
          '<button class="cancel">取消</button>' +
          '<button class="save">保存</button>' +
        '</div>' +
      '</div>';
    document.getElementById("phone").appendChild(mask);

    var nameEl = document.getElementById("mineName");
    var bioEl = document.getElementById("mineBio");
    var inpName = mask.querySelector("#editName");
    var inpBio = mask.querySelector("#editBio");

    function open() {
      inpName.value = nameEl.textContent;
      inpBio.value = bioEl.textContent;
      mask.classList.add("show");
      setTimeout(function () { inpName.focus(); }, 260);
    }
    function close() { mask.classList.remove("show"); }

    document.getElementById("mineEdit").addEventListener("click", open);
    nameEl.style.cursor = "pointer";
    bioEl.style.cursor = "pointer";
    nameEl.addEventListener("click", open);
    bioEl.addEventListener("click", open);

    mask.querySelector(".cancel").addEventListener("click", close);
    mask.addEventListener("click", function (e) { if (e.target === mask) close(); });
    mask.querySelector(".save").addEventListener("click", function () {
      var n = inpName.value.trim();
      var b = inpBio.value.trim();
      if (n) nameEl.textContent = n;
      bioEl.textContent = b || "这个人很懒，什么都没留下～";
      close();
      showToast("资料已更新");
    });
  }

  /* ===== 状态栏时间 ===== */
  function tick() {
    var d = new Date();
    var h = d.getHours(), m = d.getMinutes();
    document.getElementById("statusTime").textContent =
      h + ":" + (m < 10 ? "0" + m : m);
  }

  /* ===== 初始化 ===== */
  renderGoods();
  renderCircle();
  renderMessage();
  renderMenu();
  renderAllChips();
  buildEditMask();
  tick();
  setInterval(tick, 30000);
})();