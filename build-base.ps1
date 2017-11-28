param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 2010 SDK SP1',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '7.0.4'
$OutDir = 'packages-base'

$packages = @(
	# Visual Studio Base Metadata Package
	'VSSDK.IDE'

	# Visual Studio Base Build Support
	'VSSDK.Build'

	# Immutable COM-interop packages
	'VSSDK.Designer'
	'VSSDK.DTE'
	'VSSDK.OLE.Interop'
	'VSSDK.Shell.Interop'
	'VSSDK.TextManager.Interop'
	'VSSDK.VSHelp'
	'VSSDK.VSLangProj'
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
