param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Visual Studio 2005 SDK',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 8\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '8.0.1'
$OutDir = 'packages-2005'

$packages = @(
	# Visual Studio 2005 Metadata Package
	'VSSDK.IDE.8'
	'VSSDK.IDE.8Only'

	# Immutable COM-interop packages
	'VSSDK.Debugger.Interop.8'
	'VSSDK.DTE.8'
	'VSSDK.Shell.Interop.8'
	'VSSDK.TextManager.Interop.8'
	'VSSDK.VSLangProj.8'

	# Managed packages with binding redirects in newer versions of Visual Studio
	'VSSDK.DebuggerVisualizers.8'
	'VSSDK.Shell.8'
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
