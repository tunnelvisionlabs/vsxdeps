param($installPath, $toolsPath, $package, $project)

foreach ($reference in $project.Object.References)
{
	switch -regex ($reference.Name.ToLowerInvariant())
	{
	"^microsoft\.visualstudio\.package\.languageservice\.12\.0$"
		{
			$reference.CopyLocal = $false;
		}
	default
		{
			# ignore
		}
	}
}
