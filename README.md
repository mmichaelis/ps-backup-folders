# ps-sync-folders

PowerShell script to synchronize folders, for example to perform a backup to NAS.

## Usage

The following is a short example usage. For more help call `Get-Help Sync-Folders.ps1`.

### Syntax

```PowerShell
PS C:\> Sync-Folders.ps1 [[-PropertiesFile] <String>]
```

### Description

This script synchronises folders based on ROBOCOPY. It is configured through a JSON file which mght list several folders to synchronize/mirror.

The script is especially meant to have an easy way to do backups for example to a NAS or an external drive.

The default JSON file to read is `~/Sync-Folders.json` which for example might look like this:

```JSON
{
  "items": [
    {
      "from": "C:/FromSimple",
      "to": "C:/ToSimple",
    },
    {
      "from": "C:/FromLocal",
      "to": "//Fritz-nas/fritz.nas/Elements/ToNAS"
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

This performs two backups, one just on your local drive from one folder to another and the second one a more sophisticated example to NAS (here: USB drive attached to FritzBOX) with options to ROBOCOPY and an action to perform when synchronization is done, i. e. to shutdown the computer.

## See Also

* [References used during development][REFERENCES]

[REFERENCES]: <./REFERENCES.md>
