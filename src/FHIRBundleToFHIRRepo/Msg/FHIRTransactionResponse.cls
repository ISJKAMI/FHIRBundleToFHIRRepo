Class FHIRBundleToFHIRRepo.Msg.FHIRTransactionResponse Extends Ens.Response
{

Property StatusCode As %String;

Property RawResponse As %String(MAXLEN = "");

Storage Default
{
<Data name="FHIRTransactionResponseDefaultData">
<Subscript>"FHIRTransactionResponse"</Subscript>
<Value name="1">
<Value>StatusCode</Value>
</Value>
<Value name="2">
<Value>RawResponse</Value>
</Value>
</Data>
<DefaultData>FHIRTransactionResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
