# **** READ DEPENDENCIES ARRAY ****
$depsFilePath = "$ENV:BUILD_SOURCESDIRECTORY\BHoM_Installer\dependencies.txt"
$dependencies = gc $depsFilePath

# **** READ INCLUDE ARRAY ****
$incFilePath = "$ENV:BUILD_SOURCESDIRECTORY\BHoM_Installer\include.txt"
$includes = gc $incFilePath

# **** READ UIs ARRAY ****
$uisFilePath = "$ENV:BUILD_SOURCESDIRECTORY\BHoM_Installer\userInterfaces.txt"
$uis = gc $uisFilePath


# **** Constants ****
$msbuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"

git config --global user.email "BHoMBot@bhom.xyz"
git config --global user.name "BHoMBot"

# **** Clone Datasets ****
Write-Output ("Cloning BHoM_Datasets to " + $ENV:BUILD_SOURCESDIRECTORY + "\BHoM_Datasets")
git clone -q --branch=master https://github.com/BHoM/BHoM_Datasets.git  $ENV:BUILD_SOURCESDIRECTORY\BHoM_Datasets


# **** Iterate over all dependencies ****
write-Output ("**** ITERATE OVER ALL DEPENDENCIES ****")
ForEach ($repo in $dependencies) 
{
  & "$ENV:BUILD_SOURCESDIRECTORY\BHoM_Installer\CloneAndBuildRepo.ps1" -repo $repo
}


# **** Iterate over all Toolkits to Include ****
write-Output ("**** ITERATE OVER ALL TOOLKITS TO INCLUDE ****")
ForEach ($repo in $includes) {
  & "$ENV:BUILD_SOURCESDIRECTORY\BHoM_Installer\CloneAndBuildRepo.ps1" -repo $repo
}


# **** Build alternate Revit Configurations ****
$repo = "Revit_Toolkit"
$slnPath = "$ENV:BUILD_SOURCESDIRECTORY\$repo\$repo.sln"
$configurations = @("Release2018","Release2019")

ForEach ($config in $configurations) 
{
  write-Output ("Building " + $repo + " " + $config)
  & $msbuildPath -nologo $slnPath /verbosity:minimal /p:Configuration=$config
}


# **** Iterate over all UIs ****
write-Output ("**** ITERATE OVER ALL USER INTERFACES ****")
ForEach ($repo in $uis) 
{
  & "$ENV:BUILD_SOURCESDIRECTORY\BHoM_Installer\CloneAndBuildRepo.ps1" -repo $repo
}

