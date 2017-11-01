------------------------------------------------------------------------------------------------
-- Client Lua Script for BenikUI_Resources
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local OptionList = {"Medic","Slinger","Stalker","Esper","Engineer","Warrior"}

local BenikUI_Resources = {}

local knSaveVersion = 1

function BenikUI_Resources:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function BenikUI_Resources:Init()
    Apollo.RegisterAddon(self, nil, nil, {"BenikUI_ActionBar"})
end

function BenikUI_Resources:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("BenikUI_Resources.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)

	Apollo.RegisterEventHandler("ActionBarLoaded", 			"OnRequiredFlagsChanged", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", "OnTutorial_RequestUIAnchor", self)
end

function BenikUI_Resources:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	local tSave =
	{
		bShowPet = self.bShowPet,
		nSaveVersion = knSaveVersion,
	}

	return tSave
end

function BenikUI_Resources:OnRestore(eType, tSavedData)
	if not tSavedData or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end

	self.bShowPet = tSavedData.bShowPet
end

function BenikUI_Resources:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	self.Options = Apollo.GetAddon("BenikUI")
	if self.Options == nil then
		Apollo.AddAddonErrorText(self, "Could not find main BanikUi Window.")
		return
	end
	--Register in Options
	self.Options:RegisterAddon("Resources")
	--Color Picker
	GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
	self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
	self.colorPicker:Show(false, true)
	

	self.bDocLoaded = true
	self:OnRequiredFlagsChanged()
end

function BenikUI_Resources:OnRequiredFlagsChanged()
	if g_wndActionBarResources and self.bDocLoaded then
		if GameLib.GetPlayerUnit() then
			self:OnCharacterCreated()
		else
			Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
		end
	end
end

function BenikUI_Resources:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	end
	
	local eClassId =  unitPlayer:GetClassId()
	if eClassId == GameLib.CodeEnumClass.Engineer then
		self:OnCreateEngineer()
	elseif unitPlayer:GetClassId() == GameLib.CodeEnumClass.Esper then
		self:OnCreateEsper()
	elseif unitPlayer:GetClassId() == GameLib.CodeEnumClass.Spellslinger then
		self:OnCreateSlinger()
	elseif unitPlayer:GetClassId() == GameLib.CodeEnumClass.Medic then
		self:OnCreateMedic()
	elseif unitPlayer:GetClassId() == GameLib.CodeEnumClass.Warrior then
		self:OnCreateWarrior()
	elseif unitPlayer:GetClassId() == GameLib.CodeEnumClass.Stalker then
		self:OnCreateStalker()
	end
end

function BenikUI_Resources:LoadOptions(wnd)
	local MainGrid = wnd:FindChild("MainGrid")
	local OptList = wnd:FindChild("OptionsList")
	OptList:DestroyChildren()
	
	for i,j in pairs(OptionList) do
		local newOption = Apollo.LoadForm(self.xmlDoc, "ListItem", OptList,self)
		newOption:SetText(j)
	end
	
	OptList:ArrangeChildrenVert()
	self.wndOption = Apollo.LoadForm(self.xmlDoc, "OptionsFrame", MainGrid,self)
		--Filling Options
	for k,v in pairs(self.Options.db.profile.Resources)do
		local Controls = self.wndOption:FindChild(k.."Controls")
		for i,j in pairs(v) do
			local next = Controls:FindChild(i)
			if next ~= nil  then
				next:FindChild("Swatch"):SetBGColor(j)
			end
		end
	end
end

function BenikUI_Resources:OnListItemClick( wndHandler, wndControl, eMouseButton )
	for i,j in pairs(self.wndOption:GetChildren()) do
		if j:GetName() == wndHandler:GetText().."Controls" then
			j:Show(true)
		else
			j:Show(false)
		end
	end
end

function BenikUI_Resources:ColorPickerCallback(strColor)
	self.Options.db.profile.Resources[self.UpdateSave[1]][self.UpdateSave[2]] = strColor
	self.Update:SetBGColor(strColor)
	
	self:UpdateBars()
end

function BenikUI_Resources:OnColorPlayer(wndHandler)
	local name = wndHandler:GetParent():GetName()
	local main = wndHandler:GetParent():GetParent():GetName()
	if main == "SlingerControls" then
		main = "Slinger"
	elseif main == "WarriorControls" then
		main = "Warrior"
	elseif main == "MedicControls" then
		main = "Medic"
	elseif main == "EsperControls" then
		main = "Esper"
	elseif main == "EngineerControls" then
		main = "Engineer"
	else--Stalker
		main = "Stalker"
	end
	self.UpdateSave = {main,name}
	self.Update = wndHandler
	self.colorPicker:Show(true)
  	self.colorPicker:ToFront()
end

function BenikUI_Resources:UpdateBars()
	local main = self.wndMain:GetName()
	if main == "MedicResourceForm" then
		self.wndMain:FindChild("ProgressBar"):SetBarColor(self.Options.db.profile.Resources.Medic.BarColor)
	elseif main == "EsperResourceForm" then
		self.wndMain:FindChild("ProgressBar"):SetBarColor(self.Options.db.profile.Resources.Esper.BarColor)
	elseif main == "EngineerResourceForm" then
		self.wndMain:FindChild("ProgressBar"):SetBarColor(self.Options.db.profile.Resources.Engineer.BarColor)
	elseif main == "WarriorResourceForm" then
		self.wndMain:FindChild("ChargeBar"):SetBarColor(self.Options.db.profile.Resources.Warrior.BarColor)
		self.wndMain:FindChild("ChargeBarOverdriven"):SetBarColor(self.Options.db.profile.Resources.Warrior.InZone)
	elseif main == "SlingerResourceForm" then
		self.wndMain:FindChild("ProgressBar"):SetBarColor(self.Options.db.profile.Resources.Slinger.BarColor)
	elseif main == "StalkerResourceForm" then
		self.wndMain:FindChild("CenterMeter1"):SetBarColor(self.Options.db.profile.Resources.Stalker.BarColor)
		self.wndMain:FindChild("Innate"):SetBGColor(self.Options.db.profile.Resources.Stalker.Innate)
	end
end

-----------------------------------------------------------------------------------------------
-- Esper
-----------------------------------------------------------------------------------------------

function BenikUI_Resources:OnCreateEsper()
	Apollo.RegisterEventHandler("NextFrame", 					"OnEsperUpdateTimer", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnEsperEnteredCombat", self)
	Apollo.RegisterTimerHandler("EsperOutOfCombatFade", 		"OnEsperOutOfCombatFade", self)
	Apollo.RegisterEventHandler("BuffAdded", 					"OnEsperBuffAdded", self)
	Apollo.RegisterEventHandler("BuffUpdated", 					"OnEsperBuffUpdated", self)
	Apollo.RegisterEventHandler("BuffRemoved", 					"OnEsperBuffRemoved", self)
	self.timerEsperOutOfCombatFade = ApolloTimer.Create(0.5, false, "OnEsperOutOfCombatFade", self)
	self.timerEsperOutOfCombatFade:Stop()

    self.wndMain = Apollo.LoadForm(self.xmlDoc, "EsperResourceForm", g_wndActionBarResources, self)
	self.wndMain:ToFront()

	local nLeft, nTop, nRight, nBottom = self.wndMain:GetRect()
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop, true)

	self.tWindowMap =
	{
		["ProgressBar"]					=	self.wndMain:FindChild("ProgressBar"),
		["Extra1"]							=	self.wndMain:FindChild("Extra1"),
		["Extra2"]							=	self.wndMain:FindChild("Extra2"),

	}
	self.nOverflow = 0
	self.bLastInCombat = nil
	self.nComboCurrent = nil
	self.bInnate = nil
	self.nFadeLevel = 0
	
	self:UpdateBars()
end

function BenikUI_Resources:OnEsperBuffAdded(unit, tBuff, nCout)
	if not unit or not unit:IsThePlayer() then return end

	if tBuff.splEffect:GetId() == 77116 then
		self.nOverflow = tBuff.nCount
	end
end

function BenikUI_Resources:OnEsperBuffUpdated(unit, tBuff, nCout)
	if not unit or not unit:IsThePlayer() then return end

	if tBuff.splEffect:GetId() == 77116 then
		self.nOverflow = tBuff.nCount
	end
end

function BenikUI_Resources:OnEsperBuffRemoved(unit, tBuff, nCout)
	if not unit or not unit:IsThePlayer() then return end

	if tBuff.splEffect:GetId() == 77116 then
		self.nOverflow = tBuff.nCount
	end
end

function BenikUI_Resources:OnEsperUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()
	local nComboCurrent = unitPlayer:GetResource(1)
	local bInnate = GameLib.IsCurrentInnateAbilityActive()
	
	self.bLastInCombat = bInCombat
	self.nComboCurrent = nComboCurrent
	self.bInnate = bInnate

	-- Combo Points
	self.tWindowMap["ProgressBar"]:SetMax(5)
	self.tWindowMap["ProgressBar"]:SetProgress(nComboCurrent)
	if self.nOverflow == 1 then
		self.tWindowMap["Extra1"]:Show(true)
		self.tWindowMap["Extra2"]:Show(false)
	elseif self.nOverflow == 2 then
		self.tWindowMap["Extra2"]:Show(true)
		self.tWindowMap["Extra1"]:Show(false)
	else
		self.tWindowMap["Extra1"]:Show(false)
		self.tWindowMap["Extra2"]:Show(false)
	end

end

function BenikUI_Resources:OnEsperEnteredCombat(unitPlayer, bInCombat)
end

function BenikUI_Resources:OnEsperOutOfCombatFade()

end

-----------------------------------------------------------------------------------------------
-- Spellslinger
-----------------------------------------------------------------------------------------------

function BenikUI_Resources:OnCreateSlinger()
	Apollo.RegisterEventHandler("NextFrame", 		"OnSlingerUpdateTimer", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnSlingerEnteredCombat", self)

    self.wndMain = Apollo.LoadForm(self.xmlDoc, "SlingerResourceForm", g_wndActionBarResources, self)
	self.wndMain:ToFront()

	local nLeft, nTop, nRight, nBottom = self.wndMain:GetRect()
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop, true)

	self.tWindowMap =
	{
		["ProgressBar"]				=	self.wndMain:FindChild("ProgressBar"),
	}

	self.bLastInCombat = nil
	self.nLastCurrent = nil
	self.nLastMax = nil
	self.bInnate = nil
	self.nLastFocus = nil
	self.nFadeLevel = 0

	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self:OnSlingerEnteredCombat(unitPlayer, unitPlayer:IsInCombat())
	end
	self:UpdateBars()
end

function BenikUI_Resources:OnSlingerUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()
	local bInCombat = unitPlayer:IsInCombat()
	local nResourceMax = unitPlayer:GetMaxResource(4)
	local nResourceCurrent = unitPlayer:GetResource(4)
	local bInnate = GameLib.IsSpellSurgeActive()
	if self.bLastInCombat == bInCombat and self.nLastCurrent == nResourceCurrent and self.nLastMax == nResourceMax and self.bInnate == bInnate and self.nLastFocus == nFocusCurrent then
		return
	end
	self.bLastInCombat = bInCombat
	self.nLastCurrent = nResourceCurrent
	self.nLastMax = nResourceMax
	self.bInnate = bInnate
	self.nLastFocus = nFocusCurrent

	-- Nodes
	local strNodeTooltip = String_GetWeaselString(Apollo.GetString("Spellslinger_SpellSurge"), nResourceCurrent, nResourceMax)
	self.tWindowMap["ProgressBar"]:SetMax(nResourceMax)
	self.tWindowMap["ProgressBar"]:SetProgress(nResourceCurrent, 100)

	-- Surge
	if bInnate then
		self.tWindowMap["ProgressBar"]:SetBarColor(self.Options.db.profile.Resources.Slinger.Innate)
	else
		self.tWindowMap["ProgressBar"]:SetBarColor(self.Options.db.profile.Resources.Slinger.BarColor)
	end
	
end

function BenikUI_Resources:OnSlingerEnteredCombat(unitPlayer, bInCombat)

end

-----------------------------------------------------------------------------------------------
-- Medic
-----------------------------------------------------------------------------------------------

function BenikUI_Resources:OnCreateMedic()
	Apollo.RegisterEventHandler("NextFrame", 		"OnMedicUpdateTimer", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnMedicEnteredCombat", self)

    self.wndMain = Apollo.LoadForm(self.xmlDoc, "MedicResourceForm", g_wndActionBarResources, self)
	self.wndMain:ToFront()

	local nLeft, nTop, nRight, nBottom = self.wndMain:GetRect()
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop, true)

	self.tWindowMap =
	{
		["ProgressBar"]	=	self.wndMain:FindChild("ProgressBar"),
	}

	self.bLastInCombat = nil
	self.nLastCurrent = nil
	self.nLastMax = nil
	self.bInnate = nil
	self.nLastPartialCount = nil
	self.bCombat = nil

	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self.bCombat = unitPlayer:IsInCombat()
		self:OnMedicEnteredCombat(unitPlayer, self.bCombat)
	end
	
	self:UpdateBars()
end

function BenikUI_Resources:OnMedicUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()	-- Can instead just listen to a CharacterChange, CharacterCreate, etc. event
	local bInCombat = self.bCombat
	local nResourceMax = unitPlayer:GetMaxResource(1)
	local nResourceCurrent = unitPlayer:GetResource(1)
	local bInnate = GameLib.IsCurrentInnateAbilityActive()
	local nFocusCurrent = math.floor(unitPlayer:GetFocus())

	-- Partial Node Count
	local nPartialCount = 0
	local tBuffs = unitPlayer:GetBuffs()
	for idx, tCurrBuffData in pairs(tBuffs.arBeneficial or {}) do
		if tCurrBuffData.splEffect:GetId() == 42569 then -- TODO replace with code enum
			nPartialCount = tCurrBuffData.nCount
			break
		end
	end

	if self.bLastInCombat == bInCombat and self.nLastCurrent == nResourceCurrent and self.nLastMax == nResourceMax
		and self.bInnate == bInnate and self.nLastPartialCount == nPartialCount and self.nLastFocus == nFocusCurrent then
		return
	end
	self.bLastInCombat = bInCombat
	self.nLastCurrent = nResourceCurrent
	self.nLastMax = nResourceMax
	self.bInnate = bInnate
	self.nLastPartialCount = nPartialCount

	self.tWindowMap["ProgressBar"]:SetMax(nResourceMax)
	self.tWindowMap["ProgressBar"]:SetProgress(nResourceCurrent)
	
end

function BenikUI_Resources:OnMedicEnteredCombat(unitPlayer, bInCombat)

end

-----------------------------------------------------------------------------------------------
-- Stalker
-----------------------------------------------------------------------------------------------

function BenikUI_Resources:OnCreateStalker()
	Apollo.RegisterEventHandler("NextFrame", "OnStalkerUpdateTimer", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "StalkerResourceForm", g_wndActionBarResources, self)
	self.wndMain:ToFront()

	local nLeft0, nTop0, nRight0, nBottom0 = self.wndMain:GetRect()
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop0 - 15, true)

	self.tWindowMap =
	{
		["CenterMeter1"]		=	self.wndMain:FindChild("CenterMeter1"),
		["CenterMeterText"]		=	self.wndMain:FindChild("CenterMeterText"),
		["Base"]				=	self.wndMain:FindChild("Base"),
		["Innate"]				=	self.wndMain:FindChild("Innate"),
	}

	self.bLastInCombat = nil
	self.nLastCurrent = nil
	self.nLastMax = nil
	self.bInnate = nil
	
	self:UpdateBars()
end

function BenikUI_Resources:OnStalkerUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()
	local bInCombat = unitPlayer:IsInCombat()
	local nResourceCurrent = unitPlayer:GetResource(3)
	local nResourceMax = unitPlayer:GetMaxResource(3)
	local bInnate = GameLib.IsCurrentInnateAbilityActive()
	if self.bLastInCombat == bInCombat and self.nLastCurrent == nResourceCurrent and self.nLastMax == nResourceMax and self.bInnate == bInnate then
		return
	end
	self.bLastInCombat = bInCombat
	self.nLastCurrent = nResourceCurrent
	self.nLastMax = nResourceMax
	self.bInnate = bInnate

	self.tWindowMap["CenterMeter1"]:SetStyleEx("EdgeGlow", nResourceCurrent < nResourceMax)
	self.tWindowMap["CenterMeter1"]:SetMax(nResourceMax)
	self.tWindowMap["CenterMeter1"]:SetProgress(nResourceCurrent)
	self.tWindowMap["CenterMeterText"]:SetText(nResourceCurrent.." / "..nResourceMax)

	-- Innate
	local strInnateWindow = ""
	if bInnate then
		self.tWindowMap["Innate"]:Show(true)
	else
		self.tWindowMap["Innate"]:Show(false)
	end

end

-----------------------------------------------------------------------------------------------
-- Warrior
-----------------------------------------------------------------------------------------------

function BenikUI_Resources:OnCreateWarrior()
	self.timerOverdriveTick = ApolloTimer.Create(0.01, false, "OnWarriorResource_ChargeBarOverdriveTick", self)
	self.timerOverdriveTick:Stop()
	self.timerOverdriveDone = ApolloTimer.Create(10.0, false, "OnWarriorResource_ChargeBarOverdriveDone", self)
	self.timerOverdriveDone:Stop()

	Apollo.RegisterEventHandler("NextFrame", 					"OnWarriorUpdateTimer", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "WarriorResourceForm", g_wndActionBarResources, self)
	self.wndMain:ToFront()

	local nLeft0, nTop0, nRight0, nBottom0 = self.wndMain:GetRect()
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop0 - 15, true)

	self.tWindowMap =
	{
		["Base"]					=	self.wndMain:FindChild("Base"),
		["BarBG"]					=	self.wndMain:FindChild("BarBG"),
		["Skulls"]					=	self.wndMain:FindChild("Skulls"),
		["Skulls:Skull0"]			=	self.wndMain:FindChild("Skulls:Skull0"),
		["Skulls:Skull1"]			=	self.wndMain:FindChild("Skulls:Skull1"),
		["Skulls:Skull2"]			=	self.wndMain:FindChild("Skulls:Skull2"),
		["Skulls:Skull3"]			=	self.wndMain:FindChild("Skulls:Skull3"),
		["Skulls:Skull4"]			=	self.wndMain:FindChild("Skulls:Skull4"),
		["ChargeBar"]				=	self.wndMain:FindChild("ChargeBar"),
		["ChargeBarOverdriven"]		=	self.wndMain:FindChild("ChargeBarOverdriven"),
		["InsetFrameDivider"]		=	self.wndMain:FindChild("InsetFrameDivider"),
		["ResourceCount"]			=	self.wndMain:FindChild("ResourceCount"),
	}


	self.tWindowMap["ChargeBarOverdriven"]:SetMax(1)

	self.bLastInCombat = nil
	self.nLastCurrent = nil
	self.nLastMax = nil
	self.bLastOverDrive = nil
	self.bOverDriveActive = false
	
	self:UpdateBars()
