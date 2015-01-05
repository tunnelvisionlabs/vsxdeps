param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\VSSDK',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '14.0.4-preview'
$OutDir = 'packages-2015'

$packages = @(
	# Visual Studio 2015 Metadata Package
	'VSSDK.IDE.14'
	'VSSDK.IDE.14Only'

	# Immutable COM-interop packages
	'VSSDK.Debugger.Interop.14'

	# Immutable managed assemblies that ship with newer versions of Visual Studio
	'VSSDK.Shell.Immutable.14'

	# Managed packages with binding redirects in newer versions of Visual Studio
	'VSSDK.ComponentModelHost.14'
	'VSSDK.CoreUtility.14'
	'VSSDK.Data.14'
	'VSSDK.DebuggerVisualizers.14'
	'VSSDK.Editor.14'
	'VSSDK.GraphModel.14'
	'VSSDK.Language.14'
	'VSSDK.LanguageService.14'
	'VSSDK.NavigateTo.14'
	'VSSDK.Settings.14'
	'VSSDK.Shell.14'
	'VSSDK.Text.14'
	'VSSDK.Threading.14'
	'VSSDK.TemplateWizardInterface.14'

	# Managed packages which are not compatible with newer versions of Visual Studio
	'VSSDK.Language.CallHierarchy.14'
	'VSSDK.ServerExplorer.14'
)

$wrappedPackages = @{
	# Managed packages with binding redirects in newer versions of Visual Studio
	# Note: the commented lines are packages which use unique assembly names in addition to binding redirects, so
	# wrapping is not necessary.
	'VSSDK.ComponentModelHost.14' = 'VSSDK.ComponentModelHost'
	'VSSDK.CoreUtility.14' = 'VSSDK.CoreUtility'
	'VSSDK.Data.14' = 'VSSDK.Data'
	'VSSDK.DebuggerVisualizers.14' = 'VSSDK.DebuggerVisualizers'
	'VSSDK.Editor.14' = 'VSSDK.Editor'
	'VSSDK.GraphModel.14' = 'VSSDK.GraphModel'
	'VSSDK.Language.14' = 'VSSDK.Language'
	#'VSSDK.LanguageService.14' = 'VSSDK.LanguageService'
	'VSSDK.NavigateTo.14' = 'VSSDK.NavigateTo'
	#'VSSDK.Shell.14' = 'VSSDK.Shell'
	'VSSDK.Text.14' = 'VSSDK.Text'
	'VSSDK.Threading.14' = 'VSSDK.Threading'
	'VSSDK.TemplateWizardInterface.14' = 'VSSDK.TemplateWizardInterface'
}

# Create the output folder if it doesn't exist
if (!(Test-Path $OutDir))
{
	mkdir $OutDir | Out-Null
}

foreach ($package in $packages)
{
	&$nuget pack "$package\$package.nuspec" -Version $Version -OutputDirectory $OutDir -Prop MSEnv=$MSEnv -Prop VSSDK=$VSSDK -Prop VSIDE=$VSIDE
}

foreach ($package in $wrappedPackages.GetEnumerator())
{
	&$nuget pack "$($package.Key)\$($package.Value).nuspec" -Version $Version -OutputDirectory $OutDir -Prop MSEnv=$MSEnv -Prop VSSDK=$VSSDK -Prop VSSDK9=$VSSDK9 -Prop VSIDE=$VSIDE
}
