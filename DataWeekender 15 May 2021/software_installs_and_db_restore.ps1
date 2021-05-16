# Mounting Azure File Store for low-cost storage
$connectTestResult = Test-NetConnection -ComputerName YOUR_FILESTORE_NAME.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"YOUR_FILESTORE_NAME.file.core.windows.net`" /user:`"YOUR_USERNAME`" /pass:`"YOUR_PASSWORD`""
    # Mount the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\YOUR_FILESTORE_NAME.file.core.windows.net\YOUR_FOLDER_PATH" -Persist
}
else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

# Enabling execution of PowerShell scripts:
set-executionpolicy remotesigned -Force

# Install Chocolatey:
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Chocolatey GUI and other software:
choco install chocolateygui microsoft-edge tabular-editor daxstudio azure-data-studio git dbatools vscode -y

# Rebooting Computer to complete installs if necessary, depending on your installs/configurations.  
# You can wait until Bastion connects you again
Restart-Computer


# Restore Parameters
$SQLBackupSource = "Z:\YOUR_BACKUP_PATH\*.bak"
# Restore databases
Copy-Item $SQLBackupSource -Destination "C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup" -Force -Verbose # this path should be fine for most users if you're using SQL Server 2019
Restore-DbaDatabase -SqlInstance localhost -Path "C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\" # this path should be fine for most users if you're using SQL Server 2019

# For stopping this VM: 
# Stop-AzVM -Name $VMName -ResourceGroupName $ResourceGroupName

# # For removing (deleting) this VM: 
# Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName

# For removing (deleting) resource group (and all its objects, including this VM):
# $ResourceGroupName = 'conflab'
# Remove-AzResourceGroup -Name $ResourceGroupName -Force


