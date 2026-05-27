Class FHIRBundleToFHIRRepo.DemoProduction Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="FHIRBundleToFHIRRepo.DemoProduction" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="FHIRBundleToFHIRRepo.FileIn" Category="" ClassName="EnsLib.File.PassthroughService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetConfigNames">FHIRBundleToFHIRRepo.DocumentImportProcess</Setting>
    <Setting Target="Adapter" Name="ArchivePath">/tmp/fhirdemo/archive</Setting>
    <Setting Target="Adapter" Name="FilePath">/tmp/fhirdemo/in</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.json</Setting>
    <Setting Target="Adapter" Name="WorkPath">/tmp/fhirdemo/work</Setting>
    <Setting Target="Adapter" Name="Charset">utf-8</Setting>
  </Item>
  <Item Name="FHIRBundleToFHIRRepo.DocumentImportProcess" Category="" ClassName="FHIRBundleToFHIRRepo.BP.DocumentImportProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="SearchOperationName">FHIRBundleToFHIRRepo.FHIRSearchOperation</Setting>
    <Setting Target="Host" Name="TransactionOperationName">FHIRBundleToFHIRRepo.FHIRTransactionOperation</Setting>
    <Setting Target="Host" Name="InsertOperationName">FHIRBundleToFHIRRepo.BO.InsertConditionToRDBOperation</Setting>
  </Item>
  <Item Name="FHIRBundleToFHIRRepo.FHIRSearchOperation" Category="" ClassName="FHIRBundleToFHIRRepo.BO.FHIRSearchOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="Server">fhir.example.com</Setting>
    <Setting Target="Host" Name="Port">443</Setting>
    <Setting Target="Host" Name="Https">1</Setting>
    <Setting Target="Host" Name="SSLConfiguration">DemoFHIRSSL</Setting>
    <Setting Target="Host" Name="Credentials">DemoFHIRUser</Setting>
    <Setting Target="Host" Name="BasePath">/csp/healthshare/fhirserver/fhir/r4</Setting>
  </Item>
  <Item Name="FHIRBundleToFHIRRepo.FHIRTransactionOperation" Category="" ClassName="FHIRBundleToFHIRRepo.BO.FHIRTransactionOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="Server">fhir.example.com</Setting>
    <Setting Target="Host" Name="Port">443</Setting>
    <Setting Target="Host" Name="Https">1</Setting>
    <Setting Target="Host" Name="SSLConfiguration">DemoFHIRSSL</Setting>
    <Setting Target="Host" Name="Credentials">DemoFHIRUser</Setting>
    <Setting Target="Host" Name="BasePath">/csp/healthshare/fhirserver/fhir/r4</Setting>
  </Item>
  <Item Name="FHIRBundleToFHIRRepo.BO.InsertConditionToRDBOperation" Category="" ClassName="FHIRBundleToFHIRRepo.BO.InsertConditionToRDBOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
