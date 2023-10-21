param adminAccount string
param adminPassword string
param loginServer string

resource aci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: 'aci'
  properties: {
    containers: []
    osType: 'Windows'
    imageRegistryCredentials: [
      {
        server: loginServer
        username: adminAccount
        password: adminPassword
        }
    ]
  }
}
