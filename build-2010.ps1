param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 2010 SDK SP1',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '10.0.0-alpha001'
$OutDir = 'packages-2010'

$packages = @(
	# Visual Studio 2010 Metadata Package
	'Tvl.VisualStudio.Dependencies.10'

	# Immuatble COM-interop packages
	'Tvl.VisualStudio.Dependencies.DTE.10'
	'Tvl.VisualStudio.Dependencies.VSLangProj.10'
	'Tvl.VisualStudio.Dependencies.OLE.Interop.10'
	'Tvl.VisualStudio.Dependencies.Shell.Interop.10'
	'Tvl.VisualStudio.Dependencies.TextManager.Interop.10'

	# Managed packages with binding redirects in newer versions of Visual Studio
	'Tvl.VisualStudio.Dependencies.CoreUtility.10'
	'Tvl.VisualStudio.Dependencies.Data.10'
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
