param([string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv')

$nuget = '.\.nuget\NuGet.exe'
$Version = '12.0.0-alpha001'
$OutDir = 'packages-2013'

$packages = @(
	'Tvl.VisualStudio.Dependencies.12'
)

# Create the output folder if it doesn't exist
if (!(Test-Path $OutDir))
{
	mkdir $OutDir | Out-Null
}

foreach ($package in $packages)
{
	&$nuget pack "$package\$package.nuspec" -Version $Version -OutputDirectory $OutDir -Prop MSEnv=$MSEnv
}
