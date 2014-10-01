<#############################################################################
The TypePx module adds properties and methods to the most commonly used types
to make common tasks easier. Using these type extensions together can provide
an enhanced syntax in PowerShell that is both easier to read and self-
documenting. TypePx also provides commands to manage type accelerators. Type
acceleration also contributes to making scripting easier and they help produce
more readable scripts, particularly when using a library of .NET classes that
belong to the same namespace.

Copyright © 2014 Kirk Munro.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License in the
license folder that is included in the ScsmPx module. If not, see
<https://www.gnu.org/licenses/gpl.html>.
#############################################################################>

<#
.SYNOPSIS
    Gets the list of type accelerators that are defined in the current session.
.DESCRIPTION
    The Get-TypeAccelerator command gets the list of type accelerators that are defined in the current session.

    By default, Get-TypeAccelerator will return all type accelerators. If you want a filtered list of type accelerators, you can use the Name, Namespace, and/or Type parameters to filter the type accelerators that are returned by Get-TypeAccelerator.
.INPUTS
    None
.OUTPUTS
    TypeAccelerator
.EXAMPLE
    PS C:\> Get-TypeAccelerator

    This command gets a list of all type accelerators that are defined in the current session.
.EXAMPLE
    PS C:\> Get-TypeAccelerator -Name switch

    This command gets the "switch" type accelerator that is defined in the current session.
.EXAMPLE
    PS C:\> Get-TypeAccelerator -Namespace System.Management.Automation

    This command gets any type accelerators that are defined in the current session that reference types belonging to the System.Management.Automation namespace.
.EXAMPLE
    PS C:\> Get-TypeAccelerator -Type System.Management.ManagementObject

    This command gets any type accelerators that are defined in the current session that reference the System.Management.ManagementObject type.
.LINK
    Add-TypeAccelerator
.LINK
    Remove-TypeAccelerator
.LINK
    Set-TypeAccelerator
.LINK
    Use-Namespace
#>
function Get-TypeAccelerator {
    [CmdletBinding()]
    [OutputType('TypeAccelerator')]
    param(
        # The name of the type accelerator.
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [System.String[]]
        $Name,

        # The namespace containing the type that the type accelerator references.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [System.String[]]
        $Namespace,

        # The type that the type accelerator references.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Type[]]
        $Type
    )
    try {
        #region Get all type accelerators.

        $typeAccelerators = $script:typeAcceleratorsType::Get | Select-Object -ExpandProperty Keys | Sort-Object

        #endregion

        #region If -Name was used, filter the list of type accelerators.

        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Name')) {
            $typeAccelerators = @(
                $typeAccelerators.LikeAny($Name)
            )
        }

        #endregion

        #region If -Namespace was used, filter the list of type accelerators.

        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Namespace')) {
            :acceleratorLoop foreach ($key in $typeAccelerators) {
                foreach ($item in $Namespace | ForEach-Object {[System.Text.RegularExpressions.Regex]::Escape($_) -replace '\*','.*' -replace '\?','.'}) {
                    if (($script:typeAcceleratorsType::Get[$key].FullName -match "^$item\.") -or
                        (($item -notmatch '^System\.') -and ($script:typeAcceleratorsType::Get[$key].FullName -match "^System\.$item\."))) {
                        continue acceleratorLoop
                    }
                }
                $typeAccelerators = $typeAccelerators | Where-Object {$_ -ne $key}
            }
        }

        #endregion

        #region If -Type was used, filter the list of type accelerators.

        $filter = {$typeAccelerators -contains $_.Key}
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Type')) {
            $filter = {($typeAccelerators -contains $_.Key) -and ($Type -contains $_.Value)}
        }

        #endregion

        #region Enumerate all type accelerators and return only those that pass all filters.

        $script:typeAcceleratorsType::Get.GetEnumerator() `
            | Where-Object $filter `
            | Sort-Object -Property Key `
            | ForEach-Object {
                [pscustomobject]@{
                    PSTypeName = 'TypeAccelerator'
                          Name = $_.Key
                          Type = $_.Value
                }
            }

        #endregion
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

Export-ModuleMember -Function Get-TypeAccelerator

New-Alias -Name gtx -Value Get-TypeAccelerator -ErrorAction Ignore
if ($?) {
    Export-ModuleMember -Alias gtx
}