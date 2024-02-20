#######################################
# BitLocker Status and Backup by Paul
# Version: 1.0
# Date: 20240127
#
# Version: 1.1
# Date: 20240206
# Changes: removed PID display, fixed inability to handle more than 1 disk
#
# Version: 1.2
# Date: 20240206
# Changes: really fixed inability to handle more than 1 disk, tidied label text
#
# Version: 1.3
# Date: 20240206
# Changes: actually fixed inability to handle more than 1 disk
#
# Version: 1.4
# Date: 20240207
# Changes: used "dynamic" height to allow up to 5 disks to fit in window
#          simplified some code to reduce duplication
#
# Version: 1.5
# Date: 20240208
# Changes: fixed issue where "Run as Admin" button didn't display correctly
#          updated AskWoody icon to "new" version
#          changed OK button text to Done
#          reduced overall padding for a "slightly smaller" display window
#          added "empty label" as last item so buttons still line up properly
#          moved the "Run as Admin" code to the "Get-AdminStatus" section and
#          modified it (new variable name $Admin???, set text color to red, etc.)
#          numerous other "minor changes" to make things easier to read/understand
#
# Version: 1.6
# Date: 20240209
# Changes: +10 to "Run as Admin" label width to fix line wrapping issue
#          modified so "Done" button shows as "Cancel" on "Run as Admin" screen
#          set form to "always" display on top of other windows
#
# Version: 1.7
# Date: 20240209
# Changes: fixed drive letter in description.
#          Changed text "Drive Use" to "Label" and added padding
#
# Version: 1.8
# Date: 20240209
# Changes: reverted label change
#
# Version: 1.9
# Date: 20240210
# Changes: converted "Backup Recovery Key" to a function so it always displays at the bottom of the screen
#          +22 to drive label & textbox widths so description isn't "trucated" on displays scaled above 100%
#          deleted all the "unused" code sections
#          minor changes to the code layout so it's easier to understand what it's doing
#
# Version: 1.91
# Date: 20240217
# Changes: moved label width definition into label templates and added 10 points, to be sure
#          embedded Askwoody icon so it displays when run as admin
#          mapped drives now use "continue" instead of "return" in case they intersperse fixed drives
#
# Version: 1.92
# Date: 20240218
# Changes: reverted: mapped drives now use "continue" instead of "return" in case they intersperse fixed drives
#		   Improved ElevateUser function
#
#######################################

# add PowerShell Gui
Add-Type -AssemblyName System.Windows.Forms

# add .Net methods for hiding/showing the console in the background
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
## end add .Net methods

function Hide-Console
{
    $consolePtr = [Console.Window]::GetConsoleWindow()

    #0 = hide it
    [Console.Window]::ShowWindow($consolePtr, 0)
}

Hide-Console

Function Get-AdminStatus
{
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity

    If (-NOT ($principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)))
        {"User"}
    Else
        {"Administrator"}
}

Function ElevateUser
{
    $BitLockerStatusForm.Close()
	$PSVersInUse = (& {IF (($PSVersionTable.PSVersion.Major) -le 5) {"powershell.exe"} else {"pwsh.exe"}})
	$SPArgs = @{
		verb         = "runas"
		filepath     = "$PSVersInUse"
		argumentlist = "-executionpolicy Bypass -File $PSCommandPath"
		}

	start-process @SPArgs
}

Function ShowMessage 
{
    param($MessageBody, $MessageTitle)
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::Ok
    $MessageIcon = [System.Windows.MessageBoxImage]::Error
    $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
}

