Class FHIRBundleToFHIRRepo.BP.DocumentImportProcess Extends Ens.BusinessProcess
{

Parameter INVOCATION = "Queue";

Property SearchOperationName As %String(MAXLEN = 200);

Property TransactionOperationName As %String(MAXLEN = 200);

Property InsertOperationName As %String(MAXLEN = 200);

Parameter SETTINGS = "SearchOperationName,TransactionOperationName,InsertOperationName";

Method OnRequest(pRequest As Ens.Request, Output pResponse As FHIRBundleToFHIRRepo.Msg.FHIRTransactionResponse) As %Status
{
    Try {
        Set json = ..GetRequestBody(pRequest)
        Set doc = ##class(%DynamicObject).%FromJSON(json)

        If doc.%Get("resourceType")'="Bundle" {
            Return $$$ERROR($$$GeneralError,"resourceType must be Bundle")
        }

        Set type = doc.%Get("type")

        If (type'="document") && (type'="collection") {
            Return $$$ERROR($$$GeneralError,"Bundle.type must be document or collection")
        }
        /*
        If doc.%Get("type")'="document" {
            Return $$$ERROR($$$GeneralError,"Bundle.type must be document")
        }
        */

        /* ここでテーブルINSERT用BOへ送信 */
        Set insertReq = ##class(Ens.StringContainer).%New()
        Set insertReq.StringValue = json

        Set sc = ..SendRequestSync(..InsertOperationName, insertReq, .insertResp)
        If $$$ISERR(sc) {
            Return sc
        }



        Set entries = doc.%Get("entry")
        If '$IsObject(entries) {
            Return $$$ERROR($$$GeneralError,"Bundle.entry is required")
        }

        Set refMap = ##class(%DynamicObject).%New()

        Set sc = ..InitializeFullUrlMap(entries,refMap)
        If $$$ISERR(sc) { Return sc }

        Set sc = ..ResolveMasterResources(entries,refMap)
        If $$$ISERR(sc) { Return sc }

        Set sc = ..BuildAndSendTransaction(entries,refMap,.pResponse)
        If $$$ISERR(sc) { Return sc }

        Return $$$OK

    } Catch ex {
        Return ex.AsStatus()
    }
}

Method GetRequestBody(pRequest As Ens.Request) As %String
{
    If pRequest.%IsA("Ens.StreamContainer") {

        Do pRequest.Stream.Rewind()

        Set json = ""

        While 'pRequest.Stream.AtEnd {
            Set json = json _ pRequest.Stream.Read(32000)
        }

        Return json
    }

    If pRequest.%IsA("Ens.StringContainer") {
        Return pRequest.StringValue
    }

    Return ""
}

Method InitializeFullUrlMap(entries As %DynamicArray, refMap As %DynamicObject) As %Status
{
    Try {
        For i=0:1:entries.%Size()-1 {
            Set entry = entries.%Get(i)
            Set res = entry.%Get("resource")

            If '$IsObject(res) {
                Continue
            }

            Set fullUrl = entry.%Get("fullUrl")

            If fullUrl="" {
                Set fullUrl = "urn:uuid:" _ ..NewUUID()
                Do entry.%Set("fullUrl",fullUrl)
            }

            Do refMap.%Set(fullUrl,fullUrl)

            Set rt = res.%Get("resourceType")
            Set id = res.%Get("id")

            If rt'="", id'="" {
                Do refMap.%Set(rt_"/"_id,fullUrl)
            }
        }

        Return $$$OK

    } Catch ex {
        Return ex.AsStatus()
    }
}

Method ResolveMasterResources(entries As %DynamicArray, refMap As %DynamicObject) As %Status
{
    Try {
        For i=0:1:entries.%Size()-1 {
            Set entry = entries.%Get(i)
            Set res = entry.%Get("resource")

            If '$IsObject(res) {
                Continue
            }

            Set rt = res.%Get("resourceType")

            If '..IsMaster(rt) {
                Continue
            }

            Set fullUrl = entry.%Get("fullUrl")
            If fullUrl="" {
                Continue
            }

            Set ident = ..GetFirstIdentifier(res)

            If ident.%Get("value")="" {
                Continue
            }

            Set req = ##class(FHIRBundleToFHIRRepo.Msg.FHIRSearchRequest).%New()
            Set req.ResourceType = rt
            Set req.IdentifierSystem = ident.%Get("system")
            Set req.IdentifierValue = ident.%Get("value")

            Set sc = ..SendRequestSync(..SearchOperationName,req,.searchResp)
            If $$$ISERR(sc) {
                Return sc
            }

            If searchResp.Found {
                Do refMap.%Set(fullUrl,searchResp.Reference)

                Set id = res.%Get("id")
                If id'="" {
                    Do refMap.%Set(rt_"/"_id,searchResp.Reference)
                }
            }
        }

        Return $$$OK

    } Catch ex {
        Return ex.AsStatus()
    }
}

