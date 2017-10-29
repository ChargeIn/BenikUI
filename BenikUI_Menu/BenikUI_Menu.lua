----------------------------------------------------------------------------------------------
-- Client Lua Script for BenikUI_Menu
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "Apollo"

local BenikUI_Menu = {}
local knVersion = 2

function BenikUI_Menu:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function BenikUI_Menu:Init()
    Apollo.RegisterAddon(self)
end

function BenikUI_Menu:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	local nRegisteredAddons = self:GetTableSize(self.tMenuData)
	if #self.tPinnedAddons > nRegisteredAddons then
		self.tPinnedAddons = {}
	end

	local tSavedData = {
		nVersion = knVersion,
		tPinnedAddons = self.tPinnedAddons,
	}

	return tSavedData
end

function BenikUI_Menu:OnRestore(eType, tSavedData)
	if tSavedData.nVersion ~= knVersion then
		return
	end

	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	if tSavedData.tPinnedAddons then
		self.tPinnedAddons = tSavedData.tPinnedAddons
	end

	self.tSavedData = tSavedData
end


function BenikUI_Menu:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("BenikUI_Menu.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function BenikUI_Menu:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("InterfaceMenuList_NewAddOn", 			"OnNewAddonListed", self)
	Apollo.RegisterEventHandler("InterfaceMenuList_AlertAddOn", 		"OnDrawAlert", self)
	Apollo.RegisterEventHandler("CharacterCreated", 					"OnCharacterCreated", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 			"OnTutorial_RequestUIAnchor", self)
	Apollo.RegisterEventHandler("ApplicationWindowSizeChanged", 		"ButtonListRedraw", self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged",				"OnAccountCurrencyChanged", self)

	self.timerQueueRedrawTimer = ApolloTimer.Create(0.3, false, "OnQueuedRedraw", self)
	self.timerQueueRedrawTimer:Stop()

    self.wndMain = Apollo.LoadForm(self.xmlDoc , "InterfaceMenuListForm", "FixedHudStratumHigh", self)
	self.wndList = Apollo.LoadForm(self.xmlDoc , "FullListFrame", nil, self)

	self.wndMain:FindChild("OpenFullListBtn"):AttachWindow(self.wndList)

	Apollo.CreateTimer("QueueRedrawTimer", 0.3, false)

	if not self.tPinnedAddons then
		self.tPinnedAddons = {
			Apollo.GetString("InterfaceMenu_AccountInventory"),
			Apollo.GetString("InterfaceMenu_Character"),
			Apollo.GetString("InterfaceMenu_AbilityBuilder"),
			Apollo.GetString("InterfaceMenu_QuestLog"),
			Apollo.GetString("InterfaceMenu_GroupFinder"),
			Apollo.GetString("InterfaceMenu_Social"),
			Apollo.GetString("InterfaceMenu_Mail"),
			Apollo.GetString("InterfaceMenu_Lore"),
		}
	end

	self.tMenuData = {
		[Apollo.GetString("InterfaceMenu_SystemMenu")] = { "", "Escape", "Icon_Windows32_UI_CRB_InterfaceMenu_EscMenu" },
		[Apollo.GetString("InterfaceMenu_Store")] = { "", "Store", "Icon_Windows32_UI_CRB_InterfaceMenu_Credd" },
	}

	local wndInterfaceMenuBtn = Apollo.LoadForm(self.xmlDoc , "InterfaceMenuButton", nil, self)
	self.knInterfaceMenuBtnWidth = wndInterfaceMenuBtn:GetWidth()
	wndInterfaceMenuBtn:Destroy()

	self.tMenuTooltips = {}
	self.tMenuAlerts = {}

	self:ButtonListRedraw()

	local nFortuneCoinAmount = AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.MysticShiny):GetAmount()
	self.wndMain:FindChild("CoinsPendingAnim"):Show(nFortuneCoinAmount > 0)

	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	end

	Event_FireGenericEvent("InterfaceMenuListHasLoaded")
end

function BenikUI_Menu:OnListShow()
	self.wndList:ToFront()
end

function BenikUI_Menu:OnCharacterCreated()
end

function BenikUI_Menu:OnAccountCurrencyChanged()
	if self.wndMain ~= nil and self.wndMain:IsValid() then
		local nFortuneCoinAmount = AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.MysticShiny):GetAmount()
		self.wndMain:FindChild("CoinsPendingAnim"):Show(nFortuneCoinAmount > 0)
	end
