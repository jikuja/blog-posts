resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'acr'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Never do this on production code
output adminAccount string = acr.listCredentials().username
output adminPassword string = acr.listCredentials().passwords[0].value
output loginServer string = acr.properties.loginServer
