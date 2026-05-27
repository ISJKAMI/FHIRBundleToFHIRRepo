Class FHIRBundleToFHIRRepo.BO.InsertConditionToRDBOperation Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Method OnInit() As %Status
{
    Return ..EnsureConditionTable()
}

Method OnMessage(pRequest As Ens.StringContainer, Output pResponse As Ens.Response) As %Status
{
    Set pResponse = ##class(Ens.Response).%New()

    Set tConditionCount = 0
    Set tInsertedCount = 0
    Set tFailedCount = 0

    Try {
        Set tJson = pRequest.StringValue

        If tJson="" {
            $$$LOGWARNING("Condition insert skipped. Empty request message.")
            Return $$$OK
        }

        Set tBundle = ##class(%DynamicObject).%FromJSON(tJson)

        Set tSC = ..InsertConditionsFromBundle(tBundle,.tConditionCount,.tInsertedCount,.tFailedCount)

        $$$LOGINFO("Condition insert completed. Found="_tConditionCount_", Inserted="_tInsertedCount_", Failed="_tFailedCount)

        Return tSC
    }
    Catch ex {
        $$$LOGERROR("Condition insert failed. "_ex.DisplayString())
        Return ex.AsStatus()
    }
}

ClassMethod InsertConditionsFromBundle(pBundle As %DynamicObject, Output pConditionCount As %Integer, Output pInsertedCount As %Integer, Output pFailedCount As %Integer) As %Status
{
    If '$IsObject(pBundle) {
        Return $$$OK
    }

    If '..HasProperty(pBundle,"entry") {
        Return $$$OK
    }

    Set tEntries = pBundle.%Get("entry")

    If '$IsObject(tEntries) {
        Return $$$OK
    }

    For i=0:1:tEntries.%Size()-1 {
        Set tEntry = tEntries.%Get(i)

        If '$IsObject(tEntry) {
            Continue
        }

        If '..HasProperty(tEntry,"resource") {
            Continue
        }

        Set tResource = tEntry.%Get("resource")

        If '$IsObject(tResource) {
            Continue
        }

        Set tResourceType = ..GetValue(tResource,"resourceType")

        If tResourceType="Condition" {
            Set pConditionCount = pConditionCount + 1
            Set tSC = ..InsertCondition(pBundle,tResource)

            If $$$ISOK(tSC) {
                Set pInsertedCount = pInsertedCount + 1
            } Else {
                Set pFailedCount = pFailedCount + 1
                $$$LOGERROR("Failed to insert Condition. Status="_$SYSTEM.Status.GetErrorText(tSC))
            }
        }

        If tResourceType="Bundle" {
            Set tSC = ..InsertConditionsFromBundle(tResource,.pConditionCount,.pInsertedCount,.pFailedCount)
            If $$$ISERR(tSC) {
                Return tSC
            }
        }
    }

    Return $$$OK
}

ClassMethod InsertCondition(pBundle As %DynamicObject, pCondition As %DynamicObject) As %Status
{
    Try {
        Set tBundleId = ..GetValue(pBundle,"identifier.value")
        Set tBundleTimestamp = ..GetValue(pBundle,"timestamp")

        Set tPatientId = ..GetPatientIdFromBundle(pBundle)
        Set tPatientIdentifier = ..GetPatientIdentifierFromBundle(pBundle)
        Set tPatientName = ..GetPatientNameFromBundle(pBundle)
        Set tPatientGender = ..GetPatientGenderFromBundle(pBundle)
        Set tPatientBirthDate = ..GetPatientBirthDateFromBundle(pBundle)

        Set tConditionId = ..GetValue(pCondition,"id")
        Set tConditionIdentifier = ..GetValue(pCondition,"identifier.0.value")
        Set tClinicalStatus = ..GetValue(pCondition,"clinicalStatus.coding.0.code")
        Set tVerificationStatus = ..GetValue(pCondition,"verificationStatus.coding.0.code")
        Set tCategory = ..GetValue(pCondition,"category.0.coding.0.code")
        Set tConditionCode = ..GetValue(pCondition,"code.coding.0.code")
        Set tConditionText = ..GetValue(pCondition,"code.text")
        Set tOnsetDateTime = ..GetValue(pCondition,"onsetDateTime")
        Set tAbatementDateTime = ..GetValue(pCondition,"abatementDateTime")
        Set tRecordedDate = ..GetValue(pCondition,"recordedDate")
        Set tRecorder = ..GetValue(pCondition,"recorder.display")
        Set tAsserter = ..GetValue(pCondition,"asserter.display")
        Set tInstitutionNumber = ..GetExtensionIdentifierValue(pCondition,"http://jpfhir.jp/fhir/clins/Extension/StructureDefinition/JP_eCS_InstitutionNumber")
        Set tDepartment = ..GetExtensionCodeableConceptText(pCondition,"http://jpfhir.jp/fhir/eCS/Extension/StructureDefinition/JP_eCS_Department")
        Set tDiagnosisType = ..GetExtensionCodeableConceptText(pCondition,"http://jpfhir.jp/fhir/eCS/Extension/StructureDefinition/JP_eCS_DiagnosisType")
        Set tRawConditionJson = pCondition.%ToJSON()

        Set tSQL = "INSERT INTO Demo_Condition (" _
            "BundleId, BundleTimestamp, PatientId, PatientIdentifier, PatientName, PatientGender, PatientBirthDate, " _
            "ConditionId, ConditionIdentifier, ClinicalStatus, VerificationStatus, Category, ConditionCode, ConditionText, " _
            "OnsetDateTime, AbatementDateTime, RecordedDate, Recorder, Asserter, InstitutionNumber, Department, DiagnosisType, RawConditionJson" _
            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

        Set tStmt = ##class(%SQL.Statement).%New()
        Set tSC = tStmt.%Prepare(tSQL)

        If $$$ISERR(tSC) {
            Return tSC
        }

        Set tRS = tStmt.%Execute(
            tBundleId,
            ..ToSQLTimestamp(tBundleTimestamp),
            tPatientId,
            tPatientIdentifier,
            tPatientName,
            tPatientGender,
            ..ToSQLDate(tPatientBirthDate),
            tConditionId,
            tConditionIdentifier,
            tClinicalStatus,
            tVerificationStatus,
            tCategory,
            tConditionCode,
            tConditionText,
            ..ToSQLTimestamp(tOnsetDateTime),
            ..ToSQLTimestamp(tAbatementDateTime),
            ..ToSQLTimestamp(tRecordedDate),
            tRecorder,
            tAsserter,
            tInstitutionNumber,
            tDepartment,
            tDiagnosisType,
            tRawConditionJson
        )

        If tRS.%SQLCODE < 0 {
            Return $$$ERROR($$$GeneralError,tRS.%Message)
        }

        Return $$$OK
    }
    Catch ex {
        Return ex.AsStatus()
    }
}

