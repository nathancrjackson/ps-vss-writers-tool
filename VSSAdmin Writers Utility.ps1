param(
	[bool]	$Debug = $FALSE
)

#
# VSSAdmin Writers Utility
# Version 1.0.0
# https://github.com/nathancrjackson/ps-vss-writers-util
#

FUNCTION CheckElevated
{
	[OutputType([Bool])]
	Param()

	$User = [Security.Principal.WindowsIdentity]::GetCurrent();

	$Elevated = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

	RETURN $Elevated
}

#Check if user is running as administrator
IF (CheckElevated)
{
	#Prep keypress storage
	$KeyPress = $NULL

	#Start a loop
	DO
	{
		#Break loop if key is anything unpressed or R, otherwise clear screen
		IF ($KeyPress -ne $NULL -AND $KeyPress.Character -ne 'r')
			{ BREAK }
		ELSEIF ($KeyPress.Character -eq 'r')
			{ CLEAR }

		#Get VSS data and record time metric
		$CommandStartTime = Get-Date
		$VSSAdminOutput = & "vssadmin" "List" "Writers"
		$CommandEndTime = Get-Date
		$CommandTime = (($CommandEndTime.ToUniversalTime()) - ($CommandStartTime.ToUniversalTime())).TotalSeconds

		#Debug: Output raw data
		IF ($Debug)
		{
			Write-Host "--- Output Start ---"
			$VSSAdminOutput
			Write-Host "--- Output End ---`n"
		}

		#Handle the case of a long output time
		$StartLine = 3
		IF ($VSSAdminOutput[$StartLine] -like "*Waiting for responses*")
			{ $StartLine = 6 }

		#Debug: Inform of start line
		IF ($Debug)
			{ Write-Host "--- Start Line: $StartLine`n" }

		#Prep result object
		$WriterObject = New-Object PSObject
		$WritersArray = @()

		#Go through output and extract data
		FOR ($Line = $StartLine; $Line -lt $VSSAdminOutput.Count; $Line++)
		{

			#WORKS BUT DROPPED FOR OLDER COMPATIBILITY
			#IF (![string]::IsNullOrWhitespace($VSSAdminOutput[$Line])) {

			$LineNotNull = [bool]$VSSAdminOutput[$Line]
			IF ($LineNotNull)
			{

				IF ($Debug)
					{ Write-Host "--- Processing Line: $Line" }

				$LineData = $VSSAdminOutput[$Line] -split ':'
				$LineData[0] = $LineData[0].Trim()
				$LineData[1] = ($LineData[1].Trim()).Trim("'")
				Add-Member -InputObject $WriterObject -MemberType NoteProperty -Name $LineData[0] -Value $LineData[1]
			}
			ELSE
			{
				IF($Debug)
					{ Write-Host "--- Null Line: $Line" }

				$WritersArray += $WriterObject

				$WriterObject = New-Object PSObject
			}
		}

		#Sort array by Writer Name for ease of reference
		$WritersArray = $WritersArray | Sort-Object -Property 'Writer Name'

		#Create a list for failed writers, go through each and add appropriately
		$NonstableWriterList = @()
		FOREACH ($Writer in $WritersArray)
		{
			IF ($Writer.State -ne "[1] Stable")
			{
				$WriterError = $Writer.'Writer name' + " (" + $Writer.'Last error' + ")"
				$NonstableWriterList += $Writer | Select 'Writer name', 'State', 'Last error'
			}
			$Writer
		}

		#Output how long the VSSAdmin command took
		Write-Host "`nVSSAdmin command took: $CommandTime seconds`n`n"

		#If we had failures, sort the list and output
		IF ($NonstableWriterList.Count -gt 0)
		{
			$NonstableWriterList = $NonstableWriterList | Sort-Object -Property 'State', 'Last Error', 'Writer Name'

			Write-Host -noNewLine "The following is a list of non-stable writers and their errors:`n"
			Format-Table -InputObject $NonstableWriterList | Out-String
		}
		ELSE
		{
			Write-Host "No writers had errors`n`n"
		}

		Write-Host "Press r to rerun or any other key to exit"

		#Clear the key press buffer otherwise we can get multiple reruns
		$Host.UI.RawUI.FlushInputBuffer()
	}
	WHILE ($KeyPress = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyUp'))

#END OF ADMIN AREA
}
ELSE
{
	Write-Host "Please run script as Administrator`n"
	Write-Host "Press any key to exit`n"

	$Host.UI.RawUI.ReadKey() | Out-Null
}


