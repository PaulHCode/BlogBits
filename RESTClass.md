<details>
<summary><h2>About the presentation</h2></summary>

- This presentation is about REST and how to use it with Azure
- It is not a deep dive, but an introduction
- Let me know if you want a deeper dive with more interactive practice, and I'll develop it
</details>

<details>
<summary><h2>What is REST</h2></summary>

- REST - REpresentational State Transfer
- Used to send queries and commmands to Azure
- Used in the background by PowerShell modules and Python libraries
- not a protocol or a standard, it is an architectural style
- Stateless - each request is independent and contains all information needed. It does not depend on previously submitted info.
</details>

<details>
<summary><h2>Why is it useful</h2></summary>

- Consistent performance, even if PS modules or Python libraries get updated and change schemas
- Supports capabilities not yet available in PS modules or Python libraries
- Works consistently across clouds
- Useful for understanding how the portal is working and to help in troubleshooting
</details>

<details>

<summary><h2>Structure of a REST call</h2></summary>

  - URI - Uniform Resource Identifier
    - https://{endpoint}/{provider}/{command}?api-version={version}&${parameterName}={parameterValue}
    - https://management.azure.com/providers/Microsoft.Authorization/roleDefinitions?api-version=2022-04-01
    - Other endpoints include: https://storage.azure.com, https://graph.microsoft.com, https://api.loganalytics.io, https://vault.azure.net
  - Method
    - GET, POST, PUT, PATCH, DELETE
  - Headers
    - Authorization, Content-Type, and others
  - Body
    - JSON

  Pay close attention to the documentation, it often has all the details you need.
  Finding the right api version through guessing.

  If you follow the documentation and get an error, the errors often provide useful information.

  Example documentation: https://learn.microsoft.com/en-us/rest/api/authorization/role-definitions/list?view=rest-authorization-2022-04-01&tabs=HTTP

</details>

<details>
<summary><h2>Testing with Insomnia / PostMan</h2></summary>

I'll cover insomnia today, but PostMan is also a good tool.
Let's just do one to see what it looks like.

- Getting a bearer token
  - Get-AzAccessToken
    - (Get-AzAccessToken -ResourceUrl https://management.azure.com).token
    - (Get-AzAccessToken -ResourceTypeName MSGraph -TenantId $tenantId).token

- Example0:
  ```
  $token = (Get-AzAccessToken -ResourceUrl https://management.azure.com).Token; $token | Set-Clipboard
  URI: https://management.azure.com/providers/Microsoft.Authorization/roleDefinitions?api-version=2022-04-01
  ```

- JSON Path queries
  - Filter the output of the previous command to only show role names
    - $.value[*].properties.roleName
  - Filter the output of the previous command to only show role names that start with "C"
    - $.value[?(@.properties.roleName && @.properties.roleName.match(/^C/))].properties.roleName

- Example1:
  ```
  $graphToken = (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.us').token; $graphToken | Set-Clipboard
  $uri = "https://graph.microsoft.us/v1.0/users"
  $uri = "https://graph.microsoft.us/v1.0/users?$select=displayName"
  $uri = "https://graph.microsoft.us/v1.0/users?$filter=startswith(displayName,'t')"
  https://graph.microsoft.us/v1.0/users?$filter=startswith(displayName,'t')&$select=displayName

  ```

- pagination
  - If you have a large number of results, you may need to paginate through them.
  - Use ?$top=2 as an example
  - Depending on the API are a few different ways to do it. I'll cover this in detail in the longer class if there is sufficient interest.
- expand, filter, select, orderby
- https://insomnia.rest
- https://www.postman.com/
</details>

<details>
<summary><h2>Investigating the portal</h2></summary>
- Using F12
- https://developer.microsoft.com/en-us/graph/graph-explorer
- Show parameters, headers, body

</details>

<details>
<summary><h2>Writing in PowerShell</h2></summary>

<details>
<summary><h3>Getting a token - additional info</h3></summary>
- If you don't want to have any dependencies on PowerShell cmdlets then an easy way to get REST endpoints is to just load variables at the beginning of your code

```
        Set-Variable -Name managementUrl -Value 'https://management.azure.com' -Option Constant
        Set-Variable -Name StorageTokenResourceUrl -Value 'https://storage.azure.com' -Option Constant
        Set-Variable -Name LoginUrl -Value "https://login.microsoftonline.com" -Option Constant
        Set-Variable -Name GraphResourceUrl -Value "https://graph.microsoft.com" -Option Constant
        Set-Variable -Name StorageResourceUrl -Value "https://storage.azure.com" -Option Constant
        Set-Variable -Name PrivGroupUrl -Value "https://api.azrbac.mspim.azure.com" -Option Constant
        Set-Variable -Name LogAnalyticsUrl -Value "https://api.loganalytics.io" -Option Constant
        Set-Variable -Name odsEndpoint -Value 'ods.opinsights.azure.com' -Option Constant
        Set-Variable -Name SecurityCenterUrl -Value 'https://api-gcc.securitycenter.microsoft.us' -Option Constant
        Set-Variable -Name KeyVaultUrl -Value 'https://vault.azure.net' -Option Constant
```
- If you have az.accounts loaded and have ran connect-azaccount, then you can get find endpoints with 

```
Get-AzEnvironment -Name AzureCloud | fl *
```
For example:
```
PS C:\Users\pauharri [155]> (Get-AzEnvironment -Name AzureCloud).ResourceManagerUrl
https://management.azure.com/
PS C:\Users\pauharri [127]>
```
</details>

  <details>
  <summary><h3>Cmdlets</h3></summary>

    - Invoke-RestMethod
      - Automatically converts response to PS objects from JSON/XML
    - Invoke-WebRequest
      - Also works, but I'd use for HTML, not REST
  - Example0:
    ```
    $token = (Get-AzAccessToken -ResourceUrl https://management.azure.com).Token
    $uri = "https://management.azure.com/providers/Microsoft.Authorization/roleDefinitions?api-version=2022-04-01"
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{Authorization = "Bearer $token"}
    $response.value | Select-Object -Property id, roleName, description
    ```
  </details>

  <details>
  <summary><h3>Wrapper Functions</h3></summary>
    
    - What is a wrapper function?
    - Why use them?
    - Examples.
  </details>
</details>

<details>
<summary><h2>Writing in Python</h2></summary>

  - This will be added later if there is interest.

</details>

<details>
<summary><h2>JSON Path Filters</h2></summary>

I used JSON Path Filters when looking at output for https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?\$expand=principal
$.value[*].principal[createdDateTime]

- $.value[*].properties
- $.value[*].properties.roleName
- $.value[?(@.properties.roleName && @.properties.roleName.match(/^C/))].properties.roleName

</details>

<details>
<summary><h2>Reference Documentation</h2></summary>

- Azure REST API 
  - https://learn.microsoft.com/en-us/rest/api/azure/
  - https://learn.microsoft.com/en-us/rest/api/authorization/versions
- Azure Graph 
  - https://learn.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0
  - https://learn.microsoft.com/en-us/graph/filter-query-parameter?tabs=http
- Azure Resource Graph 
  - https://learn.microsoft.com/en-us/rest/api/azure-resourcegraph/

</details>

<details>
<summary><h2>Code Help Teams Channels</h2></summary>

- [Code Help](https://teams.microsoft.com/l/team/19%3A0yq3TVVE2jjDWwLWkWyA_q7I3ZDu113bjNFUjI_xGd01%40thread.tacv2/conversations?groupId=8f600e81-404e-40b8-9d21-2e16caf93e7c&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47 "A new Team") - This is a new team for code help. I've been holding meetings to answer questions and help with PowerShell and REST for a while. If no one has questions I usually have a small lesson, now I'm opening up to a larger group.
  - [PowerShell](https://teams.microsoft.com/l/channel/19%3A0yq3TVVE2jjDWwLWkWyA_q7I3ZDu113bjNFUjI_xGd01%40thread.tacv2/PowerShell?groupId=8f600e81-404e-40b8-9d21-2e16caf93e7c&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47)
  - [REST](https://teams.microsoft.com/l/channel/19%3A586d41f52dac4e3c9404cb324cb9ff4e%40thread.tacv2/REST?groupId=8f600e81-404e-40b8-9d21-2e16caf93e7c&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47)
- [PowerShell Community](https://teams.microsoft.com/l/team/19%3A02fc780f787b4c43b1912befb930ffa8%40thread.skype/conversations?groupId=8fa0fae2-104d-42af-a85e-d8c0ed64b948&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47) - This is the PowerShell community team. It is a great place to ask questions and get help.
- [Python Community](https://teams.microsoft.com/l/team/19%3Ab1620cabfa8049329cee7ba42b06abe6%40thread.skype/conversations?groupId=68ae9c56-b648-45f2-b7d3-c65feb9b3d20&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47) - I don't know Pyton well, but the folks here do and are happy to help.

</details>