end

function BenikUI_Resources:OnWarriorUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()
	local bInCombat = unitPlayer:IsInCombat()
	local bOverdrive = GameLib.IsOverdriveActive()
	local nResourceCurr = unitPlayer:GetResource(1)
	local nResourceMax = unitPlayer:GetMaxResource(1)
	if self.bLastInCombat == bInCombat and self.nLastCurrent == nResourceCurr and self.nLastMax == nResourceMax and self.bLastOverdrive == bOverdrive then
		return
	end
	self.bLastInCombat = bInCombat
	self.nLastCurrent = nResourceCurr
	self.nLastMax = nResourceMax
	self.bLastOverdrive = bOverdrive

	self.tWindowMap["ChargeBar"]:SetMax(nResourceMax)
	self.tWindowMap["ChargeBar"]:SetProgress(nResourceCurr)

	if bOverdrive and not self.bOverDriveActive then
		self.bOverDriveActive = true
		self.tWindowMap["ChargeBarOverdriven"]:SetProgress(1)
		self.timerOverdriveTick:Start()
		self.timerOverdriveDone:Start()
	end

	self.tWindowMap["ChargeBar"]:Show(not bOverdrive)
	self.tWindowMap["ChargeBarOverdriven"]:Show(bOverdrive)

	if bOverdrive then
		self.tWindowMap["ResourceCount"]:SetText(Apollo.GetString("WarriorResource_OverdriveCaps"))
		self.tWindowMap["ResourceCount"]:SetTextColor(ApolloColor.new("Amber"))
	else
		self.tWindowMap["ResourceCount"]:SetText(nResourceCurr == 0 and "0 / 1000" or nResourceCurr.." / 1000")
		self.tWindowMap["ResourceCount"]:SetTextColor(ApolloColor.new("white"))
	end
