# References

This document contains references used while writing this Windows PowerShell script. As I am not _fluent_ talking PowerShell these references helped me along while writing the script.

## Comment Based Help

PowerShell provides a format for documentation within scripts, so that you can get help directly from the command line. To do so you have to stick to some formatting rules.

* [About Comment Based Help | Microsoft Docs][MS-PS-COMMENTS]

## PowerShell Tips And Tricks

* [Powershell: resolve path that might not exist? - Stack Overflow][SO-RESOLVE-PATH]
* [Simplify Your PowerShell Script with Parameter Validation – Hey, Scripting Guy! Blog][BLOG-VALIDATE-PARAMETERS]
* [about_Functions_Advanced_Parameters][]
* [Why does casting PSCustomObjects to custom type with DateTime in PowerShell fails? - Stack Overflow][SO-PSCustomObject-1]
* [powershell - PSCustomObject to Hashtable - Stack Overflow][SO-PSCustomObject-1]
* [Powershell: Creating parameter validators and transforms][KM-Parameter-Validation]
* [What does PowerShell's \[CmdletBinding()\] Do?][DJ-CMDLETBINDING]
* [All .Net Exceptions List][NET-EXCEPTIONS]
* [Building PowerShell Functions That Support the Pipeline -- Microsoft Certified Professional Magazine Online][MS-FUNC-PIPELINE]
* [Write PowerShell Functions That Accept Pipelined Input – Hey, Scripting Guy! Blog][HSG-FUNC-PIPELINE]
* [Best IDE/editor for PowerShell? - Spiceworks][POWERSHELL_IDES]
* [Weekend Scripter: Easily Add Whatif Support to Your PowerShell Functions – Hey, Scripting Guy! Blog][PS-WHATIF]

### Pester

* [\[Bug\] PowerShell Scripts in ScriptsToProcess attribute appear as loaded modules – d-fens GmbH][BUG-ScriptsToProcess]

<!-- Links -->

[MS-PS-COMMENTS]: <https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-6> "About Comment Based Help | Microsoft Docs"
[SO-RESOLVE-PATH]: <https://stackoverflow.com/questions/3038337/powershell-resolve-path-that-might-not-exist> "Powershell: resolve path that might not exist? - Stack Overflow"
[BLOG-VALIDATE-PARAMETERS]: <https://blogs.technet.microsoft.com/heyscriptingguy/2011/05/15/simplify-your-powershell-script-with-parameter-validation/> "Simplify Your PowerShell Script with Parameter Validation – Hey, Scripting Guy! Blog"
[about_Functions_Advanced_Parameters]: <https://technet.microsoft.com/en-us/library/dd347600.aspx> "about_Functions_Advanced_Parameters"
[SO-PSCustomObject-1]: <https://stackoverflow.com/questions/38217736/why-does-casting-pscustomobjects-to-custom-type-with-datetime-in-powershell-fail> "Why does casting PSCustomObjects to custom type with DateTime in PowerShell fails? - Stack Overflow"
[SO-PSCustomObject-1]: <https://stackoverflow.com/questions/3740128/pscustomobject-to-hashtable> "powershell - PSCustomObject to Hashtable - Stack Overflow"
[KM-Parameter-Validation]: <https://kevinmarquette.github.io/2017-02-20-Powershell-creating-parameter-validators-and-transforms/> "Powershell: Creating parameter validators and transforms"
[DJ-CMDLETBINDING]: <http://www.itprotoday.com/management-mobility/what-does-powershells-cmdletbinding-do> "What does PowerShell's [CmdletBinding()] Do?"
[BUG-ScriptsToProcess]: <https://d-fens.ch/2014/11/26/bug-powershell-scripts-in-scriptstoprocess-attribute-appear-as-loaded-modules/> "[Bug] PowerShell Scripts in ScriptsToProcess attribute appear as loaded modules – d-fens GmbH"
[NET-EXCEPTIONS]: <https://kevinmarquette.github.io/2017-04-07-all-dotnet-exception-list/?utm_source=blog&amp;amp;amp;utm_medium=blog&amp;amp;amp;utm_content=crosspost> "All .Net Exceptions List"
[MS-FUNC-PIPELINE]: <https://mcpmag.com/articles/2015/05/20/functions-that-support-the-pipeline.aspx> "Building PowerShell Functions That Support the Pipeline -- Microsoft Certified Professional Magazine Online"
[HSG-FUNC-PIPELINE]: <https://blogs.technet.microsoft.com/heyscriptingguy/2010/12/31/write-powershell-functions-that-accept-pipelined-input/> "Write PowerShell Functions That Accept Pipelined Input – Hey, Scripting Guy! Blog"
[POWERSHELL_IDES]: <https://community.spiceworks.com/topic/1962830-best-ide-editor-for-powershell> "Best IDE/editor for PowerShell? - Spiceworks"
[PS-WHATIF]: <https://blogs.technet.microsoft.com/heyscriptingguy/2012/07/08/weekend-scripter-easily-add-whatif-support-to-your-powershell-functions/> "Weekend Scripter: Easily Add Whatif Support to Your PowerShell Functions – Hey, Scripting Guy! Blog"