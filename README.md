# ps-backup-folders

PowerShell script to backup folders, for example to perform a backup to NAS.

## Usage

The following is a short example usage. For more help call `Get-Help Backup-Folders`.

### Syntax

```PowerShell
PS C:\> Backup-Folders [[-PropertiesFile] <String>]
```

### Description

This script creates backups of folders based on ROBOCOPY. It is configured through a JSON file which mght list several folders to backup/mirror.

The script is especially meant to have an easy way to do backups for example to a NAS or an external drive.

The default JSON file to read is `~/Backup-Folders.json` which might look like this:

```JSON
{
  "items": [
    {
      "from": "C:/FromSimple",
      "to": "C:/ToSimple",
    },
    {
      "from": {
        "path": "F:/rom"
        "removable": false
      },
      "to": {
        "path": "T:/owards"
        "removable": true
      }
    },
    {
      "from": "C:/FromLocal",
      "to": "//Fritz-nas/fritz.nas/Elements/ToNAS",
      "options": [
        "/MIR",
        "/R:5",
        "/W:15",
        "/FFT"
      ]
    }
  ],
  "afterAll": "shutdown"
}
```

This performs backups, either just between local files, or to a removable device and to a NAS drive with extra options for ROBOCOPY. The computer will be shutdown eventually after backup.

## Development

* This module has been developed with Powershell ISE.
* It uses [Pester][PESTER] for testing.

    Tests won't run with pre-installed Windows 10 Pester. Instead follow the installation instructions for an updated version of Pester.

## See Also

* [References used during development][REFERENCES]

[REFERENCES]: <./REFERENCES.md>
[PESTER]: <https://github.com/pester/Pester> "pester/Pester: Pester is the ubiquitous test and mock framework for PowerShell."