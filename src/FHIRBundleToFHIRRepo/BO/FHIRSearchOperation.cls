Class FHIRBundleToFHIRRepo.BO.FHIRSearchOperation Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Property Server As %String;

Property Port As %Integer [ InitialExpression = 443 ];

Property Https As %Boolean [ InitialExpression = 1 ];

Property SSLConfiguration As %String;

Property Credentials As %String;

Property BasePath As %String;

Parameter SETTINGS = "Server,Port,Https,SSLConfiguration,Credentials,BasePath";

Method OnMessage(pRequest As FHIRBundleToFHIRRepo.Msg.FHIRSearchRequest, Output pResponse As FHIRBundleToFHIRRepo.Msg.FHIRSearchResponse) As %Status
{
    Set pResponse = ##class(FHIRBundleToFHIRRepo.Msg.FHIRSearchResponse).%New()

    Try {

        If pRequest.ResourceType="" {
            Return $$$ERROR($$$GeneralError,"ResourceType is required")
        }

        If pRequest.IdentifierValue="" {
            Return $$$ERROR($$$GeneralError,"IdentifierValue is required")
        }

        Set q = pRequest.ResourceType _ "?identifier="

        If pRequest.IdentifierSystem'="" {
            Set q = q _ pRequest.IdentifierSystem _ "|" _ pRequest.IdentifierValue
        } Else {
            Set q = q _ pRequest.IdentifierValue
        }

        Set path = ..BasePath _ "/" _ q

        Set req = ##class(%Net.HttpRequest).%New()

        Set req.Server = ..Server
        Set req.Port = ..Port
        Set req.Https = ..Https

        If ..SSLConfiguration'="" {
            Set req.SSLConfiguration = ..SSLConfiguration
        }

        // Credentials取得
        If ..Credentials'="" {

            Set sc = ##class(Ens.Config.Credentials).GetCredentialsObj(
                .credObj,
                ..%ClassName(1),
                "Ens.Config.Credentials",
                ..Credentials
            )

            If $$$ISERR(sc) {
                Return sc
            }

            Set req.Username = credObj.Username
            Set req.Password = credObj.Password
        }

        Do req.SetHeader("Accept","application/fhir+json")
        Set req.ContentType = "application/fhir+json"

        Set sc = req.Get(path)

        If $$$ISERR(sc) {
            Return sc
        }

        Set status = req.HttpResponse.StatusCode

        Set body = ""
        If $IsObject(req.HttpResponse.Data) {
            Set body = req.HttpResponse.Data.Read()
        }

        Set pResponse.RawResponse = ##class(%Stream.GlobalCharacter).%New()
        Do pResponse.RawResponse.Write(body)
        Set pResponse.Found = 0
        Set pResponse.Reference = ""

        If status'=200 {

            Set err = "FHIR search failed. HTTP="_status
            Set err = err_" Reason="_req.HttpResponse.ReasonPhrase
            Set err = err_" Body="_$Extract(body,1,500)

            Return $$$ERROR($$$GeneralError,err)
        }

        If body="" {
            Return $$$ERROR($$$GeneralError,"FHIR search returned empty body")
        }

        If ($Extract(body,1,1)'="{") && ($Extract(body,1,1)'="[") {

            Set err = "FHIR search returned non-JSON. Body="_$Extract(body,1,500)

            Return $$$ERROR($$$GeneralError,err)
        }

        Set result = ##class(%DynamicObject).%FromJSON(body)

        If result.%Get("resourceType")="Bundle" {

            Set entries = result.%Get("entry")

            If $IsObject(entries), entries.%Size()>0 {

                Set first = entries.%Get(0).%Get("resource")

                Set id = first.%Get("id")

                If id'="" {

                    Set pResponse.Found = 1
                    Set pResponse.Reference = pRequest.ResourceType _ "/" _ id
                }
            }
        }

        Return $$$OK

    } Catch ex {

        Set pResponse.RawResponse = ex.DisplayString()

        Return ex.AsStatus()
    }
}

}
