Import-Module './YouLessDataLogger.psm1'

$deviceip = '192.168.1.242'

Clear-Host
Get-YouLessLS110StatusInfo -DeviceAddress $deviceip

Get-YouLessLS110Measurements -DeviceAddress $deviceip -Range Year
Get-YouLessLS110Measurements -DeviceAddress $deviceip -Range Week -Verbose
Get-YouLessLS110Measurements -DeviceAddress $deviceip -Range Day
$deviceip | Get-YouLessLS110Measurements -Range Hour

Get-YouLessLS110HistoricalData -DeviceAddress $deviceip -Range Week -Offset 3
$deviceip | Get-YouLessLS110Measurements -Range Hour

Get-YouLessLS110HistoricalData -DeviceAddress $deviceip -Range Hour -Offset 1 | Select-YouLessMeasurements
