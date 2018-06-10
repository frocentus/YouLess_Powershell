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
      Gets you a basic status info about your LS110 Energy-Monitor

      .DESCRIPTION
      This command calls the YouLess LS110 Energy-Monitor an gets some basis status
      info. It calls the YouLess Energy-Monitor via an http-call to get the basic
      status info and transform it into a better readable Object

      .PARAMETER DeviceAddress
      Specifies the address to query in IP4-Format. Wildcards are not permitted. 
      This parameter is required.

      .EXAMPLE
      Get-YouLessStatusInfo -DeviceAddress "192.168.0.1"
      This command sends a status request to the YouLess LS110 EnergyMonitor at IP-Address
      192.168.0.1 and returns a basic status-info if it succeeds

      .INPUTS
      System.String
      You can pipe a string that contains the address of the device to query.

      .OUTPUTS
      System.Management.Automation.PSCustomObject
      Return the an Object, which contains the Status of your Energy-Monitor in its Properties

      .LINK
      Get-YouLessLS110HistoricalData
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


function Get-YouLessLS110HistoricalData 
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
      'Year' = 'm'
      'Week' = 'd'
      'Day' = 'w'
      'Hour' = 'h'
    }
  } 
  
  process {
    $uri = ('http://{0}/V?{1}={2}&f=j' -f $DeviceAddress, $_lookuptable[$Range], $_offset)
    Write-Verbose -Message ('Querying URL: {0}' -f $uri)
    Invoke-RestMethod -Uri $uri -Method Get
  }
}

function Get-YouLessLS110Measurements 
{
  <#
      .SYNOPSIS
      Describe purpose of "Get-YouLessMeasurements" in 1-2 sentences.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .PARAMETER DeviceAddress
      Specifies the address to query in IP4-Format. Wildcards are not permitted. 
      This parameter is required.

      .PARAMETER Range
      Describe parameter -Range.

      .EXAMPLE
      Get-YouLessMeasurements -DeviceAddress Value -Range Value
      Describe what this call does

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Get-YouLessMeasurements

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  param(
    [Parameter(Position = 0,HelpMessage = 'Add help message for user',Mandatory,ValueFromPipeline)]
    [String]$DeviceAddress,
  
    [parameter(Position = 1,HelpMessage = 'Add help message for user', Mandatory)]
    [ValidateSet('Hour','Day','Week','Year')]
    [String]$Range
  )
  
  $_range = $null
    
  switch ($Range) {
  
    'Hour' 
    {
      $_range = @(2..1)
    }
    
    'Day' 
    {
      $_range = @(3..1)
    }
    
    'Week' 
    {
      $_range = @(6..0)
    }
    
    'Year' 
    {
      $_range = @(12..1)
    }
  }
  
  $_range | ForEach-Object -Process {
    Get-YouLessLS110HistoricalData -DeviceAddress $DeviceAddress -Range $Range -Offset $_ `
     | Select-YouLessMeasurements 
  }
}

  function Select-YouLessMeasurements 
  {
    <#
        .SYNOPSIS
        Converts the JSON-Object-Structure returned from the YouLess-Energy-Monitor into Powershell-Objects
        for easier handling

        .DESCRIPTION
        Add a more complete description of what the function does.

        .PARAMETER RawResponse
        Describe parameter -InputObject.

        .EXAMPLE
        Select-YouLessMeasurements -InputObject Value -StartTime Value -Unit Value -StepSize Value
        Describe what this call does

        .NOTES
        Place additional notes here.

        .LINK
        URLs to related sites
        The first link is opened by Get-Help -Online Select-YouLessMeasurements

        .INPUTS
        List of input types that are accepted by this function.

        .OUTPUTS
        List of output types produced by this function.
    #>


    param
    (
      [PSObject]
      [Parameter(Mandatory, ValueFromPipeline, HelpMessage = 'Data to process')]
      $RawResponse
    )
    
    begin {
      $_formatProvider = New-Object -TypeName System.Globalization.CultureInfo -ArgumentList 'de-AT'
    }
    
    process
    {
      $StartTime = Get-Date -Date ($RawResponse.tm)
      $i = 0
      
      $RawResponse.val | Select-Object -SkipLast 1 | ForEach-Object {
        $converted = [convert]::ToDouble($_, $_formatProvider)
  
        $props = @{
          DateTime = $StartTime.AddSeconds($i)
          Value    = $converted
          Unit     = $RawResponse.un
        }
        $i = $i + $RawResponse.dt
        
        [PSCustomObject]$props
      }

    }
  }