ClassMethod EnsureConditionTable() As %Status
{
    Try {
        Set tSQL = "SELECT COUNT(*) AS Cnt FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DEMO_CONDITION'"
        Set tRS = ##class(%SQL.Statement).%ExecDirect(,tSQL)

        If tRS.%Next() {
            If tRS.Cnt > 0 {
                Return $$$OK
            }
        }

        Set tCreateSQL = "CREATE TABLE Demo_Condition (" _
            "ID INTEGER IDENTITY PRIMARY KEY, " _
            "BundleId VARCHAR(128), " _
            "BundleTimestamp TIMESTAMP, " _
            "PatientId VARCHAR(128), " _
            "PatientIdentifier VARCHAR(128), " _
            "PatientName VARCHAR(200), " _
            "PatientGender VARCHAR(32), " _
            "PatientBirthDate DATE, " _
            "ConditionId VARCHAR(128), " _
            "ConditionIdentifier VARCHAR(128), " _
            "ClinicalStatus VARCHAR(64), " _
            "VerificationStatus VARCHAR(64), " _
            "Category VARCHAR(64), " _
            "ConditionCode VARCHAR(64), " _
            "ConditionText VARCHAR(500), " _
            "OnsetDateTime TIMESTAMP, " _
            "AbatementDateTime TIMESTAMP, " _
            "RecordedDate TIMESTAMP, " _
            "Recorder VARCHAR(200), " _
            "Asserter VARCHAR(200), " _
            "InstitutionNumber VARCHAR(64), " _
            "Department VARCHAR(200), " _
            "DiagnosisType VARCHAR(100), " _
            "RawConditionJson LONGVARCHAR, " _
            "CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP" _
            ")"

        Set tRS = ##class(%SQL.Statement).%ExecDirect(,tCreateSQL)

        If $IsObject(tRS), tRS.%SQLCODE < 0 {
            Return $$$ERROR($$$GeneralError,tRS.%Message)
        }

        Return $$$OK
    }
    Catch ex {
        Return ex.AsStatus()
    }
}

ClassMethod GetPatientIdFromBundle(pBundle As %DynamicObject) As %String
{
    Set tPatient = ..FindFirstResource(pBundle,"Patient")
    If '$IsObject(tPatient) {
        Return ""
    }

    Return ..GetValue(tPatient,"id")
}

ClassMethod GetPatientIdentifierFromBundle(pBundle As %DynamicObject) As %String
{
    Set tPatient = ..FindFirstResource(pBundle,"Patient")
    If '$IsObject(tPatient) {
        Return ""
    }

    Return ..GetValue(tPatient,"identifier.0.value")
}

ClassMethod GetPatientNameFromBundle(pBundle As %DynamicObject) As %String
{
    Set tPatient = ..FindFirstResource(pBundle,"Patient")
    If '$IsObject(tPatient) {
        Return ""
    }

    Set tName = ..GetValue(tPatient,"name.0.text")
    If tName'="" {
        Return tName
    }

    Set tFamily = ..GetValue(tPatient,"name.0.family")
    Set tGiven = ..GetValue(tPatient,"name.0.given.0")

    Return $ZStrip(tFamily_" "_tGiven,"<>W")
}

