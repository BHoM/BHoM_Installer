
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

If($releaseType -eq "beta")
{
	# Try and checkout tags
	
	$version = $ENV:Version

	$cwd = Get-Location

	Write-Output("Changing into repo directory")
	Set-Location $ENV:BUILD_SOURCESDIRECTORY\BHoM_Installer

	# Update repo to get latest tags
	git fetch
	$tags = git tag -l
	$repoTags = $tags.split(" ")
	$tag = ""

	For ($i = $repoTags.Length - 1; $i -ge 0; $i--)
	{
    	$splitTag = $repoTags[$i].split(".")
    	If(($splitTag[0] + "." + $splitTag[1]) -eq $version)
    	{
    		If($splitTag[3] -le $patchVersion)
    		{
    			$tag = $repoTags[$i]
    			break
    		}
    	}
    }

    If($tag -eq "")
    {
    	Write-Output("A suitable Tag for " + $version + ".B." + $patchVersion + " could not be found, staying on master")
    }
    Else
    {
		Write-Output ("Checking out at tag " + $tag)
		git checkout -q tags/$tag
	}
	
	Write-Output ("Changing back directory location")
	Set-Location $cwd
}

& $msbuildPath -nologo /verbosity:minimal /p:RunWixToolsOutOfProc=true /p:DeployOnBuild=true /p:ReleaseType=$releaseType /p:PatchVersion=$patchVersion /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true
