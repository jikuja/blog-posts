module acr 'bad-acr.bicep' = {
  name: 'acrModuleDeployment'
}

module aci 'bad-aci.bicep' = {
  name: 'aciModuleDeployment'
  params: {
    adminAccount: acr.outputs.adminAccount
    adminPassword: acr.outputs.adminPassword
    loginServer:  acr.outputs.loginServer
  }
}
