# 股市技術分析 App — 改進路線圖

最後更新：2026-05-11

本文件列出當前 App 所有可改進 / 缺漏項目，包含現況、目標、實作要點、工作量估計與檔案位置。
每一項都有獨立編號 (`#01` ~ `#36`)，後續開發時直接指明編號即可。

---

## 目錄

- [優先級總覽表](#優先級總覽表)
- [A. 資料 / 功能層 (`#01` ~ `#13`)](#a-資料--功能層)
- [B. UX / 細節 (`#14` ~ `#22`)](#b-ux--細節)
- [C. 架構 / 品質 (`#23` ~ `#30`)](#c-架構--品質)
- [D. 合規 / 安全 (`#31` ~ `#33`)](#d-合規--安全)
- [E. 進階 / 高難度 (`#34` ~ `#36`)](#e-進階--高難度)
- [執行階段建議](#執行階段建議)
- [附錄：Fugle API 對照](#附錄fugle-api-對照)

---

## 優先級總覽表

| # | 名稱 | 分類 | 工作量 | 優先級 | 備註 |
|---|---|---|---|---|---|
| 01 | 五檔買賣盤 | 資料 | S | ★★★ | 資料已抓，純 UI |
| 02 | 52 週高低 | 資料 | S | ★★★ | 一個 API call |
| 03 | 內外盤比 | 資料 | S | ★★★ | 當沖必備 |
| 04 | 逐筆成交 (大單偵測) | 資料 | M | ★★ | 給當沖使用 |
| 05 | 分價量表 | 資料 | M | ★★ | 籌碼分布視覺化 |
| 06 | 除權息資訊 | 資料 | M | ★★★ | 中長期必備 |
| 07 | 減資 / ETF 分割 | 資料 | S | ★★ | 解釋跳空 |
| 08 | 市場熱度頁 | 資料 | M | ★★★ | 漲跌排行 + 成交量榜 |
| 09 | K 線多週期 (週/月) | 資料 | M | ★★★ | 中長期分析 |
| 10 | K 線時間區間切換 | 資料 | M | ★★ | 近 90 / 180 / 365 日 |
| 11 | 基本面快照 | 資料 | M | ★★ | PE / EPS / ROE |
| 12 | 個股新聞 | 資料 | M | ★ | 需第三方來源 |
| 13 | 大盤指數對比 | 資料 | M | ★★ | 個股 vs 加權 |
| 14 | Token 即時驗證 | UX | S | ★★★ | 提升新手成功率 |
| 15 | 錯誤訊息友善化 | UX | S | ★★★ | DioException 翻譯 |
| 16 | 空狀態引導 | UX | S | ★★ | 自選股空時的引導 |
| 17 | 首次 Onboarding | UX | M | ★★ | 教設 Token |
| 18 | 價格警示 | UX | M | ★★ | 到價 in-app 通知 |
| 19 | 自選股備份 / 匯出 | UX | S | ★★ | JSON / CSV |
| 20 | 自選股分組 | UX | M | ★★ | 群組管理 |
| 21 | K 線縮放 / 平移 | UX | M | ★ | 需 fl_chart 1.x |
| 22 | Loading shimmer | UX | S | ★ | 取代 spinner |
| 23 | 單元測試 | 架構 | M | ★★★ | 指標純函式 |
| 24 | WebSocket 即時報價 | 架構 | L | ★★ | 盯盤體驗 |
| 25 | 崩潰回報 (Sentry) | 架構 | S | ★★ | Release 必備 |
| 26 | 生物識別解鎖 | 架構 | S | ★★ | Token 加保護 |
| 27 | i18n / l10n | 架構 | L | ★ | 英文版基礎 |
| 28 | 背景刷新 + 通知 | 架構 | L | ★★ | 配合 #18 |
| 29 | 持倉 / 損益試算 | 架構 | M | ★★ | 投資組合 |
| 30 | 多股對比圖 | 架構 | M | ★★ | 相對表現分析 |
| 31 | 免責聲明強化 | 合規 | S | ★★★ | 法律必要 |
| 32 | 隱私 / 條款頁面 | 合規 | S | ★★ | 上架要求 |
| 33 | 資料來源標示 | 合規 | S | ★★ | TWSE / Fugle 標註 |
| 34 | K 線型態自動辨識 | 進階 | L | ★ | 雙底、頭肩 |
| 35 | 圖表畫線工具 | 進階 | L | ★ | 趨勢線、支撐壓力 |
| 36 | 自訂指標參數 | 進階 | M | ★ | MA / RSI 週期 |

**工作量**：S = < 2 小時 · M = 2-8 小時 · L = 8+ 小時
**優先級**：★★★ 強烈建議 · ★★ 值得做 · ★ 進階加分

---

## A. 資料 / 功能層

### #01 五檔買賣盤
- **現況**：`FugleApiClient.intradayQuote()` 已抓回 `bids` / `asks` 五檔，但 UI 完全沒呈現。
- **目標**：在個股詳情頁加上一個五檔買賣盤元件，顯示買 5 ~ 賣 5 的價格與張數，並用色塊長度比例化張數。
- **實作要點**：
  - 新檔：`lib/features/stock_detail/widgets/order_book_widget.dart`
  - 從現有 `StockQuote` 模型擴充 `bids` / `asks` 欄位 (修改 `stock_quote.dart` Hive adapter)
  - 顯示位置：價量資訊 (`PriceHeader`) 下方
  - 顯示時機：僅當日分線 tab，日 K 模式可選擇隱藏
- **工作量**：S (約 1.5 小時)
- **依賴**：無
- **風險**：Hive adapter 版本變更需要 migration，或直接刪掉舊快取

### #02 52 週高低
- **現況**：完全沒接 `/historical/stats/{symbol}` 端點。
- **目標**：在價量資訊區顯示「52W 高 / 低」與「距高點 X%、距低點 Y%」。
- **實作要點**：
  - `FugleApiClient` 加 `historicalStats(symbol)` 方法
  - 新 provider `historicalStatsProvider`（family / 24h Hive 快取）
  - 顯示在 `PriceHeader` 右側或單獨一個小卡
  - 順便顯示前一交易日成交金額
- **工作量**：S (約 1 小時)
- **依賴**：無
- **風險**：低

### #03 內外盤比
- **現況**：`StockQuote` 已包含 `tradeVolumeAtBid` / `tradeVolumeAtAsk`（在 `total` 子物件），但 UI 沒用。
- **目標**：個股頁加上「內盤 / 外盤」比例條，並用 % 顯示。
  - 內盤比 = `tradeVolumeAtBid / (tradeVolumeAtBid + tradeVolumeAtAsk)`
  - 外盤比 = 反之
  - 一般解讀：外盤 > 50% 為買盤主動，內盤 > 50% 為賣盤主動
- **實作要點**：
  - 修改 `StockQuote` 模型加 `bidVolume` / `askVolume`（或包成 sub-object）
  - 在 `PriceHeader` 或新 widget 顯示
- **工作量**：S (約 1 小時)

### #04 逐筆成交 (大單偵測)
- **現況**：沒接 `/intraday/trades/{symbol}` 端點。
- **目標**：當沖 tab 加「逐筆成交」清單，標記「大單」（單筆 > N 張或 > N 萬元）。
- **實作要點**：
  - `FugleApiClient.intradayTrades(symbol, {limit, offset, isTrial})`
  - 新模型 `IntradayTrade`：bid, ask, price, size, volume, time
  - 新 widget：滾動清單，大單高亮（紅色背景表示主動買、綠色表示主動賣）
  - 可設定「大單門檻」(預設 100 張)
- **工作量**：M (約 4 小時)
- **依賴**：無
- **風險**：盤中逐筆會很多筆，要做 pagination + virtualized list

### #05 分價量表
- **現況**：沒接 `/intraday/volumes/{symbol}` 端點。
- **目標**：顯示各價位的累計成交量、內外盤量，視覺化成水平柱狀圖（價格在 Y 軸）。
- **實作要點**：
  - 新模型 `PriceVolume`：price, volume, volumeAtBid, volumeAtAsk
  - 顯示位置：當沖 tab，與當日分線並排或下方
  - CustomPainter 畫水平 bar
- **工作量**：M (約 3 小時)
- **使用場景**：判斷支撐壓力位、籌碼集中區

### #06 除權息資訊
- **現況**：沒接 `/corporate-actions/dividends`。
- **目標**：個股頁加「股息資訊」卡，顯示：
  - 最近一次除權息日 + 現金股利 + 股票股利
  - 殖利率（用最新股價計算）
  - 下次除權息預告日（若有）
  - 過去 5 年股息歷史 (小表格)
- **實作要點**：
  - `FugleApiClient.dividends(startDate, endDate)` 一次抓近 5 年，client 端篩 symbol
  - 新模型 `Dividend`
  - Hive 快取，每月更新一次（除權息日表變動不頻繁）
  - 新 widget：`DividendCard`
- **工作量**：M (約 4 小時)
- **風險**：API 屬於「開發者」方案專屬，基本用戶可能無權呼叫（試到再說，目前免費版開放體驗到 2026/2/12）

### #07 減資 / ETF 分割
- **現況**：沒接 `/corporate-actions/capital-changes`。
- **目標**：在 K 線圖上標註減資 / 分割事件（一條垂直虛線 + 圖示），點擊可看詳情。
- **實作要點**：
  - `FugleApiClient.capitalChanges(startDate, endDate)`
  - K 線 painter 加 event overlay
  - 解釋為什麼有跳空（避免使用者誤判技術形態）
- **工作量**：S (約 2 小時)
- **依賴**：與 #06 同 API 群組

### #08 市場熱度頁
- **現況**：沒有「探索」頁面，使用者只能搜尋已知股票代號。
- **目標**：新 tab「市場」，顯示：
  - 上漲排行（前 30）
  - 下跌排行（前 30）
  - 成交量榜（前 30）
  - 成交值榜（前 30）
  - 切換上市 / 上櫃
- **實作要點**：
  - `FugleApiClient.snapshotMovers({market, direction, change})`
  - `FugleApiClient.snapshotActives({market, trade})`
  - 新頁面 `lib/features/market/market_page.dart`
  - Bottom navigation 加第二個 tab（或從首頁 AppBar 進入）
  - 每筆可點擊跳到該股詳情頁
- **工作量**：M (約 5 小時)
- **風險**：snapshot API 屬於「開發者」方案專屬，需確認 Token 權限

### #09 K 線多週期 (週 / 月)
- **現況**：詳情頁固定顯示日 K（近 90 日）。
- **目標**：K 線圖頂端加 timeframe chips：`分 / 5分 / 60分 / 日 / 週 / 月`，可切換。
- **實作要點**：
  - `FugleApiClient.historicalCandles` 已支援 `timeframe` 參數
  - 分 K 受限：API 強制回近 30 日，無法指定區間（要在 UI 註明）
  - `candlesProvider` 改成 family of `(symbol, timeframe)`
  - 切換時 invalidate 並重新 fetch
- **工作量**：M (約 4 小時)
- **依賴**：無，但建議與 #10 一起做

### #10 K 線時間區間切換
- **現況**：固定 90 日，無法看更久。
- **目標**：加區間選擇 `近 1 月 / 3 月 / 6 月 / 1 年 / 2 年 / 全部`。
- **實作要點**：
  - 受 Fugle 限制：個股最遠 2010，指數最遠 2015
  - StockRepository.getDailyCandles 加 days 參數（已有但未暴露）
  - UI 在 KLineChart 上方加 chip 列
- **工作量**：M (約 2 小時)
- **依賴**：建議與 #09 一起做

### #11 基本面快照
- **現況**：完全沒有基本面資料。
- **目標**：個股頁加「基本面」卡：本益比、股價淨值比、ROE、EPS、毛利率、營收年增率。
- **實作要點**：
  - Fugle 不直接提供。可走：
    - **方案 A**：TWSE 公開 OpenAPI `https://openapi.twse.com.tw/v1/exchangeReport/BWIBBU_d`（本益比、殖利率、股價淨值比）
    - **方案 B**：[FinMind](https://finmindtrade.com/) 第三方 API（要 token）
    - **方案 C**：證交所每月 EPS / 營收 ZIP 下載 + 解析
  - 建議方案 A，免費且穩定
  - 新 service `TwseFundamentalClient`
  - 新模型 `FundamentalSnapshot`
- **工作量**：M (約 5 小時)
- **風險**：第三方資料源規格變動

### #12 個股新聞
- **現況**：完全沒有新聞。
- **目標**：詳情頁底部加「相關新聞」清單。
- **實作要點**：
  - Fugle 沒提供。需要第三方：
    - Google News RSS（按 symbol 搜尋）
    - Yahoo Finance（爬蟲，不穩）
    - 鉅亨網 / 富邦 e01 等 API
  - 建議簡化：先實作 Google News RSS，按「股票代號 + 名稱」搜尋
- **工作量**：M (約 4 小時)
- **風險**：第三方來源不穩、新聞品質參差

### #13 大盤指數對比
- **現況**：個股 K 線是單獨的，無法跟大盤對照。
- **目標**：K 線圖上可開「加權指數 (IR0001) 對比線」，標準化後疊在主圖。
- **實作要點**：
  - 抓加權指數歷史 K（用 Fugle `/historical/candles/IR0001`）
  - 把指數值轉成相對變化 % 並按個股的相對 % 同尺度疊圖
  - K 線 widget 加一條 line series
  - UI：右上角 toggle 「對比加權」
- **工作量**：M (約 3 小時)
- **使用場景**：判斷個股是「跑贏大盤」還是「跟著大盤」

---

## B. UX / 細節

### #14 Token 即時驗證
- **現況**：設定頁存 Token 後沒驗證，使用者貼錯字要等到看股票時才會發現 401。
- **目標**：按下「儲存」後自動打一個 lightweight API call（例如查 0050 ticker）測試 Token 是否有效。
  - 成功：綠勾 + 「Token 驗證通過」
  - 失敗：紅叉 + 顯示具體錯誤
- **實作要點**：
  - 修改 `ApiTokenNotifier.save()`
  - 新增 `ApiTokenStatus` enum (`verifying`, `valid`, `invalid`)
  - SettingsPage 顯示驗證狀態
- **工作量**：S (約 1 小時)

### #15 錯誤訊息友善化
- **現況**：所有錯誤直接 `e.toString()`，例如 `DioException [bad response]: ...`，使用者看不懂。
- **目標**：包一層 `AppError` 把 DioException 翻譯：
  - 401 → 「API Token 無效，請至設定重新填寫」
  - 403 → 「您的方案無法使用此功能」
  - 404 → 「找不到此股票或資料」
  - 429 → 「API 用量已達上限，請稍後再試」
  - 連線失敗 → 「網路異常，請檢查網路連線」
- **實作要點**：
  - 新檔：`lib/core/errors/app_error.dart`
  - Interceptor 統一捕捉 DioException 轉 AppError
  - UI 端統一用 `AppError` 訊息
- **工作量**：S (約 2 小時)

### #16 空狀態引導
- **現況**：自選股空時只顯示「尚未加入任何自選股」一行字。
- **目標**：illustration + 指向 FAB 的箭頭 + 「點右下角加入第一檔股票」+ 推薦熱門股 quick add 按鈕。
- **實作要點**：
  - Lottie animation 或 SVG illustration
  - 或簡化：用 Material Icons 大圖
- **工作量**：S (約 1.5 小時)

### #17 首次 Onboarding
- **現況**：第一次開 App 只看到頂部黃色橫幅「請去設定填 Token」，新手不一定看得到。
- **目標**：第一次開啟跑 3 頁式 onboarding：
  1. 歡迎 + App 介紹
  2. 教申請 Fugle Token（含連結到 developer.fugle.tw）
  3. 教如何加入自選股
- **實作要點**：
  - 新檔：`lib/features/onboarding/`
  - Hive 存「已完成 onboarding」flag
  - `app.dart` 啟動時判斷顯示哪個頁面
- **工作量**：M (約 3 小時)

### #18 價格警示
- **現況**：完全沒有警示功能。
- **目標**：對自選股設「到價提醒」：高於 X 元或低於 Y 元時通知。
  - Phase 1：App 開啟時檢查（in-app SnackBar / toast）
  - Phase 2：背景排程 + 系統推播（見 #28）
- **實作要點**：
  - 新模型 `PriceAlert`：symbol, condition (above/below), price, enabled
  - Hive box `price_alerts_box`
  - 自選股長按 → 設定警示
  - Dashboard 載入時檢查所有警示，命中即彈通知
- **工作量**：M (約 4 小時)
- **依賴**：Phase 2 依賴 #28

### #19 自選股備份 / 匯出
- **現況**：自選股只存本地 Hive，換手機 / 重灌就沒了。
- **目標**：設定頁加「匯出 / 匯入」按鈕，匯出 JSON。
- **實作要點**：
  - 匯出：`watchlist.values` 轉 JSON，用 `share_plus` 套件分享 / 存檔
  - 匯入：選擇 JSON 檔，覆蓋或合併
  - 順便可備份 API Token (但要警告)
- **工作量**：S (約 1.5 小時)
- **新增 dep**：`share_plus`, `file_picker`

### #20 自選股分組
- **現況**：所有自選股堆一起，沒辦法分「長期持有 / 短線觀察 / 觀察名單」群組。
- **目標**：可建立群組，每檔股票歸屬一群組，Dashboard tab 切換群組查看。
- **實作要點**：
  - 新模型 `WatchlistGroup`：id, name, color, sortOrder
  - `WatchlistItem` 加 `groupId` 欄位
  - Dashboard 頂部加 TabBar
  - 拖拉重新分組 (ReorderableListView)
- **工作量**：M (約 6 小時)
- **依賴**：要做 Hive migration

### #21 K 線縮放 / 平移
- **現況**：固定 90 日，使用者無法 pinch zoom 或拖曳查更久歷史。
- **目標**：兩指縮放、單指拖曳查看不同區間。
- **實作要點**：
  - fl_chart 1.x 有原生支援，但升級成本高（見 #issue）
  - 自行實作：在現有 CustomPainter 上加 GestureDetector，維護一個 `viewportRange`
- **工作量**：M (約 4-6 小時)
- **依賴**：可能要升 fl_chart 到 1.x（會踩到整個 chart API breaking change）

### #22 Loading shimmer
- **現況**：所有載入狀態都是 `CircularProgressIndicator`，視覺單調。
- **目標**：股票卡片、圖表 placeholder 用 shimmer 動畫。
- **實作要點**：
  - 套件：`shimmer`
  - 包裝現有 `_LoadingBlock` / 卡片 placeholder
- **工作量**：S (約 1 小時)
- **新增 dep**：`shimmer: ^3.0.0`

---

## C. 架構 / 品質

### #23 單元測試
- **現況**：0 個測試。
- **目標**：至少覆蓋：
  - `Indicators` 所有純函式 (SMA, EMA, RSI, MACD, KD, Bollinger, OBV, W%R, ATR)
  - `Diagnoser.diagnose()` 各規則
  - `SignalAnalyser.analyse()` 投票邏輯
  - `VolatilityAnalyser.analyse()` 計算
  - `StockRepository` 快取邏輯
- **實作要點**：
  - `test/indicators/indicators_test.dart`
  - 用真實歷史資料（CSV 載入）做 fixture
  - `flutter test` 應全綠
- **工作量**：M (約 6-8 小時)

### #24 WebSocket 即時報價
- **現況**：報價是 60 秒快取，使用者要手動下拉刷新。
- **目標**：開啟個股詳情頁時自動訂閱 WebSocket，即時推送成交 / 五檔。
- **實作要點**：
  - Fugle `wss://api.fugle.tw/marketdata/v1.0/stock/streaming`
  - 套件：`web_socket_channel`
  - 新 service `FugleWebSocketService`
  - 訂閱頻道：`trades`, `books`, `candles`
  - 進入詳情頁 subscribe、離開 unsubscribe
  - 注意：訂閱數量受 plan 限制（基本 5 / 開發者 300）
- **工作量**：L (約 8-12 小時)
- **風險**：連線管理複雜，要處理 reconnect / heartbeat / 訂閱衝突

### #25 崩潰回報 (Sentry)
- **現況**：Release 版掛了無法得知。
- **目標**：接 Sentry，所有 unhandled exception 自動上報。
- **實作要點**：
  - 套件：`sentry_flutter`
  - `main.dart` 包 `SentryFlutter.init`
  - DSN 寫到設定檔或環境變數
- **工作量**：S (約 1 小時)
- **新增 dep**：`sentry_flutter`

### #26 生物識別解鎖
- **現況**：App 開啟即可看所有資料，Token 也在背景持有。
- **目標**：可選啟用 FaceID / 指紋鎖。
- **實作要點**：
  - 套件：`local_auth`
  - 設定頁加 toggle
  - main.dart 啟動時若已啟用，要求生物驗證才進首頁
- **工作量**：S (約 2 小時)
- **新增 dep**：`local_auth`

### #27 i18n / l10n
- **現況**：所有 UI 字串寫死中文。
- **目標**：抽出到 `arb` 檔，至少支援中 / 英。
- **實作要點**：
  - 套件：`flutter_localizations`, `intl_utils`
  - `lib/l10n/app_zh_TW.arb` / `app_en.arb`
  - 全 codebase 用 `AppLocalizations.of(context).xxx` 取代
- **工作量**：L (約 10-15 小時，純機械工作)

### #28 背景刷新 + 通知
- **現況**：App 在背景時不會更新資料。
- **目標**：背景定時抓自選股報價、命中價格警示 (#18) 時推播。
- **實作要點**：
  - 套件：`workmanager` (Android) + `flutter_local_notifications`
  - iOS 限制較多（背景頻率不能太高）
  - 每 15 分鐘執行一次 background task
- **工作量**：L (約 8 小時)
- **風險**：iOS 背景限制嚴格，效果可能不如預期
- **依賴**：#18

### #29 持倉 / 損益試算
- **現況**：完全沒「我持有什麼」的概念。
- **目標**：可記錄持倉（symbol, 股數, 成本），即時試算損益。
- **實作要點**：
  - 新模型 `Holding`：symbol, quantity, avgCost, addedAt
  - 新頁面 `lib/features/portfolio/`
  - 計算：未實現損益 = (current_price - avg_cost) × quantity
  - 不接券商 API，純手動輸入（避免合規問題）
- **工作量**：M (約 6 小時)

### #30 多股對比圖
- **現況**：只能單股查看。
- **目標**：選 2-5 檔股票放同一張圖，標準化後比較相對表現。
- **實作要點**：
  - 新頁面 `lib/features/compare/`
  - 從自選股或搜尋加入比較
  - 統一起點 = 100，計算每日的相對倍數
- **工作量**：M (約 5 小時)

---

## D. 合規 / 安全

### #31 免責聲明強化
- **現況**：只有設定頁底部一行「不構成投資建議」。
- **目標**：
  - 診斷面板、綜合評分卡顯著位置加「⚠ 僅供參考」
  - 首次顯示診斷時跳 disclaimer dialog（同意一次後不再顯示）
  - 設定頁可隨時重看完整免責內容
- **實作要點**：
  - 新 widget `DisclaimerBanner`
  - Hive 存「已閱讀免責」flag
- **工作量**：S (約 2 小時)

### #32 隱私 / 條款頁面
- **現況**：完全沒有 privacy policy。
- **目標**：
  - 設定頁加「隱私政策」「使用條款」連結
  - 內容說明：API Token 加密儲存於本地 Keystore、不上傳、API 用量僅本地統計
- **實作要點**：
  - 兩份 markdown 文件
  - 新頁面用 markdown viewer 顯示
- **工作量**：S (約 2 小時)
- **重要性**：上架 Google Play / App Store 必備

### #33 資料來源標示
- **現況**：診斷標籤、報價數值沒標來源。
- **目標**：
  - 個股頁底部加「資料來源：Fugle Market Data + TWSE」
  - 三大法人卡標「TWSE 公開資料」
  - 連結到 Fugle 與 TWSE 官網
- **實作要點**：
  - 小字註腳，無功能性影響
- **工作量**：S (約 1 小時)

---

## E. 進階 / 高難度

### #34 K 線型態自動辨識
- **目標**：自動偵測經典型態：雙底 / 雙頂 / 頭肩 / 三角收斂 / 楔形 / 旗形。
- **實作要點**：
  - 純演算法：找局部極值，比對型態幾何關係
  - 偵測命中後在 K 線上標註
  - 加入診斷規則
- **工作量**：L (15+ 小時)
- **風險**：誤判率可能高，需大量調校

### #35 圖表畫線工具
- **目標**：使用者可在 K 線上畫趨勢線、水平支撐 / 壓力線、Fibonacci 回測線。
- **實作要點**：
  - 模式切換：瀏覽 / 畫線
  - GestureDetector 取得起點終點
  - 畫線資料存 Hive，重啟保留
- **工作量**：L (12+ 小時)

### #36 自訂指標參數
- **現況**：MA(5,10,20,60)、RSI(14)、KD(9,3,3) 全部寫死。
- **目標**：設定頁加「指標參數」section，使用者可自訂週期。
- **實作要點**：
  - 新模型 `IndicatorPreferences`
  - 全 codebase 改成從 provider 讀參數
- **工作量**：M (5-6 小時)

---

## 執行階段建議

### Phase 1 — Quick Wins (約 1-2 天) ✅ 已完成
完成最有感的小項，立刻看到改善：
- ✅ `#02` 52 週高低
- ✅ `#01` 五檔買賣盤
- ✅ `#03` 內外盤比
- ✅ `#14` Token 即時驗證
- ✅ `#15` 錯誤訊息友善化
- ✅ `#19` 自選股備份
- ✅ `#31` 免責聲明
- ✅ `#33` 資料來源標示

### Phase 2 — 深度資料 (約 3-4 天)
讓 App 從「技術指標 App」升級成「綜合分析 App」：
- `#06` 除權息資訊
- `#08` 市場熱度頁
- `#09` `#10` K 線多週期 + 區間切換
- `#11` 基本面快照
- `#13` 大盤對比

### Phase 3 — 體驗打磨 (約 2-3 天)
- `#16` `#17` 空狀態 + Onboarding
- `#18` 價格警示 (in-app 版)
- `#20` 自選股分組
- `#22` Loading shimmer
- `#23` 單元測試
- `#25` 崩潰回報
- `#32` 隱私政策

### Phase 4 — 即時化 (約 1 週)
- `#24` WebSocket 即時報價
- `#28` 背景刷新 + 推播
- `#26` 生物識別
- `#29` 持倉試算
- `#30` 多股對比

### Phase 5 — 進階 (彈性安排)
- `#04` 逐筆成交
- `#05` 分價量表
- `#07` 減資 / ETF 分割
- `#12` 個股新聞
- `#27` i18n
- `#34` `#35` `#36` 進階功能

---

## 附錄：Fugle API 對照

| Fugle 端點 | 已接 | 用途 | 對應 # |
|---|---|---|---|
| `/intraday/tickers` | ✓ | 代號目錄 | (已完成) |
| `/intraday/ticker/{symbol}` | ✓ | 個股基本資料 | (已完成) |
| `/intraday/quote/{symbol}` | ✓ | 即時報價 (五檔已抓未顯示) | #01 #03 |
| `/intraday/candles/{symbol}` | ✓ | 分 K | (已完成) |
| `/intraday/trades/{symbol}` | ✗ | 逐筆成交 | #04 |
| `/intraday/volumes/{symbol}` | ✗ | 分價量表 | #05 |
| `/snapshot/quotes/{market}` | ✗ | 全市場快照 | #08 |
| `/snapshot/movers/{market}` | ✗ | 漲跌幅排行 | #08 |
| `/snapshot/actives/{market}` | ✗ | 成交量值排行 | #08 |
| `/historical/candles/{symbol}` | ✓ | 歷史 K | #09 #10 |
| `/historical/stats/{symbol}` | ✗ | 52 週統計 | #02 |
| `/technical/*` | ✗ | 伺服器計算指標 | (不採用，本地算) |
| `/corporate-actions/dividends` | ✗ | 除權息 | #06 |
| `/corporate-actions/capital-changes` | ✗ | 減資 / ETF 分割 | #07 |
| `/corporate-actions/listing-applicants` | ✗ | 上市申請 | (低優先) |
| WebSocket `streaming` | ✗ | 即時推送 | #24 |

| TWSE 公開資料 | 已接 | 對應 # |
|---|---|---|
| `/rwd/zh/fund/T86` 三大法人 | ✓ | (已完成) |
| OpenAPI `/exchangeReport/BWIBBU_d` 本益比 | ✗ | #11 |

---

## 開發紀錄

每完成一項，請更新本表並把對應項目劃掉 (`~~#XX~~`) 或加 ✅ 標記。
重要決策（例如套件選擇、API 替換）也記在這裡。

| 日期 | 編號 | 變更 |
|---|---|---|
| 2026-05-11 | — | 路線圖建立 |
| 2026-05-11 | #15 | ✅ AppError 統一錯誤類別 + userMessage 擴充 |
| 2026-05-11 | #14 | ✅ Token 即時驗證 (ApiTokenState + status badge) |
| 2026-05-11 | #02 | ✅ 52 週高低 (HistoricalStats + Range52WCard) |
| 2026-05-11 | #01 #03 | ✅ 五檔買賣盤 + 內外盤比 (OrderBookCard) |
| 2026-05-11 | #33 | ✅ 資料來源 + 免責 footer (DataSourcesFooter) |
| 2026-05-11 | #31 | ✅ 首次使用免責 dialog |
| 2026-05-11 | #19 | ✅ 自選股剪貼簿備份 / 匯入 |

