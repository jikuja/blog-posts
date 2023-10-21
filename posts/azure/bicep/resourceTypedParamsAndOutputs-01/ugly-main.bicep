param acrName string = 'test-acr'

module acr 'ugly-acr.bicep' = {
  name: 'acrModuleDeployment'
  params: {
    acrName: acrName
  }
}

module aci 'ugly-aci.bicep' = {
  name: 'aciModuleDeployment'
  params: {
    // approach 1
    acrName: acrName
    acrRg: resourceGroup().name

    // approach 2
    acrId: acr.outputs.acrId
  }
}
