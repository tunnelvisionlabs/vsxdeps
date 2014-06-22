param($installPath, $toolsPath, $package, $project)

foreach ($reference in $project.Object.References)
{
	switch -regex ($reference.Name.ToLowerInvariant())
	{
	"^(?:envdte(?:90|90a))$"
		{
			$reference.CopyLocal = $false;
			$reference.EmbedInteropTypes = $false;
		}
	default
		{
			# ignore
		}
	}
}