end

function BenikUI_Resources:OnWarriorResource_ChargeBarOverdriveTick()
	self.timerOverdriveTick:Stop()
	self.tWindowMap["ChargeBarOverdriven"]:SetProgress(0, 1 / 8)
end

function BenikUI_Resources:OnWarriorResource_ChargeBarOverdriveDone()
	self.timerOverdriveDone:Stop()
	self.bOverDriveActive = false
end

-----------------------------------------------------------------------------------------------
-- Engineer
-----------------------------------------------------------------------------------------------

function BenikUI_Resources:OnCreateEngineer()
	Apollo.RegisterEventHandler("NextFrame", 		"OnEngineerUpdateTimer", self)
	Apollo.RegisterEventHandler("ShowActionBarShortcut", 		"OnShowActionBarShortcut", self)
	Apollo.RegisterTimerHandler("EngineerOutOfCombatFade", 		"OnEngineerOutOfCombatFade", self)

	Apollo.RegisterEventHandler("PetStanceChanged", 			"OnPetStanceChanged", self)
	Apollo.RegisterEventHandler("PetSpawned",					"OnPetSpawned", self)

    self.wndMain = Apollo.LoadForm(self.xmlDoc, "EngineerResourceForm", g_wndActionBarResources, self)
	self.wndMain:ToFront()

	local nLeft0, nTop0, nRight0, nBottom0 = self.wndMain:GetRect()
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop0 - 15, true)

	self.tWindowMap =
	{
		["MainResourceFrame"]		=	self.wndMain:FindChild("MainResourceFrame"),
		["ProgressBar"]				=	self.wndMain:FindChild("ProgressBar"),
		["ProgressText"]			=	self.wndMain:FindChild("ProgressText"),
		["ProgressBacker"]			=	self.wndMain:FindChild("ProgressBacker"),
		["LeftCap"]					=	self.wndMain:FindChild("LeftCap"),
		["RightCap"]				=	self.wndMain:FindChild("RightCap"),
		["StanceMenuOpenerBtn"]		=	self.wndMain:FindChild("StanceMenuOpenerBtn"),
		["PetBarContainer"]			=	self.wndMain:FindChild("PetBarContainer"),
		["PetText"]					=	self.wndMain:FindChild("PetText"),
		["PetBtn"]					=	self.wndMain:FindChild("PetBtn"),
	}

	for idx = 1, 5 do
		self.wndMain:FindChild("Stance"..idx):SetData(idx)
	end

	self:HelperShowPetBar(self.bShowPet)
	self.wndMain:FindChild("StanceMenuOpenerBtn"):AttachWindow(self.wndMain:FindChild("StanceMenuBG"))

	self:OnShowActionBarShortcut(1, IsActionBarSetVisible(1)) -- Show petbar if active from reloadui/load screen

	-- Show initial Stance
	-- Pet_GetStance(0) -- First arg is for the pet ID, 0 means all engineer pets
	self.ktEngineerStanceToShortString =
	{
		[0] = "",
		[1] = Apollo.GetString("EngineerResource_Aggro"),
		[2] = Apollo.GetString("EngineerResource_Defend"),
		[3] = Apollo.GetString("EngineerResource_Passive"),
		[4] = Apollo.GetString("EngineerResource_Assist"),
		[5] = Apollo.GetString("EngineerResource_Stay"),
	}
	self.tWindowMap["PetText"]:SetText(self.ktEngineerStanceToShortString[Pet_GetStance(0)])
	self.tWindowMap["PetText"]:SetData(self.ktEngineerStanceToShortString[Pet_GetStance(0)])

	self.bLastInCombat = nil
	self.nLastCurrent = nil
	
	self:UpdateBars()
