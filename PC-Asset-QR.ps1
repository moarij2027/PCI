$cs=Get-CimInstance Win32_ComputerSystem
$os=Get-CimInstance Win32_OperatingSystem
$cpu=Get-CimInstance Win32_Processor
$nic=Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"|Select-Object -First 1
$bat=Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
$ram=Get-CimInstance Win32_PhysicalMemory
$ramTotal=[math]::Round((($ram|Measure-Object Capacity -Sum).Sum)/1GB,0)
$ramType=switch([int]($ram|Select-Object -First 1).SMBIOSMemoryType){20{'DDR'};21{'DDR2'};22{'DDR2'};24{'DDR3'};26{'DDR4'};29{'DDR4'};30{'DDR4'};34{'DDR5'}default{'Unknown'}}
$ramSpeed=(($ram|Measure-Object ConfiguredClockSpeed -Maximum).Maximum)
$physical=Get-PhysicalDisk
$storageGB=[math]::Round((($physical|Measure-Object Size -Sum).Sum)/1GB,2)
$storageType=(($physical|ForEach-Object{
if($_.MediaType -eq 'SSD' -and $_.BusType -eq 'NVMe'){'NVMe SSD'}
elseif($_.MediaType -eq 'SSD' -and $_.BusType -eq 'SATA'){'SATA SSD'}
elseif($_.MediaType -eq 'SSD'){'SSD'}
elseif($_.MediaType -eq 'HDD'){'HDD'}
else{$_.MediaType}
})|Select-Object -Unique)-join ', '

$ip=(($nic.IPAddress|Where-Object{$_ -match '^\d+\.'}|Select-Object -First 1))

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "          PC ASSET INFORMATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

[PSCustomObject]@{
    "Manufacturer"    = $cs.Manufacturer
    "Model Number"    = $cs.Model
    "IP Address"      = $ip
    "Hostname"        = $env:COMPUTERNAME
    "MAC Address"     = $nic.MACAddress
    "Operating System"= $os.Caption
    "OS Version"      = $os.Version
    "CPU Model"       = $cpu.Name
    "CPU Cores"       = $cpu.NumberOfCores
    "RAM"             = "$ramTotal GB $ramType $ramSpeed MT/s"
    "Storage"         = "$storageGB GB"
    "Storage Type"    = $storageType
    "Power Status"    = if($bat){$bat.Status}else{'AC/No Battery'}
    "Network Status"  = if($nic){'Connected'}else{'Disconnected'}
} | Format-List

Write-Host "========================================" -ForegroundColor Cyan
