
<#

Author: Harald Reisinger
Version: 0.1
Version History: initial release

Purpose: Querying a YouLess-EnergyMonitor DataLogger from Powershell

#>

function Get-YouLessLS110StatusInfo 
{
  <#
      .SYNOPSIS
      Gets you a basic status info about your Energy-Monitor

      .DESCRIPTION
      This command calls the YouLess Energy-Monitor an gets some basis status
      info. It calls the YouLess Energy-Monitor via an http-call to get the basic
      status info and transform it into a better readable Object

      .PARAMETER DeviceAddress
      Specifies the address to query in IP4-Format. Wildcards are not permitted. 
      This parameter is required.

      .EXAMPLE
      Get-YouLessStatusInfo -DeviceAddress "192.168.0.1"
      This command sends a status request to the YouLess EnergyMonitor at IP-Address
      192.168.0.1 and returns a basic status-info if it succeeds

      .INPUTS
      System.String
      You can pipe a string that contains the address of the device to query.

      .OUTPUTS
      System.Management.Automation.PSCustomObject
      Return the an Object, which contains the Status of your Energy-Monitor in its Properties

      .LINK
      Get-YouLessHistoricalData
      Get-YouLessLS110Measurements 
  #>
  
  param
  (
    [Parameter(ValueFromPipeline, Mandatory, HelpMessage = 'The address to query in IP4-Format')]
    [string]
    $DeviceAddress
  )

  Invoke-RestMethod -Uri ('http://{0}/a?f=j' -f $DeviceAddress) -Method Get `
  | Select-Object -Property `
  @{
    Name       = 'Counter (kWh)'
    Expression = {
      $_.cnt
    }
  }, 
  @{
    Name       = 'Reflection Level'
    Expression = {
      $_.lvl
    }
  }, 
  @{
    Name       = 'Deviation of Reflection'
    Expression = {
      $_.dev.replace('&plusmn;', '±')
    }
  }, 
  @{
    Name       = 'Raw 10bit Reflection Level'
    Expression = {
      $_.raw
    }
  }, 
  @{
    Name       = 'Power (W)'
    Expression = {
      $_.pwr
    }
  }, 
  @{
    Name       = 'Upload'
    Expression = {
      $_.con
    }
  }, 
  @{
    Name       = 'Next Status Update'
    Expression = {
      $_.sts
    }
  }, 
  'det'
}


function Get-YouLessHistoricalData 
{
  <#
      .SYNOPSIS
      Retrieves Historical Data from the Memory of your YouLess-energy-monitor

      .DESCRIPTION
      Add a more complete description of what the function does.

      .PARAMETER DeviceAddress
      Specifies the address to query in IP4-Format. Wildcards are not permitted. 
      This parameter is required.

      .PARAMETER Range
      With this parameter you decide, for what time period you want to fetch the 
      measurements from the device.

      .PARAMETER Offset
      TODO

      .EXAMPLE
      Get-YouLessHistoricalData -DeviceAddress Value -Range Value
      Describe what this call does

      .NOTES
      Place additional notes here.

      .INPUTS
      System.String
      You can pipe a string that contains the address of the device to query.

      .OUTPUTS
      List of output types produced by this function.
  #>


  param
  (
    [Parameter(Position = 0,HelpMessage = 'The address to query in IP4-Format',Mandatory,ValueFromPipeline)]
    [String]$DeviceAddress,
    
    [parameter(Position = 1, Mandatory,HelpMessage = 'Add help message for user')]
    [ValidateSet('Hour','Day','Week','Year')]
    [String]$Range

  )
  
  dynamicparam {
    $attributes = New-Object -TypeName System.Management.Automation.ParameterAttribute
    $attributes.ParameterSetName = '__AllParameterSets'
    $attributes.Mandatory = $true
    $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
    $attributeCollection.Add($attributes)
      
    $values = $null
      
    switch ($Range) {
      'Hour' { $values = @(1..2) }
      'Day'  { $values = @(1..3) }   
      'Week' { $values = @(0..6) }
      'Year' { $values = @(1..12) }        
    }
      
    $ValidateSet = New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList ($values)
    $attributeCollection.Add($ValidateSet)

    $dynParam1 = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList ('Offset', [int], $attributeCollection)
    $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add('Offset', $dynParam1)
    return $paramDictionary 
  } 
  
  begin {
    $_offset = $PSBoundParameters.Offset
    $_lookuptable = @{
      'Year' = 'h'
      'Week' = 'w'
      'Day' = 'd'
      'Hour' = 'm'
    }
  } 
  
  process {
      Invoke-RestMethod -Uri ('http://{0}/V?{1}={2}&f=j' -f $DeviceAddress, $_lookuptable[$Range], $_offset) -Method Get
  }
}