end

function BenikUI_Menu:OnNewAddonListed(strKey, tParams)
	if type(strKey) ~= "string" or type(tParams) ~= "table" then
		return
	end

	strKey = string.gsub(strKey, ":", "|") -- ":'s don't work for window names, sorry!"

	self.tMenuData[strKey] = tParams

	self:FullListRedraw()
	self:ButtonListRedraw()
end

function BenikUI_Menu:IsPinned(strText)
	local nHasTableValue = self:GetPinIndex(self.tPinnedAddons,strText)
	if nHasTableValue ~= nil then
			return true
		end

	return false
end

function BenikUI_Menu:FullListRedraw()
	local strUnbound = Apollo.GetString("Keybinding_Unbound")
	local wndParent = self.wndList:FindChild("FullListScroll")

	local strQuery = Apollo.StringToLower(tostring(self.wndList:FindChild("SearchEditBox"):GetText()) or "")
	if strQuery == nil or strQuery == "" or not strQuery:match("[%w%s]+") then
		strQuery = ""
	end

	for strAddonName, tData in pairs(self.tMenuData) do
		local bSearchResultMatch = string.find(Apollo.StringToLower(strAddonName), strQuery) ~= nil

		if strQuery == "" or bSearchResultMatch then
			local wndMenuItem = self:LoadByName("MenuListItem", wndParent, strAddonName)
			local wndMenuButton = self:LoadByName("InterfaceMenuButton", wndMenuItem:FindChild("Icon"), strAddonName)
			local strTooltip = strAddonName

			if Apollo.StringLength(tData[2]) > 0 then
				local strKeyBindLetter = GameLib.GetKeyBinding(tData[2])
				strKeyBindLetter = strKeyBindLetter == strUnbound and "" or string.format(" (%s)", strKeyBindLetter)  -- LOCALIZE

				strTooltip = strKeyBindLetter ~= "" and strTooltip .. strKeyBindLetter or strTooltip
			end

			if tData[3] ~= "" then
				wndMenuButton:FindChild("Icon"):SetSprite(tData[3])
			else
				wndMenuButton:FindChild("Icon"):SetText(string.sub(strTooltip, 1, 1))
			end

			wndMenuButton:FindChild("ShortcutBtn"):SetData(strAddonName)
			wndMenuButton:FindChild("Icon"):SetTooltip(strTooltip)
			self.tMenuTooltips[strAddonName] = strTooltip

			wndMenuItem:FindChild("MenuListItemBtn"):SetText(strAddonName)
			wndMenuItem:FindChild("MenuListItemBtn"):SetData(strAddonName)

			wndMenuItem:FindChild("PinBtn"):SetCheck(self:IsPinned(strAddonName))
			wndMenuItem:FindChild("PinBtn"):SetData(strAddonName)

			if Apollo.StringLength(tData[2]) > 0 then
				local strKeyBindLetter = GameLib.GetKeyBinding(tData[2])
				wndMenuItem:FindChild("MenuListItemBtn"):FindChild("MenuListItemKeybind"):SetText(strKeyBindLetter == strUnbound and "" or string.format("(%s)", strKeyBindLetter))  -- LOCALIZE
			end
		elseif not bSearchResultMatch and wndParent:FindChild(strAddonName) then
			wndParent:FindChild(strAddonName):Destroy()
		end
		if self.tMenuAlerts[strAddonName] then
			self:OnDrawAlertVisual(strAddonName, self.tMenuAlerts[strAddonName])
		end
	end

	wndParent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function (a,b) return a:GetName() < b:GetName() end)
end

function BenikUI_Menu:ButtonListRedraw()
	self.timerQueueRedrawTimer:Start()
end

function BenikUI_Menu:OnQueuedRedraw()
	local wndParent = self.wndMain:FindChild("ButtonList")
	wndParent:DestroyChildren()

	for idx, strPinName in ipairs(self.tPinnedAddons) do
		self:AddPinToButtonList(strPinName)
	end
end

