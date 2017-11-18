
require "Window"
require "Apollo"
require "GameLib"
require "Spell"
require "AbilityBook"
require "ActionSetLib"
require "Tooltip"

local ChargeUI_SkillSwitch = {}

-- A "static constructor" ----------------------------------------------------------------------

local function Initialize()
    setmetatable({}, ChargeUI_SkillSwitch)
    ChargeUI_SkillSwitch.__index = ChargeUI_SkillSwitch
    Apollo.RegisterAddon(ChargeUI_SkillSwitch, true, "ChargeUI_SkillSwitch")
   	ChargeUI_SkillSwitch.defaultSettings = { buttonWidth = 45, buttonHeight = 22,
   									buttonYOffset = -12,
   									showTooltips = true,
   									maxShortcuts = 3,
   									debug = false,
   									menuButtonSize = 50,
   									enablePathFlyOut = true,
   									enableMenuButtons = true,
   									invisibleActivationButtons = false }
	ChargeUI_SkillSwitch.settings = ChargeUI_SkillSwitch.defaultSettings
end

-- Public entry points -------------------------------------------------------------------------

function ChargeUI_SkillSwitch:OnLoad()
	self:WriteDebug("Loading ChargeUI_SkillSwitch")
	Apollo.RegisterSlashCommand("SkillSwitch", "OnSlashCommand", self)
	Apollo.RegisterSlashCommand("skillswitch", "OnSlashCommand", self)
	Apollo.RegisterSlashCommand("ss", "OnSlashCommand", self)

	Apollo.RegisterTimerHandler("SkillSwitchCloseFlyOutTimer", "CloseFlyOutByTimer",self)
	Apollo.RegisterTimerHandler("SkillSwitchCloseAbilityMenuTimer", "CloseAbilityMenuByTimer",self)
	Apollo.RegisterTimerHandler("SkillSwitchLoadTimer", "LoadUI", self)

	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
	Apollo.RegisterEventHandler("PlayerLevelChange", "CreateFlyOutButtons", self)

	self.xmlDoc = XmlDoc.CreateFromFile("ChargeUI_SkillSwitch.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)

	self.swapHistory = {}
end

function ChargeUI_SkillSwitch:OnSlashCommand(command, args)
	local argWords = {}
	local word = ""

	if (args ~= nil and args ~= "") then
		argWords = SplitString(args)
		if (argWords ~= nil) then
			word = argWords[1]:lower()
		end
	end

	if (word == "swap") then
		self:OnSwapCommand(argWords)
	elseif (word == "reset") then
		self.settings = self.defaultSettings
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, "SkillSwitch settings have been reset")
	elseif (word == "clear") then
		self.swapHistory = {}
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, "SkillSwitch history has been cleared")
	elseif (word == "debug") then
		self.settings.debug = not self.settings.debug
		if (self.settings.debug) then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, "SkillSwitch debug flag turned on")
		else
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, "SkillSwitch debug flag turned off")
		end
	else
		self:OpenConfigurationWindow()
	end
end

function ChargeUI_SkillSwitch:OnConfigure()
	self:OpenConfigurationWindow()
end

function ChargeUI_SkillSwitch:OnSave(eLevel)
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
		data = {}
		data.swapHistory = self.swapHistory
		data.settings = self.settings
		return data
	end
end

function ChargeUI_SkillSwitch:OnRestore(eLevel, tSavedData)
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
		data = tSavedData or {}
		self.swapHistory = data.swapHistory or {}
		if (data.settings) then
			self.settings = self:CoalesceTables(data.settings, self.defaultSettings)
		end
	end
end

function ChargeUI_SkillSwitch:OnEnteredCombat(unitChecked, bInCombat)
	if (unitChecked == GameLib.GetPlayerUnit() and self.flyOutButtons) then
		if (bInCombat) then
			for _,w in pairs(self.flyOutButtons) do
				w:Show(false)
			end
			self:CloseFlyOut()
			self:CloseAbilityMenu()
		else
			for _,w in pairs(self.flyOutButtons) do
				w:Show(true, true)
			end
		end
	end
end

-- UI STARTUP ----------------------------------------------------------------

function ChargeUI_SkillSwitch:OnDocLoaded()
	Apollo.CreateTimer("SkillSwitchLoadTimer", 6, false)
end

function ChargeUI_SkillSwitch:LoadUI()
	self.abilityMenuWindow = Apollo.LoadForm(self.xmlDoc, "AbilityMenu", nil, self)
	self.flyOutWindow = Apollo.LoadForm(self.xmlDoc, "FlyOutWindow", nil, self)

	self:CreateFlyOutButtons()
end

-- FLYOUT BUTTONS ------------------------------------------------------------

