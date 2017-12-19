Set-StrictMode -Version Latest

Class Files {
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
