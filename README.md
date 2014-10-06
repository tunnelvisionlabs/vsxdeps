# Visual Studio SDK Dependencies

This project is a collection of NuGet package specifications (`*.nuspec`) for many of the packages used in extensions for Visual Studio 2005 and newer.

## Benefits

These packages offer several benefits over traditional methods involving references to assemblies located on local systems, including but not limited to the following.

1. **Simplified package management for cross-version extensions.** [Versioned](http://blog.slaks.net/2014-02-25/extending-visual-studio-part-4-writing-cross-version-extensions/) and [unversioned](http://blog.slaks.net/2014-02-26/extending-visual-studio-part-5-dealing-with-unversioned-assemblies/) assemblies are tracked through NuGet package metadata, and the description of each package includes tags indicating the version(s) of Visual Studio the package is known to work with.

2. **Support building Visual Studio extensions for multiple versions of Visual Studio, without requiring installation of all versions and their SDKs.** For example, an extension could target Visual Studio 2010-2013, but be developed on a system that only has Visual Studio 2012 installed.

3. **Automatic references to dependencies when a package is installed.** Each time a new assembly is referenced, all dependencies which are exposed through the public interface of that package are automatically added as well.

## Determining the supported versions of Visual Studio

The project includes several NuGet packages which help establish the version(s) of Visual Studio your extension is able to support. These packages do not add any assembly references to your project, but by opening the **Tools &rarr; NuGet Package Manager &rarr; Manage NuGet Packages for Solution...**, you can determine which (if any) projects in your solution contain references to the following packages. The packages fall into two groups based on compatibility with other versions of Visual Studio.

### VSSDK.IDE.{Version}Only

These packages indicate support for a single version of Visual Studio. Extensions using these packages are unlikely to work in multiple versions of Visual Studio, whether older or newer.

1. **VSSDK.IDE.12Only:** This package indicates that your extension *may* reference an assembly that *only* shipped with Visual Studio 2013. Any code which uses those features will result in a `TypeLoadException` if you try to run it in any version of Visual Studio other than 2013.
2. **VSSDK.IDE.11Only:** This package indicates that your extension *may* reference an assembly that *only* shipped with Visual Studio 2012. Any code which uses those features will result in a `TypeLoadException` if you try to run it in any version of Visual Studio other than 2012.
3. **VSSDK.IDE.10Only:** This package indicates that your extension *may* reference an assembly that *only* shipped with Visual Studio 2010. Any code which uses those features will result in a `TypeLoadException` if you try to run it in any version of Visual Studio other than 2010.

### VSSDK.IDE.{Version}

These packages indicate support for a *minimum* version of Visual Studio. Extensions using these packages are known to work with newer versions of Visual Studio up to 2013, and may continue to work with future releases (although no guarantees are made to this).

1. **VSSDK.IDE.12:** This package indicates that your extension *may* reference an assembly that *first* shipped with Visual Studio 2013. Based on conventions used in Visual Studio 2013, it is likely that this extension will continue to work with future Visual Studio releases without API changes. However, any code which uses these new features will result in a `TypeLoadException` if you try to run it in any version of Visual Studio *prior* to 2013.
2. **VSSDK.IDE.11:** This package indicates that your extension *may* reference an assembly that *first* shipped with Visual Studio 2012. These APIs are known to still be supported in Visual Studio 2013, and based on current conventions it is likely that this extension will continue to work with future Visual Studio releases without API changes. However, any code which uses these new features will result in a `TypeLoadException` if you try to run it in any version of Visual Studio *prior* to 2012.
3. **VSSDK.IDE.10:** This package indicates that your extension *may* reference an assembly that *first* shipped with Visual Studio 2010. These APIs are known to still be supported in Visual Studio 2013, and based on current conventions it is likely that this extension will continue to work with future Visual Studio releases without API changes. However, any code which uses these new features will result in a `TypeLoadException` if you try to run it in any version of Visual Studio *prior* to 2010.
4. **VSSDK.IDE.9:** This package indicates that your extension *may* reference an assembly that *first* shipped with Visual Studio 2008. These APIs are known to still be supported in Visual Studio 2013, and based on current conventions it is likely that this extension will continue to work with future Visual Studio releases without API changes. However, any code which uses these new features will result in a `TypeLoadException` if you try to run it in any version of Visual Studio *prior* to 2008.
5. **VSSDK.IDE.8:** This package indicates that your extension *may* reference an assembly that *first* shipped with Visual Studio 2005. These APIs are known to still be supported in Visual Studio 2013, and based on current conventions it is likely that this extension will continue to work with future Visual Studio releases without API changes. However, any code which uses these new features will result in a `TypeLoadException` if you try to run it in any version of Visual Studio *prior* to 2005.
6. **VSSDK.IDE:** This package indicates that your extension *may* reference an assembly that *first* shipped with Visual Studio .NET or Visual Studio .NET 2003. These APIs are known to still be supported in Visual Studio through version 2013, and based on current conventions it is likely that this extension will continue to work with future Visual Studio releases without API changes. However, any code which uses these new features will result in a `TypeLoadException` if you try to run it in any version of Visual Studio *prior* to the version in which it was introduced (this framework does not currently support writing extensions Visual Studio versions prior to 2005, so this limitation has limited applicability).

### Managing Visual Studio Versions

The packages above are described in terms of *restrictions*. For example, if your extension references both **VSSDK.IDE.10** and **VSSDK.IDE.11**, the stronger restrictions imposed by **VSSDK.IDE.11** are the ones that apply to your extension as a whole. If you find that a reference is more restrictive than you intended for your project, you can use the NuGet Package Manager to attempt to uninstall the reference. The uninstallation will fail if your extension references assemblies that impose those restrictions, and inform you of the changes required before the restriction can be lifted. For the previously described case, uninstalling **VSSDK.IDE.11** would result in the extension supporting Visual Studio 2010 and newer, as opposed to just Visual Studio 2012 and newer.

## Supporting Additional Packages

The current packages only provide a subset of the available assemblies used by Visual Studio extensions. If your extension requires references to Visual Studio assemblies which are not currently provided through NuGet, please [create a new issue](https://github.com/tunnelvisionlabs/vsxdeps/issues) requesting a package be created for the new assembly. Make sure to include the complete name of every assembly file which should be included in the package.

## Managed Packages with Binding Redirects

Certain Visual Studio assemblies use the same assembly name, but update the assembly version with each supported release of Visual Studio. These dependencies are distributed using a two-part strategy to meet the needs of different extension development and distribution strategies.

The managed assemblies themselves are packaged in a *version independent* NuGet package, where the name of the NuGet package does not include the version number, but the major version of the package corresponds to the targeted release of Visual Studio. In addition to the package containing the assemblies, a metadata-only *version dependent* NuGet package is created for each supported version of Visual Studio.

### Extension development

During extension and/or library development, projects should declare dependencies on the *version dependent* NuGet packages for the managed packages they use. This strategy ensures that NuGet will use the dependencies corresponding to the intended target version of Visual Studio, and will not be able to upgrade the dependency to a version incompatible with the requirements of the project. For example, a project which adds the **VSSDK.Text.10** NuGet package to support Visual Studio 2010+ will not be allowed to update the underlying version independent **VSSDK.Text** dependency to version 11.x, which requires Visual Studio 2012.

Reusable extensions, such as those in the VSBase project, should use a NuGet package specification which only references *version independent* packages. This strategy ensures that the distributed package will not prevent extension developers from creating Visual Studio extensions that only support a subset of the versions of Visual Studio supported by the reusable extension. For example, a NuGet package which includes a dependency on **VSSDK.Text** version `[11,)` is compatible with projects using either the **VSSDK.Text.11** or **VSSDK.Text.12** packages, but cannot be used in a project which uses **VSSDK.Text.10**.
