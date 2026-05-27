Class FHIRBundleToFHIRRepo.Msg.FHIRSearchRequest Extends Ens.Request
{

Property ResourceType As %String(MAXLEN = 100);

Property IdentifierSystem As %String(MAXLEN = 500);

Property IdentifierValue As %String(MAXLEN = 500);

Storage Default
{
<Data name="FHIRSearchRequestDefaultData">
<Subscript>"FHIRSearchRequest"</Subscript>
<Value name="1">
<Value>ResourceType</Value>
</Value>
<Value name="2">
<Value>IdentifierSystem</Value>
</Value>
<Value name="3">
<Value>IdentifierValue</Value>
</Value>
</Data>
<DefaultData>FHIRSearchRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
