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
	'Tvl.VisualStudio.Dependencies.12'

	# Immuatble COM-interop packages
	'Tvl.VisualStudio.Dependencies.Shell.Interop.12'

	# Immutable managed assemblies that ship with newer versions of Visual Studio
	'Tvl.VisualStudio.Dependencies.Shell.Immutable.12'

	# Managed packages with binding redirects in newer versions of Visual Studio
	'Tvl.VisualStudio.Dependencies.CoreUtility.12'
	'Tvl.VisualStudio.Dependencies.Data.12'
	'Tvl.VisualStudio.Dependencies.Editor.12'
	'Tvl.VisualStudio.Dependencies.GraphModel.12'
	'Tvl.VisualStudio.Dependencies.Language.12'
	'Tvl.VisualStudio.Dependencies.Shell.12'
	'Tvl.VisualStudio.Dependencies.Text.12'
	'Tvl.VisualStudio.Dependencies.Threading.12'

	# Managed packages which are not compatible with newer versions of Visual Studio
	'Tvl.VisualStudio.Dependencies.Language.CallHierarchy.12'
	'Tvl.VisualStudio.Dependencies.Language.CSharp.12'
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
