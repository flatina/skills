<#
Usage examples:
  pwsh ./scripts/capture-window.ps1 -Out C:\temp\notepad.png -ProcessName notepad -TitleContains "Untitled" -RestoreIfMinimized -Activate
  pwsh ./scripts/capture-window.ps1 -Out .\window.png -Hwnd 123456 -Json
  pwsh ./scripts/capture-window.ps1 -Out .\client.png -Pid 4242 -ClientOnly -NoFallback
#>

[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Out,
    [string]$Hwnd,
    [Alias('Pid')]
    [string]$TargetPid,
    [string]$ProcessName,
    [string]$TitleContains,
    [switch]$Activate,
    [switch]$RestoreIfMinimized,
    [switch]$ClientOnly,
    [switch]$NoFallback,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ExitCodes = @{
    Success                      = 0
    WindowNotFound               = 10
    AmbiguousMatch               = 11
    MinimizedNotRestored         = 12
    InvalidBounds                = 13
    PrintWindowNoFallback        = 14
    PrintWindowAndFallbackFailed = 15
    SaveFailed                   = 16
    InvalidArguments             = 17
    InternalError                = 18
}

function Format-Quoted {
    param(
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        $Value = ''
    }

    $Value = $Value -replace "`r", ' '
    $Value = $Value -replace "`n", ' '
    $Value = $Value -replace "`t", ' '
    $Value = $Value -replace '"', '\"'
    return '"' + $Value + '"'
}

function New-CandidatePayload {
    param(
        [object[]]$Candidates
    )

    return @(
        foreach ($candidate in $Candidates) {
            [ordered]@{
                hwnd        = [int64]$candidate.Hwnd
                pid         = [int]$candidate.Pid
                title       = if ($null -eq $candidate.Title) { '' } else { [string]$candidate.Title }
                processName = if ($null -eq $candidate.ProcessName) { '' } else { [string]$candidate.ProcessName }
            }
        }
    )
}

function Write-Result {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [psobject]$Window,

        [Parameter(Mandatory = $true)]
        [string]$OutPath,

        [Parameter(Mandatory = $true)]
        [int]$Width,

        [Parameter(Mandatory = $true)]
        [int]$Height
    )

    if ($Json) {
        $result = [ordered]@{
            ok     = $true
            method = $Method
            hwnd   = [int64]$Window.Hwnd
            pid    = [int]$Window.Pid
            title  = if ($null -eq $Window.Title) { '' } else { [string]$Window.Title }
            out    = $OutPath
            width  = $Width
            height = $Height
        }

        [Console]::Out.WriteLine(($result | ConvertTo-Json -Compress -Depth 4))
    }
    else {
        $line = 'OK method={0} hwnd={1} pid={2} title={3} out={4} width={5} height={6}' -f `
            $Method, `
            ([int64]$Window.Hwnd), `
            ([int]$Window.Pid), `
            (Format-Quoted -Value $Window.Title), `
            (Format-Quoted -Value $OutPath), `
            $Width, `
            $Height

        [Console]::Out.WriteLine($line)
    }

    exit $script:ExitCodes.Success
}

function Fail-With {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Code,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [object[]]$Candidates,

        [System.Collections.IDictionary]$Details
    )

    if ($Json) {
        $result = [ordered]@{
            ok      = $false
            code    = $Code
            message = $Message
        }

        if ($null -ne $Candidates -and $Candidates.Count -gt 0) {
            $result.candidates = $Candidates
        }

        if ($null -ne $Details -and $Details.Count -gt 0) {
            foreach ($key in $Details.Keys) {
                $result[$key] = $Details[$key]
            }
        }

        [Console]::Out.WriteLine((ConvertTo-Json -InputObject $result -Compress -Depth 6))
    }
    else {
        [Console]::Error.WriteLine(('ERROR code={0} message={1}' -f $Code, (Format-Quoted -Value $Message)))

        if ($null -ne $Candidates -and $Candidates.Count -gt 0) {
            [Console]::Error.WriteLine(('CANDIDATES {0}' -f (ConvertTo-Json -InputObject $Candidates -Compress -Depth 4)))
        }

        if ($null -ne $Details -and $Details.Count -gt 0) {
            [Console]::Error.WriteLine(('DETAILS {0}' -f (ConvertTo-Json -InputObject $Details -Compress -Depth 4)))
        }
    }

    exit $Code
}

function Parse-Int64Argument {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Fail-With -Code $script:ExitCodes.InvalidArguments -Message "$Name must not be empty"
    }

    $text = $Value.Trim()

    try {
        return [int64]::Parse($text, [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture)
    }
    catch {
        if ($text.StartsWith('0x', [System.StringComparison]::OrdinalIgnoreCase)) {
            try {
                return [Convert]::ToInt64($text.Substring(2), 16)
            }
            catch {
            }
        }

        Fail-With -Code $script:ExitCodes.InvalidArguments -Message "$Name must be an int64"
    }
}

function Parse-Int32Argument {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Fail-With -Code $script:ExitCodes.InvalidArguments -Message "$Name must not be empty"
    }

    $text = $Value.Trim()

    try {
        return [int]::Parse($text, [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture)
    }
    catch {
        if ($text.StartsWith('0x', [System.StringComparison]::OrdinalIgnoreCase)) {
            try {
                return [Convert]::ToInt32($text.Substring(2), 16)
            }
            catch {
            }
        }

        Fail-With -Code $script:ExitCodes.InvalidArguments -Message "$Name must be an int32"
    }
}

function Normalize-ProcessName {
    param(
        [AllowNull()]
        [string]$Name
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $null
    }

    $normalized = $Name.Trim()
    if ($normalized.EndsWith('.exe', [System.StringComparison]::OrdinalIgnoreCase)) {
        $normalized = $normalized.Substring(0, $normalized.Length - 4)
    }

    return $normalized
}

function Test-ProcessNameMatch {
    param(
        [AllowNull()]
        [string]$ProcessName,

        [Parameter(Mandatory = $true)]
        [string]$Filter
    )

    $normalizedProcessName = Normalize-ProcessName -Name $ProcessName
    $normalizedFilter = Normalize-ProcessName -Name $Filter

    if ([string]::IsNullOrWhiteSpace($normalizedProcessName) -or [string]::IsNullOrWhiteSpace($normalizedFilter)) {
        return $false
    }

    if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($normalizedFilter)) {
        $pattern = [System.Management.Automation.WildcardPattern]::new(
            $normalizedFilter,
            [System.Management.Automation.WildcardOptions]::IgnoreCase
        )

        return $pattern.IsMatch($normalizedProcessName)
    }

    return $normalizedProcessName -eq $normalizedFilter
}

function Test-TitleMatch {
    param(
        [AllowNull()]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Needle
    )

    if ($null -eq $Title) {
        $Title = ''
    }

    return $Title.IndexOf($Needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Test-IsWindowsPlatform {
    $isWindowsVariable = Get-Variable -Name IsWindows -ErrorAction SilentlyContinue
    if ($null -ne $isWindowsVariable) {
        return [bool]$isWindowsVariable.Value
    }

    return [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
}

function Initialize-NativeInterop {
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    }
    catch {
        Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop
    }

    if (-not ([System.Management.Automation.PSTypeName]'FlCap.NativeMethods').Type) {
        $interopPath = Join-Path -Path $PSScriptRoot -ChildPath 'capture-window.cs'
        if (-not (Test-Path -LiteralPath $interopPath -PathType Leaf)) {
            throw [System.IO.FileNotFoundException]::new("native interop source not found: $interopPath")
        }

        Add-Type -Path $interopPath -ErrorAction Stop
    }
}

function Get-VisibleTopLevelWindows {
    $processCache = @{}
    foreach ($process in Get-Process -ErrorAction SilentlyContinue) {
        $mainWindowHandle = 0
        try {
            $mainWindowHandle = [int64]$process.MainWindowHandle
        }
        catch {
            $mainWindowHandle = 0
        }

        $processCache[[int]$process.Id] = [ordered]@{
            ProcessName      = [string]$process.ProcessName
            MainWindowHandle = $mainWindowHandle
        }
    }

    $foregroundHwnd = [int64][FlCap.NativeMethods]::GetForegroundWindow().ToInt64()
    $rawWindows = @(
        foreach ($window in [FlCap.NativeMethods]::EnumVisibleTopLevelWindows()) {
            $pidValue = [int]$window.Pid
            $processInfo = $processCache[$pidValue]
            $resolvedProcessName = ''
            $mainWindowHandle = 0

            if ($null -ne $processInfo) {
                $resolvedProcessName = [string]$processInfo.ProcessName
                $mainWindowHandle = [int64]$processInfo.MainWindowHandle
            }
            elseif ($pidValue -gt 0) {
                try {
                    $fallbackProcess = Get-Process -Id $pidValue -ErrorAction Stop
                    $resolvedProcessName = [string]$fallbackProcess.ProcessName
                    $mainWindowHandle = [int64]$fallbackProcess.MainWindowHandle
                }
                catch {
                    $resolvedProcessName = ''
                    $mainWindowHandle = 0
                }
            }

            [pscustomobject]@{
                Hwnd             = [int64]$window.Hwnd
                Pid              = $pidValue
                Title            = if ($null -eq $window.Title) { '' } else { [string]$window.Title }
                ProcessName      = $resolvedProcessName
                MainWindowHandle = $mainWindowHandle
                IsForeground     = ([int64]$window.Hwnd -eq $foregroundHwnd)
            }
        }
    )

    $windowCountsByPid = @{}
    foreach ($rawWindow in $rawWindows) {
        if ($windowCountsByPid.ContainsKey($rawWindow.Pid)) {
            $windowCountsByPid[$rawWindow.Pid] += 1
        }
        else {
            $windowCountsByPid[$rawWindow.Pid] = 1
        }
    }

    return @(
        foreach ($rawWindow in $rawWindows) {
            $isMainWindow = $false

            if ($rawWindow.MainWindowHandle -ne 0) {
                $isMainWindow = ($rawWindow.Hwnd -eq $rawWindow.MainWindowHandle)
            }
            elseif ($windowCountsByPid[$rawWindow.Pid] -eq 1) {
                $isMainWindow = $true
            }

            [pscustomobject]@{
                Hwnd         = [int64]$rawWindow.Hwnd
                Pid          = [int]$rawWindow.Pid
                Title        = [string]$rawWindow.Title
                ProcessName  = [string]$rawWindow.ProcessName
                IsForeground = [bool]$rawWindow.IsForeground
                IsMainWindow = [bool]$isMainWindow
            }
        }
    )
}

function Resolve-TargetWindow {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Windows,

        [Parameter(Mandatory = $true)]
        [bool]$HasHwnd,

        [Parameter(Mandatory = $true)]
        [int64]$ResolvedHwnd,

        [Parameter(Mandatory = $true)]
        [bool]$HasPid,

        [Parameter(Mandatory = $true)]
        [int]$ResolvedPid,

        [Parameter(Mandatory = $true)]
        [bool]$HasProcessName,

        [AllowNull()]
        [string]$ResolvedProcessName,

        [Parameter(Mandatory = $true)]
        [bool]$HasTitleContains,

        [AllowNull()]
        [string]$ResolvedTitleContains
    )

    if ($HasHwnd) {
        $matches = @($Windows | Where-Object { $_.Hwnd -eq $ResolvedHwnd })
    }
    elseif ($HasPid) {
        $matches = @($Windows | Where-Object { $_.Pid -eq $ResolvedPid })
    }
    elseif ($HasProcessName -and $HasTitleContains) {
        $matches = @(
            $Windows | Where-Object {
                (Test-ProcessNameMatch -ProcessName $_.ProcessName -Filter $ResolvedProcessName) -and
                (Test-TitleMatch -Title $_.Title -Needle $ResolvedTitleContains)
            }
        )
    }
    elseif ($HasProcessName) {
        $matches = @($Windows | Where-Object { Test-ProcessNameMatch -ProcessName $_.ProcessName -Filter $ResolvedProcessName })
    }
    else {
        $matches = @($Windows | Where-Object { Test-TitleMatch -Title $_.Title -Needle $ResolvedTitleContains })
    }

    if ($matches.Count -eq 0) {
        return [pscustomobject]@{
            Status     = 'NotFound'
            Window     = $null
            Candidates = @()
        }
    }

    if ($matches.Count -eq 1) {
        return [pscustomobject]@{
            Status     = 'Resolved'
            Window     = $matches[0]
            Candidates = (New-CandidatePayload -Candidates $matches)
        }
    }

    $preferred = $matches
    $mainWindowCandidates = @($preferred | Where-Object { $_.IsMainWindow })
    if ($mainWindowCandidates.Count -eq 1) {
        return [pscustomobject]@{
            Status     = 'Resolved'
            Window     = $mainWindowCandidates[0]
            Candidates = (New-CandidatePayload -Candidates $matches)
        }
    }
    elseif ($mainWindowCandidates.Count -gt 1) {
        $preferred = $mainWindowCandidates
    }

    $foregroundCandidates = @($preferred | Where-Object { $_.IsForeground })
    if ($foregroundCandidates.Count -eq 1) {
        return [pscustomobject]@{
            Status     = 'Resolved'
            Window     = $foregroundCandidates[0]
            Candidates = (New-CandidatePayload -Candidates $matches)
        }
    }
    elseif ($foregroundCandidates.Count -gt 1) {
        $preferred = $foregroundCandidates
    }

    $titledCandidates = @($preferred | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Title) })
    if ($titledCandidates.Count -eq 1) {
        return [pscustomobject]@{
            Status     = 'Resolved'
            Window     = $titledCandidates[0]
            Candidates = (New-CandidatePayload -Candidates $matches)
        }
    }
    elseif ($titledCandidates.Count -gt 0 -and $titledCandidates.Count -lt $preferred.Count) {
        $preferred = $titledCandidates
    }

    return [pscustomobject]@{
        Status     = 'Ambiguous'
        Window     = $null
        Candidates = (New-CandidatePayload -Candidates $matches)
    }
}

function Get-WindowBounds {
    param(
        [Parameter(Mandatory = $true)]
        [int64]$ResolvedHwnd,

        [Parameter(Mandatory = $true)]
        [bool]$UseClientOnly
    )

    $handle = [IntPtr]::new($ResolvedHwnd)
    $rect = New-Object FlCap.RECT
    $source = $null

    if ($UseClientOnly) {
        if (-not [FlCap.NativeMethods]::TryGetClientBounds($handle, [ref]$rect)) {
            return $null
        }

        $source = 'ClientRect'
    }
    else {
        $extendedFrameRect = New-Object FlCap.RECT
        if ([FlCap.NativeMethods]::TryGetExtendedFrameBounds($handle, [ref]$extendedFrameRect)) {
            $extendedWidth = $extendedFrameRect.Right - $extendedFrameRect.Left
            $extendedHeight = $extendedFrameRect.Bottom - $extendedFrameRect.Top
            if ($extendedWidth -gt 0 -and $extendedHeight -gt 0) {
                $rect = $extendedFrameRect
                $source = 'ExtendedFrameBounds'
            }
        }

        if ($null -eq $source) {
            if (-not [FlCap.NativeMethods]::GetWindowRect($handle, [ref]$rect)) {
                return $null
            }

            $source = 'WindowRect'
        }
    }

    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top

    if ($width -le 0 -or $height -le 0) {
        return $null
    }

    return [pscustomobject]@{
        Left   = [int]$rect.Left
        Top    = [int]$rect.Top
        Right  = [int]$rect.Right
        Bottom = [int]$rect.Bottom
        Width  = [int]$width
        Height = [int]$height
        Source = $source
    }
}

function Test-LikelyBlankBitmap {
    param(
        [Parameter(Mandatory = $true)]
        [System.Drawing.Bitmap]$Bitmap
    )

    if ($Bitmap.Width -le 0 -or $Bitmap.Height -le 0) {
        return $true
    }

    $stepX = [Math]::Max(1, [int][Math]::Floor($Bitmap.Width / 20))
    $stepY = [Math]::Max(1, [int][Math]::Floor($Bitmap.Height / 20))

    for ($y = 0; $y -lt $Bitmap.Height; $y += $stepY) {
        for ($x = 0; $x -lt $Bitmap.Width; $x += $stepX) {
            $color = $Bitmap.GetPixel($x, $y)
            if (($color.A -gt 0) -and ($color.R -ne 0 -or $color.G -ne 0 -or $color.B -ne 0)) {
                return $false
            }
        }
    }

    $last = $Bitmap.GetPixel($Bitmap.Width - 1, $Bitmap.Height - 1)
    return -not (($last.A -gt 0) -and ($last.R -ne 0 -or $last.G -ne 0 -or $last.B -ne 0))
}

function Invoke-PrintWindowCapture {
    param(
        [Parameter(Mandatory = $true)]
        [int64]$ResolvedHwnd,

        [Parameter(Mandatory = $true)]
        [psobject]$Bounds,

        [Parameter(Mandatory = $true)]
        [bool]$UseClientOnly
    )

    $bitmap = $null
    $graphics = $null
    $hdc = [IntPtr]::Zero

    try {
        $bitmap = [System.Drawing.Bitmap]::new(
            $Bounds.Width,
            $Bounds.Height,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )

        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([System.Drawing.Color]::Black)
        $hdc = $graphics.GetHdc()

        $flags = if ($UseClientOnly) {
            [FlCap.NativeMethods]::PW_CLIENTONLY
        }
        else {
            [FlCap.NativeMethods]::PW_RENDERFULLCONTENT
        }

        $ok = [FlCap.NativeMethods]::PrintWindow([IntPtr]::new($ResolvedHwnd), $hdc, $flags)
    }
    catch {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }

        return [pscustomobject]@{
            Ok      = $false
            Bitmap  = $null
            Message = $_.Exception.Message
            Blank   = $false
        }
    }
    finally {
        if ($null -ne $graphics) {
            if ($hdc -ne [IntPtr]::Zero) {
                $graphics.ReleaseHdc($hdc)
            }

            $graphics.Dispose()
        }
    }

    if (-not $ok) {
        $bitmap.Dispose()
        return [pscustomobject]@{
            Ok      = $false
            Bitmap  = $null
            Message = 'PrintWindow returned false'
            Blank   = $false
        }
    }

    if (Test-LikelyBlankBitmap -Bitmap $bitmap) {
        $bitmap.Dispose()
        return [pscustomobject]@{
            Ok      = $false
            Bitmap  = $null
            Message = 'PrintWindow returned a blank image'
            Blank   = $true
        }
    }

    return [pscustomobject]@{
        Ok      = $true
        Bitmap  = $bitmap
        Message = $null
        Blank   = $false
    }
}

function Invoke-ScreenCopyCapture {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Bounds
    )

    $bitmap = $null
    $graphics = $null

    try {
        $bitmap = [System.Drawing.Bitmap]::new(
            $Bounds.Width,
            $Bounds.Height,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )

        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        # Fallback copies the live screen, so occluded windows are captured as currently visible.
        $graphics.CopyFromScreen(
            $Bounds.Left,
            $Bounds.Top,
            0,
            0,
            [System.Drawing.Size]::new($Bounds.Width, $Bounds.Height),
            [System.Drawing.CopyPixelOperation]::SourceCopy
        )

        return [pscustomobject]@{
            Ok      = $true
            Bitmap  = $bitmap
            Message = $null
        }
    }
    catch {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }

        return [pscustomobject]@{
            Ok      = $false
            Bitmap  = $null
            Message = $_.Exception.Message
        }
    }
    finally {
        if ($null -ne $graphics) {
            $graphics.Dispose()
        }
    }
}

function Save-BitmapPng {
    param(
        [Parameter(Mandatory = $true)]
        [System.Drawing.Bitmap]$Bitmap,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $directory = [System.IO.Path]::GetDirectoryName($fullPath)

    if ([string]::IsNullOrWhiteSpace($directory)) {
        throw [System.InvalidOperationException]::new('output directory could not be resolved')
    }

    if (-not [System.IO.Directory]::Exists($directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }

    $Bitmap.Save($fullPath, [System.Drawing.Imaging.ImageFormat]::Png)
    return $fullPath
}

try {
    if (-not (Test-IsWindowsPlatform)) {
        Fail-With -Code $script:ExitCodes.InvalidArguments -Message 'this script only supports Windows'
    }

    if ($PSVersionTable.PSVersion.Major -lt 5 -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)) {
        Fail-With -Code $script:ExitCodes.InvalidArguments -Message 'PowerShell 5.1+ is required'
    }

    $hasHwnd = $PSBoundParameters.ContainsKey('Hwnd')
    $hasPid = $PSBoundParameters.ContainsKey('TargetPid')
    $hasProcessName = $PSBoundParameters.ContainsKey('ProcessName')
    $hasTitleContains = $PSBoundParameters.ContainsKey('TitleContains')

    if ([string]::IsNullOrWhiteSpace($Out)) {
        Fail-With -Code $script:ExitCodes.InvalidArguments -Message 'Out is required'
    }

    $resolvedOutPath = $null
    try {
        $resolvedOutPath = [System.IO.Path]::GetFullPath($Out)
    }
    catch {
        Fail-With -Code $script:ExitCodes.InvalidArguments -Message ('Out is not a valid path: ' + $_.Exception.Message)
    }

    if ([string]::IsNullOrWhiteSpace([System.IO.Path]::GetFileName($resolvedOutPath))) {
        Fail-With -Code $script:ExitCodes.InvalidArguments -Message 'Out must be a file path'
    }

    if ($hasProcessName -and [string]::IsNullOrWhiteSpace($ProcessName)) {
        Fail-With -Code $script:ExitCodes.InvalidArguments -Message 'ProcessName must not be empty'
    }

    if ($hasTitleContains -and [string]::IsNullOrWhiteSpace($TitleContains)) {
        Fail-With -Code $script:ExitCodes.InvalidArguments -Message 'TitleContains must not be empty'
    }

    if (-not ($hasHwnd -or $hasPid -or $hasProcessName -or $hasTitleContains)) {
        Fail-With -Code $script:ExitCodes.InvalidArguments -Message 'one of Hwnd, Pid, ProcessName, or TitleContains is required'
    }

    $resolvedHwnd = 0L
    if ($hasHwnd) {
        $resolvedHwnd = Parse-Int64Argument -Name 'Hwnd' -Value $Hwnd
        if ($resolvedHwnd -le 0) {
            Fail-With -Code $script:ExitCodes.InvalidArguments -Message 'Hwnd must be greater than zero'
        }
    }

    $resolvedPid = 0
    if ($hasPid) {
        $resolvedPid = Parse-Int32Argument -Name 'Pid' -Value $TargetPid
        if ($resolvedPid -le 0) {
            Fail-With -Code $script:ExitCodes.InvalidArguments -Message 'Pid must be greater than zero'
        }
    }

    $resolvedProcessName = if ($hasProcessName) { $ProcessName.Trim() } else { $null }
    $resolvedTitleContains = if ($hasTitleContains) { $TitleContains } else { $null }

    Initialize-NativeInterop
    [FlCap.NativeMethods]::TrySetDpiAwareness() | Out-Null

    $resolution = Resolve-TargetWindow `
        -Windows (Get-VisibleTopLevelWindows) `
        -HasHwnd $hasHwnd `
        -ResolvedHwnd $resolvedHwnd `
        -HasPid $hasPid `
        -ResolvedPid $resolvedPid `
        -HasProcessName $hasProcessName `
        -ResolvedProcessName $resolvedProcessName `
        -HasTitleContains $hasTitleContains `
        -ResolvedTitleContains $resolvedTitleContains

    if ($resolution.Status -eq 'NotFound') {
        Fail-With -Code $script:ExitCodes.WindowNotFound -Message 'window not found'
    }

    if ($resolution.Status -eq 'Ambiguous') {
        Fail-With -Code $script:ExitCodes.AmbiguousMatch -Message 'ambiguous window match' -Candidates $resolution.Candidates
    }

    $window = $resolution.Window
    $windowHandle = [IntPtr]::new([int64]$window.Hwnd)

    if (-not [FlCap.NativeMethods]::IsWindow($windowHandle)) {
        Fail-With -Code $script:ExitCodes.WindowNotFound -Message 'window not found'
    }

    if ([FlCap.NativeMethods]::IsIconic($windowHandle)) {
        if (-not [bool]$RestoreIfMinimized) {
            Fail-With -Code $script:ExitCodes.MinimizedNotRestored -Message 'window is minimized and was not restored' -Details ([ordered]@{
                hwnd  = [int64]$window.Hwnd
                pid   = [int]$window.Pid
                title = [string]$window.Title
            })
        }

        [FlCap.NativeMethods]::ShowWindowAsync($windowHandle, [FlCap.NativeMethods]::SW_RESTORE) | Out-Null
        [FlCap.NativeMethods]::ShowWindow($windowHandle, [FlCap.NativeMethods]::SW_RESTORE) | Out-Null
        [System.Threading.Thread]::Sleep(250)

        if ([FlCap.NativeMethods]::IsIconic($windowHandle)) {
            Fail-With -Code $script:ExitCodes.MinimizedNotRestored -Message 'window is minimized and could not be restored' -Details ([ordered]@{
                hwnd  = [int64]$window.Hwnd
                pid   = [int]$window.Pid
                title = [string]$window.Title
            })
        }
    }

    if ([bool]$Activate) {
        [FlCap.NativeMethods]::SetForegroundWindow($windowHandle) | Out-Null
        [System.Threading.Thread]::Sleep(120)
    }

    $bounds = Get-WindowBounds -ResolvedHwnd ([int64]$window.Hwnd) -UseClientOnly ([bool]$ClientOnly)
    if ($null -eq $bounds) {
        Fail-With -Code $script:ExitCodes.InvalidBounds -Message 'invalid window bounds' -Details ([ordered]@{
            hwnd       = [int64]$window.Hwnd
            pid        = [int]$window.Pid
            title      = [string]$window.Title
            clientOnly = [bool]$ClientOnly
        })
    }

    $bitmap = $null
    $method = $null
    $printWindowResult = Invoke-PrintWindowCapture -ResolvedHwnd ([int64]$window.Hwnd) -Bounds $bounds -UseClientOnly ([bool]$ClientOnly)

    if ($printWindowResult.Ok) {
        $bitmap = $printWindowResult.Bitmap
        $method = 'PrintWindow'
    }
    else {
        if ([bool]$NoFallback) {
            Fail-With -Code $script:ExitCodes.PrintWindowNoFallback -Message 'PrintWindow failed and fallback disabled' -Details ([ordered]@{
                hwnd              = [int64]$window.Hwnd
                pid               = [int]$window.Pid
                title             = [string]$window.Title
                printWindowReason = [string]$printWindowResult.Message
            })
        }

        $screenCopyResult = Invoke-ScreenCopyCapture -Bounds $bounds
        if (-not $screenCopyResult.Ok) {
            Fail-With -Code $script:ExitCodes.PrintWindowAndFallbackFailed -Message 'PrintWindow failed and fallback failed' -Details ([ordered]@{
                hwnd              = [int64]$window.Hwnd
                pid               = [int]$window.Pid
                title             = [string]$window.Title
                printWindowReason = [string]$printWindowResult.Message
                fallbackReason    = [string]$screenCopyResult.Message
            })
        }

        $bitmap = $screenCopyResult.Bitmap
        $method = 'ScreenCopy'
    }

    try {
        $savedOutPath = Save-BitmapPng -Bitmap $bitmap -Path $resolvedOutPath
    }
    catch {
        Fail-With -Code $script:ExitCodes.SaveFailed -Message ('failed to save PNG: ' + $_.Exception.Message) -Details ([ordered]@{
            out    = $resolvedOutPath
            hwnd   = [int64]$window.Hwnd
            pid    = [int]$window.Pid
            method = $method
        })
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }

    Write-Result -Method $method -Window $window -OutPath $savedOutPath -Width $bounds.Width -Height $bounds.Height
}
catch {
    Fail-With -Code $script:ExitCodes.InternalError -Message ('unexpected internal error: ' + $_.Exception.Message)
}

<#
Self-test examples:
  pwsh ./scripts/capture-window.ps1 -Out "$env:TEMP\capture-selftest.png" -ProcessName notepad -Json
  pwsh ./scripts/capture-window.ps1 -Out "$env:TEMP\capture-selftest-client.png" -TitleContains "Notepad" -ClientOnly
#>