ClassMethod GetPatientGenderFromBundle(pBundle As %DynamicObject) As %String
{
    Set tPatient = ..FindFirstResource(pBundle,"Patient")
    If '$IsObject(tPatient) {
        Return ""
    }

    Return ..GetValue(tPatient,"gender")
}

ClassMethod GetPatientBirthDateFromBundle(pBundle As %DynamicObject) As %String
{
    Set tPatient = ..FindFirstResource(pBundle,"Patient")
    If '$IsObject(tPatient) {
        Return ""
    }

    Return ..GetValue(tPatient,"birthDate")
}

ClassMethod FindFirstResource(pBundle As %DynamicObject, pResourceType As %String) As %DynamicObject
{
    If '$IsObject(pBundle) {
        Return ""
    }

    If '..HasProperty(pBundle,"entry") {
        Return ""
    }

    Set tEntries = pBundle.%Get("entry")

    If '$IsObject(tEntries) {
        Return ""
    }

    For i=0:1:tEntries.%Size()-1 {
        Set tEntry = tEntries.%Get(i)

        If '$IsObject(tEntry) {
            Continue
        }

        If '..HasProperty(tEntry,"resource") {
            Continue
        }

        Set tResource = tEntry.%Get("resource")

        If '$IsObject(tResource) {
            Continue
        }

        If ..GetValue(tResource,"resourceType") = pResourceType {
            Return tResource
        }

        If ..GetValue(tResource,"resourceType") = "Bundle" {
            Set tFound = ..FindFirstResource(tResource,pResourceType)
            If $IsObject(tFound) {
                Return tFound
            }
        }
    }

    Return ""
}

ClassMethod GetExtensionIdentifierValue(pResource As %DynamicObject, pUrl As %String) As %String
{
    If '$IsObject(pResource) {
        Return ""
    }

    If '..HasProperty(pResource,"extension") {
        Return ""
    }

    Set tExtensions = pResource.%Get("extension")

    If '$IsObject(tExtensions) {
        Return ""
    }

    For i=0:1:tExtensions.%Size()-1 {
        Set tExt = tExtensions.%Get(i)

        If '$IsObject(tExt) {
            Continue
        }

        If ..GetValue(tExt,"url") = pUrl {
            Return ..GetValue(tExt,"valueIdentifier.value")
        }
    }

    Return ""
}

ClassMethod GetExtensionCodeableConceptText(pResource As %DynamicObject, pUrl As %String) As %String
{
    If '$IsObject(pResource) {
        Return ""
    }

    If '..HasProperty(pResource,"extension") {
        Return ""
    }

    Set tExtensions = pResource.%Get("extension")

    If '$IsObject(tExtensions) {
        Return ""
    }

    For i=0:1:tExtensions.%Size()-1 {
        Set tExt = tExtensions.%Get(i)

        If '$IsObject(tExt) {
            Continue
        }

        If ..GetValue(tExt,"url") = pUrl {
            Set tText = ..GetValue(tExt,"valueCodeableConcept.text")
            If tText'="" {
                Return tText
            }
            Return ..GetValue(tExt,"valueCodeableConcept.coding.0.display")
        }
    }

    Return ""
}

ClassMethod GetValue(pObject As %DynamicAbstractObject, pPath As %String) As %String
{
    If '$IsObject(pObject) {
        Return ""
    }

    Try {
        Set tCurrent = pObject
        Set tParts = $Length(pPath,".")

        For i=1:1:tParts {
            Set tPart = $Piece(pPath,".",i)

            If '$IsObject(tCurrent) {
                Return ""
            }

            If tPart?1.N {
                If tPart >= tCurrent.%Size() {
                    Return ""
                }
                Set tCurrent = tCurrent.%Get(tPart)
            } Else {
                If '..HasProperty(tCurrent,tPart) {
                    Return ""
                }
                Set tCurrent = tCurrent.%Get(tPart)
            }
        }

        If $IsObject(tCurrent) {
            Return tCurrent.%ToJSON()
        }

        Return tCurrent
    }
    Catch ex {
        Return ""
    }
}

ClassMethod HasProperty(pObject As %DynamicAbstractObject, pProperty As %String) As %Boolean
{
    If '$IsObject(pObject) {
        Return 0
    }

    Try {
        Return pObject.%IsDefined(pProperty)
    }
    Catch ex {
        Return 0
    }
}

ClassMethod ToSQLDate(pValue As %String) As %String
{
    If pValue="" {
        Return ""
    }

    Try {
        Return $ZDATEH($Extract(pValue,1,10),3)
    }
    Catch ex {
        Return ""
    }
}

ClassMethod ToSQLTimestamp(pValue As %String) As %String
{
    If pValue="" {
        Return ""
    }

    If pValue["T" {
        Return $Translate($Extract(pValue,1,19),"T"," ")
    }

    Return pValue
}

}
