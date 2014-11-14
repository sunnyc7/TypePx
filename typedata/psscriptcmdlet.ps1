﻿<#############################################################################
The TypePx module adds properties and methods to the most commonly used types
to make common tasks easier. Using these type extensions together can provide
an enhanced syntax in PowerShell that is both easier to read and
self-documenting. TypePx also provides commands to manage type accelerators.
Type acceleration also contributes to making scripting easier and they help
produce more readable scripts, particularly when using a library of .NET
classes that belong to the same namespace.

Copyright 2014 Kirk Munro

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#############################################################################>

$typeName = 'System.Management.Automation.PSScriptCmdlet'

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ThrowException -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The exception to be thrown
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Exception]
        $Exception,

        # The category of the error
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory,

        # An object related to the error
        [Parameter(Position=2)]
        [System.Object]
        $RelatedObject = $null
    )
    try {
        # Throw an error record wrapping the exception
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList @(
            $Exception
            $Exception.GetType().Name
            $ErrorCategory
            $RelatedObject
        )
        throw $errorRecord
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ThrowError -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The error message to be reported to the caller
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        # The type of exception to be thrown
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionTypeName,

        # The category of the error
        [Parameter(Position=2, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory,

        # An object related to the error
        [Parameter(Position=3)]
        [System.Object]
        $RelatedObject = $null
    )
    try {
        # Throw an exception
        $exception = New-Object -TypeName $ExceptionTypeName -ArgumentList $Message
        $this.ThrowException($exception, $ErrorCategory, $RelatedObject)
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ThrowCommandNotFoundError -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The name of the command that was not found
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $CommandName,

        # An object related to the error
        [Parameter(Position=1)]
        [System.Object]
        $RelatedObject = $null
    )
    try {
        # Throw a command not found exception
        $message = $this.GetResourceString('DiscoveryExceptions','CommandNotFoundException') -f $CommandName
        $exception = New-Object -TypeName System.Management.Automation.CommandNotFoundException -ArgumentList $message
        $exception.CommandName = $CommandName
        $this.ThrowException($exception, [System.Management.Automation.ErrorCategory]::ObjectNotFound, $RelatedObject)
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ValidateParameterDependency -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The name of the parameter that requires other parameters in the same parameter set when it is used
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ParameterName,

        # The list of names of other required parameters
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $RequiredParameterName
    )
    # Make sure we work like a function, without requiring array input.
    if ($args) {
        $IncompatibleParameterName += $args
    }
    try {
        # If the current parameter set contains missing required parameters, throw an exception
        if ($this.MyInvocation.BoundParameters.ContainsKey($ParameterName) -and
            -not @($this.MyInvocation.BoundParameters.Keys).ContainsAny($RequiredParameterName)) {
            $message = "The following parameters are required when using the ${ParameterName} parameter: $($RequiredParameterName -join ',')."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            $this.ThrowException($exception, [System.Management.Automation.ErrorCategory]::InvalidOperation)
        }
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ValidateParameterIncompatibility -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The name of the parameter that is not compatible with other parameters in the same parameter set
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ParameterName,

        # The list of names of other incompatible parameters
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $IncompatibleParameterName
    )
    # Make sure we work like a function, without requiring array input.
    if ($args) {
        $IncompatibleParameterName += $args
    }
    try {
        # If the current parameter set contains incompatible parameters, throw an exception
        if ($this.MyInvocation.BoundParameters.ContainsKey($ParameterName) -and
            @($this.MyInvocation.BoundParameters.Keys).ContainsAny($IncompatibleParameterName)) {
            $message = "The following parameters may not be used in combination with the ${ParameterName} parameter: $($IncompatibleParameterName -join ',')."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            $this.ThrowException($exception, [System.Management.Automation.ErrorCategory]::InvalidOperation)
        }
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetSplattableParameters -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The names of the parameters that you want to splat into other commands.
        [System.String[]]$ParameterName = @()
    )
    # Make sure we work like a function, without requiring array input.
    if ($args) {
        $ParameterName += $args
    }
    # Define the hashtable that will contain the pass thru parameters.
    $splattableParameters = @{}
    # Load the parameters that will be passed through into the hashtable.
    if (-not $ParameterName) {
        # If no specific parameters were requested, splat all bound parameters.
        $splattableParameters = $this.MyInvocation.BoundParameters
    } else {
        # Otherwise, only splat the bound parameters that were requested.
        foreach ($item in $ParameterName) {
            if ($this.MyInvocation.BoundParameters.ContainsKey($item)) {
                $splattableParameters[$item] = $this.MyInvocation.BoundParameters.$item
            }
        }
    }
    # Return the hashtable to the caller.
    $splattableParameters
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetBoundPagingParameters -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the paging parameters in a splattable hashtable.
    $commandMetadata = $this.MyInvocation.MyCommand -as [System.Management.Automation.CommandMetadata]
    if (-not $commandMetadata -or -not $commandMetadata.SupportsPaging) {
        # If paging is not supported for this command, return an empty hashtable.
        @{}
    } else {
        # Otherwise, create a splattable hashtable containing all bound paging parameters.
        $pagingParameterNames = Get-Member -InputObject $this.PagingParameters -MemberType Property | Select-Object -ExpandProperty Name
        $this.GetSplattableParameters($pagingParameterNames)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetBoundShouldProcessParameters -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the should process parameters in a splattable hashtable.
    $commandMetadata = $this.MyInvocation.MyCommand -as [System.Management.Automation.CommandMetadata]
    if (-not $commandMetadata -or -not $commandMetadata.SupportsShouldProcess) {
        # If should process is not supported for this command, return an empty hashtable.
        @{}
    } else {
        # Otherwise, create a splattable hashtable containing all bound should process parameters.
        $this.GetSplattableParameters(@('Confirm','WhatIf'))
    }
}
# SIG # Begin signature block
# MIIZIAYJKoZIhvcNAQcCoIIZETCCGQ0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyz4SvDOjD1bxibFmtP8Rhma+
# zxagghRWMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggUSMIID+qADAgECAhAN//fSWE4vjemplVn1wnAjMA0GCSqGSIb3DQEBBQUAMG8x
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29k
# ZSBTaWduaW5nIENBLTEwHhcNMTQxMDAzMDAwMDAwWhcNMTUxMDA3MTIwMDAwWjBo
# MQswCQYDVQQGEwJDQTEQMA4GA1UECBMHT250YXJpbzEPMA0GA1UEBxMGT3R0YXdh
# MRowGAYDVQQKExFLaXJrIEFuZHJldyBNdW5ybzEaMBgGA1UEAxMRS2lyayBBbmRy
# ZXcgTXVucm8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDIANwog4/2
# JUJCJ1PKeXu8S+eBp1F8fHaVFVgMToGhyNz+UptqDVBIsOu21AXNd4s/3WqhOnOt
# yBvyn5thWNGCMB/XcX6/SdV8lSyg0swreiiR7ksJc1jK75aDJV2UE/mOiMtcWo01
# SQGddbF4FpK3LxbzjKGMPP7uI1TUFTxmdR8t8HaRlI7KcsZkckGffkboAm5CWDhZ
# d4f9YhVzZ8uV0jAN9i+mtmIOHTMMskQ7tZy17GkgyjiGrnMxy6VZ18hya062ZLcV
# 20LUqsUkjr0oNvf54KrhZrPQhULagcpKwmxw3hzDfvWov4yVLWdgWT6a+TUG8D39
# HUuVCpXG+OgZAgMBAAGjggGvMIIBqzAfBgNVHSMEGDAWgBR7aM4pqsAXvkl64eU/
# 1qf3RY81MjAdBgNVHQ4EFgQUG+clmaBur2rhO4i38pTJHCFSya0wDgYDVR0PAQH/
# BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMG0GA1UdHwRmMGQwMKAuoCyGKmh0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9hc3N1cmVkLWNzLWcxLmNybDAwoC6gLIYq
# aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL2Fzc3VyZWQtY3MtZzEuY3JsMEIGA1Ud
# IAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRp
# Z2ljZXJ0LmNvbS9DUFMwgYIGCCsGAQUFBwEBBHYwdDAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuZGlnaWNlcnQuY29tMEwGCCsGAQUFBzAChkBodHRwOi8vY2FjZXJ0
# cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURDb2RlU2lnbmluZ0NBLTEu
# Y3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEFBQADggEBACJI6tx95+XcEC6X
# EAxbRZjIXJ085IDdqWXImnfQ8To+yAeHM5kP506ddtzlztW9esOxqnhnfIAClB1e
# 1f/FAlgpxrEQ2IRCuUHuMfy4AxqRkD9jePVZ7NYKcKxJZ87iu32iuGT+phFip+ZP
# O9GkqDYkvzQmB74b7hQ3knn6qFLqUZ8njpSceIeC8PHINZmSx+v+KVkEavN/z0hF
# T9xYR2VPPjIIk3MnwtkyHhTWWxNoKGCg+BZV2mApwR9EsWJHVpiGru6DNfNwSQpB
# oIvMGOOL919XgE4J1B022xnAcnCCxoGjjSmBPb1TWemijGsGD2Je8/EALw9geBB9
# vbJvwn8wggajMIIFi6ADAgECAhAPqEkGFdcAoL4hdv3F7G29MA0GCSqGSIb3DQEB
# BQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQg
# SUQgUm9vdCBDQTAeFw0xMTAyMTExMjAwMDBaFw0yNjAyMTAxMjAwMDBaMG8xCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29kZSBT
# aWduaW5nIENBLTEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCcfPmg
# jwrKiUtTmjzsGSJ/DMv3SETQPyJumk/6zt/G0ySR/6hSk+dy+PFGhpTFqxf0eH/L
# er6QJhx8Uy/lg+e7agUozKAXEUsYIPO3vfLcy7iGQEUfT/k5mNM7629ppFwBLrFm
# 6aa43Abero1i/kQngqkDw/7mJguTSXHlOG1O/oBcZ3e11W9mZJRru4hJaNjR9H4h
# webFHsnglrgJlflLnq7MMb1qWkKnxAVHfWAr2aFdvftWk+8b/HL53z4y/d0qLDJG
# 2l5jvNC4y0wQNfxQX6xDRHz+hERQtIwqPXQM9HqLckvgVrUTtmPpP05JI+cGFvAl
# qwH4KEHmx9RkO12rAgMBAAGjggNDMIIDPzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMwggHDBgNVHSAEggG6MIIBtjCCAbIGCGCGSAGG/WwDMIIB
# pDA6BggrBgEFBQcCARYuaHR0cDovL3d3dy5kaWdpY2VydC5jb20vc3NsLWNwcy1y
# ZXBvc2l0b3J5Lmh0bTCCAWQGCCsGAQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMA
# ZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8A
# bgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAA
# dABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBDAFAAUwAgAGEAbgBkACAA
# dABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0A
# ZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQA
# eQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgA
# ZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBjAGUALjASBgNVHRMBAf8E
# CDAGAQH/AgEAMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4
# MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVk
# SURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGln
# aUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMB0GA1UdDgQWBBR7aM4pqsAXvkl64eU/
# 1qf3RY81MjAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG
# 9w0BAQUFAAOCAQEAe3IdZP+IyDrBt+nnqcSHu9uUkteQWTP6K4feqFuAJT8Tj5uD
# G3xDxOaM3zk+wxXssNo7ISV7JMFyXbhHkYETRvqcP2pRON60Jcvwq9/FKAFUeRBG
# JNE4DyahYZBNur0o5j/xxKqb9to1U0/J8j3TbNwj7aqgTWcJ8zqAPTz7NkyQ53ak
# 3fI6v1Y1L6JMZejg1NrRx8iRai0jTzc7GZQY1NWcEDzVsRwZ/4/Ia5ue+K6cmZZ4
# 0c2cURVbQiZyWo0KSiOSQOiG3iLCkzrUm2im3yl/Brk8Dr2fxIacgkdCcTKGCZly
# CXlLnXFp9UH/fzl3ZPGEjb6LHrJ9aKOlkLEM/zGCBDQwggQwAgEBMIGDMG8xCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29kZSBT
# aWduaW5nIENBLTECEA3/99JYTi+N6amVWfXCcCMwCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHQE
# qAXbYYuqfTTzEGUb2Ow3m4tlMA0GCSqGSIb3DQEBAQUABIIBALRHiW7DQKWPuNnp
# gmzB1sBB68aK0eFWVfND5Uov6SSQqNwolWh/3+KfksBvzL2X+/98TfREDqAoQEKH
# qSqLh2UvIRIK4Hfv+8XVENpGv5cYL9coxu1SqcAvTopX010J3LWwv2apWhihk6Gy
# uLYvN16Oy7+PDZEw7mI5Ga0CNSD4M2Tn+tO14VYXDYNAj64bFPQt70wwyPYVyZaO
# lQqotISJD8Jcs6Kv/ibYtJ8L1TrOeddTOs1uj8MTbE2gn9lYCa4pKFSgxAebhZNg
# Wsiwm99pGqVRu2GCFRQGr0Ozu37YKC8vK76R0PGLnlla3xCatYRroFNF7N6IK5s7
# 7dkOEcOhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQG
# EwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5
# bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVu
# BNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMTQxMTE0MjExNDA2WjAjBgkqhkiG9w0BCQQxFgQUJPDd
# YwDDlk+28DsNltt3+sYthVQwDQYJKoZIhvcNAQEBBQAEggEAXDWGk9hOeWb0ibJk
# 9IKFyXJfKi/ICo4RYaqJgyXl559Sm3kcxdb/XYvfo7SoYerzHx2lGyeSp7TjiW9N
# SmwhrAdkzfR5jhakJ/HtW/4eZCEQBaOul4Lns/PLm59+AfJXUrZWa1oKsRQ5mNlr
# OihGE9GGkPh2SIwIaf7AAVzktuuv6uhdS6Wv2prCIz1KpzAzeowr9YZOBwPtejQS
# HVQruIvczMFHpILVdKWmsuW/eQVN90Rd7JT8FQSTruCLiH4B+bH8W01VK6rGxNqJ
# kfVzXx+N9vR/uJMwJKd7ayJGsbvq2/kmJQZZ63PZV82wPI63C3Wa5Z2jjX4dcxuB
# RQLhJw==
# SIG # End signature block