Method BuildAndSendTransaction(entries As %DynamicArray, refMap As %DynamicObject, Output pResponse As FHIRBundleToFHIRRepo.Msg.FHIRTransactionResponse) As %Status
{
    Try {
        Set tx = ##class(%DynamicObject).%New()
        Do tx.%Set("resourceType","Bundle")
        Do tx.%Set("type","transaction")

        Set txEntries = ##class(%DynamicArray).%New()

        For i=0:1:entries.%Size()-1 {
            Set entry = entries.%Get(i)
            Set res = entry.%Get("resource")

            If '$IsObject(res) {
                Continue
            }

            Set rt = res.%Get("resourceType")
            Set fullUrl = entry.%Get("fullUrl")
            Set resolvedRef = refMap.%Get(fullUrl)

            If fullUrl="" {
                Continue
            }

            If resolvedRef="" {
                Set resolvedRef = fullUrl
            }

            // 既存 Patient / Organization / Practitioner は登録しない
            If ..IsMaster(rt), (resolvedRef [ "/") {
                Continue
            }

            // POST登録なのでトップレベル id は削除
            // contained resource の id は削除しない
            If res.%Get("id")'="" {
                Do res.%Remove("id")
            }

            Set sc = ..RewriteReferences(res,refMap)
            If $$$ISERR(sc) {
                Return sc
            }

            Set txEntry = ##class(%DynamicObject).%New()
            Do txEntry.%Set("fullUrl",fullUrl)
            Do txEntry.%Set("resource",res)

            Set req = ##class(%DynamicObject).%New()
            Do req.%Set("method","POST")
            Do req.%Set("url",rt)

            Do txEntry.%Set("request",req)
            Do txEntries.%Push(txEntry)
        }

        Do tx.%Set("entry",txEntries)

        Set txReq = ##class(FHIRBundleToFHIRRepo.Msg.FHIRTransactionRequest).%New()
        Set txReq.Json = ##class(%Stream.GlobalCharacter).%New()
        Do txReq.Json.Write(tx.%ToJSON())

        Set sc = ..SendRequestSync(..TransactionOperationName,txReq,.txResp)
        If $$$ISERR(sc) {
            Return sc
        }

        Set pResponse = txResp
        Return $$$OK

    } Catch ex {
        Return ex.AsStatus()
    }
}

Method RewriteReferences(obj As %DynamicObject, refMap As %DynamicObject) As %Status
{
    Try {
        Set it = obj.%GetIterator()

        While it.%GetNext(.key,.value) {
            If key="reference" {
                If $Extract(value,1)="#" {
                    Continue
                }

                Set newRef = refMap.%Get(value)
                If newRef'="" {
                    Do obj.%Set(key,newRef)
                }

                Continue
            }

            If $IsObject(value) {
                If value.%ClassName()="%DynamicObject" {
                    Set sc = ..RewriteReferences(value,refMap)
                    If $$$ISERR(sc) { Return sc }
                } ElseIf value.%ClassName()="%DynamicArray" {
                    Set sc = ..RewriteReferenceArray(value,refMap)
                    If $$$ISERR(sc) { Return sc }
                }
            }
        }

        Return $$$OK

    } Catch ex {
        Return ex.AsStatus()
    }
}

Method RewriteReferenceArray(arr As %DynamicArray, refMap As %DynamicObject) As %Status
{
    Try {
        For i=0:1:arr.%Size()-1 {
            Set value = arr.%Get(i)

            If $IsObject(value) {
                If value.%ClassName()="%DynamicObject" {
                    Set sc = ..RewriteReferences(value,refMap)
                    If $$$ISERR(sc) { Return sc }
                } ElseIf value.%ClassName()="%DynamicArray" {
                    Set sc = ..RewriteReferenceArray(value,refMap)
                    If $$$ISERR(sc) { Return sc }
                }
            }
        }

        Return $$$OK

    } Catch ex {
        Return ex.AsStatus()
    }
}

Method GetFirstIdentifier(res As %DynamicObject) As %DynamicObject
{
    Set empty = ##class(%DynamicObject).%New()

    Set ids = res.%Get("identifier")
    If '$IsObject(ids) {
        Return empty
    }

    If ids.%Size()=0 {
        Return empty
    }

    Return ids.%Get(0)
}

Method IsMaster(resourceType As %String) As %Boolean
{
    Return (resourceType="Patient") || (resourceType="Organization") || (resourceType="Practitioner")
}

Method NewUUID() As %String
{
    Set uuid = $System.Util.CreateGUID()
    Set uuid = $Translate(uuid,"{}","")
    Return $ZCONVERT(uuid,"L")
}

Storage Default
{
<Data name="DocumentImportProcessDefaultData">
<Subscript>"DocumentImportProcess"</Subscript>
<Value name="1">
<Value>SearchOperationName</Value>
</Value>
<Value name="2">
<Value>TransactionOperationName</Value>
</Value>
<Value name="3">
<Value>InsertOperationName</Value>
</Value>
</Data>
<DefaultData>DocumentImportProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
