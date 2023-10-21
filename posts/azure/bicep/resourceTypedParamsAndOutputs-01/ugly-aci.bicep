param acrName string
param acrRg string

// alternative approach
// /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/xxxx-rg/providers/Microsoft.ContainerRegistry/registries/xxx-acr
// segments[2] corresponds to the subscription ID.
// segments[4] corresponds to the resource group name.
// segments[8] corresponds to the resource name.
param acrId string

// approach 1
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
  // if acr is in different subscription then also subscription information is needed. Example:
  //scope: resourceGroup('subId', acrRg)
  scope: resourceGroup(acrRg)
}

// approach 2
resource alternative_acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: split(acrId, '/')[4]
  scope: resourceGroup(split(acrId, '/')[8])
}

resource aci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: 'aci'
  properties: {
    containers: []
    osType: 'Windows'
    imageRegistryCredentials: [
      {
        server: acr.properties.loginServer
        username: acr.listCredentials().username
        password: acr.listCredentials().passwords[0].value
      }
    ]
  }
}
