param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 11.0\VSSDK',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '11.0.0-alpha001'
$OutDir = 'packages-2012'

$packages = @(
	'Tvl.VisualStudio.Dependencies.11'
	'Tvl.VisualStudio.Dependencies.VSLangProj.11'
)

# Create the output folder if it doesn't exist
if (!(Test-Path $OutDir))
{
	mkdir $OutDir | Out-Null
}

foreach ($package in $packages)
{
	&$nuget pack "$package\$package.nuspec" -Version $Version -OutputDirectory $OutDir -Prop MSEnv=$MSEnv -Prop VSSDK=$VSSDK -Prop VSIDE=$VSIDE
}
