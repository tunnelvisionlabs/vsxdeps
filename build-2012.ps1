param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 11.0\VSSDK',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '11.0.0'
$OutDir = 'packages-2012'

$packages = @(
	# Visual Studio 2012 Metadata Package
	'VSSDK.IDE.11'
	'VSSDK.IDE.11Only'

	# Immuatble COM-interop packages
	'VSSDK.Debugger.Interop.11'
	'VSSDK.Shell.Interop.11'
	'VSSDK.VSLangProj.11'

	# Immutable managed assemblies that ship with newer versions of Visual Studio
	'VSSDK.Shell.Immutable.11'

	# Managed packages with binding redirects in newer versions of Visual Studio
	'VSSDK.ComponentModelHost.11'
	'VSSDK.CoreUtility.11'
	'VSSDK.Data.11'
	'VSSDK.Editor.11'
	'VSSDK.GraphModel.11'
	'VSSDK.Language.11'
	'VSSDK.LanguageService.11'
	'VSSDK.NavigateTo.11'
	'VSSDK.Shell.11'
	'VSSDK.Text.11'

	# Managed packages which are not compatible with newer versions of Visual Studio
	'VSSDK.Language.CallHierarchy.11'
	'VSSDK.Language.CSharp.11'
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
