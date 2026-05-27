Class FHIRBundleToFHIRRepo.BO.FHIRTransactionOperation Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Property Server As %String;

Property Port As %Integer [ InitialExpression = 443 ];

Property Https As %Boolean [ InitialExpression = 1 ];

Property SSLConfiguration As %String;

Property Credentials As %String;

Property BasePath As %String;

Parameter SETTINGS = "Server,Port,Https,SSLConfiguration,Credentials,BasePath";

Method OnMessage(pRequest As FHIRBundleToFHIRRepo.Msg.FHIRTransactionRequest, Output pResponse As FHIRBundleToFHIRRepo.Msg.FHIRTransactionResponse) As %Status
{
    Set pResponse = ##class(FHIRBundleToFHIRRepo.Msg.FHIRTransactionResponse).%New()

    Try {
        Set req = ##class(%Net.HttpRequest).%New()
        Set req.Server = ..Server
        Set req.Port = ..Port
        Set req.Https = ..Https

        If ..SSLConfiguration'="" {
            Set req.SSLConfiguration = ..SSLConfiguration
        }

        Set sc = ..ApplyCredentials(.req)
        If $$$ISERR(sc) {
            Return sc
        }

        Do req.SetHeader("Accept","application/fhir+json")
        Set req.ContentType = "application/fhir+json; charset=UTF-8"

        Do pRequest.Json.Rewind()

        While 'pRequest.Json.AtEnd {
            Do req.EntityBody.Write(
                pRequest.Json.Read(32000)
            )
        }

        Set sc = req.Post(..BasePath)
        If $$$ISERR(sc) {
            Return sc
        }

        Set body = ..ReadResponseBody(req.HttpResponse)

        Set pResponse.StatusCode = req.HttpResponse.StatusCode
        Set pResponse.RawResponse = body

        If req.HttpResponse.StatusCode<200 || req.HttpResponse.StatusCode>299 {
            Set err = "FHIR transaction failed. HTTP="_req.HttpResponse.StatusCode
            Set err = err_" Reason="_req.HttpResponse.ReasonPhrase
            Set err = err_" Body="_$Extract(body,1,500)
            Return $$$ERROR($$$GeneralError,err)
        }

        Return $$$OK

    } Catch ex {
        Return ex.AsStatus()
    }
}

ClassMethod ReadResponseBody(pHttpResponse As %Net.HttpResponse) As %String
{
    Set tBody = ""

    If '$IsObject(pHttpResponse) {
        Return tBody
    }

    If '$IsObject(pHttpResponse.Data) {
        Return tBody
    }

    Do pHttpResponse.Data.Rewind()

    While 'pHttpResponse.Data.AtEnd {
        Set tBody = tBody _ pHttpResponse.Data.Read(32000)
    }

    Return tBody
}

Method ApplyCredentials(Output pHttpRequest As %Net.HttpRequest) As %Status
{
    If ..Credentials="" {
        Return $$$OK
    }

    Set sc = ##class(Ens.Config.Credentials).GetCredentialsObj(
        .credObj,
        ..%ClassName(1),
        "Ens.Config.Credentials",
        ..Credentials
    )

    If $$$ISERR(sc) {
        Return sc
    }

    Set pHttpRequest.Username = credObj.Username
    Set pHttpRequest.Password = credObj.Password

    Return $$$OK
}

}
