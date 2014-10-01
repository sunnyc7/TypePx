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
    Removes one or more type accelerators that are defined in the current session.
.DESCRIPTION
    The Remove-TypeAccelerator command removes one or more type accelerators that are defined in the current session.

    You must specify the Name of the type accelerator, the Namespace containing the type that the type accelerator references, or the Type that the type accelerator references in order to remove a type accelerator.
.INPUTS
    String,TypeAccelerator
.OUTPUTS
    None
.EXAMPLE
    PS C:\> Remove-TypeAccelerator -Name uri

    This command removes the "uri" type accelerator from the current session.
.EXAMPLE
    PS C:\> Remove-TypeAccelerator -Namespace System.Windows.Forms

    This command removes any type accelerators that reference types belonging to the System.Windows.Forms namespace.
.EXAMPLE
    PS C:\> Remove-TypeAccelerator -Type System.Windows.Forms.MessageBox

    This command removes any type accelerators that are defined in the current session that reference the System.Windows.Forms.MessageBox type.
.LINK
    Add-TypeAccelerator
.LINK
    Get-TypeAccelerator
.LINK
    Set-TypeAccelerator
.LINK
    Use-Namespace
#>
function Remove-TypeAccelerator {
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName='byName')]
    [OutputType([System.Void])]
    param(
        # The name of the type accelerator.
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='byName')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [System.String[]]
        $Name,

        # The namespace containing the type that the type accelerator references.
        [Parameter(Position=1, Mandatory=$true, ParameterSetName='byNamespace')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [System.String[]]
        $Namespace,

        # The type that the type accelerator references.
        [Parameter(Position=1, Mandatory=$true, ParameterSetName='byType')]
        [ValidateNotNullOrEmpty()]
        [System.Type[]]
        $Type
    )
    process {
        try {
            #region Define a collection to hold the names of accelerators we will remove.

            $typeAcceleratorNames = @()

            #endregion

            if ($PSCmdlet.ParameterSetName -eq 'byName') {
                foreach ($item in $Name) {
                    if (-not [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($item)) {
                        #region Add non-wildcard names directly to the collection of names to remove.

                        $typeAcceleratorNames += $item

                        #endregion
                    } else {
                        #region For wildcard names, lookup all possible matches and add them to the collection of names to remove.

                        $typeAcceleratorNames += @(Get-TypeAccelerator -Name $item | Select-Object -ExpandProperty Name)

                        #endregion
                    }
                }
            } else {
                #region For type or namespace removal, retrieve all matching type accelerators and add their names to the collection of names to remove.

                $typeAcceleratorNames += @(Get-TypeAccelerator @PSBoundParameters | Select-Object -ExpandProperty Name)

                #endregion
            }

            #region Now remove any names that were marked for removal.

            foreach ($item in $typeAcceleratorNames | Select-Object -Unique) {
                if ($PSCmdlet.ShouldProcess($item)) {
                    $script:typeAcceleratorsType::Remove($item) > $null
                }
            }

            #endregion
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

Export-ModuleMember -Function Remove-TypeAccelerator

New-Alias -Name rtx -Value Remove-TypeAccelerator -ErrorAction Ignore
if ($?) {
    Export-ModuleMember -Alias rtx
}