end

function BenikUI_Resources:OnEngineerUpdateTimer()
	local unitPlayer = GameLib.GetPlayerUnit()
	local bInCombat = unitPlayer:IsInCombat()
	local nResourceCurrent = unitPlayer:GetResource(1)

	if self.bLastInCombat == bInCombat and self.nLastCurrent == nResourceCurrent then
		return
	end

	self.bLastInCombat = bInCombat
	self.nLastCurrent = nResourceCurrent

	local nResourceMax = unitPlayer:GetMaxResource(1)
	local nResourcePercent = nResourceCurrent / nResourceMax

	self.tWindowMap["ProgressBar"]:SetMax(nResourceMax)
	self.tWindowMap["ProgressBar"]:SetProgress(nResourceCurrent)
	self.tWindowMap["ProgressText"]:SetText(String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), nResourceCurrent, nResourceMax))
	self.tWindowMap["ProgressBacker"]:Show(nResourcePercent >= 0.4 and nResourcePercent <= 0.6)

	local Engineer = self.Options.db.profile.Resources.Engineer
	if nResourcePercent > 0 and nResourcePercent < 0.3 then
		self.tWindowMap["ProgressText"]:SetTextColor("white")
		self.tWindowMap["ProgressBar"]:SetBarColor(Engineer.BarColor)
	elseif nResourcePercent >= 0.3 and nResourcePercent <= 0.7 then
		self.tWindowMap["ProgressText"]:SetTextColor(Engineer.TextZone)
		self.tWindowMap["ProgressBar"]:SetBarColor(Engineer.InZone)
	elseif nResourcePercent > 0.7 then
		self.tWindowMap["ProgressText"]:SetTextColor("white")
		self.tWindowMap["ProgressBar"]:SetBarColor(Engineer.BarColor)
	else
		self.tWindowMap["ProgressText"]:SetTextColor("white")
		self.tWindowMap["ProgressBar"]:SetBarColor(Engineer.BarColor)
	end

	if GameLib.IsCurrentInnateAbilityActive() then
		self.tWindowMap["ProgressText"]:SetTextColor(Engineer.TextZone)
		self.tWindowMap["ProgressBar"]:SetBarColor(Engineer.InZone)	
	end
