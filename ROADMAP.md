# 股市技術分析 App — 路線圖

最後更新：2026-05-11

本文件追蹤 App 已完成功能與未來方向。
按優先級分四群：**C → D → B → Z**（C 與 D 同等重要，B 慢慢做，Z 永遠不做）。

---

## 目錄

- [現況總覽](#現況總覽)
- [已完成（Phase 1-5）](#已完成phase-1-5)
- [Phase 6 — 進階功能（C）](#phase-6--進階功能c)
- [Phase 7 — 品質與維運（D）](#phase-7--品質與維運d)
- [Phase 8 — 上架準備（B，慢慢做）](#phase-8--上架準備b慢慢做)
- [永久延後 / 不做（Z）](#永久延後--不做z)
- [Fugle API 對照](#fugle-api-對照)
- [開發紀錄](#開發紀錄)

---

## 現況總覽

| Phase | 狀態 | 範圍 |
|---|---|---|
| Phase 1 — Quick Wins | ✅ 完成 | 8 項 |
| Phase 2 — 深度資料 | ✅ 完成 | 5 項 |
| Phase 3 — 體驗打磨 | ✅ 完成（Sentry 延後） | 7 項 |
| Phase 4 — 即時化 | ✅ 完成（含 bonus 通知） | 6 項 |
| Phase 5 — 進階 | ✅ 完成（新聞/i18n/畫線延後） | 6 項 |
| **Phase 6 — 進階功能（C）** | 🟡 待做 | 10 項 |
| **Phase 7 — 品質與維運（D）** | 🟡 待做 | 7 項 |
| **Phase 8 — 上架準備（B）** | 🟢 慢慢做 | 5 項 |
| 永久延後（Z） | ⛔ 不做 | 3 項 |

**已完成共 32 項**，App 已具備：14 種技術指標 + 自訂參數、即時 WebSocket 報價、5 大類籌碼面、基本面 + 除權息 + 減資、12+ K 線型態 + 7 指標投票、持倉 / 多股對比 / 警示 / 群組 / 背景刷新 / 生物識別。

---

## 已完成（Phase 1-5）

### Phase 1 — Quick Wins
- ✅ `#02` 52 週高低
- ✅ `#01` 五檔買賣盤
- ✅ `#03` 內外盤比
- ✅ `#14` Token 即時驗證
- ✅ `#15` 錯誤訊息友善化（AppError）
- ✅ `#19` 自選股備份 / 匯入（剪貼簿 JSON）
- ✅ `#31` 免責聲明強化（首次 dialog）
- ✅ `#33` 資料來源標示

### Phase 2 — 深度資料
- ✅ `#06` 除權息資訊 + 殖利率 + 預告
- ✅ `#08` 市場熱度頁（漲跌幅 / 成交量值 × 上市 / 上櫃）
- ✅ `#09` `#10` K 線多週期（日 / 週 / 月）+ 5 種區間
- ✅ `#11` 基本面快照（PE / PB / 殖利率，TWSE BWIBBU_d）
- ✅ `#13` 加權指數對比

### Phase 3 — 體驗打磨
- ✅ `#16` 空狀態引導
- ✅ `#17` 首次 Onboarding（3 頁）
- ✅ `#18` 價格警示（in-app + 系統通知）
- ✅ `#20` 自選股分組（TabBar + 長按移動）
- ✅ `#22` Loading shimmer
- ✅ `#23` 單元測試（指標 + analysis）
- ✅ `#32` 隱私政策 / 使用條款

### Phase 4 — 即時化
- ✅ `#24` WebSocket 即時報價（Fugle aggregates，引用計數 + 重連）
- ✅ `#26` 生物識別解鎖（local_auth + BiometricGate）
- ✅ `#29` 持倉 / 損益試算
- ✅ `#30` 多股對比（標準化疊圖）
- ✅ Bonus: 系統通知（flutter_local_notifications，含 Inbox style）

### Phase 5 — 進階
- ✅ `#04` 逐筆成交（大單高亮 + 主動方向）
- ✅ `#05` 分價量表（籌碼分布 + 主力價位）
- ✅ `#07` 減資 / ETF 分割
- ✅ `#28` Android 背景排程（workmanager，含 UI 設定）
- ✅ `#34` K 線型態辨識（12+ 種型態）
- ✅ `#36` 自訂指標參數

---

## Phase 6 — 進階功能（C）

「沒做也能用，但有了會差很多」的功能。對重度使用者影響大、技術門檻不高（多數已有 API）。

### #C01 券商分點
- **目標**：個股頁加「主力買賣超」表，顯示前 N 家券商今日 / 5 日累計買賣超金額。
- **資料源**：TWSE 沒直接給，要走 [富果 / 群益 / 玩股網] 等爬蟲，或 [神秘金字塔 BSR](https://norway.twsthr.info/StockHolders.aspx?stock=2330)。
- **實作要點**：可能需要自己架簡單代理伺服器。複雜度高。
- **工作量**：L（10+ 小時）
- **依賴**：可能需要外部服務

### #C02 融資融券餘額
- **目標**：個股頁加「信用交易」卡，顯示融資 / 融券餘額、券資比、近 5 日變化。
- **資料源**：TWSE [/exchangeReport/MI_MARGN](https://www.twse.com.tw/zh/page/trading/exchange/MI_MARGN.html) 公開 API。
- **實作要點**：類似三大法人作法，整批抓 + 篩 symbol + Hive 快取。
- **工作量**：M（4-5 小時）

### #C03 個股新聞
- **目標**：個股頁底部加「相關新聞」3-5 條，標題 + 來源 + 時間。
- **資料源候選**：
  - Google News RSS（按代號 + 名稱搜尋，免費但格式變動風險）
  - 鉅亨網 API（要查授權）
  - 自家爬蟲（複雜）
- **實作要點**：建議從 RSS 開始，套件 `webfeed`。
- **工作量**：M（4 小時）
- **風險**：來源穩定性

### #C04 盤前 / 盤後試撮
- **目標**：8:30-9:00 盤前試撮、13:25-13:30 收盤前試撮的價格 / 量。
- **資料源**：Fugle WebSocket `aggregates` channel 已含 `isTrial` 欄位。
- **實作要點**：詳情頁 PriceHeader 加試撮指示燈 + 預估開盤價。
- **工作量**：M（3 小時）

### #C05 歷史型態回測
- **目標**：「過去 N 次 KD 金叉後 5 日平均報酬」「MACD 黃金交叉勝率」之類的統計。
- **實作要點**：純客戶端計算，跑近 1 年歷史。可呈現勝率、平均報酬、最大跌幅。
- **工作量**：L（8-10 小時）

### #C06 產業類股比較
- **目標**：同產業他股對比（同個股票分類）。
- **資料源**：Fugle ticker 已有 `industry` 欄位。
- **實作要點**：個股頁加「同產業表現」清單，可跳轉。
- **工作量**：M（4 小時）

### #C07 K 線 pinch zoom
- **目標**：兩指縮放、單指拖曳查看更長歷史。
- **實作要點**：fl_chart 1.x 有原生支援（要升級），或自製 GestureDetector + viewport 邏輯。
- **工作量**：L（升 fl_chart 是 breaking change，預估 6-8 小時包含 migration）

### #C08 自選股拖曳排序
- **目標**：在「自訂」模式下可手動拖曳排序。
- **實作要點**：`ReorderableListView` + WatchlistItem 加 `sortOrder` 欄位。
- **工作量**：S（2 小時）

### #C09 搜尋歷史 / 最近查看
- **目標**：Add sheet 記錄最近搜尋詞 + 最近開啟過的股票。
- **實作要點**：Hive 存 LRU，最多 10 筆。
- **工作量**：S（1.5 小時）

### #C10 匯出 K 線截圖
- **目標**：右上加分享按鈕，把當前圖表存成 PNG。
- **實作要點**：套件 `screenshot` + `share_plus`。
- **工作量**：S（1.5 小時）

---

## Phase 7 — 品質與維運（D）

「給未來自己」的投資。功能再多，沒有測試與監測都會出事。

### #D01 提升單元測試覆蓋率
- **現況**：只有 `test/indicators_test.dart` 與 `test/analysis_test.dart`（純函式）。
- **目標**：覆蓋至少：
  - `Candle` / `StockQuote` / `Holding` 等模型的解析與計算方法
  - `StockRepository` 的快取邏輯
  - `WatchlistGroupNotifier`、`PriceAlertNotifier`、`IndicatorPrefsNotifier` 等 Notifier
  - `Diagnoser`、`SignalAnalyser`、`VolatilityAnalyser`、`PatternRecognition`
- **目標覆蓋率**：>= 60%
- **工作量**：L（8-10 小時）

### #D02 加入 integration / widget 測試
- **目標**：用 `flutter_test` widget 測試或 `integration_test` 套件，驗證：
  - Dashboard 加入自選股流程
  - 個股頁切換 timeframe
  - 觸發價格警示
  - 設定頁切換配色
- **工作量**：M-L（6-8 小時）

### #D03 GitHub Actions CI
- **目標**：每次 push 自動：
  1. `flutter analyze`
  2. `flutter test`
  3. `flutter build apk --debug`
- **實作要點**：`.github/workflows/ci.yml`，使用 `subosito/flutter-action`。
- **工作量**：S（1-2 小時）

### #D04 iOS 適配與測試
- **現況**：Flutter 跨平台寫法，但完全沒在 iOS 跑過。
- **要驗證**：
  - `flutter_secure_storage` iOS Keychain 運作
  - `local_auth` FaceID 流程
  - `flutter_local_notifications` iOS APNs / 權限請求
  - `workmanager` iOS BGTaskScheduler（功能有限）
  - 字體與佈局在較窄寬度的 iPhone（如 SE）的呈現
- **工作量**：L（8-12 小時 + 需要 Mac / iPhone 實機）

### #D05 無障礙（Accessibility）
- **目標**：替關鍵元件加 `Semantics` label，支援 TalkBack / VoiceOver。
- **重點區**：StockCard、價格、漲跌幅、警示按鈕。
- **工作量**：M（4 小時）

### #D06 效能 profiling
- **目標**：跑 DevTools Profiler，找出渲染瓶頸。常見問題：
  - K 線圖在大量蠟燭時 jank
  - 三大法人卡 progressive load 期間 rebuild 過多
  - WebSocket onMessage 觸發整顆 UI rebuild
- **預期改善**：jank 從 60ms 降到 16ms 內
- **工作量**：M（4-6 小時）

### #D07 i18n / l10n（中 / 英）
- **目標**：字串抽出到 `arb`，至少支援 zh_TW + en。
- **實作要點**：
  - 套件：`flutter_localizations`, `intl_utils`
  - `lib/l10n/app_zh_TW.arb` / `app_en.arb`
  - 全 codebase 改用 `AppLocalizations.of(context).xxx`
- **工作量**：L（10-15 小時，純機械工作）

---

## Phase 8 — 上架準備（B，慢慢做）

App 已經能跑、可以給人試用，但要傳上 Play Store 還要這幾項。沒急的話可以一晚做完。

### #B01 App icon
- **目標**：取代 Flutter 預設藍底 logo。
- **實作要點**：1024×1024 PNG + `flutter_launcher_icons` 套件自動生成各尺寸。
- **工作量**：S（1 小時，含設計或找素材時間）

### #B02 Splash screen
- **目標**：取代預設白底，做品牌啟動畫面（深色背景 + logo）。
- **實作要點**：套件 `flutter_native_splash`，配置 `pubspec.yaml`，跑 `dart run flutter_native_splash:create`。
- **工作量**：S（1 小時）

### #B03 正式 Android 簽章
- **現況**：`build.gradle.kts` 用 debug key。
- **目標**：產 release key + 設定 `signingConfigs.release`，把 key 路徑與密碼放在 `key.properties`（不進 git）。
- **實作要點**：依官方文件 [Build and release an Android app](https://docs.flutter.dev/deployment/android)。
- **工作量**：S（1 小時）

### #B04 App 名稱 / 版本號
- **現況**：`AndroidManifest.xml` 標籤是 `fugle_api_app`、`pubspec.yaml` 版本 `0.1.0+1`。
- **目標**：改成中文名稱（例如「股市技術分析」），版本號規範化（例如 `1.0.0+1` 正式版）。
- **工作量**：S（5 分鐘）

### #B05 Sentry 崩潰回報
- **現況**：完全沒接，release 掛了不知道。
- **目標**：接 `sentry_flutter`，所有 unhandled exception 上報。
- **實作要點**：
  - 註冊 Sentry 帳號取得 DSN
  - DSN 寫到 build-time `--dart-define=SENTRY_DSN=...`
  - `main.dart` 包 `SentryFlutter.init` + `runZonedGuarded`
- **工作量**：S（1.5 小時，含註冊時間）

---

## 永久延後 / 不做（Z）

這幾項評估後不做：

### Z01 桌面 widget（Android App Widget）
- **理由**：需要原生 Kotlin + XML layout + 通訊 channel，與 Flutter 開發節奏不合。
- **使用者已表態取消**。

### Z02 圖表畫線工具
- **理由**：UI 工程量大（拖曳起終點、儲存、編輯、刪除、模式切換），對個人技術分析 App 價值與工作量不成比例。
- **替代方案**：依靠系統截圖 + 第三方畫圖 App。

### Z03 整合券商下單
- **理由**：合規門檻高（需要 PCI / 個資審查），不是個人專案能做的範圍。
- **替代方案**：使用者自行在券商 App 下單。

---

## Fugle API 對照

| Fugle 端點 | 已接 | 對應 # |
|---|---|---|
| `/intraday/tickers` | ✓ | (已完成) |
| `/intraday/ticker/{symbol}` | ✓ | (已完成) |
| `/intraday/quote/{symbol}` | ✓ | #01 #03 |
| `/intraday/candles/{symbol}` | ✓ | 當日分線 |
| `/intraday/trades/{symbol}` | ✓ | #04 |
| `/intraday/volumes/{symbol}` | ✓ | #05 |
| `/snapshot/quotes/{market}` | ✗ | (低優先) |
| `/snapshot/movers/{market}` | ✓ | #08 |
| `/snapshot/actives/{market}` | ✓ | #08 |
| `/historical/candles/{symbol}` | ✓ | #09 #10 |
| `/historical/stats/{symbol}` | ✓ | #02 |
| `/technical/*` | ✗ | (不採用，本地算) |
| `/corporate-actions/dividends` | ✓ | #06 |
| `/corporate-actions/capital-changes` | ✓ | #07 |
| `/corporate-actions/listing-applicants` | ✗ | (低優先) |
| WebSocket `streaming` | ✓ | #24 |

| TWSE 公開資料 | 已接 | 對應 # |
|---|---|---|
| `/rwd/zh/fund/T86` 三大法人 | ✓ | (已完成) |
| OpenAPI `/exchangeReport/BWIBBU_d` 本益比 | ✓ | #11 |
| `/exchangeReport/MI_MARGN` 融資融券 | ✗ | #C02 |

---

## 建議執行順序（給未來的自己）

### 短期（1-2 天）— 上架前最小清單
`#B01` icon → `#B02` splash → `#B03` 簽章 → `#B04` 名稱 → `#B05` Sentry → 上架 Play Store 內測

### 中期（一週）— 強化品質
`#D03` CI → `#D01` 測試覆蓋 → `#D02` widget 測試 → `#D06` 效能 profiling

### 長期（兩週 +）— 進階功能
`#C02` 融資融券 → `#C04` 盤前盤後 → `#C08` 拖曳排序 → `#C09` 搜尋歷史 → `#C10` 截圖分享
→ `#C06` 產業比較 → `#C03` 新聞（看穩不穩）
→ 想做大的：`#C01` 券商分點 / `#C05` 歷史回測 / `#C07` K 線 zoom

### 國際化（沒急可以等）
`#D07` i18n → `#D04` iOS → `#D05` 無障礙

---

## 開發紀錄

| 日期 | 編號 | 變更 |
|---|---|---|
| 2026-05-11 | — | 路線圖建立 |
| 2026-05-11 | #15 | ✅ AppError 統一錯誤類別 + userMessage 擴充 |
| 2026-05-11 | #14 | ✅ Token 即時驗證（ApiTokenState + status badge） |
| 2026-05-11 | #02 | ✅ 52 週高低（HistoricalStats + Range52WCard） |
| 2026-05-11 | #01 #03 | ✅ 五檔買賣盤 + 內外盤比（OrderBookCard） |
| 2026-05-11 | #33 | ✅ 資料來源 + 免責 footer |
| 2026-05-11 | #31 | ✅ 首次使用免責 dialog |
| 2026-05-11 | #19 | ✅ 自選股剪貼簿備份 / 匯入 |
| 2026-05-11 | #06 | ✅ 除權息資料 + 殖利率 + 下次預告 |
| 2026-05-11 | #09 #10 | ✅ K 線多週期 + 5 種區間 |
| 2026-05-11 | #13 | ✅ 加權指數對比疊圖 |
| 2026-05-11 | #11 | ✅ 基本面快照（TWSE BWIBBU_d） |
| 2026-05-11 | #08 | ✅ 市場熱度頁 |
| 2026-05-11 | #22 | ✅ 自製 Shimmer widget |
| 2026-05-11 | #16 | ✅ EmptyWatchlistView |
| 2026-05-11 | #17 | ✅ 3 頁 onboarding |
| 2026-05-11 | #32 | ✅ 隱私政策 + 使用條款 |
| 2026-05-11 | #18 | ✅ 價格警示（in-app + 系統通知） |
| 2026-05-11 | #20 | ✅ 自選股分組 |
| 2026-05-11 | #23 | ✅ 指標 + analysis 單元測試 |
| 2026-05-11 | #26 | ✅ 生物識別解鎖 |
| 2026-05-11 | #28 | ✅ Android workmanager 背景排程 |
| 2026-05-11 | — | ✅ Bonus 系統通知（rich Android 通知） |
| 2026-05-11 | #29 | ✅ 持倉試算 |
| 2026-05-11 | #30 | ✅ 多股對比 |
| 2026-05-11 | #24 | ✅ WebSocket 即時報價 |
| 2026-05-11 | #04 | ✅ 逐筆成交（大單高亮） |
| 2026-05-11 | #05 | ✅ 分價量表 |
| 2026-05-11 | #07 | ✅ 減資 / ETF 分割 |
| 2026-05-11 | #36 | ✅ 自訂指標參數 |
| 2026-05-11 | #34 | ✅ K 線型態辨識（12+ 種） |
| 2026-05-11 | — | 🛠 修 const + 動態色 release build 錯誤 |
| 2026-05-11 | — | 🛠 workmanager 0.5 → 0.9，啟用 desugar |
| 2026-05-11 | — | 🛠 historical/candles 改用 adjusted=false（未還原權值） |
| 2026-05-11 | — | 加「清除本地快取」按鈕 |
| 2026-05-11 | — | 📋 路線圖大改版：分 C/D/B/Z 四群 |
