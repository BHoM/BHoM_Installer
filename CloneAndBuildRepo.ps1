Param([string]$repo)

$msbuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"

$parts = $repo.split("/")
$org = $parts[0]
$repo = $parts[1]

$slnPath = "$ENV:BUILD_SOURCESDIRECTORY\$repo\$repo.sln"

$releaseType = $ENV:ReleaseType
$version = $ENV:Version
$patch = $ENV:PatchVersion

# **** Cloning Repo ****
Write-Output ("Cloning " + $repo + " to " + $ENV:BUILD_SOURCESDIRECTORY + "\" + $repo)
git clone -q --branch=master https://github.com/$org/$repo.git $ENV:BUILD_SOURCESDIRECTORY\$repo

If($releaseType -eq "beta")
{
	# Try and checkout tags

	$cwd = Get-Location

	Write-Output("Changing into repo directory")
	Set-Location $ENV:BUILD_SOURCESDIRECTORY\$repo

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
    		If($splitTag[3] -le $patch)
    		{
    			$tag = $repoTags[$i]
    			break
    		}
    	}
    }

    If($tag -eq "")
    {
    	Write-Output("A suitable Tag for " + $version + ".B." + $patch + " could not be found, staying on master")
    }
    Else
    {
		Write-Output ("Checking out at tag " + $tag)
		git checkout -q tags/$tag
	}
	
	Write-Output ("Changing back directory location")
	Set-Location $cwd
}

# **** Restore NuGet ****
Write-Output ("Restoring NuGet packages for " + $repo)
& NuGet.exe restore $slnPath

# **** Building .sln ****
write-Output ("Building " + $repo + ".sln")
& $msbuildPath -nologo $slnPath /verbosity:minimal
