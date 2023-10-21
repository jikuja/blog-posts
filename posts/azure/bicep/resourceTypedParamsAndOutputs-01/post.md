---
title: 'Bicep module resource passing; The Good, the Bad and the Ugly'
description: How to pass Azure resources and sentive data to/from Bicep modules
tags: 'Azure,Bicep'
cover_image: ''
canonical_url: null
published: false
id: 1560674
---

{%- # TOC start (generated with https://github.com/derlin/bitdowntoc) -%}

- [Azure resource properties, keys and secrets](#azure-resource-properties-keys-and-secrets)
- [Passing resource properties and sensitivr data in single-module template](#passing-resource-properties-and-sensitivr-data-in-singlemodule-template)
- [Bicep module system](#bicep-module-system)
- [The Bad: pass sensitive data to/from modules](#the-bad-pass-sensitive-data-tofrom-modules)
- [The Ugly: pass resource names or id and use existing keyword](#the-ugly-pass-resource-names-or-id-and-use-existing-keyword)
- [The Good: resource-typed module input and output](#the-good-resourcetyped-module-input-and-output)
- [Links](#links)

{%- # TOC end -%}
 
# Azure resource properties, keys and secrets

Azure resources typically have set of [properties](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/resource-declaration?tabs=azure-powershell#resource-specific-properties) that define resource definition. 

```bicep
// acr-01.bicep

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

output loginServer string = containerRegistry.properties.loginServer

```

Some resources also have keys and secrets that are usually read-only. Those values are read with `list*()` [accessor](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-resource#list) method.

```bicep
// acr-02.bicep

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

```

# Passing resource properties and sensitivr data in single-module template

```bicep
// acr-and_aci-01.bicep

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

```

Sensitive data does not leak from deployment because deployment is done in the single scope.

# Bicep module system

Bicep supports [modules](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules) but some really important features are still on preview

<!-- textlint-disable -->
Tähän esimerkkikuva, jossa
* pää-moduuli
  * ACR
  * ACI
<!-- textlint-enable -->

To automate container deployment from ACR to ACI we need to pass ACR credentials to ACI deployment

Spoiler: Windows ACI does not support MSI

# The Bad: pass sensitive data to/from modules

Disclaimer: never do this. Not suitable for production code

```bicep
// bad-main.bicep

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

```

```bicep
// bad-aci.bicep

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

```

```bicep
// bad-acr.bicep

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

```

# The Ugly: pass resource names or id and use existing keyword

```bicep
// ugly-main.bicep

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

```

```bicep
// ugly-acr.bicep

param acrName string

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Needed for approach 2
output acrId string = acr.id

```

```bicep
// ugly-aci.bicep

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

```

# The Good: resource-typed module input and output

The most simple Bicep code can be written by passing resources to and from modules.



<<<<<<< HEAD
https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-resource#list
=======
```bicep
// good-main.bicep

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

```

```bicep
// good-acr.bicep

param acrName string

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

output acr resource = acr

```

```bicep
// good-aci.bicep

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

```

# Links

* Bicep [experimental feature flags](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-config#enable-experimental-features)
* Resource referencing simplification [ticket 1](https://github.com/azure/bicep/issues/2245)
* Resource referencing simplification [ticket 2](https://github.com/Azure/bicep/issues/2246)
* Resource-typed module input/output implemention [PR](https://github.com/Azure/bicep/pull/4971)
* [Best mechanism for converting a resource ID into name/resourceGroup/subscription?](https://github.com/Azure/bicep/issues/10872)
  * [The answer](https://github.com/Azure/bicep/issues/1722#issuecomment-952118402)
>>>>>>> cd65381 (Added published version)
