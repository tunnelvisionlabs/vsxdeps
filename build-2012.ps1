param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 11.0\VSSDK',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '11.0.0-alpha001'
$OutDir = 'packages-2012'

$packages = @(
	# Visual Studio 2012 Metadata Package
	'Tvl.VisualStudio.Dependencies.11'

	# Immuatble COM-interop packages
	'Tvl.VisualStudio.Dependencies.VSLangProj.11'

	# Managed packages with binding redirects in newer versions of Visual Studio
	'Tvl.VisualStudio.Dependencies.CoreUtility.11'
	'Tvl.VisualStudio.Dependencies.Data.11'
	'Tvl.VisualStudio.Dependencies.Text.11'

	# Managed packages which are not compatible with newer versions of Visual Studio
	'Tvl.VisualStudio.Dependencies.Language.CallHierarchy.11'
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
