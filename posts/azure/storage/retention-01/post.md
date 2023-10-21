---
title: Azure storage with lease and retention policy
published: false
description: Real-life scenarion what happens when lease and renention policy are enabled on storage account
tags: 'azure, storage'
id: 1642100
---

Recently I added lease to some files that were in the container having retention
policy to delete files that are 30 days old.

Sources were telling that it

* will not work
* will work

## The first symptom

Later I noticed huge increase on **StorageBlobLogs** table
ingress on **Log Analytics Insights** workbook:

**Log Analytics insights** / **Ingestion Over Time (MB)**

![Log Analytics insights graph](insights-graph.png)

**Log Analytics insights** / **Ingestion Anomalies**

![Log Analytics insights ingestion anomalies](insights-ingestion-anomaly.png)

## Next steps

First I did not remember turning on lease for blobs and therefore I had to
investigate **StorageBlobLogs** table.

### The first query: `Who is making request?`

Query:

```kql
let ll = (s:string) {
  iff(s contains "AzureDataFactoryCopy", "AzureDataFactoryCopy", 
    iff(s contains "APN/1.0 Azure Blob FS", "APN/1.0 Azure Blob FS", 
      iff(s contains "Microsoft Azure Storage Explorer", "Microsoft Azure Storage Explorer", s)
    )
  )
};
StorageBlobLogs
| where TimeGenerated > ago(90d)
| summarize count=count() by UserAgentHeader=ll(UserAgentHeader), bin(TimeGenerated, 1d)
```

Result:

![Storage account requests by UserAgentHeader](requests-by-name.png)

### The second query: `What are the results of the queries?`

Query:

```kql
StorageBlobLogs
| where TimeGenerated > ago(90d)
| where UserAgentHeader == "xAzure/1.0 AzureStorage/1.0 ObjectLifeCycleScanner/0.50"
| summarize count=count() by StatusText, bin(TimeGenerated, 1d)
```

Result:

![Storage account requests by StatusText](requests-by-status.png)

### Bonus query: `What of lifecycle process trying to do?`

Query:

```kql
StorageBlobLogs
| where TimeGenerated > ago(90d) and UserAgentHeader == "xAzure/1.0 AzureStorage/1.0 ObjectLifeCycleScanner/0.50"
| summarize count=count() by OperationName, bin(TimeGenerated, 1d)
```

Result:

![Storage account requests by OperationName](requests-by-operation.png)

## Summary

Using leases with storage account that has life-cycle management enabled might cause issues.
If you ever enable leases on storage account that haas life-cycle management turned on you should
follow if the request done by ObjectLifeCycleScanner are succeeded or not to avoid increase
on log ingestion rates.