function ChargeUI_SkillSwitch:CreateFlyOutButtons()
	if (self.flyOutButtons) then
		for _,button in pairs(self.flyOutButtons) do
			button:Destroy()
		end
	end

	self.flyOutButtons= {}

	local buttonDataList = nil

	buttonDataList = self:GetActionButtonPositions()
	if (buttonDataList == nil ) then
		self:WriteDebug("No action button host addon found")
		return
	end

	for i, buttonData in pairs(buttonDataList) do
		if (ActionSetLib.IsSlotUnlocked(buttonData.lasIndex - 1) == 1) then
			self:WriteDebug("Creating activation button")
			local win = Apollo.LoadForm(self.xmlDoc, "FlyOutButtonWindow", nil, self)
			if (self.settings.invisibleActivationButtons) then
				win:SetSprite(nil)
			end
			win:SetData({lasIndex=buttonData.lasIndex, type=buttonData.type, actionButtonInfo = buttonData})
			self.flyOutButtons[#self.flyOutButtons + 1] = win
			self:PositionFlyOutButton(win)
			win:Show(true)
		end
	end
end

function ChargeUI_SkillSwitch:GetActionButtonPositions()
	local buttonPositions = {}
	local windowPositionCache = {}

	--buttonPositions = self:GetActionButtonsCandyBars()
	--if (buttonPositions == nil) then
		--buttonPositions = self:GetActionButtonsCarbine("VikingActionBarFrame")
	--end
	--if (buttonPositions == nil) then
		--buttonPositions = self:GetActionButtonsCarbine("ActionBarFrame")
	--end

	buttonPositions = self:GetActionButtonsCarbine("ChargeUI_ActionBar")

	return buttonPositions
end

function ChargeUI_SkillSwitch:GetActionButtonsCarbine(addonName)
	local addon = Apollo.GetAddon(addonName)
	if (addon == nil) then
		self:WriteDebug(addonName .. " is not enabled")
		return nil
	end
	local lasButtons = addon.arBarButtons
	if (lasButtons == nil or lasButtons[1] == nil or lasButtons[8] == nil) then
		self:WriteDebug("No action buttons found in " .. addonName)
		return nil
	end
	local result = {}
	local windowPositionCache = {}
	for i = 1,8 do
		result[#result+1] = self:CreateAbilityButtonData(lasButtons[i], i, windowPositionCache, "skill")
	end


	if (self.settings.enablePathFlyOut) then
		pathButtonContainer = addon.wndMain:FindChild("Bar1ButtonSmallContainer:Buttons")
		pathButton = self:FindLasButton(pathButtonContainer, ActionSetLib.GetCurrentActionSet()[10])
		if (pathButton ~= nil) then
			result[#result+1] = self:CreateAbilityButtonData(pathButton, 10, windowPositionCache, "path")
		end
	end

	-- if (self.settings.enablePathFlyOut and lasButtons[10] ~= nil) then
	-- 	result[#result+1] = self:CreateAbilityButtonData(lasButtons[10], 10, windowPositionCache, "path")
	-- end
	return result
end

function ChargeUI_SkillSwitch:GetActionButtonsCandyBars()
	self:WriteDebug("Checking for CandyBars addon")
	local addon = Apollo.GetAddon("CandyBars")
	if (addon == nil) then
		self:WriteDebug("No action buttons found in CandyBars addon")
		return nil
	end

	if (addon.actionButtons == nil) then
		self:WriteDebug("No action buttons found in CandyBars addon")
		return nil
	end

	local result = {}
	local windowPositionCache = {}
	local startIndex = 1
	local endIndex = 8
	if (addon.db.profile.actionBar.bReverseOrder) then
		startIndex = 8
		endIndex = 1
	end
	for i = 1,8 do
		local buttonWindow = self:FindLasButton(addon.actionButtons[i])
		if (buttonWindow == nil) then
			self:WriteDebug("No LASbutton found in actionButton " .. i)
		else
			result[#result+1] = self:CreateAbilityButtonData(buttonWindow, i, windowPositionCache, "skill")
		end
	end

	if (self.settings.enablePathFlyOut) then
		local pathButton = nil
		for _, bFrame in pairs(addon.utilityButtons1) do
			pathButton = self:FindLasButton(bFrame, ActionSetLib.GetCurrentActionSet()[10])
			if (pathButton ~= nil) then
				break
			end
		end
		if (pathButton == nil) then
			for _, bFrame in pairs(addon.utilityButtons2) do
				pathButton = self:FindLasButton(bFrame, ActionSetLib.GetCurrentActionSet()[10])
				if (pathButton ~= nil) then
					break
				end
			end
		end

		if (pathButton ~= nil) then
			result[#result+1] = self:CreateAbilityButtonData(pathButton, 10, windowPositionCache, "path")
		end
	end

	return result
end

function ChargeUI_SkillSwitch:FindLasButton(window, skillId)
	if (self:IsActionBarButton(window, skillId)) then
		return window
	end
	for _,child in pairs(window:GetChildren()) do
		local result = self:FindLasButton(child, skillId)
		if (result) then
			return result
		end
	end
	return nil
end

function ChargeUI_SkillSwitch:FindLasButtons(window, result)
	if (self:IsActionBarButton(window)) then
		result[#result+1] = window
	end
	for _,child in pairs(window:GetChildren()) do
		self:FindLasButtons(child, result)
	end
end

function ChargeUI_SkillSwitch:IsActionBarButton(window, skillId)
	if (window == nil or window["GetContent"] == nil) then
		return false
	end
	local content = window:GetContent()
	if (content.strType == "LASBar") then
		if (skillId ~= nil) then
			self:WriteDebug("comparing with skillId " .. skillId)
			if (content.spell) then
				self:WriteDebug("found " .. content.spell:GetBaseSpellId())
			end
			return content.spell ~= nil and content.spell:GetBaseSpellId() == skillId
		else
			return true
		end
	end
	return false
end

function ChargeUI_SkillSwitch:CreateAbilityButtonData(window, lasIndex, windowPositionCache, type)
	--self:WriteDebug("Creating ability button data, win = " .. window:GetName() .. " lasIndex = " .. lasIndex)
	x,y,scale = self:GetAbsolutePosition(window, windowPositionCache)
	local r = window:GetClientRect()
	return { x=x, y=y, scale=scale, width=r.nWidth, height=r.nHeight, lasIndex=lasIndex, type=type}
end

function ChargeUI_SkillSwitch:PositionFlyOutButton(flyOutButton)
	local buttonInfo = flyOutButton:GetData().actionButtonInfo

	local xOffset = (buttonInfo.width * buttonInfo.scale - self.settings.buttonWidth) / 2
	local x = buttonInfo.x + xOffset * buttonInfo.scale
	local y = buttonInfo.y + self.settings.buttonYOffset * buttonInfo.scale
	local w = x + self.settings.buttonWidth
	local h = y + self.settings.buttonHeight

	flyOutButton:SetAnchorOffsets(x+2, y, w-2, h-10)
end

-- function ChargeUI_SkillSwitch:GetAddonWindows(addon)
-- 	local windows = {}
-- 	for _, item in pairs(addon) do
-- 		if (type(item) == "userdata" and item["GetChildren"] ~= nil) then
-- 			windows[#windows+1] = item
-- 		end
-- 	end
-- 	return windows
-- end

function ChargeUI_SkillSwitch:RepositionFlyOutButtons()
	for _, button in pairs(self.flyOutButtons) do
		self:PositionFlyOutButton(button)
	end
end

function ChargeUI_SkillSwitch:OnOpenFlyOutButtonEnter( wndHandler, wndControl, x, y )
	self:WriteDebug("-> SkillSwitch:OnOpenFlyOutButtonEnter")

	if ((self.currentFlyOutButton == nil) or (self.currentFlyOutButton ~= wndControl)) then
		local buttonData = wndControl:GetData()
		self:PopulateAndOpenFlyOut(buttonData.lasIndex, buttonData.type, wndControl)
	end
end

function ChargeUI_SkillSwitch:OnOpenFlyOutButtonExit( wndHandler, wndControl, x, y )
	self:CloseFlyOutSoon()
end

function ChargeUI_SkillSwitch:PopulateAndOpenFlyOut(lasIndex, type, ownerButton)
	for _,child in pairs(self.flyOutWindow:GetChildren()) do
		child:Destroy()
	end

	local oldSkillId = ActionSetLib.GetCurrentActionSet()[lasIndex]

	local targetTier = 1
	if (self.settings.showTooltips and oldSkillId ~= nil and oldSkillId ~= 0) then
		targetTier = self:GetCurrentTierForLasSkill(oldSkillId)
	end

	if (self.settings.enableMenuButtons) then
		if (type == "skill") then
			self:CreateAbilityMenuButton("Assault", Spell.CodeEnumSpellTag.Assault, lasIndex, 100, targetTier)
			self:CreateAbilityMenuButton("Support", Spell.CodeEnumSpellTag.Support, lasIndex, 99, targetTier)
			self:CreateAbilityMenuButton("Utility", Spell.CodeEnumSpellTag.Utility, lasIndex, 98, targetTier)
		elseif (type == "path") then
			self:CreateAbilityMenuButton("Skills", Spell.CodeEnumSpellTag.Path, lasIndex, 100, targetTier)
		end
	end

	for i, skillId in pairs(self:GetSuggestedSkillsToSwapTo(lasIndex, oldSkillId)) do
		self:WriteDebug("Adding history skill " .. skillId)
		local skill = self:GetAvailableAssaultSkills()[skillId] or self:GetAvailableSupportSkills()[skillId] or self:GetAvailableUtilitySkills()[skillId] or self:GetAvailablePathSkills()[skillId]
		if (skill) then
			self:CreateSwapButton(skill, lasIndex, i, targetTier)
		end
	end

	self.flyOutWindow:ArrangeChildrenVert(2, function(a,b) return a:GetData().prio >= b:GetData().prio end)

	local x, y = self:GetAbsolutePosition(ownerButton)

	local xDiff = (ownerButton:GetClientRect().nWidth - self.settings.menuButtonSize) / 2.0

	x = x + xDiff + 2

	self:WriteDebug(x)

	self.flyOutWindow:SetAnchorPoints(0,0,0,0)
	self.flyOutWindow:SetAnchorOffsets(x, y-600, x+self.settings.menuButtonSize, y)
	self.flyOutWindow:ToFront()
	self.flyOutWindow:Show(true, true)
	self.currentFlyOutButton = ownerButton

	self.flyOutWindow:Show(true,true)

end

function ChargeUI_SkillSwitch:GetCurrentTierForLasSkill(skillId)
	for _, s in pairs(AbilityBook.GetAbilitiesList()) do
		if (s.nId == skillId) then
			return s.nCurrentTier
		end
	end
	return nil
end


function ChargeUI_SkillSwitch:CreateAbilityMenuButton(caption, skillCategory, lasIndex, prio, targetTier)
	if (next(self:GetAbilityMenuSkills(lasIndex, skillCategory)) ~= nil) then
		local button = Apollo.LoadForm(self.xmlDoc, "SkillSwitchButton", self.flyOutWindow, self)
		button:SetText(caption)
		button:SetAnchorPoints(0,0,0,0)
		button:SetAnchorOffsets(0,0,self.settings.menuButtonSize,self.settings.menuButtonSize)
		button:SetData({ type = "menu", skillCategory = skillCategory, lasIndex = lasIndex, prio = prio, targetTier = targetTier })
	end
end

function ChargeUI_SkillSwitch:CreateSwapButton(skill, lasIndex, prio, targetTier)
	local button = Apollo.LoadForm(self.xmlDoc, "SkillSwitchButton", self.flyOutWindow, self)
	button:SetSprite(skill.icon)
	local buttonData = { type="history", lasIndex = lasIndex, newSkillId = skill.id, prio = prio }


	if (targetTier) then
		local tieredSkill = skill.tiers[targetTier]
		if (tieredSkill) then
			buttonData.tieredSkill = tieredSkill.splObject
		end
	end

	button:SetAnchorPoints(0,0,0,0)
	button:SetAnchorOffsets(0,0,self.settings.menuButtonSize,self.settings.menuButtonSize)
	button:SetData(buttonData)
	return button
end


function ChargeUI_SkillSwitch:CloseFlyOutSoon(timeOut)
	self:WriteDebug("-> CloseFlyOutSoon")
	if (timeOut == nil) then
		timeOut = 0.2
	end
	Apollo.CreateTimer("SkillSwitchCloseFlyOutTimer",timeOut,false)
end

function ChargeUI_SkillSwitch:CloseFlyOutByTimer()
	self:WriteDebug("-> CloseFlyOutByTimer")
	local w = Apollo.GetMouseTargetWindow()
	if (w and (w:GetName() == "SkillSwitchButton" or w:GetName() == "FlyOutButtonWindow")) then
		self:WriteDebug("Exiting CloseFlyOutByTimer, mouse is on a " .. w:GetName())
		return
	end

	self:CloseFlyOut()
end

function ChargeUI_SkillSwitch:CloseFlyOut()
	self:WriteDebug("-> CloseFlyOut")
	if (self.flyOutWindow:IsVisible()) then
		self:WriteDebug("Closing flyOut")
		self.flyOutWindow:Show(false)
	end
	self.currentFlyOutButton = nil
end

function ChargeUI_SkillSwitch:GetSuggestedSkillsToSwapTo(lasIndex, oldId)
	self:WriteDebug("Suggestions to swap from " .. oldId)

	local historyList = nil
	if (lasIndex == 10) then
		historyList = self.swapHistory["path"]
	else
		local setHistory = self.swapHistory[AbilityBook.GetCurrentSpec()]
		if (setHistory) then
			historyList = setHistory[lasIndex]
		end
	end

	local result = {}
	if (historyList) then
		if (historyList) then
			for _,new in pairs(historyList) do
				if (oldId and new ~= oldId) then
					result[#result+1] = new
				end
				if (#result >= self.settings.maxShortcuts) then
					break
				end
			end
		end
	end
	return result
end

---------------------- ChargeUI_SkillSwitchButton -------------------------------

function ChargeUI_SkillSwitch:OnSkillSwitchButtonEnter( wndHandler, wndControl, x, y )
	self:WriteDebug("-> OnSkillSwitchButtonEnter")

	local buttonData = wndControl:GetData()
	local buttonType = buttonData.type

	if (buttonType == "menu" and self.currentAbilityMenuButton ~= wndControl) then
		self:WriteDebug("Entering new menu button")
		self:PopulateAbilityMenu(buttonData.lasIndex, buttonData.skillCategory, buttonData.targetTier)
		self:OpenAbilityMenu(wndControl)
	end
end

function ChargeUI_SkillSwitch:OnSkillSwitchButtonExit( wndHandler, wndControl, x, y )
	self:WriteDebug("-> OnSkillSwitchButtonExit")
	self:CloseFlyOutSoon()
	self:CloseAbilityMenuSoon()
end

function ChargeUI_SkillSwitch:OnSkillSwitchButtonClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	self:WriteDebug("-> OnSkillSwitchButtonClick, button = " .. eMouseButton)

	local buttonData = wndControl:GetData()
	if (buttonData and (buttonData.type == "history" or buttonData.type == "abilityMenu")) then
		--right click
		if (eMouseButton == 1) then
			if (buttonData.type == "history") then
				self:RemoveSwapHistory(buttonData.lasIndex, buttonData.newSkillId)
				self:CloseFlyOut()
			end
		else
			self:Swap(buttonData.lasIndex, buttonData.newSkillId)
			self:CloseAbilityMenu()
			self:CloseFlyOut()
		end
	end
end

function ChargeUI_SkillSwitch:OnSkillSwitchGenerateTooltip( wndHandler, wndControl, eToolTipType, x, y )
	if (self.settings.showTooltips) then
		local data = wndControl:GetData()
		if (data and (data.type == "history" or data.type == "abilityMenu") and data.tieredSkill) then
			Tooltip.GetSpellTooltipForm(self, wndControl, data.tieredSkill)
		end
	end
end

function ChargeUI_SkillSwitch:OnSwapCommand(args)
	local lasIndex = tonumber(args[2])
	local newId = tonumber(args[3])
	if (not lasIndex or not newId) then
		self:WriteDebug("Invalid swap parameter. Usage: swap [lasIndex] [newSkillId]")
	else
		self:Swap(lasIndex, newId)
	end
end

function ChargeUI_SkillSwitch:Swap(oldIndex, newSkillId)
	self:WriteDebug("Attempting to swap skill at index " .. oldIndex .. " to skill " .. newSkillId)
	local las = ActionSetLib.GetCurrentActionSet()
	local lasLookup = {}
	for index, skillId in pairs( las) do
		lasLookup[skillId] = index
	end

	local oldSkillId = las[oldIndex]
	self:WriteDebug("oldSkillId = " .. tostring(oldSkillId))
	if (oldSkillId) then
		self:WriteDebug("Found skill " .. oldSkillId .. " on index " .. oldIndex .. " in current las")
		las[oldIndex] = newSkillId
		if (oldSkillId ~= 0) then
			-- Or new skill is from the book, then we swap tier numbers
			self:WriteDebug("Copying tier level...")
			local oldSkillTier = self:GetTierOfSkill(oldSkillId)
			self:SetTier(oldSkillId, 1)
			self:SetTier(newSkillId, oldSkillTier)
		end

		local tResult = ActionSetLib.RequestActionSetChanges(las)
		if (tResult.eResult ~= ActionSetLib.CodeEnumLimitedActionSetResult.Ok) then
			self:WriteDebug("Failed to save new las, result " .. tResult.eResult)
		end

		if (oldSkillId ~= 0) then
			self:AddSwapHistory(oldIndex, oldSkillId, newSkillId)
		end
	else
		self:WriteDebug("The skill " .. oldSkillId .. " is not on the las")
	end
end

function ChargeUI_SkillSwitch:GetTierOfSkill(skillId)
	for _, s in pairs(AbilityBook.GetAbilitiesList()) do
		if (s.nId == skillId) then
			return s.nCurrentTier
		end
	end
end

function ChargeUI_SkillSwitch:SetTier(skillId, tierLevel)
	self:WriteDebug("Setting tier " .. tierLevel .. " for skill " .. skillId)
	AbilityBook.UpdateSpellTier(skillId, tierLevel)
end

function ChargeUI_SkillSwitch:AddSwapHistory(lasIndex, oldId, newId)
	self:WriteDebug("Adding swap history from index " .. lasIndex .. " oldId = " .. oldId .. " newId = " .. newId)

	-- path slot, should not be saved by skill set
	if (lasIndex == 10) then
		self:WriteDebug("adding path swap history")
		self.swapHistory["path"] = self:AddHistoryToList(self.swapHistory["path"], oldId, newId)
	else
		local setNo = AbilityBook.GetCurrentSpec()

		if (not self.swapHistory[setNo]) then self.swapHistory[setNo] = {} end
		local setHistory = self.swapHistory[setNo]

		setHistory[lasIndex] = self:AddHistoryToList(setHistory[lasIndex], oldId, newId)
	end
end

function ChargeUI_SkillSwitch:AddHistoryToList(list, oldId, newId)
	if (list == nil) then
		list = {}
	end
	list = self:AddToTopUnique(list, newId, self.settings.maxShortcuts + 3)
	list = self:AddToTopUnique(list, oldId, self.settings.maxShortcuts + 3)
	return list
end

function ChargeUI_SkillSwitch:RemoveSwapHistory(lasIndex, skillId)
	self:WriteDebug("-> RemoveSwapHistory lasIndex = " .. lasIndex .. " skillId = " .. skillId)
	if (lasIndex == 10) then
		self.swapHistory["path"] = self:RemoveFromList(self.swapHistory["path"], skillId)
	else
		local setNo = AbilityBook.GetCurrentSpec()
		if (self.swapHistory[setNo]) then
			self.swapHistory[setNo][lasIndex] = self:RemoveFromList(self.swapHistory[setNo][lasIndex], skillId)
		end
	end
end

-------- Ability Menu -----------------------

function ChargeUI_SkillSwitch:PopulateAbilityMenu(lasIndex, skillCategory, targetTier)
	self:WriteDebug("PopulateAbilityMenu lasIndex: " .. lasIndex .. " skillCat: " .. skillCategory .. " targetTier: " .. targetTier)
	for _,child in pairs(self.abilityMenuWindow:GetChildren()) do
		child:Destroy()
	end

	for skillId, skill in pairs(self:GetAbilityMenuSkills(lasIndex, skillCategory)) do

		local button = Apollo.LoadForm(self.xmlDoc, "SkillSwitchButton", self.abilityMenuWindow, self)
		button:SetAnchorPoints(0,0,0,0)
		button:SetAnchorOffsets(0,0,self.settings.menuButtonSize,self.settings.menuButtonSize)
		button:SetSprite(skill.icon)
		local buttonData = {type = "abilityMenu", newSkillId = skillId, lasIndex = lasIndex, level = skill.level}

		if (targetTier and skill.tiers) then
			local tieredSkill = skill.tiers[targetTier]
			if (tieredSkill) then
				buttonData.tieredSkill = tieredSkill.splObject
			end
		end
		button:SetData(buttonData)
	end

	self.abilityMenuWindow:ArrangeChildrenHorz(0, function(a,b) return a:GetData().level < b:GetData().level end)
end

function ChargeUI_SkillSwitch:GetAbilityMenuSkills(lasIndex, skillCategory)
	local las = ActionSetLib.GetCurrentActionSet()
	local skillIdsToExclude = {}
	for _, id in pairs(las) do
		skillIdsToExclude[id] = true
	end

	for _, id in pairs(self:GetSuggestedSkillsToSwapTo(lasIndex, las[lasIndex])) do
		if (not skillIdsToExclude[id]) then
			skillIdsToExclude[id] = true
		end
	end

	return 	self:GetAvailableSkills(skillCategory, skillIdsToExclude)
end

function ChargeUI_SkillSwitch:OpenAbilityMenu(ownerButton)
	local x, y = self:GetAbsolutePosition(ownerButton)
	x = x + ownerButton:GetClientRect().nWidth
	self.abilityMenuWindow:SetAnchorOffsets(x, y, x+600, y+50)
	self.abilityMenuWindow:ToFront()
	self.abilityMenuWindow:Show(true, true)
	self.currentAbilityMenuButton = ownerButton
end

function ChargeUI_SkillSwitch:CloseAbilityMenuSoon()
	self:WriteDebug("-> CloseAbilityMenuSoon")
	Apollo.CreateTimer("SkillSwitchCloseAbilityMenuTimer",0.2,false)
end

function ChargeUI_SkillSwitch:CloseAbilityMenuByTimer()
	self:WriteDebug("-> CloseAbilityMenuByTimer")
	local w = Apollo.GetMouseTargetWindow()
	if (w and w:GetName() == "SkillSwitchButton" and w:GetData().type ~= "history") then
		self:WriteDebug("Exiting CloseAbilityMenuByTimer, mouse is on a " .. w:GetName())
		if ( w:GetData()) then
			self:WriteDebug("Button type = " .. w:GetData().type)
		end
		return
	end

	self:CloseAbilityMenu()
end

function ChargeUI_SkillSwitch:CloseAbilityMenu()
	self:WriteDebug("-> CloseAbilityMenu")
	if (self.abilityMenuWindow and self.abilityMenuWindow:IsVisible()) then
		self:WriteDebug("Closing ability window")
		self.abilityMenuWindow:Show(false)
	end
	self.currentAbilityMenuButton =nil
end

function ChargeUI_SkillSwitch:GetAvailableAssaultSkills()
	return self:GetAvailableSkills(Spell.CodeEnumSpellTag.Assault)
end

function ChargeUI_SkillSwitch:GetAvailableSupportSkills()
	return self:GetAvailableSkills(Spell.CodeEnumSpellTag.Support)
end

function ChargeUI_SkillSwitch:GetAvailableUtilitySkills()
	return self:GetAvailableSkills(Spell.CodeEnumSpellTag.Utility)
end

function ChargeUI_SkillSwitch:GetAvailablePathSkills()
	return self:GetAvailableSkills(Spell.CodeEnumSpellTag.Path)
end

function ChargeUI_SkillSwitch:GetAvailableSkills(skillCategory, idsToExclude)
	result = {}
	selectedIds = {}
	for index, skillId in pairs( ActionSetLib.GetCurrentActionSet()) do
		selectedIds[skillId] = true
	end
	for _, s in pairs(AbilityBook.GetAbilitiesList(skillCategory)) do
		if (s.bIsActive) then
			if (idsToExclude == nil or not idsToExclude[s.nId]) then
				local tier1 = s.tTiers[1]
				result[s.nId] = { id = s.nId, name = s.strName, tier = s.nCurrentTier, level = tier1.nLevelReq, icon = tier1.splObject:GetIcon(), active = (selectedIds[s.nId] == true), tiers = s.tTiers }
			end
		end
	end
	table.sort(result, function(a,b) return a.level < b.level end)
	return result
end

-- Utility functions ---------------------------------------------------------------------------

function ChargeUI_SkillSwitch:WriteDebug(message)
	if (self.settings.debug) then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Debug, message)
	end
end

function SplitString(s)
	local words = {}
	for word in s:gmatch("%w+") do table.insert(words, word) end
	return words
end

function ChargeUI_SkillSwitch:PrintObject(value, key, indentation)
	if (not indentation) then indentation = "" end
	if (not key) then key = "" end

	if (type(value) ~= "table") then
		self:WriteDebug(indentation .. "[" .. tostring(key) .. "] = " .. tostring(value))
	else
		self:WriteDebug(indentation .. "[" .. tostring(key) .. "] = " .. "table (" .. #(value) .. "): ")
		indentation = indentation .. "  "
		for subKey,subValue in pairs(value) do
			self:PrintObject(subValue, subKey, indentation)
		end
	end
end

function ChargeUI_SkillSwitch:GetAbsolutePosition2(window, cache)
	if (cache) then
		local savedPosition = cache[window]
		if (savedPosition) then
			return savedPosition.x, savedPosition.y
		end
	end
	local x,y = window:GetPos()
	local parent = window:GetParent()
	if (parent ~= nil) then
		local parentScale =parent:GetScale()
		x = x * parentScale
		y = y * parentScale
		local parentX, parentY = self:GetAbsolutePosition2(parent)
		x = x + parentX
		y = y + parentY
	end
	if (cache) then
		cache[window] = { x = x, y = y}
	end
	return x,y
end

function ChargeUI_SkillSwitch:GetAbsolutePosition(window, cache)
	local windows = self:GetWindowChain(window)

	local x = 0
	local y = 0

	local scale = 1.0

	for i = #windows, 1, -1 do
		local dx,dy = windows[i]:GetPos()
		x = x + dx * scale
		y = y + dy * scale
		scale = scale * windows[i]:GetScale()
	end

	return x,y, scale
end

function ChargeUI_SkillSwitch:GetWindowChain(window)
	result = { }
	while window do
		result[#result+1] = window
		window = window:GetParent()
	end
	return result
end

-- Returns a new table that contains the first non nil value for each table item
-- table1 takes precedence
function ChargeUI_SkillSwitch:CoalesceTables(table1, table2)
	result = {}
	for k,v in pairs(table1) do
		result[k] = v
	end
	for k,v in pairs(table2) do
		if (result[k] == nil) then
			result[k] = v
		end
	end
	return result
end

function ChargeUI_SkillSwitch:RemoveFromList(list, skillId)
	local newList = {}
	if (list ~= nil) then
		for _,v in pairs(list) do
			if (v ~= skillId) then
				newList[#newList+1] = v
			end
		end
	end
	return newList
end

-- Adds an item to the top of a list and makes sure there are no duplicates in list
function ChargeUI_SkillSwitch:AddToTopUnique(list, newId, max)
	self:WriteDebug("-> AddToTopUnique newId = ".. newId .. " max = " .. max)
	local result = { newId}
	list = list or {}

	for _, id in pairs(list) do
		if (#result >= max) then
			break
		end

		if (id ~= newId and not result[id]) then
			result[#result+1] = id
		end
	end

	return result
end

-- CONFIGURATION -----------------------------------------------------------------------

function ChargeUI_SkillSwitch:OpenConfigurationWindow()
	self.configurationWindow = Apollo.LoadForm(self.xmlDoc, "ConfigurationWindow", nil, self)
	self.configurationWindow:FindChild("ActivationButtonWidth"):FindChild("Slider"):SetValue(self.settings.buttonWidth)
	self.configurationWindow:FindChild("ActivationButtonHeight"):FindChild("Slider"):SetValue(self.settings.buttonHeight)
	self.configurationWindow:FindChild("ActivationButtonVerticalOffset"):FindChild("Slider"):SetValue(self.settings.buttonYOffset)
	self.configurationWindow:FindChild("MenuButtonSize"):FindChild("Slider"):SetValue(self.settings.menuButtonSize)
	self.configurationWindow:FindChild("NumberOfShortCuts"):FindChild("Slider"):SetValue(self.settings.maxShortcuts)
	self.configurationWindow:FindChild("EnableTooltips"):FindChild("Button"):SetCheck(self.settings.showTooltips)
	self.configurationWindow:FindChild("EnableFlyOutMenues"):FindChild("Button"):SetCheck(self.settings.enableMenuButtons)
	self.configurationWindow:FindChild("EnablePathFlyOut"):FindChild("Button"):SetCheck(self.settings.enablePathFlyOut)
	self.configurationWindow:FindChild("InvisibleActivationButtons"):FindChild("Button"):SetCheck(self.settings.invisibleActivationButtons)
	self.configurationWindow:Show(true, true)
end

function ChargeUI_SkillSwitch:OnActivationButtonWidthSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.settings.buttonWidth = fNewValue
	self:RepositionFlyOutButtons()
end

function ChargeUI_SkillSwitch:OnActivationButtonVertivalOffsetSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.settings.buttonYOffset = fNewValue
	self:RepositionFlyOutButtons()
end

function ChargeUI_SkillSwitch:OnActivationButtonHeightSliderChanged( wndHandler, wndControl, fNewValue, fOldValue, bOkToChange )
	self.settings.buttonHeight = fNewValue
	self:RepositionFlyOutButtons()
end

function ChargeUI_SkillSwitch:OnFlyOutButtonSizeSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.settings.menuButtonSize = fNewValue
	self:PopulateAndOpenFlyOut(1, "skill", self.flyOutButtons[1])
	self:CloseFlyOutSoon(3)
end

function ChargeUI_SkillSwitch:OnConfigurationWindowCloseButtonSignal( wndHandler, wndControl, eMouseButton )
	self.configurationWindow:Show(false)
	self.configurationWindow:Destroy()
end

function ChargeUI_SkillSwitch:OnEnableToolTipsClicked( wndHandler, wndControl, eMouseButton )
	self.settings.showTooltips = wndControl:IsChecked()
end

function ChargeUI_SkillSwitch:OnEnablePathFlyOutClicked( wndHandler, wndControl, eMouseButton )
	self.settings.enablePathFlyOut = wndControl:IsChecked()
	self:CreateFlyOutButtons()
end

function ChargeUI_SkillSwitch:OnEnableFlyoutMenuesClicked( wndHandler, wndControl, eMouseButton )
	self.settings.enableMenuButtons = wndControl:IsChecked()
end

function ChargeUI_SkillSwitch:OnResetLayOut( wndHandler, wndControl, eMouseButton )
	self:CreateFlyOutButtons()
end

function ChargeUI_SkillSwitch:OnNumberOfShortCutsChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.settings.maxShortcuts = fNewValue
end

function ChargeUI_SkillSwitch:OnInvisibleActivationButttonsToggle( wndHandler, wndControl, eMouseButton )
	self.settings.invisibleActivationButtons = wndControl:IsChecked()
	self:CreateFlyOutButtons()
end

-------------------------------------------------------------------------------------

Initialize()