end

function BenikUI_Resources:OnStanceBtn(wndHandler, wndControl)
	Pet_SetStance(0, tonumber(wndHandler:GetData())) -- First arg is for the pet ID, 0 means all engineer pets

	self.tWindowMap["StanceMenuOpenerBtn"]:SetCheck(false)
	self.tWindowMap["PetText"]:SetText(self.ktEngineerStanceToShortString[tonumber(wndHandler:GetData())])
	self.tWindowMap["PetText"]:SetData(self.ktEngineerStanceToShortString[tonumber(wndHandler:GetData())])
end

function BenikUI_Resources:HelperShowPetBar(bShowIt)
	self.tWindowMap["PetBarContainer"]:Show(bShowIt)
	self.tWindowMap["PetBtn"]:SetCheck(not bShowIt)
end

function BenikUI_Resources:OnPetBtn(wndHandler, wndControl)
	self.bShowPet = not self.tWindowMap["PetBarContainer"]:IsShown()

	self:HelperShowPetBar(self.bShowPet)
end

function BenikUI_Resources:OnShowActionBarShortcut(eWhichBar, bIsVisible, nNumShortcuts)
	if eWhichBar ~= ActionSetLib.CodeEnumShortcutSet.PrimaryPetBar or not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	self.tWindowMap["PetBtn"]:Show(bIsVisible)
	self.tWindowMap["PetBtn"]:SetCheck(not bIsVisible or not self.bShowPet)
	self.tWindowMap["PetBarContainer"]:Show(bIsVisible and self.bShowPet)
