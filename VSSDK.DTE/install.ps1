param($installPath, $toolsPath, $package, $project)

foreach ($reference in $project.Object.References)
{
	switch -regex ($reference.Name.ToLowerInvariant())
	{
	"^(?:stdole|envdte)$"
		{
			$reference.EmbedInteropTypes = $false;
		}
	default
		{
			# ignore
		}
	}
}
