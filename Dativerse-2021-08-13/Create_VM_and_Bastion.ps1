# Variables
## Global Settings
$Location = "switzerlandnorth"
$ResourceGroupName = "conflab"

## Settings for Storage
$StorageName = $ResourceGroupName + "storage"
$StorageSku = "Standard_LRS"

## Settings for Network
$InterfaceName = $ResourceGroupName + "ServerInterface"
$NsgName = $ResourceGroupName + "nsg"
$VNetName = $ResourceGroupName + "VNet"
$SubnetName = "Default"
$VNetAddressPrefix = "10.0.0.0/16"
$VNetSubnetAddressPrefix = "10.0.0.0/24"
$TCPIPAllocationMethod = "Dynamic"
$DomainName = $ResourceGroupName

## Settings for Bastion
$publicIpName = "pip" + $ResourceGroupName
$BastionName = "Bastion" + $ResourceGroupName
$BastionSubnetName = "AzureBastionSubnet"
# -AddressPrefix 10.0.1.0/27

## Settings for hardware
$VMName = $ResourceGroupName + "VM"
$ComputerName = $ResourceGroupName + "Server"
$VMSize = "Standard_D4s_v3"
$OSDiskName = $VMName + "OSDisk"

## Settings for SQL Server licence
$PublisherName = "MicrosoftSQLServer"
$OfferName = "sql2019-ws2019"
$Sku = "SQLDEV"
$Version = "latest"

# Set credentials for logging into VM
$Credential = Get-Credential -Message "Type the name and password of the local administrator account." # this will ask for the credentials if you don't want to use the powershell vault. 
# solution for PS Vault https://www.thomasmaurer.ch/2021/04/stop-typing-powershell-credentials-in-demos-using-powershell-secretmanagement/
# $CredentialSecret = Get-Secret -Vault SecretStore -Name DemoAdmin01
# $Credential = New-Object -TypeName pscredential -ArgumentList "DemoAdmin01", $CredentialSecret 

# Creation of Objects
## Resource Group
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

## Storage
$StorageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -SkuName $StorageSku -Kind "Storage" -Location $Location

## Network
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
$VNet = New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
$PublicIp = New-AzPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod $TCPIPAllocationMethod -DomainNameLabel $DomainName
$NsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name "RDPRule" -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
$NsgRuleSQL = New-AzNetworkSecurityRuleConfig -Name "MSSQLRule"  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 1433 -Access Allow
$Nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $Location -Name $NsgName -SecurityRules $NsgRuleRDP, $NsgRuleSQL
$Interface = New-AzNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PublicIp.Id -NetworkSecurityGroupId $Nsg.Id

## Compute
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate #-TimeZone = $TimeZone
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -Caching ReadOnly -CreateOption FromImage

## Image
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $PublisherName -Offer $OfferName -Skus $Sku -Version $Version

## Create the VM in Azure
New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine

## Add the SQL IaaS Extension with chosen license type
New-AzSqlVM -ResourceGroupName $ResourceGroupName -Name $VMName -Location $Location -LicenseType PAYG

## Create Azure Bastion Host
Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $BastionSubnetName -AddressPrefix 10.0.1.0/27
$VNet | Set-AzVirtualNetwork
$publicip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -name $publicIpName -location $Location -AllocationMethod Static -Sku Standard
New-AzBastion -ResourceGroupName $ResourceGroupName -Name $BastionName -PublicIpAddress $publicip -VirtualNetworkId $VNet.id