Function Get-FileName
{
    param($Type='open', $Title='Select File', $FileFilter) [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    if ($Type -eq 'open')
    {
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    }

    if ($Type -eq 'create')
    {
        $OpenFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    }

    $OpenFileDialog.filter = $FileFilter
    OpenFileDialog.Title = $Title
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.ShowHelp = $true
    $OpenFileDialog.filename
}

Function SaveFile
{
    $BackupFileName = Get-FileName -Type "create" -Title "Select backup file" -FileFilter "TXT (*.txt)|*.txt"

    if ($BackupFileName -eq '')
    {
        ShowMessage -MessageTitle "File Selection Failed" -MessageBody "No backup file selected"
    }
    else
    {
        Set-content -path $BackupFileName -value $RecoveryFileText
        Start-Process $BackupFileName
    }
}

Function BackupKeyButton
{
    $BackupBtn           = New-Object system.Windows.Forms.Button
    $BackupBtn.ForeColor = "#fff"
    $BackupBtn.BackColor = "#a4ba67"
    $BackupBtn.Font      = 'Microsoft Sans Serif,12'
    $BackupBtn.text      = "Backup Recovery Key"
    $BBTsize             = [System.Windows.Forms.TextRenderer]::MeasureText($BackupBtn.text, 'Microsoft Sans Serif,12')
    $BackupBtn.width     = $BBTsize.Width+20
    $BackupBtn.height    = 30
    $BackupBtn.Top       = ($BitLockerStatusForm.ClientSize.Height-40)
    $BackupBtn.Left      = 20
    $BackupBtn.Anchor    = "bottom,left"
    $BackupBtn.Add_Click({ SaveFile })
    $BitLockerStatusForm.controls.Add($BackupBtn)
}

Function ButtonSpacer
{
    $Spacer           = New-Object System.Windows.Forms.Label
    $Spacer.Text      = " "
    $Spacer.Height    = 26
    $Spacer.Width     = 10
    $Spacer.Top       = ($BitLockerStatusForm.ClientSize.Height-20)
    $Spacer.left      = 0
    $BitLockerStatusForm.controls.Add($Spacer)
}


# ============== SET FIXED VALUES ==============
# background colours
$BackColorOK     = "#009904"
$BackColorEnc    = "#FFA500"
$BackColorNoProt = "#FF0000"

# label text
$DrvTextOK     = " drive is not encrypted"
$DrvTextEnc    = " drive is encrypted`n`nYou can make a backup of the recovery key by`nclicking the ""Backup Recovery Key"" button"
$DrvTextNoProt = " drive is encrypted but not protected`n`nYou need to either decrypt this drive or logon with a`nMS account and make a backup of the recovery key."

# misc text
$DrvRecoveryText  = "##################################`n`nThis file must be saved in a place you can access if the machine you are using needs BitLocker Recovery`n`n##################################"
$DrvRecoveryTextA = "`n`nBitLocker Drive Encryption recovery infomation`n`nVerify that this is the correct recovery key for your system.`n`nDrive Identifier: "
$DrvRecoveryTextB = "`n`nConfirm that the identifier matches your system. If not, this is not the correct recovery key.`n`nRecovery Key: "
$DrvNotProtText   = " drive is encrypted but not protected`n`nYou need to either decrypt the drive or logon with`nan MS account and then make sure you have a backup`nof the recovery key."
$RunAsAdminText   = "You need to run this script with Admin privileges`n`nClick the ""Run as Admin"" button to continue"
# ============ END SET FIXED VALUES ============


# ================= CREATE FORM ================
# create form and set parmaters
$BitLockerStatusForm = New-Object system.Windows.Forms.Form
$BitLockerStatusForm.AutoSize        = $true
$BitLockerStatusForm.Topmost         = $true
$BitLockerStatusForm.text            = "BitLocker Check and Backup Script, courtesy of askwoody.com"
$BitLockerStatusForm.StartPosition   = 'CenterScreen'
$BitLockerStatusForm.BackColor       = "#ffffff"
$BitLockerStatusForm.AutoSize        = '1'
$BitLockerStatusForm.AutoSizeMode    = 'GrowAndShrink'
$BitLockerStatusForm.MaximizeBox     = 0
$BitLockerStatusForm.MinimizeBox     = 0
$BitLockerStatusForm.FormBorderStyle = 'FixedSingle' # disable resize
$BitLockerStatusForm.Padding         = 20

# create "Askwoody" icon for form
# This base64 string holds the bytes for the icon
$iconBase64      = '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'
$iconBytes       = [Convert]::FromBase64String($iconBase64)
# initialize a Memory stream holding the bytes
$stream          = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)
$BitLockerStatusForm.Icon       = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($stream).GetHIcon()))

