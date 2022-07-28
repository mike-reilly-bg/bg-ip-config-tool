#Region license
; -----------------------------------------------------------------------------
; This file is part of Simple IP Config.
;
; Simple IP Config is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Simple IP Config is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Simple IP Config.  If not, see <http://www.gnu.org/licenses/>.
; -----------------------------------------------------------------------------
#EndRegion license

;==============================================================================
; Filename:		events.au3
; Description:	- functions called in response to events (button clicks, etc...)
;				- 'onFunctionName' naming convention
;				- also includes WM_COMMAND and WM_NOTIFY
;==============================================================================


;------------------------------------------------------------------------------
; Title........: _onExit
; Description..: Clean up and exit the program
; Events.......: GUI_EVENT_CLOSE, tray item 'Exit', File menu 'Exit'
;------------------------------------------------------------------------------
Func _onExit()
	_GDIPlus_Shutdown()

	; save window position in ini file
	If Not BitAND(WinGetState($hgui), $WIN_STATE_MINIMIZED) Then
		$currentWinPos = WinGetPos($hgui)
		$options.PositionX = $currentWinPos[0]
		$options.PositionY = $currentWinPos[1]
		IniWriteSection($sProfileName, "options", $options.getSection, 0)
	EndIf

	Exit
EndFunc   ;==>_onExit

Func _onCreateLink()
	_CreateLink()
EndFunc   ;==>_onCreateLink

;------------------------------------------------------------------------------
; Title........: _onExitChild
; Description..: Close any child window
; Events.......: child window GUI_EVENT_CLOSE, OK/Cancel button
;------------------------------------------------------------------------------
Func _onExitChild()
	_ExitChild(@GUI_WinHandle)
EndFunc   ;==>_onExitChild

;------------------------------------------------------------------------------
; Title........: _OnTrayClick
; Description..: Restore or hide program to system tray
; Events.......: single left-click on tray icon
;------------------------------------------------------------------------------
Func _OnTrayClick()
	If TrayItemGetText($RestoreItem) = $oLangStrings.traymenu.restore Then
		_maximize()
	Else
		_SendToTray()
	EndIf
EndFunc   ;==>_OnTrayClick

;------------------------------------------------------------------------------
; Title........: _OnRestore
; Description..: Restore or hide program to system tray
; Events.......: 'Restore' item in tray right-click menu
;------------------------------------------------------------------------------
Func _OnRestore()
	If TrayItemGetText($RestoreItem) = $oLangStrings.traymenu.restore Then
		_maximize()
	Else
		_SendToTray()
	EndIf
EndFunc   ;==>_OnRestore

;------------------------------------------------------------------------------
; Title........: _onBlacklist
; Description..: Create the 'Hide adapters' child window
; Events.......: 'Hide adapters' item in the 'View' menu
;------------------------------------------------------------------------------
Func _onBlacklist()
	_form_blacklist()
EndFunc   ;==>_onBlacklist

;------------------------------------------------------------------------------
; Title........: _onRadio
; Description..: Update radio button selections and states
; Events.......: Any radio button state changed
;------------------------------------------------------------------------------
Func _onRadio()
	_radios()
EndFunc   ;==>_onRadio

