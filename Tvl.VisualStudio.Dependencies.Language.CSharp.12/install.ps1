param($installPath, $toolsPath, $package, $project)

foreach ($reference in $project.Object.References)
{
	switch -regex ($reference.Name.ToLowerInvariant())
	{
	"^microsoft\.visualstudio\.csharp\.services\.language$"
		{
			$reference.CopyLocal = $false;
		}
	"^microsoft\.visualstudio\.csharp\.services\.language\.interop$"
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
