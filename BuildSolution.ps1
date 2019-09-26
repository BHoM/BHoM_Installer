
$msbuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"
$slnPath = "$ENV:BUILD_SOURCESDIRECTORY\BHoM_Installer"

cd $slnPath
write-Output ("Building Installer")

If ($env:ReleaseType) {
  $releaseType = $env:ReleaseType
} Else {
  $releaseType = "alpha"
}

If ($releaseType -eq "alpha") {
  $patchVersion = $env:dateVersion
} Else {
  $patchVersion = 0
}

If ($env:PatchVersion) {
  $patchVersion = $env:PatchVersion
}


& $msbuildPath -nologo /verbosity:minimal /p:RunWixToolsOutOfProc=true /p:DeployOnBuild=true /p:ReleaseType=$releaseType /p:PatchVersion=$patchVersion /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true
