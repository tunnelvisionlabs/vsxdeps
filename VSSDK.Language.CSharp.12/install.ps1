param($installPath, $toolsPath, $package, $project)

foreach ($reference in $project.Object.References)
{
	switch -regex ($reference.Name.ToLowerInvariant())
	{
	"^microsoft\.visualstudio\.csharp\.services\.language\.interop$"
		{
			$reference.EmbedInteropTypes = $false;
		}
	default
		{
			# ignore
		}
	}
}
