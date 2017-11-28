param($installPath, $toolsPath, $package, $project)

foreach ($reference in $project.Object.References)
{
	switch -regex ($reference.Name.ToLowerInvariant())
	{
	"^envdte100$"
		{
			$reference.EmbedInteropTypes = $false;
		}
	default
		{
			# ignore
		}
	}
}
