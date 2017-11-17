-----------------------------------------------------------------------------------------------
-- Client Lua Script for BenikUI_ShortcutBar
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "Unit"
require "ActionSetLib"

local BenikUI_ShortcutBar = {}
local knVersion			= 1
local knMaxBars			= ActionSetLib.CodeEnumShortcutSet.Count
local knStartingBar		= 4 -- Skip 1 to 3, as that is the Engineer Bar and Engineer Pet Bars, which is handled in EngineerResource

function BenikUI_ShortcutBar:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	return o
end

function BenikUI_ShortcutBar:Init()
	Apollo.RegisterAddon(self, nil, nil, {"BenikUI_ActionBar"})
end

function BenikUI_ShortcutBar:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("BenikUI_ShortcutBar.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)

	self.bDocked = false
	self.bHorz = true
end

function BenikUI_ShortcutBar:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	local tSavedData =
	{
		nVersion = knVersion,
		OffsetsMain = self.OffsetsMain
	}

	return tSavedData
end

function BenikUI_ShortcutBar:OnRestore(eType, tSavedData)
	if tSavedData.nVersion ~= knVersion then
		return
	end
	
	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		if tSavedData.OffsetsMain ~= nil then
			self.OffsetsMain = tSavedData.OffsetsMain
		end
	end

	self.tSavedData = tSavedData
end

function BenikUI_ShortcutBar:OnDocumentReady()
	self.bTimerRunning = false
	self.timerShorcutArt = ApolloTimer.Create(0.5, false, "OnActionBarShortcutArtTimer", self)
	self.timerShorcutArt:Stop()
	Apollo.RegisterEventHandler("ShowActionBarShortcut", "ShowWindow", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", "OnTutorial_RequestUIAnchor", self)

	local tShortcutCount = {}

	self.tActionBarSettings = {}

	--Floating Bar - Need to refactor
	self.tActionBars = {}
	for idx = knStartingBar, knMaxBars do
		local wndCurrBar = Apollo.LoadForm(self.xmlDoc, "ActionBarShortcut", nil, self)
		wndCurrBar:FindChild("ActionBarContainer"):DestroyChildren() -- TODO can remove
		wndCurrBar:Show(false)

		for nButton = 0, 7 do
			local wndBarItem = Apollo.LoadForm(self.xmlDoc, "ActionBarShortcutItem", wndCurrBar:FindChild("ActionBarContainer"), self)
			wndBarItem:FindChild("ActionBarShortcutBtn"):SetContentId(idx * 12 + nButton)
			if wndBarItem:FindChild("ActionBarShortcutBtn"):GetContent()["strIcon"] ~= "" then
				tShortcutCount[idx] = nButton + 1
			end
			if nButton <7 then
				wndBarItem:FindChild("EditBox"):SetText(GameLib.GetKeyBinding("FloatingActionBar_Slot"..tostring(nButton+1)))
			else
				wndBarItem:FindChild("EditBox"):SetText("")
			end
		end
		self.tActionBars[idx] = wndCurrBar
		self:ArrangeGridWithGab(wndCurrBar:FindChild("ActionBarContainer"),5)
	end
	
	for idx = knStartingBar, knMaxBars do
		self:ShowWindow(idx, IsActionBarSetVisible(idx), tShortcutCount[idx])
	end
	
	self:SetWindows()
end

function BenikUI_ShortcutBar:SetWindows()
	if self.OffsetsMain ~= nil then
		local l,t,r,b = unpack(self.OffsetsMain)
		for idx = knStartingBar, knMaxBars do
			self.tActionBars[idx]:SetAnchorOffsets(l,t,r,b)
		end
	end
end


function BenikUI_ShortcutBar:ShowWindow(nBar, bIsVisible, nShortcuts)
	
    if self.tActionBars[nBar] == nil then
		return
	end
	
	self.tActionBarSettings[nBar] = {}
	self.tActionBarSettings[nBar].bIsVisible = bIsVisible
	self.tActionBarSettings[nBar].nShortcuts = nShortcuts

	if nShortcuts and bIsVisible then
		self.tActionBars[nBar]:Show(bIsVisible)
	end
	
	if not self.bTimerRunning then
		self.timerShorcutArt:Start()
		self.bTimerRunning = true
	end

	self.tActionBars[nBar]:Show(bIsVisible)
end

function BenikUI_ShortcutBar:OnActionBarShortcutArtTimer()
	self.bTimerRunning = false
	local bBarVisible = false

	for nbar, tSettings in pairs(self.tActionBarSettings) do
		bBarVisible = bBarVisible or (tSettings.bIsVisible and self.bDocked)
	end

	Event_FireGenericEvent("ShowActionBarShortcutDocked", bBarVisible)
	for idx = knStartingBar, knMaxBars do
		self.tActionBars[idx]:ToFront()
	end
end


function BenikUI_ShortcutBar:OnGenerateTooltip(wndControl, wndHandler, eType, oArg1, oArg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_ItemInstance then
		local itemEquipped = oArg1:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, oArg1, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
		--Tooltip.GetItemTooltipForm(self, wndControl, itemEquipped, {bPrimary = false, bSelling = false, itemCompare = oArg1}) -- OLD
	elseif eType == Tooltip.TooltipGenerateType_ItemData then
		local itemEquipped = oArg1:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, oArg1, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
		--Tooltip.GetItemTooltipForm(self, wndControl, itemEquipped, {bPrimary = false, bSelling = false, itemCompare = oArg1}) - OLD
	elseif eType == Tooltip.TooltipGenerateType_GameCommand then
		xml = XmlDoc.new()
		xml:AddLine(oArg2)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Macro then
		xml = XmlDoc.new()
		xml:AddLine(oArg1)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Spell then
		Tooltip.GetSpellTooltipForm(self, wndControl, oArg1)
	elseif eType == Tooltip.TooltipGenerateType_PetCommand then
		xml = XmlDoc.new()
		xml:AddLine(oArg2)
		wndControl:SetTooltipDoc(xml)
	end
end

function BenikUI_ShortcutBar:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors =
	{
		[GameLib.CodeEnumTutorialAnchor.FloatingActionBar]				= true,
		[GameLib.CodeEnumTutorialAnchor.FloatingActionBarSecondButton]	= true,
		[GameLib.CodeEnumTutorialAnchor.FloatingActionBarFifthButton]	= true,
	}

	if not tAnchors[eAnchor] or not self.tActionBarSettings[ActionSetLib.CodeEnumShortcutSet.FloatingSpellBar].bIsVisible then
		return
	end
	local tAnchorToButton =
	{
		[GameLib.CodeEnumTutorialAnchor.FloatingActionBar]				= 1,
		[GameLib.CodeEnumTutorialAnchor.FloatingActionBarSecondButton]	= 2,
		[GameLib.CodeEnumTutorialAnchor.FloatingActionBarFifthButton]	= 5,
	}
	local nButton = tAnchorToButton[eAnchor]

	local wndActionBar = nil
	local eOrientationOverride = nil
	if self.bDocked then
		eOrientationOverride = GameLib.CodeEnumTutorialAnchorOrientation.South
		for nBar, wndBar in pairs(self.tActionBars) do
			if wndBar:IsVisible() then
				wndActionBar = wndBar
				break
			end
		end
	elseif self.bHorz then
		eOrientationOverride = GameLib.CodeEnumTutorialAnchorOrientation.North
		for nBar, wndBar in pairs(self.tActionBarsHorz) do
			if wndBar:IsVisible() then
				wndActionBar = wndBar
				break
			end
		end
	else
		eOrientationOverride = GameLib.CodeEnumTutorialAnchorOrientation.Northwest
		for nBar, wndBar in pairs(self.tActionBarsVert) do
			if wndBar:IsVisible() then
				wndActionBar = wndBar
				break
			end
		end
	end

	if wndActionBar then
		local wndChild = wndActionBar:FindChild("ActionBarContainer"):GetChildren()[nButton]
		if wndChild then
			Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, wndChild, eOrientationOverride)
		end
	end
end


function BenikUI_ShortcutBar:ArrangeGridWithGab(wnd,gab)
	local last = 0
	local height = 0
	local children = wnd:GetChildren()
	local l,t,r,b = wnd:GetParent():GetAnchorOffsets()
	local l2,t2,r2,b2 = wnd:GetAnchorOffsets()
	b = b+b2
	t = t+t2
	r = r+r2
	l = l+l2
	local wndHeight = math.abs(b-t)
	local wndWidth = math.abs(r-l)
	l,t,r,b = children[1]:GetAnchorOffsets()
	wndHeight = wndHeight - math.abs(r-l)
	for i,j in pairs(children) do
		local l,t,r,b = j:GetAnchorOffsets()
		local width = math.abs(r-l)
		if last+width > wndWidth then
			last = 0
			height = height + math.abs(b-t)+gab
		end
		j:SetAnchorOffsets(last,height,last+width,height+b)
		last = last +width +gab
	end

---------------------------------------------------------------------------------------------------
-- ActionBarShortcut Functions
---------------------------------------------------------------------------------------------------
end
function BenikUI_ShortcutBar:OnBarMoved( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	local l,t,r,b = wndControl:GetAnchorOffsets()
	self.OffsetsMain = {l,t,r,b}
end

-----------------------------------------------------------
local ActionBarShortcut_Singleton = BenikUI_ShortcutBar:new()
ActionBarShortcut_Singleton:Init()
