# Demo_Condition テーブル

`InsertConditionToRDBOperation` は、入力Bundle内の `Condition` リソースを抽出し、`Demo_Condition` テーブルへ格納します。

## 自動作成

Production起動時に `Demo_Condition` が存在しない場合、Operationの `OnInit()` で自動作成します。

## 抽出対象

- トップレベルの `Bundle.entry[].resource.resourceType = "Condition"`
- ネストされた `Bundle.entry[].resource.resourceType = "Bundle"` 内の `Condition`

## ログ出力

処理後、イベントログに以下の形式で件数を出力します。

```text
Condition insert completed. Found=3, Inserted=3, Failed=0
```

## 確認SQL

```sql
SELECT
  BundleId,
  PatientIdentifier,
  PatientName,
  ConditionCode,
  ConditionText,
  ClinicalStatus,
  RecordedDate
FROM Demo_Condition
ORDER BY CreatedAt;
```
