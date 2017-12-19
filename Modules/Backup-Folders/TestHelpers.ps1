Set-StrictMode -Version Latest

Function Get-ModuleInfo {
  <#
  .SYNOPSIS
  Gets Information of the Module Under Test

  .DESCRIPTION
  Reads the information of automatic variable `$MyInvocation` and returns information
  of the module under test, expecting, that the test script shares the same name as
  the module under test, extended by '.Tests'.
  #>
  [CmdletBinding()]
  [OutputType([ModuleInfo])]
  Param(
    [Parameter(ValueFromPipeline)]
    [System.Management.Automation.InvocationInfo] $InvocationInfo
  )
  Process {
    Return [ModuleInfo]::new($InvocationInfo.MyCommand.Path);
  }
}

Function Out-JsonFile {
  <#
  .SYNOPSIS
  Writes the Hashtable into a JSON File
  #>
  [CmdletBinding()]
  Param(
    [Parameter(ValueFromPipeline)]
    [Hashtable] $Object,
    [Parameter()]
    [String]
    $FilePath,
    [Parameter()]
    [int]
    $Depth = 10
  )
  Process {
    ConvertTo-Json $Object -Depth $Depth | Out-File -FilePath $FilePath
  }
}

Function Create-Files {
  [CmdletBinding()]
  Param(
    [Parameter(ValueFromPipeline)]
    [Array] $Files,
    [Parameter()]
    [String]
    $Path
  )
  Process {
    $Files | Create-File -Path $Path
  }
}

Function Create-File {
  <#
  .SYNOPSIS
  Creates a file (or directory) from given parameters

  .DESCRIPTION
  A file is described by its name and type (directory or file). In addition to this
  you can specify 'childItems' for directories or a 'value' for the file which will
  by written as text into the file.

  For both, directories and files, you can also specify the 'lastWriteTime' and/or
  the 'creationTime' which will be set accordingly. If only specifying 'lastWriteTime'
  this will also become the file's creation time.
  #>
  [CmdletBinding()]
  Param(
    [Parameter(ValueFromPipeline)]
    [Hashtable] $File,
    [Parameter()]
    [String]
    $Path
  )
  Process {
    $FilePath = Join-Path -Path $Path -ChildPath $File.name
    Switch ($File.itemType) {
      "directory" {
        $FileItem = New-Item -ItemType "directory" -Path $FilePath -Force
        If ($File.ContainsKey("childItems")) {
          Create-Files -Files $File.childItems -Path $FilePath
        }
      }
      "file" {
        If ($File.ContainsKey("value")) {
          $Value = $File.value
        } else {
          $Value = $(Get-Random)
        }
        $FileItem = New-Item -ItemType "file" -Path $FilePath -Force -Value $Value
      }
    }
    If ($File.ContainsKey("lastWriteTime")) {
      [DateTime] $dateTime = $(Get-Date $File.lastWriteTime)
      $FileItem.CreationTime = $dateTime
      $FileItem.LastWriteTime = $dateTime
    }
    If ($File.ContainsKey("creationTime")) {
      [DateTime] $dateTime = $(Get-Date $File.creationTime)
      $FileItem.CreationTime = $dateTime
    }
  }
}

Class ModuleInfo {
  [String] $Path
  [String] $Name

  ModuleInfo([String] $Path) {
    [String] $BarePath = $Path -ireplace '(\.tests)*\.ps[dm]?1$'
    $this.Name = $BarePath | Split-Path -Leaf;
    If (Test-Path "$BarePath.psd1") {
      $this.Path = "$BarePath.psd1"
    } ElseIf (Test-Path "$BarePath.psm1") {
      $this.Path = "$BarePath.psm1"
    } Else {
      Throw [System.IO.FileNotFoundException]::New()
    }
  }

  [void] Remove() {

    Function Remove-ModuleCompletely {
      [CmdletBinding()]
      Param(
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.PSModuleInfo[]] $ModuleInfo
      )
      Process {
        Remove-Module -Force -ErrorAction SilentlyContinue -ModuleInfo $ModuleInfo
        If (Get-Member -InputObject $ModuleInfo -Name "Scripts" -Membertype Properties) {
          $ModuleInfo.Scripts | Remove-Module -Force -ErrorAction SilentlyContinue
        }
      }
    }

    Get-Module -Name $this.Name -All | Remove-ModuleCompletely
  }

  [void] Import() {
    Import-Module -Name $this.Path -Force -ErrorAction Stop
  }

  [String] ToString() {
    Return $this.Name + " <" + $this.Path + ">"
  }
}