;------------------------------------------------------------------------------
; Title........: _onSelectionChange
; Description..: Set IP address information from profile
; Events.......: Click on profile list item / deselect a list item
;------------------------------------------------------------------------------
Func _onSelectionChange()
	if $alreadyProcessedSelection Then return
	$alreadyProcessedSelection = True

	; clicked apply button, pressed enter, or double-clicked
	If $firstScan Then
		$selectedProfile = _getSelectedProfile()
		_setGUI($selectedProfile)
		_storeTempProfileValues($selectedProfile)
		_setAllGUILabelsDefault()
		_setAllListViewLabelsDefault()
	Elseif $applyGUIFlag Then
		$lastClickWasProfile = False
		$GUIProfile = _getGUI()
		_storeTempProfileValues($GUIProfile)
		_setAllGUILabelsDefault()
	; clicking in blank listview space or pressing Escape
	Elseif _GUICtrlListView_GetSelectedCount($list_profiles) = 0 Then
		if $lastClickWasProfile Then
			$GUIProfile = _dumpTempProfileValues()
			_setGUI($GUIProfile)
		Else
			$GUIProfile = _getGUI()
			_storeTempProfileValues($GUIProfile)
		EndIf
		$lastClickWasProfile = False
		_setAllGUILabelsDefault()
		_setAllListViewLabelsDefault()
	; clicked while editing GUI values
	ElseIf (Not _checkMouse($list_profiles)) And _
	(StringInStr(ControlGetFocus($hgui),"edit") Or StringInStr(ControlGetFocus($hgui),"button"))  Then
		$lastClickWasProfile = False
		$GUIProfile = _getGUI()
		_storeTempProfileValues($GUIProfile)
		_setAllGUILabelsDefault()
		_setAllListViewLabelsDefault()
		_highlightListViewItemGUIMismatch($GUIProfile)
	; clicked on a profile
	Elseif _checkMouse($list_profiles) Then
		$GUIProfile = _getGUI()
		if Not $lastClickWasProfile Then
			_storeTempProfileValues($GUIProfile)
		EndIf
		$lastClickWasProfile = True
		$selectedProfile = _getSelectedProfile()
		_setGUI($selectedProfile)
		_setAllListViewLabelsDefault()

		; update label colors based on whether the profile and previous gui values match
		_updateLabelColor($radio_IpAuto, $selectedProfile.IpAuto, $tempProfile.IpAuto)
		_updateLabelColor($radio_IpMan, $selectedProfile.IpAuto, $tempProfile.IpAuto)
		_updateLabelColor($label_ip, $selectedProfile.IpAddress, $tempProfile.IpAddress)
		_updateLabelColor($label_subnet, $selectedProfile.IpSubnet, $tempProfile.IpSubnet)
		_updateLabelColor($label_gateway, $selectedProfile.IpGateway, $tempProfile.IpGateway)
		_updateLabelColor($radio_DnsAuto, $selectedProfile.DnsAuto, $tempProfile.DnsAuto)
		_updateLabelColor($label_DnsPri, $selectedProfile.IpDnsPref, $tempProfile.IpDnsPref)
		_updateLabelColor($label_DnsAlt, $selectedProfile.IpDnsAlt, $tempProfile.IpDnsAlt)
		_updateLabelColor($ck_dnsReg, $selectedProfile.RegisterDns, $tempProfile.RegisterDns)
	Else
		return
	EndIf

	_updateApplyButtonColor()
EndFunc   ;==>_onSelectionChange


Func _highlightListViewItemGUIMismatch($guiProfile_1)
	if _GUICtrlListView_GetSelectedCount($list_profiles) <> 0 Then
		$selectedProfile = _getSelectedProfile()
		if $selectedProfile.IpAuto <> $guiProfile_1.IpAuto Or _
		$selectedProfile.IpAddress <> $guiProfile_1.IpAddress Or _
		$selectedProfile.IpSubnet <> $guiProfile_1.IpSubnet Or _
		$selectedProfile.IpGateway <> $guiProfile_1.IpGateway Or _
		$selectedProfile.DnsAuto <> $guiProfile_1.DnsAuto Or _
		$selectedProfile.IpDnsPref <> $guiProfile_1.IpDnsPref Or _
		$selectedProfile.IpDnsAlt <> $guiProfile_1.IpDnsAlt Or _
		$selectedProfile.RegisterDns <> $guiProfile_1.RegisterDns Then
			_updateLabelColor($label_CurrGateway,0)
			;_updateLabelColor(_GUICtrlListView_GetItemParam($list_profiles,_GUICtrlListView_GetSelectedIndices($list_profiles)),0)
			;~ _onRefresh()
		EndIf
		
	EndIf
EndFunc