# create "AskWoody" link & add to form
$AskWoodyLabel                     = New-Object System.Windows.Forms.LinkLabel #.Label
$AskWoodyLabel.Text                = 'askwoody.com'
$AskWoodyLabel.Font                = 'Microsoft Sans Serif,10'
$AWTsize                           = [System.Windows.Forms.TextRenderer]::MeasureText($AskWoodyLabel.Text, 'Microsoft Sans Serif,10')
$AskWoodyLabel.Width               = $AWTsize.Width+2
$AskWoodyLabel.Height              = 30
$AskWoodyLabel.Top                 = ($BitLockerStatusForm.ClientSize.Height-36)
$AskWoodyLabel.Left                = ($BitLockerStatusForm.ClientSize.Width-$AskWoodyLabel.Width-20)
$AskWoodyLabel.Anchor              = "bottom,right"
$AskWoodyLabel.Add_Click({[system.Diagnostics.Process]::start("http://www.askwoody.com")})
$BitLockerStatusForm.Controls.Add($AskWoodyLabel)

# create close button & add to form
$okBtn                             = New-Object system.Windows.Forms.Button
$okBtn.ForeColor                   = "#000"
$okBtn.Font                        = 'Microsoft Sans Serif,10'
$okBtn.text                        = "Done"
$OBTsize                           = [System.Windows.Forms.TextRenderer]::MeasureText($okBtn.text, 'Microsoft Sans Serif,10')
$okBtn.width                       = $OBTsize.Width+20
$okBtn.height                      = 30
$okBtn.Top                         = ($BitLockerStatusForm.ClientSize.Height-40)
$okBtn.Left                        = ($BitLockerStatusForm.ClientSize.Width/2-$okBtn.width/2)
$okBtn.Anchor                      = "bottom"
$okBtn.BackColor                   = "#e1e1e1"
$okBtn.DialogResult                = [System.Windows.Forms.DialogResult]::OK
$BitLockerStatusForm.AcceptButton  = $okBtn
$BitLockerStatusForm.Controls.Add($okBtn)

# drive label template
$aDrvSummaryTemplate = @{ # Use $var = [system.Windows.Forms.Label] $Template
Font                 = "Microsoft Sans Serif,14"
Width     			 = 610
Location             = New-Object System.Drawing.Point(20,20)
}

# drive textbox template. text is copyable
$aDrvDetailsTemplate = @{ # $var = [System.Windows.Forms.TextBox] $Template
Font                 = "Microsoft Sans Serif,10"
Width     			 = 610
Location             = New-Object System.Drawing.Point(20,20)
ReadOnly             = $true
}
# =============== END CREATE FORM ==============


# ========== MAIN PROGRAM STARTS HERE ==========
 
# Check for Admin privileges
If ((Get-AdminStatus) -eq "User")
<#
 +-------------------------------------+
 | User DOES NOT have Admin privileges |
 | Display prompt to elevate access    |
 +-------------------------------------+
#>
{
    # create "Run as Admin" label & add to form
    $AdminLabel           = New-Object System.Windows.Forms.Label
    $AdminLabel.ForeColor = "red"
    $AdminLabel.Font      = 'Microsoft Sans Serif,14'
    $AdminLabel.text      = $RunAsAdminText
    $ALTsize              = [System.Windows.Forms.TextRenderer]::MeasureText($AdminLabel.text, 'Microsoft Sans Serif,14')
    $AdminLabel.Width     = $ALTsize.Width+10
    $AdminLabel.Height    = $ALTsize.Height
    $AdminLabel.Top       = 14
    $AdminLabel.left      = 20
    $BitLockerStatusForm.controls.Add($AdminLabel)

    # create "Run as Admin" button & add to form
    $AdminBtn             = New-Object system.Windows.Forms.Button
    $AdminBtn.ForeColor   = "#fff"
    $AdminBtn.BackColor   = "#a4ba67"
    $AdminBtn.Font        = 'Microsoft Sans Serif,12'
    $AdminBtn.text        = "Run as Admin"
    $EBTsize              = [System.Windows.Forms.TextRenderer]::MeasureText($AdminBtn.text, 'Microsoft Sans Serif,12')
    $AdminBtn.width       = $EBTsize.Width+20
    $AdminBtn.height      = 30
    $AdminBtn.Top         = ($BitLockerStatusForm.ClientSize.Height-40)
    $AdminBtn.Left        = 20
    $AdminBtn.Anchor      = "bottom,left"
    $AdminBtn.Add_Click({ ElevateUser })
    $BitLockerStatusForm.Controls.Add($AdminBtn)

    # change close button text from "Done" to "Cancel"
    $okBtn.text = "Cancel"

}
Else
<#
 +-------------------------------------+
 | User DOES have Admin privileges     |
 | Display BitLocker status for drives |
 +-------------------------------------+
