Set-StrictMode -Version Latest

. "$PSScriptRoot/Files.ps1"
. "$PSScriptRoot/AfterAll.ps1"
. "$PSScriptRoot/ArgumentValidators.ps1"
. "$PSScriptRoot/ArgumentTransformers.ps1"

<#
.SYNOPSIS
Backup one folder to another

.DESCRIPTION
This script backups folders based on ROBOCOPY. It is configured through
a JSON file which mght list several folders to backup.

The script is especially meant to have an easy way to do backups for example
to a NAS or an external drive.

.INPUTS

None.

.OUTPUTS

None.

.NOTES
The actual implementation of this script is very basic as it is just a
wrapper around ROBOCOPY. So the complete behavior is based on ROBOCOPY
despite that the default option passed to ROBOCOPY is /MIR which is two
mirror two folders.

Here are some example configuration in Backup-Folders.json. Note that
the examples use forward slashes as path separator. This is totally
valid in Powershell. As alternative you might use backward slashes
but you need to escape them. So C:/From has to be written as
C:\\From.

This is the minimum configuration of a ROBOCOPY job. It will use
ROBOCOPY with /MIR option, i. e. to mirror one folder to another.

{
  "items": [
    {
      "from": "C:/From",
      "to": "C:/To",
    }
  ]
}

Just as the example above this will use ROBOCOPY with /MIR option.
As this is the default, you could skip the options here.

{
  "items": [
    {
      "from": "C:/From",
      "to": "C:/To",
      "options": [
        "/MIR"
      ]
    }
  ]
}

This configuration will also mirror the given folders, but it will
not delete files/folders with to not exist in source (which /MIR
would do).

{
  "items": [
    {
      "from": "C:/From",
      "to": "C:/To",
      "options": [
        "/E"
      ]
    }
  ]
}

This is an example if you want to mirror to your NAS (here: FritzBOX
with WD Elements drive attached).

{
  "items": [
    {
      "from": "C:/From",
      "to": "//Fritz-nas/fritz.nas/Elements/To"
    }
  ]
}

If a network share or drive is not always attached you can mark the
source or target folder as removable:

{
  "items": [
    {
      "from": {
        "path": "C:/From",
        "removable": true
      },
      "to": {
        "path": "//unc-host/unc-path",
        "removable": true
      }
    }
  ]
}

.PARAMETER PropertiesFile
The properties file (JSON) to read. Defaults to ~/Backup-Folders.json.

.PARAMETER AfterAll
Controls what happens when all folders are backed up. By default
this is controlled by the entry in the JSON file. This parameter
overrides any behavior specified in the JSON file. Possible values
are: default (use JSON entry), none (no action), shutdown (shutdown
the computer).

.EXAMPLE
Backup-Folders

Backup folders with a configuration file named Backup-Folders.json in
your home folder.

.EXAMPLE
Backup-Folders -PropertiesFile ~/Backup-Folders.json

The very same as the default behavior just with the configuration file
explicitly given.

.EXAMPLE
Backup-Folders -PropertiesFile .\Other-Backup-Folders.json

Read another configuration file relative to your current working
directory.

.EXAMPLE
Backup-Folders -AfterAll shutdown

Run backup and shutdown the computer after backup
is done.

.LINK
https://github.com/mmichaelis/ps-sync-folders

.LINK
https://technet.microsoft.com/en-us/library/cc733145(v=ws.10).aspx

#>
Function Backup-Folders {
  [CmdletBinding()]
  Param(
    [Parameter(
      HelpMessage="Where to read the Backup-Folders configuration file from (JSON)."
    )]
    [Alias("Config","Properties")]
    [ValidateConfigurationAttribute()]
    [PathTransformAttribute()]
    [String]
    $PropertiesFile = "~/Backup-Folders.json",
    [Parameter(
      HelpMessage="Where to read the Backup-Folders configuration file from (JSON)."
    )]
    [AfterAll]
    $AfterAll = 'Default'
  )

  $Configuration = Get-Content "$PropertiesFile" | ConvertFrom-Json
  $Configuration.items | ForEach { Backup-SingleItem $PSItem }
}

Function Backup-SingleItem {
  Param(
    [PSCustomObject] $BackupConfig
  )
  $FromFolder = [FolderObject]::getFolderObject($BackupConfig.from)
  $ToFolder = [FolderObject]::getFolderObject($BackupConfig.to)

  If ($FromFolder.removable -and -not (Get-Existance-Top-Parent -Folder $FromFolder.path)) {
    Write-Warning "Skipping removable source device as it does not exist: $($FromFolder.path)"
    Return
  }
  If ($ToFolder.removable -and -not (Get-Existance-Top-Parent -Folder $ToFolder.path)) {
    Write-Warning "Skipping removable target device as it does not exist: $($ToFolder.path)"
    Return
  }
  $Options = Get-ValueOrDefault -Object $BackupConfig -Key "options" -Default @("/MIR", "/R:5", "/W:15", "/MT:8");
  Write-Host "Back up from $($FromFolder.path) to $($ToFolder.path)."
  RoboCopy $FromFolder.path $ToFolder.path $Options
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