Func _setAllGUILabelsDefault()
	_updateLabelColor($radio_IpAuto)
	_updateLabelColor($radio_IpMan)
	_updateLabelColor($label_ip)
	_updateLabelColor($label_subnet)
	_updateLabelColor($label_gateway)
	_updateLabelColor($radio_DnsAuto)
	_updateLabelColor($label_DnsPri)
	_updateLabelColor($label_DnsAlt)
	_updateLabelColor($ck_dnsReg)
EndFunc


Func _setAllListViewLabelsDefault()
	_updateLabelColor($label_CurrGateway)
	;~ for $i = 0 to (_GUICtrlListView_GetItemCount($list_profiles) - 1)
	;~ 	_updateLabelColor(_GUICtrlListView_GetItemParam($list_profiles,$i))
	;~ Next
EndFunc


Func _updateLabelColor($labelHandle, $param1 = 1 , $param2 = 1)
	if $param1 = $param2 Then
		GUICtrlSetBkColor($labelHandle, $values_match_bk_color)
	Else
		GUICtrlSetBkColor($labelHandle, $values_no_match_bk_color)
	EndIf
EndFunc


;------------------------------------------------------------------------------
; Title........: _onApply
; Description..: Apply the selected profile
; Events.......: File menu 'Apply profile' button, toolbar 'Apply' button
;------------------------------------------------------------------------------
Func _onApply()
	_applyGUI()
EndFunc   ;==>_onApply

;------------------------------------------------------------------------------
; Title........: _onArrangeAz
; Description..: Arrange profiles in alphabetical order
; Events.......: Profiles listview context menu item
;------------------------------------------------------------------------------
Func _onArrangeAz()
	_arrange()
EndFunc   ;==>_onArrangeAz

;------------------------------------------------------------------------------
; Title........: _onArrangeZa
; Description..: Arrange profiles in reverse alphabetical order
; Events.......: Profiles listview context menu item
;------------------------------------------------------------------------------
Func _onArrangeZa()
	_arrange(1)
EndFunc   ;==>_onArrangeZa

;------------------------------------------------------------------------------
; Title........: _onRename
; Description..: Start editing profile name for the selected listview item
; Events.......: Profiles listview context menu item, F2 accelerator,
;                File menu 'Rename' item
;------------------------------------------------------------------------------
Func _onRename()
	If Not _ctrlHasFocus($list_profiles) Then
		Return
	EndIf
	$Index = _GUICtrlListView_GetSelectedIndices($list_profiles)
	$lvEditHandle = _GUICtrlListView_EditLabel(ControlGetHandle($hgui, "", $list_profiles), $Index)
EndFunc   ;==>_onRename


;------------------------------------------------------------------------------
; Title........: _onTabKey
; Description..: Cancel editing listview item - prevents system from tabbing
;					through listview items while editing
; Events.......: TAB key (while editing)
;------------------------------------------------------------------------------
Func _onTabKey()
	If IsHWnd(_GUICtrlListView_GetEditControl(ControlGetHandle($hgui, "", $list_profiles))) Then
		$lvTabKey = True
		Send("{ENTER}")		
		; IP address fields go:
		; 12 11 10 9
		; 16 15 14 13
		; 20 19 18 17
	Elseif Mod(Int(StringReplace(ControlGetFocus($hgui),"Edit",""))-5, 4) > 0 Then
		Send("^{RIGHT}")
	Else
		GUISetAccelerators(0)
		Send("{TAB}")
		GUISetAccelerators($aAccelKeys)
	EndIf
EndFunc


