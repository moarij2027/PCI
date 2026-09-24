$cs=Get-CimInstance Win32_ComputerSystem
$os=Get-CimInstance Win32_OperatingSystem
$cpu=Get-CimInstance Win32_Processor | Select-Object -First 1
$bios=Get-CimInstance Win32_BIOS
$board=Get-CimInstance Win32_BaseBoard
$nic=Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | Select-Object -First 1
$allNics=Get-CimInstance Win32_NetworkAdapter | Where-Object {$_.MACAddress -and $_.NetEnabled}
$bat=Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
$ram=Get-CimInstance Win32_PhysicalMemory
$disks=Get-PhysicalDisk
$logicalDisks=Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$gpu=Get-CimInstance Win32_VideoController
$computerProduct=Get-CimInstance Win32_ComputerSystemProduct

# RAM
$ramTotal=[math]::Round((($ram|Measure-Object Capacity -Sum).Sum)/1GB,0)

$ramType=switch([int]($ram|Select-Object -First 1).SMBIOSMemoryType){
    20 {'DDR'}
    21 {'DDR2'}
    22 {'DDR2'}
    24 {'DDR3'}
    26 {'DDR4'}
    29 {'DDR4'}
    30 {'DDR4'}
    34 {'DDR5'}
    default {'Unknown'}
}

$ramSpeed=(($ram|Measure-Object ConfiguredClockSpeed -Maximum).Maximum)
$ramSlots=$ram.Count

# Storage
$storageGB=[math]::Round((($disks|Measure-Object Size -Sum).Sum)/1GB,2)

$storageTypes=(($disks|ForEach-Object{
    if($_.MediaType -eq 'SSD' -and $_.BusType -eq 'NVMe'){'NVMe SSD'}
    elseif($_.MediaType -eq 'SSD' -and $_.BusType -eq 'SATA'){'SATA SSD'}
    elseif($_.MediaType -eq 'SSD'){'SSD'}
    elseif($_.MediaType -eq 'HDD'){'HDD'}
    else{$_.MediaType}
})|Select-Object -Unique)-join ', '

# IP
$ip=(($nic.IPAddress|Where-Object{$_ -match '^\d+\.'}|Select-Object -First 1))

# Power
$powerStatus=if($bat){
    "$($bat.Status) - $($bat.EstimatedChargeRemaining)%"
}else{
    'AC/No Battery'
}

# Network
$networkStatus=if($nic){'Connected'}else{'Disconnected'}

# GPU
$gpuNames=($gpu|ForEach-Object{$_.Name}|Select-Object -Unique)-join ', '

# Network adapters
$macs=($allNics|ForEach-Object{$_.MACAddress}|Select-Object -Unique)-join ', '

# Disk details
$diskDetails=($disks|ForEach-Object{
    $size=[math]::Round($_.Size/1GB,2)

    if($_.MediaType -eq 'SSD' -and $_.BusType -eq 'NVMe'){
        $type='NVMe SSD'
    }
    elseif($_.MediaType -eq 'SSD' -and $_.BusType -eq 'SATA'){
        $type='SATA SSD'
    }
    elseif($_.MediaType -eq 'SSD'){
        $type='SSD'
    }
    elseif($_.MediaType -eq 'HDD'){
        $type='HDD'
    }
    else{
        $type=$_.MediaType
    }

    "$($_.FriendlyName) - $type - $size GB"
}) -join '; '

# RAM details
$ramDetails=($ram|ForEach-Object{
    $size=[math]::Round($_.Capacity/1GB,0)
    "$size GB $ramType $($_.ConfiguredClockSpeed) MT/s"
}) -join '; '

# Drives / partitions
$driveDetails=($logicalDisks|ForEach-Object{
    "$($_.DeviceID) $([math]::Round($_.Size/1GB,2)) GB total, $([math]::Round($_.FreeSpace/1GB,2)) GB free"
}) -join '; '

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                    PC ASSET INFORMATION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

[PSCustomObject][ordered]@{
    "Manufacturer"        = $cs.Manufacturer
    "Model Number"        = $cs.Model
    "Serial Number"       = $bios.SerialNumber

    "IP Address"          = $ip
    "Hostname"            = $env:COMPUTERNAME
    "MAC Address"         = $macs

    "Operating System"    = $os.Caption
    "OS Version"          = $os.Version

    "CPU Model"           = $cpu.Name
    "CPU Cores"           = $cpu.NumberOfCores
    "CPU Threads"         = $cpu.NumberOfLogicalProcessors
    "CPU Max Clock"       = "$($cpu.MaxClockSpeed) MHz"

    "RAM (GB)"             = "$ramTotal GB"
    "RAM Details"         = $ramDetails
    "RAM Slots"            = $ramSlots

    "Storage (GB)"         = "$storageGB GB"
    "Storage Type"         = $storageTypes
    "Disk Details"         = $diskDetails
    "Drive Details"        = $driveDetails

    "Power Status"         = $powerStatus
    "Network Status"       = $networkStatus

    "BIOS Version"         = $bios.SMBIOSBIOSVersion
    "BIOS Manufacturer"    = $bios.Manufacturer
    "Motherboard"          = "$($board.Manufacturer) $($board.Product)"
    "Motherboard Serial"   = $board.SerialNumber
    "System UUID"           = $computerProduct.UUID
    "GPU"                  = $gpuNames
    "Windows Install Date" = $os.InstallDate
} | Format-List

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Collection completed." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