end

function BenikUI_Resources:OnEngineerPetBtnMouseEnter(wndHandler, wndControl)
	local strHover = ""
	local strWindowName = wndHandler:GetName()
	if strWindowName == "ActionBarShortcut.12" then
		strHover = Apollo.GetString("ClassResources_Engineer_PetAttack")
	elseif strWindowName == "ActionBarShortcut.13" then
		strHover = Apollo.GetString("CRB_Stop")
	elseif strWindowName == "ActionBarShortcut.15" then
		strHover = Apollo.GetString("ClassResources_Engineer_GoTo")
	end
	self.tWindowMap["PetText"]:SetText(strHover)
	wndHandler:SetBGColor("white")
end

function BenikUI_Resources:OnEngineerPetBtnMouseExit(wndHandler, wndControl)
	self.tWindowMap["PetText"]:SetText(self.tWindowMap["PetText"]:GetData() or "")
	wndHandler:SetBGColor("UI_AlphaPercent50")
end

function BenikUI_Resources:OnPetStanceChanged(petId)
	-- Pet_GetStance(0) -- First arg is for the pet ID, 0 means all engineer pets
	if self.ktEngineerStanceToShortString[Pet_GetStance(0)] then
		self.tWindowMap["PetText"]:SetText(self.ktEngineerStanceToShortString[Pet_GetStance(0)])
		self.tWindowMap["PetText"]:SetData(self.ktEngineerStanceToShortString[Pet_GetStance(0)])
	end