;------------------------------------------------------------------------------
; Title........: _onNewItem
; Description..: Create new listview item and start editing the name
; Events.......: Toolbar button, File menu 'New' item
;------------------------------------------------------------------------------
Func _onNewItem()
	$newname = $oLangStrings.message.newItem
	;Local $profileNames = _getNames()
	Local $profileNames = $profiles.getNames()
	Local $i = 1
	While _ArraySearch($profileNames, $newname) <> -1
		$newname = "New Item " & $i
		$i = $i + 1
	WEnd

	GUISwitch($hgui)
	ControlFocus($hgui, "", $list_profiles)
	GUICtrlCreateListViewItem($newname, $list_profiles)
	GUICtrlSetOnEvent(-1, "_onSelectionChange")
	$lv_newItem = 1
	$Index = ControlListView($hgui, "", $list_profiles, "GetItemCount")
	ControlListView($hgui, "", $list_profiles, "Select", $Index - 1)
	_GUICtrlListView_EditLabel(ControlGetHandle($hgui, "", $list_profiles), $Index - 1)
EndFunc   ;==>_onNewItem

;------------------------------------------------------------------------------
; Title........: _onSave
; Description..: Save the current settings to the selected profile
; Events.......: Toolbar button, File menu 'Save' item, Ctrl+s accelerator
;------------------------------------------------------------------------------
Func _onSave()
	_save()
EndFunc   ;==>_onSave

;------------------------------------------------------------------------------
; Title........: _onDelete
; Description..: Delete the selected profile
; Events.......: Toolbar button, Del accelerator
;------------------------------------------------------------------------------
Func _onDelete()
	_delete()
EndFunc   ;==>_onDelete

;------------------------------------------------------------------------------
; Title........: _onClear
; Description..: Clear the current address fields
; Events.......: Toolbar button, File menu 'Clear' item
;------------------------------------------------------------------------------
Func _onClear()
	_clear()
EndFunc   ;==>_onClear

;------------------------------------------------------------------------------
; Title........: _onRefresh
; Description..: Refresh the profiles list and current IP info
; Events.......: Toolbar button, View menu 'Refresh' item
;------------------------------------------------------------------------------
Func _onRefresh()
	$showWarning = 0
	$Index = ControlListView($hgui, "", $list_profiles, "GetSelected")
	_refresh()
	ControlListView($hgui, "", $list_profiles, "Select", $Index)
EndFunc   ;==>_onRefresh

;------------------------------------------------------------------------------
; Title........: _onLvDel
; Description..: Delete the selected listview item
; Events.......: File menu Delete item, listview context menu Delete item
;------------------------------------------------------------------------------
Func _onLvDel()
	If _ctrlHasFocus($list_profiles) Then
		_delete()
	Else
		GUISetAccelerators(0)
		Send("{DEL}")
		GUISetAccelerators($aAccelKeys)
	EndIf
EndFunc   ;==>_onLvDel

;------------------------------------------------------------------------------
; Title........: _onLvUp
; Description..: Move listview selection up 1 index and get the profile info
; Events.......: UP key accelerator
;------------------------------------------------------------------------------
Func _onLvUp()
	$alreadyProcessedSelection = False
	
	If _ctrlHasFocus($list_profiles) Then
		$Index = ControlListView($hgui, "", $list_profiles, "GetSelected")
		ControlListView($hgui, "", $list_profiles, "Select", $Index - 1)
		_onSelectionChange()
	Else
		GUISetAccelerators(0)
		Send("{Up}")
		GUISetAccelerators($aAccelKeys)
	EndIf
EndFunc   ;==>_onLvUp

;------------------------------------------------------------------------------
; Title........: _onLvDown
; Description..: Move listview selection down 1 index and get the profile info
; Events.......: DOWN key accelerator
;------------------------------------------------------------------------------
Func _onLvDown()
	$alreadyProcessedSelection = False
	
	If _ctrlHasFocus($list_profiles) Then
		$Index = ControlListView($hgui, "", $list_profiles, "GetSelected")
		ControlListView($hgui, "", $list_profiles, "Select", $Index + 1)
		_onSelectionChange()
	Else
		GUISetAccelerators(0)
		Send("{Down}")
		GUISetAccelerators($aAccelKeys)
	EndIf
EndFunc   ;==>_onLvDown