function BenikUI_Menu:AddPinToButtonList(strAddonName)
	local wndParent = self.wndMain:FindChild("ButtonList")
	local nParentWidth = wndParent:GetWidth()
	local nLastButtonWidth = 0
	local nTotalWidth = 0
	local tData = self.tMenuData[strAddonName]

	if tData then -- Checks that the AddOn has loaded/added info to the Menu Data table.
		local wndMenuItem = self:LoadByName("InterfaceMenuButton", wndParent, strAddonName)
		local strTooltip = strAddonName

			if Apollo.StringLength(tData[2]) > 0 then
			local strKeyBindLetter = GameLib.GetKeyBinding(tData[2])
			strKeyBindLetter = strKeyBindLetter == strUnbound and "" or string.format(" (%s)", strKeyBindLetter)  -- LOCALIZE
			strTooltip = strKeyBindLetter ~= "" and strTooltip .. strKeyBindLetter or strTooltip
		end

		if tData[3] ~= "" then
			wndMenuItem:FindChild("Icon"):SetSprite(tData[3])
		else
			wndMenuItem:FindChild("Icon"):SetText(string.sub(strTooltip, 1, 1))
		end

		wndMenuItem:FindChild("ShortcutBtn"):SetData(strAddonName)
		wndMenuItem:FindChild("Icon"):SetTooltip(strTooltip)
		wndMenuItem:SetName("InterfaceMenuButton_" .. strAddonName)
	end

	wndParent:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)

	if self.tMenuAlerts[strAddonName] then
		self:OnDrawAlertVisual(strAddonName, self.tMenuAlerts[strAddonName])
	end
end

function BenikUI_Menu:RemovePinFromButtonList(strAddonName)
	local wndParent = self.wndMain:FindChild("ButtonList")
	local wndButtonListItem = wndParent:FindChild("InterfaceMenuButton_" .. strAddonName)

	if wndButtonListItem then
		wndButtonListItem:Destroy()
		wndParent:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end
end

function BenikUI_Menu:OnListClose()
	self.wndMain:FindChild("OpenFullListBtn"):SetCheck(false)
end

-----------------------------------------------------------------------------------------------
-- Search
-----------------------------------------------------------------------------------------------

function BenikUI_Menu:OnSearchEditBoxChanged(wndHandler, wndControl)
	self.wndList:FindChild("SearchClearBtn"):Show(Apollo.StringLength(wndHandler:GetText() or "") > 0)
	self:FullListRedraw()
end