end

function BenikUI_Resources:OnPetSpawned(petId)
	-- Pet_GetStance(0) -- First arg is for the pet ID, 0 means all engineer pets
	if self.ktEngineerStanceToShortString[Pet_GetStance(0)] then
		self.tWindowMap["PetText"]:SetText(self.ktEngineerStanceToShortString[Pet_GetStance(0)])
		self.tWindowMap["PetText"]:SetData(self.ktEngineerStanceToShortString[Pet_GetStance(0)])
	end
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function BenikUI_Resources:OnGeneratePetCommandTooltip(wndControl, wndHandler, eType, arg1, arg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_PetCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Spell then
		xml = XmlDoc.new()
		if arg1 ~= nil then
			local tTooltips = arg1:GetTooltips()
			if tTooltips and tTooltips.strLASTooltip then
				xml:AddLine(tTooltips.strLASTooltip)
			end
		end
		wndControl:SetTooltipDoc(xml)
	end
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------
function BenikUI_Resources:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)

	local tAnchors =
	{
		[GameLib.CodeEnumTutorialAnchor.ClassResource] = true,
	}

	if not tAnchors[eAnchor] then
		return
	end

	local tAnchorMapping =
	{
		[GameLib.CodeEnumTutorialAnchor.ClassResource] = self.wndMain
	}

	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

local ClassResourcesInst = BenikUI_Resources:new()
ClassResourcesInst:Init()
