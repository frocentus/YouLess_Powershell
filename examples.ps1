Import-Module './YouLessDataLogger.psm1'

$deviceip = '192.168.1.242'

Clear-Host
Get-YouLessStatusInfo -DeviceAddress $deviceip

Get-YouLessLS110Measurements -DeviceAddress $deviceip -Range Year
Get-YouLessHistoricalData -DeviceAddress $deviceip -Range Week -Offset 3
$deviceip | Get-YouLessLS110Measurements -Range Hour