;------------------------------------------------------------------------------
; Title........: _onLvEnter
; Description..: Apply the selected profile
; Events.......: Enter key on listview item
;------------------------------------------------------------------------------
Func _onLvEnter()
	If Not $lv_editing Then
		_applyGUI()
	; If focus is on list view item
	;ElseIf 
	Else
		GUISetAccelerators(0)
		Send("{ENTER}")
		GUISetAccelerators($aAccelKeys)
	EndIf
EndFunc   ;==>_onLvEnter


;------------------------------------------------------------------------------
; Title........: _onESCKey
; Description..: Unselect listview item
; Events.......: Escape key on listview item
;------------------------------------------------------------------------------
Func _onESCKey()
	If _ctrlHasFocus($list_profiles) Then
		_GUICtrlListView_SetItemSelected($list_profiles, -1, False)
		$alreadyProcessedSelection = False
		_onSelectionChange()
	Else
		GUISetAccelerators(0)
		Send("{ESC}")
		GUISetAccelerators($aAccelKeys)
	EndIf
EndFunc


;------------------------------------------------------------------------------
; Title........: _onTray
; Description..: Hide or show main GUI window
; Events.......: Toolbar button, View menu "Send to tray" item
;------------------------------------------------------------------------------
Func _onTray()
	_SendToTray()
EndFunc   ;==>_onTray


;------------------------------------------------------------------------------
; Title........: _onPull
; Description..: Get current IP information from adapter
; Events.......: Tools menu "Pull from adapter" item
;------------------------------------------------------------------------------
Func _onPull()
	_Pull()
EndFunc   ;==>_onPull


;------------------------------------------------------------------------------
; Title........: _onDisable
; Description..: Disable / Enable the selected adapter
; Events.......: Tools menu "Disable adapter" item
;------------------------------------------------------------------------------
Func _onDisable()
	_disable()
EndFunc   ;==>_onDisable


;------------------------------------------------------------------------------
; Title........: _onRelease
; Description..: Release DHCP for the selected adapter
; Events.......: Tools menu "Release DHCP" item
;------------------------------------------------------------------------------
Func _onRelease()
	_releaseDhcp()
EndFunc   ;==>_onRelease


;------------------------------------------------------------------------------
; Title........: _onRenew
; Description..: Renew DHCP for the selected adapter
; Events.......: Tools menu "Renew DHCP" item
;------------------------------------------------------------------------------
Func _onRenew()
	_renewDhcp()
EndFunc   ;==>_onRenew


;------------------------------------------------------------------------------
; Title........: _onCycle
; Description..: Release DHCP followed by Renew DHCP for the selected adapter
; Events.......: Tools menu "Release/renew cycle" item
;------------------------------------------------------------------------------
Func _onCycle()
	_cycleDhcp()
EndFunc   ;==>_onCycle


;------------------------------------------------------------------------------
; Title........: _onSettings
; Description..: Create the settings child window
; Events.......: Tools menu "Settings" item
;------------------------------------------------------------------------------
Func _onSettings()
	_formm_settings()
EndFunc   ;==>_onSettings


;------------------------------------------------------------------------------
; Title........: _onHelp
; Description..: Navigate to documentation link <-- needs to be created!
; Events.......: Help menu "Online Documentation" item
;------------------------------------------------------------------------------
Func _onHelp()
	ShellExecute('https://github.com/KurtisLiggett/Simple-IP-Config/wiki')
EndFunc   ;==>_onHelp

Func _onUpdateCheckItem()
	$suppressComError = 1
	_checksSICUpdate(1)
	$suppressComError = 0
EndFunc   ;==>_onUpdateCheckItem


;------------------------------------------------------------------------------
; Title........: _onDebugItem
; Description..: Create debug child window
; Events.......: Help menu "Debug Information" item
;------------------------------------------------------------------------------
Func _onDebugItem()
	_form_debug()
EndFunc   ;==>_onDebugItem


