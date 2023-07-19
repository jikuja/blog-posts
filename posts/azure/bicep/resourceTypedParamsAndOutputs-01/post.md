---
title: Bicep module resourcepassing
description: How to pass Azure resources to/from Bicep modules
tags: 'Azure,Bicep'
cover_image: ''
canonical_url: null
published: false
id: 1541937
---

ToC:

* Azure resource properties and keys/secrets
* Example Scope
  * ACI + ACR
* Single-module deployment
* Multi-module deployment
  * Pass all the values
    * Security issues
  * Pass scope information
  * Pass resource id(s)
  * Pass resource to/from
 

# Azure resource properties, keys and secrets

Azure resources typically have set of [properties](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/resource-declaration?tabs=azure-powershell#resource-specific-properties) 
that define resource definition. 

```bicep
// stor.bicep

param location string = resourceGroup().locationx

resource stg 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: 'examplestorage'
  location: location
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

output propertyExample string = stg.properties.minimumTlsVersion

```

Some resources also
have keys and secrets that are usually read-only.



https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-resource#list
