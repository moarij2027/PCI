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

$info="Manufacturer:$($cs.Manufacturer)`nModel Number:$($cs.Model)`nIP Address:$ip`nHostname:$env:COMPUTERNAME`nMAC Address:$($nic.MACAddress)`nOperating System:$($os.Caption)`nOS Version:$($os.Version)`nCPU Model:$($cpu.Name)`nCPU Cores:$($cpu.NumberOfCores)`nRAM:$ramTotal GB $ramType $ramSpeed MT/s`nStorage:$storageGB GB`nStorage Type:$storageType`nPower Status:$(if($bat){$bat.Status}else{'AC/No Battery'})`nNetwork Status:$(if($nic){'Connected'}else{'Disconnected'})"

$js="$env:TEMP\qrcode.min.js"
if(!(Test-Path $js)){
Invoke-WebRequest "https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js" -OutFile $js
}

$escaped=$info.Replace('\','\\').Replace('`','\`').Replace("'","\'").Replace("`r","").Replace("`n","\n")

$html=@"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>PC Asset QR</title>
<style>
body{font-family:Arial;text-align:center;margin-top:30px}
#qrcode{display:inline-block;padding:20px;background:white}
h2{margin-bottom:20px}
button{font-size:18px;padding:10px 25px;margin-top:20px}
</style>
</head>
<body>
<h2>PC Asset QR Code</h2>
<div id="qrcode"></div>
<br>
<button onclick="downloadQR()">Save QR Code</button>
<script>
$(Get-Content $js -Raw)
</script>
<script>
var data='$escaped';
new QRCode(document.getElementById("qrcode"),{
text:data,
width:600,
height:600,
correctLevel:QRCode.CorrectLevel.M
});
function downloadQR(){
var img=document.querySelector('#qrcode img');
var a=document.createElement('a');
a.href=img.src;
a.download='PC_Asset_QR.png';
a.click();
}
</script>
</body>
</html>
"@

$file="$env:USERPROFILE\Desktop\PC_Asset_QR.html"
$html|Set-Content $file -Encoding UTF8
Start-Process $file