;------------------------------------------------------------------------------
; Title........: _onChangelog
; Description..: Create change log child window
; Events.......: Help menu "Show Change Log" item
;------------------------------------------------------------------------------
Func _onChangelog()
	_form_changelog()
EndFunc   ;==>_onChangelog


;------------------------------------------------------------------------------
; Title........: _onAbout
; Description..: Create the About child window
; Events.......: Help menu "About Simple IP Config" item, tray right-click menu
;------------------------------------------------------------------------------
Func _onAbout()
	_form_about()
EndFunc   ;==>_onAbout


;------------------------------------------------------------------------------
; Title........: _onFilter
; Description..: Filter the profiles listview
; Events.......: Filter input text change
;------------------------------------------------------------------------------
Func _onFilter()
	_filterProfiles()
EndFunc   ;==>_onFilter


;------------------------------------------------------------------------------
; Title........: _OnCombo
; Description..: Update adapter information, save last used adapter to profiles.ini
; Events.......: Combobox selection change
;------------------------------------------------------------------------------
Func _OnCombo()
	_updateCurrent()
	$adap = GUICtrlRead($combo_adapters)
	$iniAdap = iniNameEncode($adap)
	$ret = IniWrite($sProfileName, "options", "StartupAdapter", $iniAdap)
	If $ret = 0 Then
		_setStatus("An error occurred while saving the selected adapter", 1)
	Else
		$options.StartupAdapter = $adap
	EndIf
EndFunc   ;==>_OnCombo


;------------------------------------------------------------------------------
; Title........: _iconLink
; Description..: Open browser and go to icon website
; Events.......: Click on link in About window
;------------------------------------------------------------------------------
Func _iconLink()
	ShellExecute('http://www.aha-soft.com/')
	GUICtrlSetColor(@GUI_CtrlId, 0x551A8B)
EndFunc   ;==>_iconLink


;------------------------------------------------------------------------------
; Title........: _updateLink
; Description..: Open browser and go to latest version
; Events.......: Click on link in update window
;------------------------------------------------------------------------------
Func _updateLink()
	$sURL = "https://github.com/KurtisLiggett/Simple-IP-Config/releases/latest"
	ShellExecute($sURL)
	GUICtrlSetColor(@GUI_CtrlId, 0x551A8B)
EndFunc   ;==>_updateLink


;------------------------------------------------------------------------------
; Title........: _onOpenProfiles
; Description..: Open a custom profiles.ini file
; Events.......: File menu
;------------------------------------------------------------------------------
Func _onOpenProfiles()
	$OpenFileFlag = 1
EndFunc   ;==>_onOpenProfiles


;------------------------------------------------------------------------------
; Title........: _onImportProfiles
; Description..: Import profiles from a file
; Events.......: File menu
;------------------------------------------------------------------------------
Func _onImportProfiles()
	$ImportFileFlag = 1
EndFunc   ;==>_onImportProfiles


;------------------------------------------------------------------------------
; Title........: _onExportProfiles
; Description..: export profiles to a file
; Events.......: File menu
;------------------------------------------------------------------------------
Func _onExportProfiles()
	$ExportFileFlag = 1
EndFunc   ;==>_onExportProfiles


;------------------------------------------------------------------------------
; Title........: _onOpenProfLoc
; Description..: open folder containing profiles.ini file
; Events.......: Tools menu
;------------------------------------------------------------------------------
Func _onOpenProfLoc()
;~ 	Local $path = StringRegExp($sProfileName, "(.*)\\", $STR_REGEXPARRAYGLOBALMATCH)
	Local $path = $sProfileName
	Run("explorer.exe /n,/e,/select," & $path)
EndFunc   ;==>_onExportProfiles


;------------------------------------------------------------------------------
; Title........: _onOpenNetConnections
; Description..: open the network connections dialog
; Events.......: Tools menu
;------------------------------------------------------------------------------
Func _onOpenNetConnections()
	ShellExecute("ncpa.cpl")
EndFunc   ;==>_onOpenNetConnections


