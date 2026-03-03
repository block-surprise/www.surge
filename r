<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>SURGE - 検索結果</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="icon" type="image/png" sizes="16x16" href="/favicon.png">
  <link rel="icon" type="image/png" sizes="48x48" href="/favicon2.png">
  <script async src="https://www.googletagmanager.com/gtag/js?id=G-D6SC2D5KK4"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'G-D6SC2D5KK4');
  </script>
  <style>
    :root { --accent: #4f46e5; --bg: #fdfdfd; }
    body { margin: 0; font-family: 'Inter', sans-serif; background: var(--bg); color: #222; padding: 20px; }
    
    .search-container, .search-tabs, #aiSummaryBox, #aiModeContainer {
      max-width: 1000px;
      margin-left: 100px;
    }
    @media (max-width: 768px) {
      .search-container, .search-tabs, #aiSummaryBox, #aiModeContainer {
        margin-left: 0 !important;
        width: 100%;
      }
      body { padding: 10px; }
      #searchInput { font-size: 16px !important; }
    }

    #searchInput { width: 100%; padding: 14px 20px; font-size: 18px; border-radius: 32px; border: 1px solid #ccc; box-shadow: 0 2px 6px rgba(0,0,0,0.1); outline: none; box-sizing: border-box; }
    .search-tabs { display: flex; gap: 20px; margin-top: 15px; margin-bottom: 25px; font-size: 14px; color: #5f6368; overflow-x: auto; white-space: nowrap; -webkit-overflow-scrolling: touch; }
    .tab { cursor: pointer; padding-bottom: 5px; border-bottom: 3px solid transparent; transition: 0.2s; flex-shrink: 0; }
    .tab.active { color: var(--accent); border-bottom: 3px solid var(--accent); font-weight: bold; }
    
    #aiSummaryBox {
      display: none; background: #fff; border: 1px solid #e5e7eb; border-radius: 16px; padding: 20px; margin-bottom: 30px; box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    }
    .ai-badge { background: linear-gradient(135deg, #6e8efb, #a777e3); color: white; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; margin-bottom: 10px; display: inline-block; }
    
    #aiModeContainer { display: none; background: #fff; border: 1px solid #e5e7eb; border-radius: 16px; padding: 20px; margin-bottom: 30px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); }
    #aiChatHistory { max-height: 500px; overflow-y: auto; display: flex; flex-direction: column; gap: 10px; margin-bottom: 15px; }
    .ai-bubble { background: #f3f4f6; padding: 12px 16px; border-radius: 18px; line-height: 1.6; align-self: flex-start; max-width: 85%; }
    .user-bubble { background: #e0e7ff; padding: 12px 16px; border-radius: 18px; line-height: 1.6; align-self: flex-end; max-width: 85%; }
    
    .ai-reply-form { display: flex; gap: 10px; border-top: 1px solid #eee; padding-top: 15px; }
    #aiReplyInput { flex-grow: 1; padding: 10px 15px; border-radius: 24px; border: 1px solid #ddd; outline: none; }
    #aiReplyBtn { background: var(--accent); color: white; border: none; padding: 8px 18px; border-radius: 20px; cursor: pointer; font-weight: bold; }

    .gsc-tabsArea, .gsc-result-info, .gsc-orderby-container, .gcsc-find-more-on-google { display: none !important; }
    .gsc-control-cse { padding: 0 !important; }
  </style>
</head>
<body>
  <div class="search-container">
    <form id="searchForm">
      <input type="search" id="searchInput" placeholder="SURGE で検索…" autocomplete="off">
    </form>
  </div>
  <div class="search-tabs">
    <div class="tab active" data-type="web" id="tab-web" onclick="clickTab(this)">すべて</div>
    <div class="tab" data-type="image" id="tab-image" onclick="clickTab(this)">画像</div>
    <div class="tab" data-type="video" onclick="clickTab(this)">動画</div>
    <div class="tab tab-ai" data-type="ai" id="tab-ai" onclick="clickTab(this)">✨ AI</div>
  </div>

  <div id="aiSummaryBox">
    <span class="ai-badge">SURGE AI 要約</span>
    <div id="aiSummaryContent">思考中...</div>
  </div>

  <div id="aiModeContainer">
    <div id="aiChatHistory"></div>
    <div id="aiStatus" style="font-size: 12px; color: #888; margin-bottom: 10px; display: none;">回答を生成中...</div>
    <div class="ai-reply-form">
      <input type="text" id="aiReplyInput" placeholder="AIにメッセージを送る..." onkeydown="if(event.key==='Enter') sendAIFollowUp()">
      <button id="aiReplyBtn" onclick="sendAIFollowUp()">送信</button>
    </div>
  </div>

  <div id="webResultsArea">
    <div class="gcse-searchresults-only" data-gname="searchresults-only"></div>
  </div>

  <script>
    const WORKER_URL = "https://surge.proluce.workers.dev/"; 
    
    async function getAIResponse(query, targetId, isFollowUp = false) {
      const target = document.getElementById(targetId);
      const status = document.getElementById('aiStatus');
      if (isFollowUp) status.style.display = 'block';

      try {
        const res = await fetch(WORKER_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ inputs: `あなたはSURGEのAI。${query}について簡潔に答えて。` })
        });
        const data = await res.json();
        const raw = Array.isArray(data) ? (data[0]?.generated_text || "") : (data.generated_text || "");
        const reply = raw.split("AI:").pop()?.trim() || "応答なし";
        
        if (targetId === 'aiChatHistory') {
          const div = document.createElement('div');
          div.className = 'ai-bubble';
          div.innerText = reply;
          target.appendChild(div);
          target.scrollTop = target.scrollHeight;
        } else {
          target.innerText = reply;
        }
      } catch (e) { 
        if(isFollowUp) {
          const errDiv = document.createElement('div');
          errDiv.className = 'ai-bubble';
          errDiv.innerText = "エラーが発生しました。";
          target.appendChild(errDiv);
        } else {
          target.innerText = "AIエラー";
        }
      } finally {
        status.style.display = 'none';
      }
    }

    async function sendAIFollowUp() {
      const input = document.getElementById('aiReplyInput');
      const text = input.value.trim();
      if (!text) return;
      const history = document.getElementById('aiChatHistory');
      const userDiv = document.createElement('div');
      userDiv.className = 'user-bubble';
      userDiv.innerText = text;
      history.appendChild(userDiv);
      input.value = '';
      history.scrollTop = history.scrollHeight;
      await getAIResponse(text, 'aiChatHistory', true);
    }

    function clickTab(el) {
      const type = el.getAttribute('data-type');
      const q = document.getElementById('searchInput').value.trim();
      if (!q) return;

      if (type === 'image') {
        const targetUrl = `https://surge.ad-hub.f5.si/results?q=${encodeURIComponent(q)}#gsc.tab=1&gsc.q=${encodeURIComponent(q)}`;
        location.href = targetUrl;
        return;
      }

      // 【修正】画像以外のタブを押したとき、URLからハッシュを消去して履歴に残す
      const newUrl = window.location.protocol + "//" + window.location.host + window.location.pathname + '?q=' + encodeURIComponent(q);
      window.history.replaceState({path:newUrl}, '', newUrl);

      document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      el.classList.add('active');
      
      const summaryBox = document.getElementById('aiSummaryBox');
      const aiModeArea = document.getElementById('aiModeContainer');
      const webArea = document.getElementById('webResultsArea');
      const element = google.search.cse.element.getElement("searchresults-only");

      if (type === 'ai') {
        webArea.style.display = 'none'; summaryBox.style.display = 'none'; aiModeArea.style.display = 'block';
        if (!document.getElementById('aiChatHistory').hasChildNodes()) {
          const history = document.getElementById('aiChatHistory');
          const firstUserMsg = document.createElement('div');
          firstUserMsg.className = 'user-bubble';
          firstUserMsg.innerText = q;
          history.appendChild(firstUserMsg);
          getAIResponse(q, 'aiChatHistory', true);
        }
      } else {
        aiModeArea.style.display = 'none'; webArea.style.display = 'block';
        summaryBox.style.display = (type === 'web') ? 'block' : 'none';
        if (element) {
          if (type === 'video') element.execute(q + " site:youtube.com");
          else element.execute(q, 1, {searchType: ''});
        }
      }
    }

    window.__gcse = {
      callback: function() {
        const params = new URLSearchParams(location.search);
        const q = params.get('q');
        const input = document.getElementById('searchInput');
        if (q) {
          input.value = q;
          const element = google.search.cse.element.getElement("searchresults-only");
          const summaryBox = document.getElementById('aiSummaryBox');
          
          if (location.hash.includes('gsc.tab=1')) {
            const imgTab = document.getElementById('tab-image');
            const webTab = document.getElementById('tab-web');
            webTab.classList.remove('active');
            imgTab.classList.add('active');
            summaryBox.style.display = 'none';
            if (element) element.execute(q, 1, {searchType: 'image'});
          } else {
            summaryBox.style.display = 'block';
            getAIResponse(q, 'aiSummaryContent');
            if (element) element.execute(q);
          }
        }
        document.getElementById('searchForm').addEventListener('submit', (e) => {
          e.preventDefault();
          if (input.value.trim()) location.href = "?q=" + encodeURIComponent(input.value.trim());
        });
      }
    };
  </script>
  <script async src="https://cse.google.com/cse.js?cx=818be131768c247f3"></script>
</body>
</html>
