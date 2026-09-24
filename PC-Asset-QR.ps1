$cs=Get-CimInstance Win32_ComputerSystem
$os=Get-CimInstance Win32_OperatingSystem
$cpu=Get-CimInstance Win32_Processor|Select-Object -First 1
$bios=Get-CimInstance Win32_BIOS
$nic=Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"|Select-Object -First 1
$bat=Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
$ram=Get-CimInstance Win32_PhysicalMemory
$disks=Get-PhysicalDisk

$ramTotal=[math]::Round((($ram|Measure-Object Capacity -Sum).Sum)/1GB,0)

$ramType=switch([int]($ram|Select-Object -First 1).SMBIOSMemoryType){
20{'DDR'}
21{'DDR2'}
22{'DDR2'}
24{'DDR3'}
26{'DDR4'}
29{'DDR4'}
30{'DDR4'}
34{'DDR5'}
default{'Unknown'}
}

$ramSpeed=(($ram|Measure-Object ConfiguredClockSpeed -Maximum).Maximum)

$storageGB=[math]::Round((($disks|Measure-Object Size -Sum).Sum)/1GB,2)

$storageType=(($disks|ForEach-Object{
if($_.MediaType -eq 'SSD' -and $_.BusType -eq 'NVMe'){'NVMe SSD'}
elseif($_.MediaType -eq 'SSD' -and $_.BusType -eq 'SATA'){'SATA SSD'}
elseif($_.MediaType -eq 'SSD'){'SSD'}
elseif($_.MediaType -eq 'HDD'){'HDD'}
else{$_.MediaType}
})|Select-Object -Unique)-join ', '

$ip=(($nic.IPAddress|Where-Object{$_ -match '^\d+\.'}|Select-Object -First 1))

$mac=$nic.MACAddress

$powerStatus=if($bat){"$($bat.Status) - $($bat.EstimatedChargeRemaining)%"}else{'AC/No Battery'}

$networkStatus=if($nic){'Connected'}else{'Disconnected'}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "              PC ASSET INFORMATION" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

[PSCustomObject][ordered]@{
"Manufacturer"=$cs.Manufacturer
"Model Number"=$cs.Model
"Serial Number"=$bios.SerialNumber
"IP Address"=$ip
"Hostname"=$env:COMPUTERNAME
"MAC Address"=$mac
"Operating System"=$os.Caption
"OS Version"=$os.Version
"CPU Model"=$cpu.Name
"CPU Cores"=$cpu.NumberOfCores
"RAM (GB)"="$ramTotal GB $ramType $ramSpeed MT/s"
"Storage (GB)"="$storageGB GB"
"Storage Type"=$storageType
"Power Status"=$powerStatus
"Network Status"=$networkStatus
}|Format-List

Write-Host "==================================================" -ForegroundColor Cyan
