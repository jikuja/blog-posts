param acrName string = 'test-acr'

module acr 'good-acr.bicep' = {
  name: 'acrModuleDeployment'
  params: {
    acrName: acrName
  }
}

module aci 'good-aci.bicep' = {
  name: 'aciModuleDeployment'
  params: {
    acr: acr.outputs.acr
  }
}
