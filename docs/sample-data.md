# サンプルデータ

このプロジェクトには、CLINS 風のFHIR Bundleサンプルを含めています。実患者データや非公開データではなく、公開用に作成した合成データです。

## 構成

```text
data/samples/
├─ document/
│  ├─ 01_eReferral_document.json
│  ├─ 02_eReferral_with_discharge_summary_document.json
│  ├─ 06_patient_summary_document.json
│  └─ 07_checkup_document.json
└─ collection/
   ├─ 03_clinical_condition_collection.json
   ├─ 04_clinical_allergyintolerance_collection.json
   └─ 05_clinical_observation_collection.json
```

## Bundle type

- 診療情報提供書、退院時サマリー、患者サマリー、健診文書は `type: document` です。
- 臨床情報の Condition / AllergyIntolerance / Observation は `type: collection` です。

Production はこれらの入力Bundleを受け取り、FHIR Repository登録用に `type: transaction` のBundleへ変換します。

## 患者情報

サンプルは同一患者として扱えるよう、患者識別子を公開用ダミー値に統一しています。

```text
SAMPLE-PATIENT-0001
```

## 注意

このサンプルはCLINS風の構造を理解するためのデモデータです。実運用のCLINS仕様や全項目を網羅するものではありません。
