# 股市技術分析 (Fugle API App)

整合 Fugle Market Data API 的 Android 技術分析 App。深色交易軟體風格 UI、Riverpod 狀態管理、Hive 本地快取、可自定的技術指標與診斷面板。

## 功能

- **設定頁**：加密儲存 Fugle API Token、即時 API 呼叫統計（今日 / 7 日 / 累計）、近 20 筆呼叫紀錄。
- **首頁 Dashboard**：自選股清單卡片化呈現，價格、漲跌、近 30 日 Sparkline。
- **個股詳情**：價量資訊頭、K 線 + 5/10/20/60MA 主圖、BIAS/RSI/MACD 副圖切換、自動診斷面板（多頭排列、過熱、超賣、金叉死叉等）。
- **快取優先策略**：日 K 線快取於 Hive，當日新鮮即不再打 API；盤中報價預設 60 秒快取窗口。
- **API 監控**：Dio Interceptor 記錄每一次呼叫至 Hive，設定頁即時統計。

## 技術棧

| 層次 | 套件 |
|---|---|
| Framework | Flutter (Android) |
| State | flutter_riverpod 2.x |
| 網路 | dio + 自訂 ApiLogInterceptor |
| 儲存 | hive / hive_flutter / flutter_secure_storage |
| 圖表 | fl_chart + 自繪 K 棒 / Histogram |

## 目錄結構

```
lib/
├── main.dart                       # 入口：初始化 Hive、注入 ProviderScope
├── app.dart                        # MaterialApp + 深色主題
├── core/
│   ├── theme/app_theme.dart        # 配色與主題定義
│   └── utils/formatters.dart       # 價格 / 百分比 / 日期格式化
├── data/
│   ├── models/                     # Hive 模型 (純手寫 TypeAdapter)
│   │   ├── candle.dart
│   │   ├── stock_quote.dart
│   │   ├── api_log.dart
│   │   └── watchlist_item.dart
│   ├── services/
│   │   ├── secure_storage_service.dart   # API Token 加密儲存
│   │   ├── hive_service.dart             # Box 開啟與 Adapter 註冊
│   │   ├── fugle_api_client.dart         # Fugle REST 包裝
│   │   ├── api_log_interceptor.dart      # Dio 攔截器
│   │   └── stock_repository.dart         # 快取優先資料層
│   └── providers/providers.dart    # Riverpod providers
├── indicators/indicators.dart      # MA / BIAS / RSI / MACD + 診斷
└── features/
    ├── dashboard/                  # 自選股首頁 + Sparkline
    ├── stock_detail/               # K 線 + 副圖 + 診斷面板
    └── settings/                   # Token + API 監控
```

## 啟動方式

```bash
flutter pub get
flutter run -d <android-device>
```

第一次啟動會看到「尚未設定 Fugle API Token」橫幅，點擊「前往設定」貼上自己的 Token 即可。Token 透過 `flutter_secure_storage` 儲存於 Android Keystore，不以明碼留存。

## Fugle API 端點對應

| 用途 | 端點 |
|---|---|
| 盤中即時 | `GET /stock/intraday/quote/{symbol}` |
| 歷史日 K | `GET /stock/historical/candles/{symbol}?from=&to=` |

API base URL: `https://api.fugle.tw/marketdata/v1.0`，於 header 帶 `X-API-KEY`。

## 減少 API 呼叫策略

1. **盤中報價**：60 秒內視為新鮮，重複進入頁面不重打。
2. **日 K**：當日最後一筆已存在且資料量足夠 (>60% 預期長度) 即不打 API。
3. **手動下拉重新整理**會 invalidate provider，強制走 API。
4. 所有呼叫都會被 `ApiLogInterceptor` 記錄到 `api_logs_box`，設定頁可即時驗證實際呼叫量。

## 技術指標說明

| 指標 | 演算法 |
|---|---|
| MA | 簡單移動平均，週期 5 / 10 / 20 / 60 |
| BIAS | `(Close - MA20) / MA20 * 100` |
| RSI | 14 日 Wilder 平滑 |
| MACD | 12/26 EMA 差 + 9 日 DEA + 柱狀 (DIF-DEA)*2 |

## 診斷邏輯

| 條件 | 標籤 |
|---|---|
| MA5 > MA10 > MA20 > MA60 | 🔥 強勢多頭 |
| MA5 < MA10 < MA20 < MA60 | ❄️ 弱勢空頭 |
| BIAS(20) > 8 | ⚠️ 過熱 |
| BIAS(20) < -8 | 🧊 超跌 |
| RSI > 70 / < 30 | 🚨 超買 / 🟢 超賣 |
| MACD 金叉 / 死叉 | ✨ / ⚠️ |
| 量 > 2x 20 日均量且收紅 | 📈 爆量上攻 |

## 免責聲明

本 App 所有技術指標、診斷標籤僅供參考，不構成任何投資建議。實際投資決策請自行判斷並承擔風險。
