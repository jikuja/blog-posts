param acr resource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview'

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
