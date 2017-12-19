Set-StrictMode -version Latest;

Class PathTransformAttribute : System.Management.Automation.ArgumentTransformationAttribute {
  [Object] Transform([System.Management.Automation.EngineIntrinsics] $engineIntrinsics, [Object] $inputData) {
    Write-Debug "Going to transform path as specified by $inputData."
    If ( $inputData -is [String] ) {
      If ( -not [String]::IsNullOrWhiteSpace( $inputData ) ) {
        [System.Management.Automation.PathInfo] $fullPath = Resolve-Path -Path $inputData -ErrorAction SilentlyContinue
        If ( -not ([String]::IsNullOrWhiteSpace( $fullPath )) ) {
          Return $fullPath.Path
        }
      }
    } Else {
      $fullName = $inputData.Fullname
      If ($fullName.count -gt 0) {
        Return $fullName
      }
    }
    Return $inputData
  }
}