#>
{

    $aDrvRecoveryDetails = @()

    # get BitLocker status
    $BitlockerVols = (Get-BitLockerVolume | Sort-Object)

    # init drive counter
    $i = 1
    $BitlockerVols | ForEach-Object {

    	if ($_.MountPoint.contains("\\"))
	# ignore network mapped drives
	{
		return
	}

	# set DEFAULT drive label text & color to "not encrypted"
	$DLBackColor = $BackColorOk
	$DLText = $_.MountPoint + $DrvTextOk

	if ($_.EncryptionPercentage -and $_.$KeyProtector -ne $false)
	{
		# drive encrypted and protected so change drive
		# label text & color to "encrypted and protected"
		$DLBackColor = $BackColorEnc
		$DLText = $_.MountPoint + $DrvTextEnc

    		# record recovery key data and add "Backup Recovery Key" button to form
		$RecoveryFileText = $RecoveryFileText + $DrvRecoveryTextA + $_.KeyProtector.KeyProtectorID + $DrvRecoveryTextB + $_.KeyProtector.RecoveryPassword
		BackupKeyButton

	}

	if ($_.EncryptionPercentage -and $_.$KeyProtector -eq $false)
	{
		# drive encrypted but not protected so change drive
		# label text & color to "encrypted but not protected"
		$DLBackColor = $BackColorNoProt
		$DLText = $_.MountPoint + $DrvTextNoProt
	}

		# create ouput for up to 5 drives
		if ($i -lt 6){

			if ($i -eq 1)
			# ouput for drive 1
			{
				$DrvLabel1           = [system.Windows.Forms.Label] $aDrvSummaryTemplate
				$DrvLabel1.BackColor = $DLBackColor
				$DrvLabel1.Text      = $DLText
				$DrvDetails1         = [System.Windows.Forms.TextBox] $aDrvDetailsTemplate
				$DrvDetails1.Text    = $_.MountPoint + "  Drive use: " + $_.VolumeType + ",  %Encrypt: " + $_.VolumeStatus + "   Protection is: " + $_.ProtectionStatus
				$DL1size             = [System.Windows.Forms.TextRenderer]::MeasureText($DrvLabel1.Text, 'Microsoft Sans Serif,14')
				$DT1size             = [System.Windows.Forms.TextRenderer]::MeasureText($DrvDetails1.Text, 'Microsoft Sans Serif,10')
				$DrvLabel1.Height    = $DL1size.Height
				$DrvLabel1.Top       = 20
				$DrvDetails1.Height  = $DT1size.Height
				$DrvDetails1.Top     = $DL1size.Height+$DT1size.Height

				# add controls to form
				$BitLockerStatusForm.controls.Add($DrvLabel1)
				$BitLockerStatusForm.controls.Add($DrvDetails1)
			}

			if ($i -eq 2)
			# ouput for drive 2
			{
				$DrvLabel2           = [system.Windows.Forms.Label] $aDrvSummaryTemplate
				$DrvLabel2.BackColor = $DLBackColor
				$DrvLabel2.Text      = $DLText
				$DrvDetails2         = [System.Windows.Forms.TextBox] $aDrvDetailsTemplate
				$DrvDetails2.Text    = $_.MountPoint + "  Drive use: " + $_.VolumeType + ",  %Encrypt: " + $_.VolumeStatus + "   Protection is: " + $_.ProtectionStatus
				$DL2size             = [System.Windows.Forms.TextRenderer]::MeasureText($DrvLabel2.Text, 'Microsoft Sans Serif,14')
				$DT2size             = [System.Windows.Forms.TextRenderer]::MeasureText($DrvDetails2.Text, 'Microsoft Sans Serif,10')
				$DrvLabel2.Height    = $DL2size.Height
				$DrvLabel2.Top       = $DrvLabel1.Top+$DL1size.Height+$DT1size.Height+20
				$DrvDetails2.Height  = $DT2size.Height
				$DrvDetails2.Top     = $DrvLabel2.Top+$DL2size.Height

				# add controls to form
				$BitLockerStatusForm.controls.Add($DrvLabel2)
				$BitLockerStatusForm.controls.Add($DrvDetails2)
			}

			if ($i -eq 3)
			# ouput for drive 3
			{
				$DrvLabel3           = [system.Windows.Forms.Label] $aDrvSummaryTemplate
				$DrvLabel3.BackColor = $DLBackColor
				$DrvLabel3.Text      = $DLText
				$DrvDetails3         = [System.Windows.Forms.TextBox] $aDrvDetailsTemplate
				$DrvDetails3.Text    = $_.MountPoint + "  Drive use: " + $_.VolumeType + ",  %Encrypt: " + $_.VolumeStatus + "   Protection is: " + $_.ProtectionStatus
				$DL3size             = [System.Windows.Forms.TextRenderer]::MeasureText($DrvLabel3.Text, 'Microsoft Sans Serif,14')
				$DT3size             = [System.Windows.Forms.TextRenderer]::MeasureText($DrvDetails3.Text, 'Microsoft Sans Serif,10')
				$DrvLabel3.Height    = $DL3size.Height
				$DrvLabel3.Top       = $DrvLabel2.Top+$DL2size.Height+$DT2size.Height+20
				$DrvDetails3.Height  = $DT3size.Height
				$DrvDetails3.Top     = $DrvLabel3.Top+$DL3size.Height

				# add controls to form
				$BitLockerStatusForm.controls.Add($DrvLabel3)
				$BitLockerStatusForm.controls.Add($DrvDetails3)
			}

			if ($i -eq 4)
			# ouput for drive 4
			{
				$DrvLabel4           = [system.Windows.Forms.Label] $aDrvSummaryTemplate
				$DrvLabel4.BackColor = $DLBackColor
				$DrvLabel4.Text      = $DLText
				$DrvDetails4         = [System.Windows.Forms.TextBox] $aDrvDetailsTemplate
				$DrvDetails4.Text    = $_.MountPoint + "  Drive use: " + $_.VolumeType + ",  %Encrypt: " + $_.VolumeStatus + "   Protection is: " + $_.ProtectionStatus
				$DL4size             = [System.Windows.Forms.TextRenderer]::MeasureText($DrvLabel4.Text, 'Microsoft Sans Serif,14')
				$DT4size             = [System.Windows.Forms.TextRenderer]::MeasureText($DrvDetails4.Text, 'Microsoft Sans Serif,10')
				$DrvLabel4.Height    = $DL4size.Height
				$DrvLabel4.Top       = $DrvLabel3.Top+$DL3size.Height+$DT3size.Height+20
				$DrvDetails4.Height  = $DT4size.Height
				$DrvDetails4.Top     = $DrvLabel4.Top+$DL4size.Height

				# add controls to form
				$BitLockerStatusForm.controls.Add($DrvLabel4)
				$BitLockerStatusForm.controls.Add($DrvDetails4)
			}

			if ($i -eq 5)
			# ouput for drive 5
			{
				$DrvLabel5           = [system.Windows.Forms.Label] $aDrvSummaryTemplate
				$DrvLabel5.BackColor = $DLBackColor
				$DrvLabel5.Text      = $DLText
				$DrvDetails5         = [System.Windows.Forms.TextBox] $aDrvDetailsTemplate
				$DrvDetails5.Text    = $_.MountPoint + "  Drive use: " + $_.VolumeType + ",  %Encrypt: " + $_.VolumeStatus + "   Protection is: " + $_.ProtectionStatus
				$DL5size             = [System.Windows.Forms.TextRenderer]::MeasureText($DrvLabel5.Text, 'Microsoft Sans Serif,14')
				$DT5size             = [System.Windows.Forms.TextRenderer]::MeasureText($DrvDetails5.Text, 'Microsoft Sans Serif,10')
				$DrvLabel5.Height    = $DL5size.Height
				$DrvLabel5.Top       = $DrvLabel4.Top+$DL4size.Height+$DT4size.Height+20
				$DrvDetails5.Height  = $DT5size.Height
				$DrvDetails5.Top     = $DrvLabel5.Top+$DL5size.Height

				# add controls to form
				$BitLockerStatusForm.controls.Add($DrvLabel5)
				$BitLockerStatusForm.controls.Add($DrvDetails5)
			}

		# increment drive counter
		$i += 1
		}
    }

    # create header for recovery file
    $RecoveryFileText = $DrvRecoveryText + $RecoveryFileText
}

# add spacer so buttons line up properly
ButtonSpacer

# display form
$BitLockerStatusForm.ShowDialog()

# ============== END MAIN PROGRAM ==============
