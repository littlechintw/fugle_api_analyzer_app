import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final String body;
  const LegalPage({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._renderMarkdown(body),
          ],
        ),
      ),
    );
  }

  List<Widget> _renderMarkdown(String md) {
    final lines = md.split('\n');
    final out = <Widget>[];
    for (final line in lines) {
      if (line.startsWith('## ')) {
        out.add(Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
          child: Text(
            line.substring(3),
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ));
      } else if (line.startsWith('# ')) {
        out.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line.substring(2),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ));
      } else if (line.startsWith('- ')) {
        out.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            '• ${line.substring(2)}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ));
      } else if (line.trim().isEmpty) {
        out.add(const SizedBox(height: 8));
      } else {
        out.add(Text(
          line,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            height: 1.7,
          ),
        ));
      }
    }
    return out;
  }
}

const String privacyPolicyText = '''
# 隱私政策

最後更新：2026 年 5 月 11 日

## 我們收集的資訊

本 App 是個人技術分析工具，原則上不收集您的個人資訊。具體而言：

- **API Token**：您輸入的 Fugle API 金鑰僅加密儲存於本機裝置 (Android Keystore / iOS Keychain)，不會傳送到任何第三方伺服器
- **自選股清單**：僅儲存於本機 Hive 資料庫
- **API 呼叫紀錄**：僅用於 App 內部統計顯示 (今日/7日/累計次數)，存於本機
- **使用者偏好**：配色模式、排序設定、群組設定皆存於本機

## 我們存取的第三方服務

- **Fugle Market Data API** (api.fugle.tw)：取得即時報價、K 線、歷史資料
- **TWSE 公開資料** (twse.com.tw, openapi.twse.com.tw)：三大法人買賣超、本益比 / 殖利率

App 透過您的 Token 與 IP 連線到上述服務，這些服務各有自己的隱私政策，請參考各自網站。

## 我們不做什麼

- 不會建立使用者帳號
- 不收集您的姓名、Email、電話、地址
- 不使用廣告 SDK
- 不追蹤您在其他 App / 網站的行為
- 不會與第三方分享您的資料

## 您的權利

您可隨時：

- 在「設定」頁清除 API Token
- 移除自選股
- 解除安裝 App，所有本機資料將一併刪除

## 聯絡方式

如有任何問題，請開啟 issue 或聯絡開發者。
''';

const String termsOfServiceText = '''
# 使用條款

最後更新：2026 年 5 月 11 日

## 服務說明

本 App「股市技術分析」提供台股市場資料展示、技術指標計算、籌碼面摘要等技術分析功能。

## 重要免責聲明

- 本 App 提供的所有資訊（包含但不限於股價、技術指標、診斷標籤、綜合評分、波動度分析、三大法人買賣超、基本面數據等）皆為 **技術面參考資料**
- **不構成任何投資建議、買賣依據或保證**
- 任何投資決策造成的損益由使用者自行承擔
- 資料可能因網路、API 限制、第三方來源異常而延遲、缺失或錯誤
- 重要決策請以證券交易所、官方公告為準

## 使用限制

- 本 App 透過 Fugle Market Data API 取得行情，使用者需自行申請並遵守 Fugle 之服務條款
- 不得將取得之資料用於商業重發布或建立競爭性服務
- 不得規避 API 呼叫頻率限制或試圖反向工程本 App

## 智慧財產權

行情資料著作權歸 Fugle、臺灣證券交易所、櫃買中心等資料提供者所有。

## 條款變更

我們可能隨時更新本條款。重大變更將於 App 內以對話框提示。

## 適用法律

本條款依中華民國法律解釋。
''';
