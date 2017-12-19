#Requires -Version 5
<#
.SYNOPSIS
Synchronises two folders

.DESCRIPTION
This script synchronises folders based on ROBOCOPY. It is configured through
a JSON file which mght list several folders to synchronize/mirror.

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

Here are some example configuration in Sync-Folders.json. Note that
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
The properties file (JSON) to read. Defaults to ~/Sync-Folders.json.

.PARAMETER AfterAll
Controls what happens when all folders are synchronized. By default
this is controlled by the entry in the JSON file. This parameter
overrides any behavior specified in the JSON file. Possible values
are: default (use JSON entry), none (no action), shutdown (shutdown
the computer).

.EXAMPLE
Sync-Folders.ps1

Synchronize folders with a configuration file named Sync-Folders.json in
your home folder.

.EXAMPLE
Sync-Folders.ps1 -PropertiesFile ~/Sync-Folders.json

The very same as the default behavior just with the configuration file
explicitly given.

.EXAMPLE
Sync-Folders.ps1 -PropertiesFile .\Other-Sync-Folders.json

Read another configuration file relative to your current working
directory.

.EXAMPLE
Sync-Folders.ps1 -AfterAll shutdown

Run synchronization and shutdown the computer after synchronization
is done.

.LINK
https://github.com/mmichaelis/ps-sync-folders

.LINK
https://technet.microsoft.com/en-us/library/cc733145(v=ws.10).aspx

#>
Param(
  [Parameter(
    HelpMessage="Where to read the Sync-Folders configuration file from (JSON)."
  )]
  [Alias("Config","Properties")]
  [ValidateScript({[ParameterValidation]::ValidatePropertiesFile($PSItem)})]
  [String]
  $PropertiesFile = "~/Sync-Folders.json",
  [Parameter(
    HelpMessage="Where to read the Sync-Folders configuration file from (JSON)."
  )]
  [ValidateSet("default","none","shutdown")]
  [String]
  $AfterAll = "default"
)

Set-StrictMode -Version Latest

Set-Variable -Name "validAfterAll" -Value @("default", "none", "shutdown") -Scope Script

Class ParameterValidation {
  static [bool] ValidatePropertiesFile([String] $Path) {
    If (Test-Path ([FileUtil]::ForceResolvePath($PSItem)) -PathType 'Leaf') {
     $true
    } Else {
      Throw "Properties file $PSItem does not exist."
    }
    Return $false
  }
}

Class FileUtil {
  <#
  .SYNOPSIS
    Calls Resolve-Path but works for files that don't exist.
  .LINK
    http://devhawk.net/2010/01/21/fixing-powershells-busted-resolve-path-cmdlet/
  #>
  static [String] ForceResolvePath([String] $FileName) {
    $_frperror = @{}
    $FileName = Resolve-Path $FileName -ErrorAction SilentlyContinue `
                                       -ErrorVariable _frperror
    If (-not($FileName)) {
        $FileName = $_frperror[0].TargetObject
    }

    Return $FileName
  }
}

<#
.Link
https://stackoverflow.com/questions/3740128/pscustomobject-to-hashtable
#>
Function Convert-PSObjectToHashtable([Parameter(ValueFromPipeline)] $InputObject) {
  Begin { }
  Process {
    If ($null -eq $InputObject) {
      return $null
    }

    If ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
      $collection = @(
        ForEach ($object in $InputObject) {
          Convert-PSObjectToHashtable $object
        }
      )

      Write-Output -NoEnumerate $collection
    } ElseIf ($InputObject -is [psobject]) {
      $hash = @{}

      ForEach ($property in $InputObject.PSObject.Properties) {
        $hash[$property.Name] = Convert-PSObjectToHashtable $property.Value
      }

      $hash
    } Else {
      $InputObject
    }
  }
  End { }
}

Function Read-Json {
  <#
  .SYNOPSIS
    Reads the given JSON File into a Hashtable.
  #>
  Param(
    [String] $Path
  )
  Get-Content "$Path" | ConvertFrom-Json
}

Function Read-Configuration {
  $Global:ConfigurationPath = [FileUtil]::ForceResolvePath($PropertiesFile)
  $Global:Configuration = Read-Json $Global:ConfigurationPath
}

Function Validate-Configuration {
  If (-not (Get-Member -inputobject $Global:Configuration -name "items" -Membertype Properties)) {
    Write-Error -Category InvalidArgument -TargetObject $Global:Configuration -Message @"
[ERROR] Missing root element 'items' in $Global:ConfigurationPath.

To get help and example configurations call:

PS C:\>Get-Help $PSScriptRoot\Sync-Folders.ps1 -full
"@
    Exit 1
  }

  $LocalAfterAll = $Global:Configuration.afterAll
  If ($AfterAll -and -not ($AfterAll -eq "default")) {
    $LocalAfterAll = $AfterAll
  }
  If ($LocalAfterAll) {
    Switch ($LocalAfterAll.ToLower()) {
      "shutdown" {
        Write-Verbose "Will shutdown computer after sync is finished."
      }
      {($PSItem -eq "none") -or ($PSItem -eq "default")} {
        Write-Debug "No action activated when sync is finished."
      }
      default {
        Write-Error -Category InvalidArgument -TargetObject $Global:Configuration.afterAll @"
[ERROR] Unsupported afterAll action: $PSItem

Supported action (case-sensitive): $($validAfterAll -join ', ')
"@
      }
    }
  }
  $AfterAll = $LocalAfterAll

  Write-Verbose "Found $($Global:Configuration.items.Count) folder pair(s) to synchronize."
}

Function Or-Default {
  Param(
    $Original,
    $Default
  )
  If ($Original) {
    $Original
  } else {
    $Default
  }
}

Function Run-Single-Synchronization {
  Param(
    [PSCustomObject] $SyncConfig
  )
  $FromFolder = [FolderObject]::getFolderObject($SyncConfig.from)
  $ToFolder = [FolderObject]::getFolderObject($SyncConfig.to)

  If ($FromFolder.removable -and -not (Exists-Top-Parent -Folder $FromFolder.path)) {
    Write-Warning "Skipping removable source device as it does not exist: $($FromFolder.path)"
    Return
  }
  If ($ToFolder.removable -and -not (Exists-Top-Parent -Folder $ToFolder.path)) {
    Write-Warning "Skipping removable target device as it does not exist: $($ToFolder.path)"
    Return
  }
  $Options = Or-Default -Original $SyncConfig.options -Default @("/MIR", "/R:5", "/W:15", "/MT:8");
  Write-Verbose "Synchronizing $($FromFolder.path) to $($ToFolder.path)."
  #RoboCopy $FromFolder.path $ToFolder.path $Options
}

Class SynchronizationItem {
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

Function Exists-Top-Parent {
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

Function Run-All-Synchronizations {
  $Global:Configuration.items | foreach { Run-Single-Synchronization $PSItem }
}

Function Run-After-All {
  If ($AfterAll) {
    Switch ($AfterAll.ToLower()) {
      "shutdown" {
        Stop-Computer
      }
      {($PSItem -eq "none") -or ($PSItem -eq "default")} {
      }
      default {
        Write-Error "[ERROR] Unsupported afterAll action: $PSItem"
      }
    }
  }
}

Read-Configuration
Validate-Configuration
Run-All-Synchronizations
Run-After-All

