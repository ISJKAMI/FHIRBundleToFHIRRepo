Class FHIRBundleToFHIRRepo.Msg.FHIRSearchResponse Extends Ens.Response
{

Property Found As %Boolean;

Property Reference As %String(MAXLEN = 500);

Property RawResponse As %Stream.GlobalCharacter;

Storage Default
{
<Data name="FHIRSearchResponseDefaultData">
<Subscript>"FHIRSearchResponse"</Subscript>
<Value name="1">
<Value>Found</Value>
</Value>
<Value name="2">
<Value>Reference</Value>
</Value>
<Value name="3">
<Value>RawResponse</Value>
</Value>
</Data>
<DefaultData>FHIRSearchResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
