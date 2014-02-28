param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 2010 SDK SP1',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '10.0.0'
$OutDir = 'packages-2010'

$packages = @(
	# Visual Studio 2010 Metadata Package
	'VSSDK.IDE.10'
	'VSSDK.IDE.10Only'

	# Immuatble COM-interop packages
	'VSSDK.Debugger.Interop.10'
	'VSSDK.Designer.10'
	'VSSDK.DTE.10'
	'VSSDK.VSLangProj.10'
	'VSSDK.OLE.Interop.10'
	'VSSDK.Shell.Interop.10'
	'VSSDK.TextManager.Interop.10'

	# Immutable managed assemblies that ship with newer versions of Visual Studio
	'VSSDK.Shell.Immutable.10'

	# Managed packages with binding redirects in newer versions of Visual Studio
	'VSSDK.ComponentModelHost.10'
	'VSSDK.CoreUtility.10'
	'VSSDK.Data.10'
	'VSSDK.Editor.10'
	'VSSDK.Language.10'
	'VSSDK.LanguageService.10'
	'VSSDK.NavigateTo.10'
	'VSSDK.Shell.10'
	'VSSDK.Text.10'

	# Managed packages which are not compatible with newer versions of Visual Studio
	'VSSDK.Language.CallHierarchy.10'
	'VSSDK.Language.CSharp.10'
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