;------------------------------------------------------------------------------
; Title........: WM_COMMAND
; Description..: Process WM_COMMAND messages
;                - Toolbar buttons
;                - Listview filter
;                - Combobox selection changed
;------------------------------------------------------------------------------
Func WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)

	Local $ID = BitAND($wParam, 0xFFFF)

	Local $iIDFrom = BitAND($wParam, 0x0000FFFF) ; LoWord - this gives the control which sent the message
	Local $iCode = BitShift($wParam, 16)     ; HiWord - this gives the message that was sent
	Local $tempstring, $iDot1Pos, $iDot2Pos, $iDot3Pos, $SplitString, $temp, $tip

	Switch $hWnd
		Case $hgui
			If $iCode = $EN_CHANGE Then
				Switch $iIDFrom
					Case $input_filter
						GUICtrlSendToDummy($filter_dummy)
				EndSwitch
			ElseIf $iCode = $CBN_CLOSEUP Then    ; check if combo was closed
				Switch $iIDFrom
					Case $combo_adapters
						GUICtrlSendToDummy($combo_dummy)
				EndSwitch
			EndIf
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_COMMAND

;------------------------------------------------------------------------------
; Title........: WM_NOTIFY
; Description..: Process WM_NOTIFY messages
;                - Toolbar tooltips
;                - Listview begin/end label edit
;                - Detect moving from IP address to Subnet mask
;------------------------------------------------------------------------------
Func WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	Local $tNMIA = DllStructCreate($tagNMITEMACTIVATE, $lParam)
	Local $hTarget = DllStructGetData($tNMIA, 'hWndFrom')
	Local $ID = DllStructGetData($tNMIA, 'Code')

	$hWndListView = $list_profiles
	If Not IsHWnd($hWndListView) Then $hWndListView = GUICtrlGetHandle($hWndListView)

	$tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")

	Switch $hWnd
		Case $hgui
			Switch $hWndFrom
				Case $hWndListView
					Switch $iCode
						Case $LVN_BEGINLABELEDITA, $LVN_BEGINLABELEDITW ; Start of label editing for an item
							$lv_editIndex = _GUICtrlListView_GetSelectedIndices($list_profiles)
							$lv_oldName = ControlListView($hgui, "", $list_profiles, "GetText", $lv_editIndex)
							$lv_editing = 1
							$lv_startEditing = 0
							$lv_aboutEditing = 0
							Return False
						Case $LVN_ENDLABELEDITA, $LVN_ENDLABELEDITW ; The end of label editing for an item
							$lv_doneEditing = 1
							$lv_editing = 0
							$tInfo = DllStructCreate($tagNMLVDISPINFO, $lParam)
							If _WinAPI_GetAsyncKeyState($VK_RETURN) == 1 Then    ;enter key was pressed
								Local $tBuffer = DllStructCreate("char Text[" & DllStructGetData($tInfo, "TextMax") & "]", DllStructGetData($tInfo, "Text"))
								If StringLen(DllStructGetData($tBuffer, "Text")) Then
									Return True
								Else
									If $lv_newItem = 1 Then
										_GUICtrlListView_DeleteItem(ControlGetHandle($hgui, "", $list_profiles), $lv_editIndex)
										$lv_newItem = 0
									EndIf
									$lv_aboutEditing = 1
								EndIf
							Else
								If $lv_newItem = 1 Then
									_GUICtrlListView_DeleteItem(ControlGetHandle($hgui, "", $list_profiles), $lv_editIndex)
									$lv_newItem = 0
								EndIf
								$lv_aboutEditing = 1
							EndIf
					EndSwitch
				Case $ip_Ip
					Switch $iCode
						Case $IPN_FIELDCHANGED ; Sent when the user changes a field in the control or moves from one field to another
;~ 							$tInfo = DllStructCreate($tagNMIPADDRESS, $lParam)
;~ 							$movetosubnet = DllStructGetData($tInfo, "hWndFrom")
							$movetosubnet = 1
					EndSwitch
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY
