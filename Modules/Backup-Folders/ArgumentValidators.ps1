Class ValidateConfigurationAttribute : System.Management.Automation.ValidateArgumentsAttribute {
  [Void] Validate([Object] $arguments, [System.Management.Automation.EngineIntrinsics] $engineIntrinsics) {
    $path = $arguments
    If ([String]::IsNullOrWhiteSpace($path)) {
      Throw [System.ArgumentNullException]::New()
    }
    If (-not (Test-Path -Path $path)) {
      Throw [System.IO.FileNotFoundException]::New()
    }        

    $configuration = Get-Content "$path" | ConvertFrom-Json
    If (-not (Get-Member -InputObject $configuration -Name "items" -Membertype Properties)) {
      Throw [System.IO.InvalidDataException]::New()
    }
    If (Get-Member -InputObject $configuration -Name "afterAll" -Membertype Properties) {
      # Provoke failure, if it does not match.
      $afterAll = [AfterAll] $configuration.afteAll
    }
  }
}
