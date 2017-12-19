Set-StrictMode -Version Latest

. "$PSScriptRoot/TestHelpers.ps1"

$ModuleInformation = $MyInvocation | Get-ModuleInfo
$ThisModuleName = $ModuleInformation.Name
$ThisModuleFilename = $ModuleInformation.Path

$ModuleInformation.Remove()
$ModuleInformation.Import()

InModuleScope $ThisModuleName {
  Describe 'Backup-Folders' {
    BeforeAll {
      $fromPath = Join-Path $TestDrive "From"
      $toPath = Join-Path $TestDrive "To"
      $SimpleItemsFile = Join-Path $TestDrive "simple.json"
      @{ "items" = @(@{
        "from" = $fromPath;
        "to" = $toPath;
      }) } | Out-JsonFile -FilePath $SimpleItemsFile

      New-Item -ItemType "directory" -Path $fromPath
      New-Item -ItemType "directory" -Path $toPath
    }
    Context 'When there is an invalid parameter' {
      It 'for PropertiesFile' {
        { Backup-Folders -PropertiesFile NoSuchFile.json } | Should -Throw "PropertiesFile"
      }
      It 'for AfterAll' {
        $EmptyItemsFile = Join-Path $TestDrive "empty.json"
        @{ "items" =  @() } | Out-JsonFile -FilePath $EmptyItemsFile
        { Backup-Folders -PropertiesFile $EmptyItemsFile -AfterAll NoSuchAction -Debug } | Should -Throw "AfterAll"
      }
    }
    Context 'Files Unit Tests' {
      It 'ForceResolvePath.existingPath' {
        @(
          @{
            "name" = "FRP.existing.txt";
            "itemType" = "file";
          }
        ) | Create-Files -Path $TestDrive
        Push-Location "$TestDrive"
        Try {
          [Files]::ForceResolvePath("./FRP.existing.txt") | Should -Be "$TestDrive\FRP.existing.txt"
        } Finally {
          Pop-Location
        }
      }
      It 'ForceResolvePath.notExistingPath' {
        [Files]::ForceResolvePath("TestDrive:/SomeDir/../NotExisting.txt") | Should -Be "TestDrive:\NotExisting.txt"
      }
    }
    Context 'When the configuration is invalid' {
      It 'items property does not exist'  {
      }
    }
    Context 'When there are files to back up' {
      It 'new file in FROM shall be backed up to TO' {
        @(
          @{
            "name" = "newInFrom.txt";
            "itemType" = "file";
          }
        ) | Create-Files -Path $fromPath
        Backup-Folders -PropertiesFile $SimpleItemsFile
        Join-Path -Path $toPath -ChildPath "newInFrom.txt" | Should -Exist
      }
      It 'old file in TO shall be removed on backup' {
        @(
          @{
            "name" = "oldInTo.txt";
            "itemType" = "file";
          }
        ) | Create-Files -Path $toPath
        Backup-Folders -PropertiesFile $SimpleItemsFile
        Join-Path -Path $toPath -ChildPath "oldInTo.txt" | Should -Not -Exist
      }
      It 'newer file in FROM should overwrite older filder in TO' {
        @(
          @{
            "name" = "newerInFrom.txt";
            "itemType" = "file";
            "lastWriteTime" = "2016-12-24 12:34:56";
            "value" = "from From";
          }
        ) | Create-Files -Path $fromPath
        @(
          @{
            "name" = "newerInFrom.txt";
            "itemType" = "file";
            "lastWriteTime" = "2016-01-01 01:01:01";
            "value" = "in To";
          }
        ) | Create-Files -Path $toPath
        Backup-Folders -PropertiesFile $SimpleItemsFile
        $fromFile = Join-Path -Path $fromPath -ChildPath "newerInFrom.txt"
        $toFile = Join-Path -Path $toPath -ChildPath "newerInFrom.txt"
        $fromDate = Get-ItemPropertyValue -Path $fromFile -Name "LastWriteTime"
        $toDate = Get-ItemPropertyValue -Path $toFile -Name "LastWriteTime"
        $expectedFromDate = $(Get-Date "2016-12-24 12:34:56")
        $unexpectedToDate = $(Get-Date "2016-01-01 01:01:01")
        $fromDate | Should -Be $expectedFromDate
        $toDate | Should -Not -Be $unexpectedToDate
        $toDate | Should -Be $expectedFromDate
        $fromFile | Should -FileContentMatch "from From";
        $toFile | Should -FileContentMatch "from From";
      }
    }
  }
}
#
# TODO: Weitere Tests, FTP-Alternative, Refactoring, AfterAll-Aktionen
