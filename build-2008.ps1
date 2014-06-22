param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 2008 SDK',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '9.0.0'
$OutDir = 'packages-2008'

$packages = @(
	# Visual Studio 2008 Metadata Package
	'VSSDK.IDE.9'
	'VSSDK.IDE.9Only'
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
