param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 12.0\VSSDK',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '12.0.0-alpha001'
$OutDir = 'packages-2013'

$packages = @(
	# Visual Studio 2013 Metadata Package
	'Tvl.VisualStudio.Dependencies.12'

	# Managed packages with binding redirects in newer versions of Visual Studio
	'Tvl.VisualStudio.Dependencies.CoreUtility.12'
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
