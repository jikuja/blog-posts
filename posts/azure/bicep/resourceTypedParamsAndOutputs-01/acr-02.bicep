resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
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
output adminAccount string = containerRegistry.listCredentials().username
output adminPasswor string = containerRegistry.listCredentials().passwords[0].value
