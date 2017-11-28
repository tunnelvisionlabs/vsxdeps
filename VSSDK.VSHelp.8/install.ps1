param($installPath, $toolsPath, $package, $project)

foreach ($reference in $project.Object.References)
{
	switch -regex ($reference.Name.ToLowerInvariant())
	{
	"^microsoft.visualstudio.vshelp80$"
		{
			$reference.EmbedInteropTypes = $false;
		}
	default
		{
			# ignore
		}
	}
}
