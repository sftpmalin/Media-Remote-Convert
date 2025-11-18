@echo off

:: --- Ouvrir le terminal Windows avec PowerShell et SSH ---
start "" wt.exe powershell -NoExit ssh -i "$HOME\.ssh\yoan" yoan@192.168.1.25

:: --- Attendre 0.6 seconde pour que la fenêtre existe ---
timeout /t 1 >nul

:: --- Centrer la fenêtre Windows Terminal ---
powershell -NoLogo -NoProfile -Command ^
"$hwnd = (Get-Process -Name 'WindowsTerminal').MainWindowHandle; ^
 Add-Type @'
 using System;
 using System.Runtime.InteropServices;
 public class Win {
   [DllImport(\"user32.dll\")] public static extern bool GetWindowRect(IntPtr h, out System.Drawing.Rectangle r);
   [DllImport(\"user32.dll\")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int h2, bool r);
 }
'@; ^
$r=[System.Drawing.Rectangle]::new(); ^
[Win]::GetWindowRect($hwnd,[ref]$r) | Out-Null; ^
$sw = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width; ^
$sh = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height; ^
$w  = $r.Width; ^
$h  = $r.Height; ^
$x = ($sw - $w) / 2; ^
$y = ($sh - $h) / 2; ^
[Win]::MoveWindow($hwnd,$x,$y,$w,$h,$true)"