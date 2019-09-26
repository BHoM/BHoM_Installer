Param([string]$repo)

$msbuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"

$parts = $repo.split("/")
$org = $parts[0]
$repo = $parts[1]

$slnPath = "$ENV:BUILD_SOURCESDIRECTORY\$repo\$repo.sln"

# **** Cloning Repo ****
Write-Output ("Cloning " + $repo + " to " + $ENV:BUILD_SOURCESDIRECTORY + "\" + $repo)
git clone -q --branch=master https://github.com/$org/$repo.git $ENV:BUILD_SOURCESDIRECTORY\$repo

# **** Restore NuGet ****
Write-Output ("Restoring NuGet packages for " + $repo)
& NuGet.exe restore $slnPath

# **** Building .sln ****
write-Output ("Building " + $repo + ".sln")
& $msbuildPath -nologo $slnPath /verbosity:minimal
