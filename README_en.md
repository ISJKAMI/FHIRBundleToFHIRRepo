# FHIRBundleToFHIRRepo

This is an InterSystems IRIS for Health sample project that receives CLINS-style FHIR Bundle files, converts them into FHIR transaction Bundles, posts them to a FHIR Repository, and stores selected `Condition` data in a simple relational table.

All sample data is synthetic. No real patient data, private CLINS data, internal host names, or real credentials are included.

## Purpose

The main purpose of this sample is to demonstrate this flow:

1. Receive CLINS-style document/collection Bundles
2. Convert them into FHIR transaction Bundles inside an Interoperability Production
3. Register them in a FHIR Repository
4. Extract Condition resources into `Demo_Condition`

## Sample data

`data/samples/` contains five synthetic CLINS-style Bundles for the same patient `SAMPLE-PATIENT-0001`:

- referral document
- clinical information
- health checkup information
- discharge summary
- follow-up laboratory and medication information

The input Bundles are intentionally `type: collection`. They are converted to `type: transaction` by `DocumentImportProcess`.

## FHIR connection settings

The Production uses placeholder settings:

```text
Server: fhir.example.com
Port: 443
Https: 1
SSLConfiguration: DemoFHIRSSL
Credentials: DemoFHIRUser
BasePath: /csp/healthshare/fhirserver/fhir/r4
```

Create matching Credentials and SSL/TLS Configuration entries in the IRIS Management Portal, or update the Production settings for your environment.

## Quick start

Import and compile classes under `src/`, start `FHIRBundleToFHIRRepo.DemoProduction`, then copy sample files to `/tmp/fhirdemo/in`.

```bash
mkdir -p /tmp/fhirdemo/in /tmp/fhirdemo/work /tmp/fhirdemo/archive
cp data/samples/*.json /tmp/fhirdemo/in/
```

## Verify FHIR data

```bash
curl -u username:password \
  "https://fhir.example.com/csp/healthshare/fhirserver/fhir/r4/Patient?identifier=SAMPLE-PATIENT-0001"
```

```bash
curl -u username:password \
  "https://fhir.example.com/csp/healthshare/fhirserver/fhir/r4/Condition?subject=Patient/sample-patient-0001"
```

## Verify RDB data

```sql
SELECT BundleId, PatientIdentifier, ConditionCode, ConditionText, RecordedDate
FROM Demo_Condition
ORDER BY CreatedAt;
```
