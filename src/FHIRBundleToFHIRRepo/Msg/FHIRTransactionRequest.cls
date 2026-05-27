Class FHIRBundleToFHIRRepo.Msg.FHIRTransactionRequest Extends Ens.Request
{

Property Json As %Stream.GlobalCharacter;

Storage Default
{
<Data name="FHIRTransactionRequestDefaultData">
<Subscript>"FHIRTransactionRequest"</Subscript>
<Value name="1">
<Value>Json</Value>
</Value>
</Data>
<DefaultData>FHIRTransactionRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
