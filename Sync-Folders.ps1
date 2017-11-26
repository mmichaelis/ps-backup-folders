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

.PARAMETER PropertiesFile
The properties file (JSON) to read. Defaults to ~/Sync-Folders.json.

.EXAMPLE
Sync-Folders

Synchronize folders with a configuration file named Sync-Folders.json in
your home folder.

.EXAMPLE
Sync-Folders -PropertiesFile ~/Sync-Folders.json

The very same as the default behavior just with the configuration file
explicitly given.

.EXAMPLE
Sync-Folders -PropertiesFile .\Other-Sync-Folders.json

Read another configuration file relative to your current working
directory.

.LINK
https://github.com/mmichaelis/ps-sync-folders

.LINK
https://technet.microsoft.com/en-us/library/cc733145(v=ws.10).aspx

#>
Param(
  [parameter(
    HelpMessage="Where to read the Sync-Folders configuration file from (JSON)."
  )]
  [String]
  $PropertiesFile = "~/Sync-Folders.json"
)

Function Force-Resolve-Path {
  <#
  .SYNOPSIS
    Calls Resolve-Path but works for files that don't exist.
  .LINK
    http://devhawk.net/2010/01/21/fixing-powershells-busted-resolve-path-cmdlet/
  #>
  Param(
    [String] $FileName
  )

  $FileName = Resolve-Path $FileName -ErrorAction SilentlyContinue `
                                       -ErrorVariable _frperror
  If (-not($FileName)) {
      $FileName = $_frperror[0].TargetObject
  }

  Return $FileName
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

Function Validate-Parameters {
  $Global:ConfigurationPath = Force-Resolve-Path $PropertiesFile
  if (-not (Test-Path $Global:ConfigurationPath)) {
    Write-Error @"
[ERROR] Unable to find configuration file: $Global:ConfigurationPath

To get help call:

PS C:\>Get-Help $PSScriptRoot\Sync-Folders.ps1
"@
    Exit 1
  }
}

Function Read-Configuration {
  $Global:Configuration = Read-Json $Global:ConfigurationPath
}

Function Validate-Configuration {
  If (-not (Get-Member -inputobject $Global:Configuration -name "items" -Membertype Properties)) {
    Write-Error @"
[ERROR] Missing root element 'items' in $Global:ConfigurationPath.

To get help and example configurations call:

PS C:\>Get-Help $PSScriptRoot\Sync-Folders.ps1 -full
"@
    Exit 1
  }

  If ($Global:Configuration.afterAll) {
    Switch ($Global:Configuration.afterAll) {
      "shutdown" {
        Write-Verbose "Will shutdown computer after sync is finished."
      }
      default {
        Write-Error @"
[ERROR] Unsupported afterAll action: $Global:Configuration.afterAll

Supported action (case-sensitive): shutdown
"@
      }
    }
  }


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
  $FromFolder = $SyncConfig.from
  $ToFolder = $SyncConfig.to
  $Options = Or-Default -Original $SyncConfig.options -Default @("/MIR", "/R:5", "/W:15", "/MT:8");
  RoboCopy $FromFolder $ToFolder $Options
}

Function Run-All-Synchronizations {
  $Global:Configuration.items | foreach { Run-Single-Synchronization $PSItem }
}

Function Run-After-All {
  If ($Global:Configuration.afterAll) {
    Switch ($Global:Configuration.afterAll) {
      "shutdown" {
        Stop-Computer
      }
      default {
        Write-Error @"
[ERROR] Unsupported afterAll action: $Global:Configuration.afterAll

Supported action (case-sensitive): shutdown
"@
      }
    }
  }
}

Validate-Parameters
Read-Configuration
Validate-Configuration
Run-All-Synchronizations
Run-After-All
