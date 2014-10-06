param(
	[string]$MSEnv = 'C:\Program Files (x86)\Common Files\microsoft shared\MSEnv',
	[string]$VSSDK = 'C:\Program Files (x86)\Microsoft Visual Studio 2010 SDK SP1',
	[string]$VSIDE = 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE'
)

$nuget = '.\.nuget\NuGet.exe'
$Version = '10.0.2'
$OutDir = 'packages-2010'

$packages = @(
	# Visual Studio 2010 Metadata Package
	'VSSDK.IDE.10'
	'VSSDK.IDE.10Only'

	# Immutable COM-interop packages
	'VSSDK.Debugger.Interop.10'
	'VSSDK.DTE.10'
	'VSSDK.VSLangProj.10'
	'VSSDK.Shell.Interop.10'
	'VSSDK.TextManager.Interop.10'

	# Immutable managed assemblies that ship with newer versions of Visual Studio
	'VSSDK.Shell.Immutable.10'

	# Managed packages with binding redirects in newer versions of Visual Studio
	'VSSDK.ComponentModelHost.10'
	'VSSDK.CoreUtility.10'
	'VSSDK.Data.10'
	'VSSDK.DebuggerVisualizers.10'
	'VSSDK.Editor.10'
	'VSSDK.Language.10'
	'VSSDK.LanguageService.10'
	'VSSDK.NavigateTo.10'
	'VSSDK.Shell.10'
	'VSSDK.Text.10'
	'VSSDK.TemplateWizardInterface.10'

	# Managed packages which are not compatible with newer versions of Visual Studio
	'VSSDK.Language.CallHierarchy.10'
	'VSSDK.Language.CSharp.10'
)

$wrappedPackages = @{
	# Managed packages with binding redirects in newer versions of Visual Studio
	# Note: the commented lines are packages which use unique assembly names in addition to binding redirects, so
	# wrapping is not necessary.
	'VSSDK.ComponentModelHost.10' = 'VSSDK.ComponentModelHost'
	'VSSDK.CoreUtility.10' = 'VSSDK.CoreUtility'
	'VSSDK.Data.10' = 'VSSDK.Data'
	'VSSDK.DebuggerVisualizers.10' = 'VSSDK.DebuggerVisualizers'
	'VSSDK.Editor.10' = 'VSSDK.Editor'
	'VSSDK.Language.10' = 'VSSDK.Language'
	#'VSSDK.LanguageService.10' = 'VSSDK.LanguageService'
	'VSSDK.NavigateTo.10' = 'VSSDK.NavigateTo'
	#'VSSDK.Shell.10' = 'VSSDK.Shell'
	'VSSDK.Text.10' = 'VSSDK.Text'
	'VSSDK.TemplateWizardInterface.10' = 'VSSDK.TemplateWizardInterface'
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
