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

#region Initialize the module.

Invoke-Snippet -Name Module.Initialize

#endregion

#region Load the TypeAccelerators internal type.

[System.Type]$typeAcceleratorsType = [System.Management.Automation.PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators', $true, $true)

#endregion

#region Define a hashtable to track the type extensions that are added.

$TypeExtensions = @{}

#endregion

#region Import type extensions.

Invoke-Snippet -Name ScriptFile.Import.Ordered -Parameters @{
    Path = Join-Path -Path $PSModuleRoot -ChildPath typedata
    Order = @(
        'hashtable.ps1'
        'string.ps1'
    )
}

#endregion

#region Import public function definitions.

Invoke-Snippet -Name ScriptFile.Import -Parameters @{
    Path = Join-Path -Path $PSModuleRoot -ChildPath functions
}

#endregion

#region Store the type accelerators when the module is first loaded.

$OldTypeAccelerators = @{}
foreach ($item in @(Get-TypeAccelerator)) {
    $OldTypeAccelerators[$item.Name] = $item.Type
}

#endregion

#region Clean-up the module when it is removed.

$PSModule.OnRemove = {
    #region Reset the type accelerators back to the original list.

    $typeAccelerators = @{}
    foreach ($item in @(Get-TypeAccelerator)) {
        $typeAccelerators[$item.Name] = $item.Type
    }
    foreach ($item in $typeAccelerators.Keys) {
        if (-not $OldTypeAccelerators.ContainsKey($item)) {
            Remove-TypeAccelerator -Name $item
        }
    }
    foreach ($item in $OldTypeAccelerators.Keys) {
        if ($typeAccelerators.ContainsKey($item)) {
            if ($typeAccelerators[$item] -ne $OldTypeAccelerators[$item]) {
                Set-TypeAccelerator -Name $item -Type $OldTypeAccelerators[$item]
            }
        } else {
            Add-TypeAccelerator -Name $item -Type $OldTypeAccelerators[$item]
        }
    }

    #endregion

    #region Remove any type data that this module added to the runspace.

    for ($index = $Host.Runspace.InitialSessionState.Types.Count - 1; $index -ge 0; $index--) {
        if ($Host.Runspace.InitialSessionState.Types[$index].FileName) {
            continue
        }
        $typeData = $Host.Runspace.InitialSessionState.Types[$index].TypeData
        if ($typeData.Members.Keys.Count -ne 1) {
            continue
        }
        if ($TypeExtensions.ContainsKey($typeData.TypeName) -and
            ($TypeExtensions[$typeData.TypeName] -contains $typeData.Members.Keys[0])) {
            $Host.Runspace.InitialSessionState.Types.RemoveItem($index)
        }
    }
    Update-TypeData

    #endregion
}

#endregion