function BenikUI_Menu:OnSearchClearBtn(wndHandler, wndControl)
	self.wndList:FindChild("SearchFlash"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
	self.wndList:FindChild("SearchFlash"):SetFocus()
	self.wndList:FindChild("SearchClearBtn"):Show(false)
	self.wndList:FindChild("SearchEditBox"):SetText("")
	self:FullListRedraw()
end

function BenikUI_Menu:OnSearchCommitBtn(wndHandler, wndControl)
	self.wndList:FindChild("SearchFlash"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
	self.wndList:FindChild("SearchFlash"):SetFocus()
	self:FullListRedraw()
end

-----------------------------------------------------------------------------------------------
-- Alerts
-----------------------------------------------------------------------------------------------

function BenikUI_Menu:OnDrawAlert(strAddonName, tParams)-- Should be reserved for AddOns pushing updates.
	if type(strAddonName) ~= "string" or type(tParams) ~= "table" then
		return
	end

	local wndButtonList = self.wndMain:FindChild("ButtonList")
	local wndButtonListItem = wndButtonList:FindChild("InterfaceMenuButton_" .. strAddonName)
	local nPinIndex = self:GetPinIndex(self.tPinnedAddons, strAddonName)

	if wndButtonListItem and nPinIndex ~= nil then
		local wndButton = wndButtonListItem:FindChild("ShortcutBtn")
		if tParams[3] and (self.tMenuAlerts[strAddonName] == nil or self.tMenuAlerts[strAddonName][3] < tParams[3]) then -- Make sure # of alerts is going up before displaying blip
			local wndFlash = self:LoadByName("AlertBlip", wndButton:FindChild("Alert"), "AlertBlip")
			wndFlash:FindChild("Sonar"):SetSprite("PlayerPathContent_TEMP:spr_Crafting_TEMP_Stretch_QuestZoneNoLoop")
		elseif wndButton:FindChild("AlertBlip") ~= nil then
			wndButton:FindChild("AlertBlip"):Destroy()
		end
	end

	self.tMenuAlerts[strAddonName] = tParams
	self:OnDrawAlertVisual(strAddonName, tParams)
end

function BenikUI_Menu:OnDrawAlertVisual(strAddonName, tParams)

	local wndButtonList = self.wndMain:FindChild("ButtonList")
	local wndButtonListItem = wndButtonList:FindChild("InterfaceMenuButton_" .. strAddonName)
	local nPinIndex = self:GetPinIndex(self.tPinnedAddons, strAddonName)

	if wndButtonListItem and nPinIndex ~= nil then
		local wndButton = wndButtonListItem:FindChild("ShortcutBtn")
		local wndIcon = wndButton:FindChild("Icon")

		if tParams[1] then
			local wndIndicator = self:LoadByName("AlertIndicator", wndButton:FindChild("Alert"), "AlertIndicator")
		elseif wndButton:FindChild("AlertIndicator") ~= nil then
			wndButton:FindChild("AlertIndicator"):Destroy()
		end

		if tParams[2] then
			wndIcon:SetTooltip(string.format("%s\n\n%s", self.tMenuTooltips[strAddonName], tParams[2]))
		end

		if tParams[3] and tParams[3] > 0 then
			local strColor = tParams[1] and "UI_WindowTextOrange" or "UI_TextHoloTitle"

			wndButton:FindChild("Number"):Show(true)
			wndButton:FindChild("Number"):SetText(tParams[3])
			wndButton:FindChild("Number"):SetTextColor(ApolloColor.new(strColor))
		else
			wndButton:FindChild("Number"):Show(false)
			wndButton:FindChild("Number"):SetText("")
			wndButton:FindChild("Number"):SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
		end
	end

	local wndParent = self.wndList:FindChild("FullListScroll")
	for idx, wndTarget in pairs(wndParent:GetChildren()) do
		local wndButton = wndTarget:FindChild("ShortcutBtn")
		local wndIcon = wndButton:FindChild("Icon")

		if wndButton:GetData() == strAddonName then
			if tParams[1] then
				local wndIndicator = self:LoadByName("AlertIndicator", wndButton:FindChild("Alert"), "AlertIndicator")
			elseif wndButton:FindChild("AlertIndicator") ~= nil then
				wndButton:FindChild("AlertIndicator"):Destroy()
			end

			if tParams[2] then
				wndIcon:SetTooltip(string.format("%s\n\n%s", self.tMenuTooltips[strAddonName], tParams[2]))
			end

			if tParams[3] and tParams[3] > 0 then
				local strColor = tParams[1] and "UI_WindowTextOrange" or "UI_TextHoloTitle"

				wndButton:FindChild("Number"):Show(true)
				wndButton:FindChild("Number"):SetText(tParams[3])
				wndButton:FindChild("Number"):SetTextColor(ApolloColor.new(strColor))
			else
				wndButton:FindChild("Number"):Show(false)
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Helpers and Errata
-----------------------------------------------------------------------------------------------

function BenikUI_Menu:OnMenuListItemClick(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end

	local strKey = wndHandler:GetData()
	local strMappingResult = (strKey and self.tMenuData[strKey]) and self.tMenuData[strKey][1] or ""

	if Apollo.StringLength(strMappingResult) > 0 then
		Event_FireGenericEvent(strMappingResult)
	else
		if strKey == Apollo.GetString("InterfaceMenu_SystemMenu") then
			InvokeOptionsScreen()
		elseif strKey == Apollo.GetString("InterfaceMenu_Store") then
			GameLib.OpenStore()
		else
			InvokeOptionsScreen()
		end
	end

	self.wndList:Close()
end

function BenikUI_Menu:OnPinChecked(wndHandler, wndControl)
	local strPinName = wndControl:GetData()
	local nPinTableSize = self:GetTableSize(self.tPinnedAddons) + 1
	table.insert(self.tPinnedAddons, strPinName)
	self:AddPinToButtonList(strPinName )
end

function BenikUI_Menu:OnPinUnchecked(wndHandler, wndControl)
	local strPinName = wndControl:GetData()
	local nPinIndex = self:GetPinIndex(self.tPinnedAddons, strPinName)

	if nPinIndex > 0 then
		table.remove(self.tPinnedAddons, nPinIndex) -- Remove from pinned table
	end

	self:RemovePinFromButtonList(strPinName)
end

function BenikUI_Menu:OnListBtnClick(wndHandler, wndControl) -- These are the five always on icons on the top
	if wndHandler ~= wndControl then return end
	local strKey = wndHandler:GetData()
	local strMappingResult = wndHandler:GetData() and self.tMenuData[strKey][1] or ""

	if Apollo.StringLength(strMappingResult) > 0 then
		Event_FireGenericEvent(strMappingResult)
	else
		if strKey == Apollo.GetString("InterfaceMenu_SystemMenu") then
			InvokeOptionsScreen()
		elseif strKey == Apollo.GetString("InterfaceMenu_Store") then
			GameLib.OpenStore()
		else
			InvokeOptionsScreen()
		end
	end

	--If AddOn has a new alert, remove it once the window has been opened.
	local wndAlertActive = wndControl:FindChild("AlertBlip") or nil
	if wndAlertActive ~= nil then
		wndAlertActive:Destroy()
	end
end

function BenikUI_Menu:OnListBtnMouseEnter(wndHandler, wndControl)
	wndHandler:SetBGColor("ffffffff")
	if wndHandler ~= wndControl or self.wndList:IsVisible() then
		return
	end
end

function BenikUI_Menu:OnListBtnMouseExit(wndHandler, wndControl) -- Also self.wndMain MouseExit and ButtonList MouseExit
	wndHandler:SetBGColor("9dffffff")
end

function BenikUI_Menu:OnOpenFullListCheck(wndHandler, wndControl)
	self.wndList:FindChild("SearchEditBox"):SetFocus()
	self.wndList:Invoke()
	self:FullListRedraw()
end

function BenikUI_Menu:OnLoginRewardsOpenBtn(wndHandler, wndControl)
	Event_FireGenericEvent("OpenDailyLogin")
end

function BenikUI_Menu:LoadByName(strForm, wndParent, strCustomName)
	local wndNew = wndParent:FindChild(strCustomName)
	if not wndNew then
		wndNew = Apollo.LoadForm(self.xmlDoc , strForm, wndParent, self)
		wndNew:SetName(strCustomName)
	end
	return wndNew
end

function BenikUI_Menu:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors =
	{
		[GameLib.CodeEnumTutorialAnchor.LASBuilderButton] 			= true,
		[GameLib.CodeEnumTutorialAnchor.InterfaceMenuListCharacter] = true,
		[GameLib.CodeEnumTutorialAnchor.FortuneButton]				= true,
		[GameLib.CodeEnumTutorialAnchor.StorefrontButton]			= true,
	}

	if not tAnchors[eAnchor] or not self.wndMain then
		return
	end

	local tAnchorMapping =
	{
		[GameLib.CodeEnumTutorialAnchor.LASBuilderButton]			= self.wndMain:FindChild("ButtonList"),
		[GameLib.CodeEnumTutorialAnchor.InterfaceMenuListCharacter]	= self.wndMain:FindChild("ButtonList"),
		[GameLib.CodeEnumTutorialAnchor.FortuneButton]				= self.wndMain:FindChild("MTX"),
		[GameLib.CodeEnumTutorialAnchor.StorefrontButton]			= self.wndMain:FindChild("OpenMarketplaceBtn"),
	}

	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

function BenikUI_Menu:OnGatchaOpenBtn(wndHandler, wndControl)
	GameLib.OpenFortunes()
end

function BenikUI_Menu:OnMarketplaceOpenBtn(wndHandler, wndControl)

	if wndControl:FindChild("MTXBtn_Runner"):IsShown() then
		wndControl:FindChild("MTXBtn_Runner"):Show(false)
	end

	GameLib.OpenStore()
end

function BenikUI_Menu:GetTableSize(tName)
	local nCount = 0
	for _ in pairs(tName) do
		nCount = nCount + 1
	end
	return nCount
end

function BenikUI_Menu:GetPinIndex(tName, strValue)
	for idx, strPinName in ipairs(tName) do
		if strPinName == strValue then
			return idx
		end
	end
	return nil
end

local InterfaceMenuListInst = BenikUI_Menu:new()
InterfaceMenuListInst:Init()
