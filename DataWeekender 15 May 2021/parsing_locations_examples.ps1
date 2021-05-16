# Look for countries
Get-AzLocation | Where-Object { $_.DisplayName -like '*german*' } | format-list # Format-Table -Wrap

# Get output of all services within location
Get-AzLocation | Where-Object { $_.DisplayName -like '*switz*' } | Select-Object -ExpandProperty Providers

# look for speficic sizes of CPU and RAM
Get-AzVMSize -Location "switzerlandnorth" | Where-Object { $_.NumberOfCores -ge 16 -and $_.NumberOfCores -le 32 -and $_.MemoryInMB -gt 64000 -and $_.MemoryInMB -lt 120000 }

## Get offers for SQL Server licence
Get-AzVMImageOffer -Location switzerlandnorth -Publisher 'MicrosoftSQLServer' | Where-Object { $_.Offer -like '*2019*' }
Get-AzVMImageSku -Location 'germanywestcentral' -PublisherName 'MicrosoftSQLServer' -Offer 'sql2019-ws2019'