Set-StrictMode -Version Latest

. "$PSScriptRoot/Files.ps1"
. "$PSScriptRoot/AfterAll.ps1"
. "$PSScriptRoot/ArgumentValidators.ps1"
. "$PSScriptRoot/ArgumentTransformers.ps1"

Import-LocalizedData -BindingVariable Messages

Function Backup-Folders {
<#
.EXTERNALHELP .\Backup-Folders.psm1-Help.xml
#>
  [CmdletBinding(SupportsShouldProcess=$True)]
  Param(
    [Parameter()]
    [Alias("Config","Properties")]
    [ValidateConfigurationAttribute()]
    [PathTransformAttribute()]
    [String]
    $PropertiesFile = "~/Backup-Folders.json",
    [Parameter()]
    [AfterAll]
    $AfterAll = 'Default'
  )

  $Configuration = Get-Content "$PropertiesFile" | ConvertFrom-Json
  $Configuration.items | ForEach { Backup-SingleItem $PSItem }
}

Function Test-Verbose {
  <#
  .SYNOPSIS
  Tests if verbose flag is turned on

  .LINK
  http://www.mobzystems.com/blog/getting-the-verbose-switch-setting-in-powershell/
  #>
  [CmdletBinding()]
  Param()
  (Write-Verbose "TEST" -OutVariable output 4>&1) | Out-Null
  Return (!!$output)
}

Function Backup-SingleItem {
  Param(
    [PSCustomObject] $BackupConfig
  )
  $FromFolder = [FolderObject]::getFolderObject($BackupConfig.from)
  $ToFolder = [FolderObject]::getFolderObject($BackupConfig.to)

  If ($FromFolder.removable -and -not (Get-Existance-Top-Parent -Folder $FromFolder.path)) {
    Write-Warning ($Messages.skipRemovableDevice -f $Messages.removableSourceType, $FromFolder.path)
    Return
  }
  If ($ToFolder.removable -and -not (Get-Existance-Top-Parent -Folder $ToFolder.path)) {
    Write-Warning ($Messages.skipRemovableDevice -f $Messages.removableTargetType, $ToFolder.path)
    Return
  }
  [String[]] $Options = Get-ValueOrDefault -Object $BackupConfig -Key "options" -Default @("/MIR", "/R:5", "/W:15", "/MT:32", "/XA:SH", "/XJD" );
  Write-Verbose ($Messages.backupFromTo -f $FromFolder.path, $ToFolder.path)
  If (Test-Verbose) {
    $Options += "/V"
  }
  If ($WhatIfPreference) {
    $Options += "/L"
  }
  $Options = @($FromFolder.path, $ToFolder.path) + $Options
  RoboCopy.exe $Options *>&1 | Write-Output
}

Function Get-ValueOrDefault {
  Param(
    [PSCustomObject] $Object,
    [String] $Key,
    $Default
  )
  If (Get-Member -InputObject $Object -Name $Key -Membertype Properties) {
    Return $Object.$Key
  }
  Return $Default
}

Function Get-Existance-Top-Parent {
  Param(
    [String] $Folder
  )
  [URI] $FolderUri = [URI]$Folder
  If ($FolderUri.IsAbsoluteUri) {
    If ($FolderUri.IsUnc) {
      Return (Test-Path -Path "//$FolderUri.Host/")
    } else {
      $DriveLetter = Split-Path -Path $Folder -Qualifier
      Return (Test-Path -Path $DriveLetter)
    }
  }
  Return $true
}

Class BackupItem {
  [FolderObject] $ToFolder;
  [FolderObject] $FromFolder;
}

Class FolderObject {
  [String] $Path;
  [bool] $Removable;
  FolderObject([String] $Path, [bool] $Removable) {
    $this.Path = $Path;
    $this.Removable = $Removable;
  }
  FolderObject([PSCustomObject] $psCustomObject) {
    $this.Path = $psCustomObject.path;
    $this.Removable = $psCustomObject.removable;
  }
  static [FolderObject] getFolderObject([Object] $Folder) {
    If ($Folder -is [System.Management.Automation.PSCustomObject]) {
      Return [FolderObject]::new($Folder);
    }
    Return [FolderObject]::new($Folder, $false);
  }
}
