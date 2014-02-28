param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 12.0\VSSDK',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '12.0.0'
$OutDir = 'packages-2013'

$packages = @(
	# Visual Studio 2013 Metadata Package
	'VSSDK.IDE.12'
	'VSSDK.IDE.12Only'

	# Immuatble COM-interop packages
	'VSSDK.Shell.Interop.12'

	# Immutable managed assemblies that ship with newer versions of Visual Studio
	'VSSDK.Shell.Immutable.12'

	# Managed packages with binding redirects in newer versions of Visual Studio
	'VSSDK.ComponentModelHost.12'
	'VSSDK.CoreUtility.12'
	'VSSDK.Data.12'
	'VSSDK.Editor.12'
	'VSSDK.GraphModel.12'
	'VSSDK.Language.12'
	'VSSDK.LanguageService.12'
	'VSSDK.Shell.12'
	'VSSDK.Text.12'
	'VSSDK.Threading.12'

	# Managed packages which are not compatible with newer versions of Visual Studio
	'VSSDK.Language.CallHierarchy.12'
	'VSSDK.Language.CSharp.12'
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
