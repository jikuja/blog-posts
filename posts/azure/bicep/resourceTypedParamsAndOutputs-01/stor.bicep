param location string = resourceGroup().location

resource stg 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: 'examplestorage'
  location: location
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

output propertyExample string = stg.properties.minimumTlsVersion
