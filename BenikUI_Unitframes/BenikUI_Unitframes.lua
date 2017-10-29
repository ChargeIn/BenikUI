-----------------------------------------------------------------------------------------------
-- Client Lua Script for BenikUI_Unitframes
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Unit"
require "GameLib"
require "Apollo"
require "PathMission"
require "P2PTrading"
 
-----------------------------------------------------------------------------------------------
-- BenikUI_Unitframes Module Definition
-----------------------------------------------------------------------------------------------
local BenikUI_Unitframes = {} 

local OptionList = {"General","Player","Target","Focus","ToT"}

local kstrRaidMarkerToSprite =
{
	"Icon_Windows_UI_CRB_Marker_Bomb",
	"Icon_Windows_UI_CRB_Marker_Ghost",
	"Icon_Windows_UI_CRB_Marker_Mask",
	"Icon_Windows_UI_CRB_Marker_Octopus",
	"Icon_Windows_UI_CRB_Marker_Pig",
	"Icon_Windows_UI_CRB_Marker_Chicken",
	"Icon_Windows_UI_CRB_Marker_Toaster",
	"Icon_Windows_UI_CRB_Marker_UFO",
}
-----------------------------------------------------------------------------------------------
-- local functions
-----------------------------------------------------------------------------------------------
local NumberToText = function(num)
	if num > 999999 then
		return tostring(math.floor((num/1000000) * 10 + 0.5) / 10).."M"
	elseif num > 999 then
		return tostring(math.floor((num/1000) * 10 + 0.5) / 10).."K"
	else
		return tostring(num)
	end
end

local NumberToTextSmall = function(num)
	if num > 999999 then
		return tostring(math.floor(num/1000000)).."M"
	elseif num > 999 then
		return tostring(math.floor(num/1000)).."K"
	else
		return tostring(num)
	end
end
 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function BenikUI_Unitframes:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function BenikUI_Unitframes:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- BenikUI_Unitframes OnLoad
-----------------------------------------------------------------------------------------------
function BenikUI_Unitframes:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("BenikUI_Unitframes.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	Apollo.LoadSprites("NewSprite.xml")
end

-----------------------------------------------------------------------------------------------
-- BenikUI_Unitframes OnDocLoaded
-----------------------------------------------------------------------------------------------
function BenikUI_Unitframes:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndUnit = Apollo.LoadForm(self.xmlDoc, "UnitFrame", nil, self)
		self.wndTarget = Apollo.LoadForm(self.xmlDoc, "TargetFrame", nil, self)
		self.wndAltTarget = Apollo.LoadForm(self.xmlDoc, "TargetFrame", nil, self)
		self.wndAltTarget:SetName("AltTargetFrame")
		self.Options = Apollo.GetAddon("BenikUI")
		if self.Options == nil then
			Apollo.AddAddonErrorText(self, "Could not find main BanikUi Window.")
			return
		end
		self.wndUnit:ToFront()
	    self.wndUnit:Show(true, true)
		self.wndTarget:Show(false,true)
		self.wndAltTarget:Show(false,true)
		self.wndOption = nil
		--Register in Options
		self.Options:RegisterAddon("Unitframes")
		--Color Picker
		GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
		self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
		self.colorPicker:Show(false, true)
				
		--Timer
		self.timerFade = ApolloTimer.Create(0.5, true, "OnSlowUpdate", self)
		--SlashCommands
		Apollo.RegisterSlashCommand("focus", "OnFocusSlashCommand", self)
		--Events
		Apollo.RegisterEventHandler("CharacterCreated", "LoadPlayer", self)
		Apollo.RegisterEventHandler("NextFrame", "OnFrame", self)
		Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
		--Var
		self.unitTarget = nil
		self.unitAltTarget = nil
		self.altPlayerTarget = nil
		self.UpdateSave = nil
		self.Update = nil
		--Functions
		self:SetWindows()
		self:UpdateAll()
		--Loading when reloadui
		if GameLib.GetPlayerUnit() ~= nil then
			self:LoadPlayer()
		end	
	end
end
-----------------------------------------------------------------------------------------------
-- Functions
-----------------------------------------------------------------------------------------------
function BenikUI_Unitframes:SetWindows()
	local WindowOpt = self.Options.db.profile.Unitframes
	--Unit
	local l,t,r,b = unpack(WindowOpt.UnitFrame)
	self.wndUnit:SetAnchorOffsets(l,t,r,b)
	--Target
	l,t,r,b = unpack(WindowOpt.TargetFrame)
	self.wndTarget:SetAnchorOffsets(l,t,r,b)
	--AltTarget
	l,t,r,b = unpack(WindowOpt.AltTargetFrame)
	self.wndAltTarget:SetAnchorOffsets(l,t,r,b)
end

function BenikUI_Unitframes:SetTheme()
	self:UpdateAll()
end

function BenikUI_Unitframes:UpdateAll()
	--Player
	self:ThemeUpdate(self.wndUnit,"Player")
	--Target
	self:ThemeUpdate(self.wndTarget,"Target")
	--Focus
	self:ThemeUpdate(self.wndAltTarget,"Focus")
	--ToT
	self:ThemeUpdateToT()
end

function BenikUI_Unitframes:ThemeUpdateToT()
	local Options = self.Options.db.profile.Unitframes["ToT"]
	local wnd = self.wndTarget:FindChild("ToT")
	wnd:FindChild("HealthEditBox"):SetTextColor(Options.HealthText)
	wnd:FindChild("ShieldEditBox"):SetTextColor(Options.Shield)
	wnd:FindChild("HealthClampMin"):SetBarColor(Options.HealthClamp)
	wnd:FindChild("HealingAbsorb"):SetBarColor(Options.HealingAbsorb)
	wnd:FindChild("Moo"):SetBarColor(Options.Moo)
	wnd:FindChild("FocusBar"):SetBarColor(Options.Focus)
end

function BenikUI_Unitframes:ThemeUpdate(wnd,name)
	local Options = self.Options.db.profile.Unitframes[name]
	wnd:FindChild("HealthEditBox"):SetTextColor(Options.HealthText)
	wnd:FindChild("ShieldEditBox"):SetTextColor(Options.Shield)
	wnd:FindChild("HealthClampMin"):SetBarColor(Options.HealthClamp)
	wnd:FindChild("HealingAbsorb"):SetBarColor(Options.HealingAbsorb)
	wnd:FindChild("Moo"):SetBarColor(Options.Moo)
	wnd:FindChild("FocusBar"):SetBarColor(Options.Focus)
	wnd:FindChild("Armor"):SetBGColor(Options.Armor)
	wnd:FindChild("Frame:Bars:Armor:EditBox"):SetTextColor(Options.Armor)
end

function BenikUI_Unitframes:LoadOptions(wnd)
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
	for i,j in pairs(self.Options.db.profile.Unitframes) do
		local next = self.wndOption:FindChild(i.."Controls")
		if next ~= nil and i~= "General" then
			for k,l in pairs(j) do
				local nextOption = next:FindChild(k)
				if nextOption ~= nil then
					nextOption:FindChild("Swatch"):SetBGColor(l)
				end
			end
		end
	end
end

function BenikUI_Unitframes:LoadPlayer()
	--Model Window
	local player = GameLib.GetPlayerUnit()
	local model  = self.wndUnit:FindChild("Frame:PicModel:TargetModel")
	model:SetCostume(player)
	model:SetData(player)
	
	--Name
	self.wndUnit:FindChild("Frame:Bars:Health:Name"):SetText(player:GetName())
	--BuffBars
	self.wndUnit:FindChild("Frame:Bars:HarmBuffBar"):SetUnit(player)
	self.wndUnit:FindChild("Frame:Bars:BeneBuffBar"):SetUnit(player)
	--Class
	local classID = player:GetClassId()
	local ClassText = self.wndUnit:FindChild("Frame:Bars:Shield:Class")
	if classID ~= nil then
		if classID == GameLib.CodeEnumClass.Engineer then
			ClassText:SetText("Engineer")
		elseif classID == GameLib.CodeEnumClass.Esper then
			ClassText:SetText("Esper")
		elseif classID == GameLib.CodeEnumClass.Warrior then
			ClassText:SetText("Warrior")
		elseif classID == GameLib.CodeEnumClass.Spellslinger then
			ClassText:SetText("Spellslinger")
		elseif classID == GameLib.CodeEnumClass.Medic then
			ClassText:SetText("Medic")
		else
			ClassText:SetText("")
		end
	else
		ClassText:SetText("")
	end
	--Target
	self.unitTarget = player:GetTarget()
	
	if self.unitTarget ~= nil then
		self:LoadTarget()
	else
		self.wndTarget:Show(false,true)
	end
	
	--AltTarget
	self.unitAltTarget = player:GetAlternateTarget()
	if self.unitAltTarget ~= nil then
		self:LoadAltTarget()
	end
end

function BenikUI_Unitframes:LoadTarget()
	--Model Window
	local player = self.unitTarget
	local model  = self.wndTarget:FindChild("Frame:PicModel:TargetModel")
	
	
	model:SetCostume(player)
	model:SetData(player)
	
	--Name
	self.wndTarget:FindChild("Frame:Bars:Health:Name"):SetText(player:GetName())
	--BuffBars
	self.wndTarget:FindChild("Frame:Bars:HarmBuffBar"):SetUnit(player)
	self.wndTarget:FindChild("Frame:Bars:BeneBuffBar"):SetUnit(player)
	--Class
	local classID = player:GetClassId()
	local ClassText = self.wndTarget:FindChild("Frame:Bars:Shield:Class")
	if classID ~= nil then
		if classID == GameLib.CodeEnumClass.Engineer then
			ClassText:SetText("Engineer")
		elseif classID == GameLib.CodeEnumClass.Esper then
			ClassText:SetText("Esper")
		elseif classID == GameLib.CodeEnumClass.Warrior then
			ClassText:SetText("Warrior")
		elseif classID == GameLib.CodeEnumClass.Spellslinger then
			ClassText:SetText("Spellslinger")
		elseif classID == GameLib.CodeEnumClass.Medic then
			ClassText:SetText("Medic")
		else
			ClassText:SetText("")
		end
	else
		ClassText:SetText("")
	end
	--ToT
	self.unitToT = self.unitTarget:GetTarget()
	if self.unitToT ~= nil then
		self:LoadToT()
	end	
	
	self.wndTarget:Show(true,true)
end

function BenikUI_Unitframes:LoadToT()
	--Model Window
	local player = self.unitToT
	local model  = self.wndTarget:FindChild("ToT:PicModel:TargetModelMini")
	
	model:SetCostume(player)
	model:SetData(player)
	
	--Name
	self.wndTarget:FindChild("ToT"):FindChild("Bars:Health:Name"):SetText(player:GetName())
	self.wndTarget:FindChild("ToT"):Show(true,true)
	
	--FocusBar
	self.wndTarget:FindChild("ToT:Bars:Focus:FocusBar"):SetMax(1)
	self.wndTarget:FindChild("ToT:Bars:Focus:FocusBar"):SetProgress(1)
end

function BenikUI_Unitframes:LoadAltTarget()
	--Model Window
	local player = GameLib.GetPlayerUnit():GetAlternateTarget()
	local model  = self.wndAltTarget:FindChild("Frame:PicModel:TargetModel")
	
	
	model:SetCostume(player)
	model:SetData(player)
	
	--Name
	self.wndAltTarget:FindChild("Frame:Bars:Health:Name"):SetText(player:GetName())
	--BuffBars
	self.wndAltTarget:FindChild("Frame:Bars:HarmBuffBar"):SetUnit(player)
	self.wndAltTarget:FindChild("Frame:Bars:BeneBuffBar"):SetUnit(player)
	--Class
	local classID = player:GetClassId()
	local ClassText = self.wndAltTarget:FindChild("Frame:Bars:Shield:Class")
	if classID ~= nil then
		if classID == GameLib.CodeEnumClass.Engineer then
			ClassText:SetText("Engineer")
		elseif classID == GameLib.CodeEnumClass.Esper then
			ClassText:SetText("Esper")
		elseif classID == GameLib.CodeEnumClass.Warrior then
			ClassText:SetText("Warrior")
		elseif classID == GameLib.CodeEnumClass.Spellslinger then
			ClassText:SetText("Spellslinger")
		elseif classID == GameLib.CodeEnumClass.Medic then
			ClassText:SetText("Medic")
		else
			ClassText:SetText("")
		end
	else
		ClassText:SetText("")
	end
	--ToT
	self.wndAltTarget:FindChild("ToT"):Show(false,true)
	
	self.wndAltTarget:Show(true,true)
end


function BenikUI_Unitframes:OnFrame()
	local player = GameLib.GetPlayerUnit()
	
	--Update Player
	self:UpdatedFrame(self.wndUnit,player,"Player")
	
	--Update Target
	local newTarget = player:GetTarget()
	if self.unitTarget ~= newTarget then
		self.unitTarget = newTarget
		if newTarget ~= nil then
			self:LoadTarget()
			self:UpdatedFrame(self.wndTarget,self.unitTarget,"Target")
		else
			self.wndTarget:Show(false,false)
		end
	else
		if newTarget ~= nil then
			self:UpdatedFrame(self.wndTarget,self.unitTarget,"Target")
		end
	end
	
	--Update AltTarget
	local newAltTarget = player:GetAlternateTarget()
	if self.unitAltTarget ~= newAltTarget then
		self.unitAltTarget = newAltTarget
		if newAltTarget ~= nil then
			self:LoadAltTarget()
			self:UpdatedFrame(self.wndAltTarget,self.unitAltTarget,"Focus")
		else
			self.wndAltTarget:Show(false,false)
		end
	else
		if newAltTarget ~= nil then
			self:UpdatedFrame(self.wndAltTarget,self.unitAltTarget,"Focus")
		end
	end
	
	--Update ToT
	if self.unitTarget ~= nil then
		local newToT = self.unitTarget:GetTarget()
		if self.unitTarget ~= newTot then
			self.unitToT = newToT
			if newToT ~= nil then
				self:LoadToT()
				self:UpdateTot(self.wndTarget:FindChild("ToT"),self.unitToT)	
			else
				self.wndTarget:FindChild("ToT"):Show(false,true)		
			end
		else
			self:UpdateTot(self.wndTarget:FindChild("ToT"),self.unitToT)
		end
	end
end


function BenikUI_Unitframes:UpdatedFrame(wndUnit, newUnit,name)
	local Bars = wndUnit:FindChild("Frame:Bars")
	local Options = self.Options.db.profile.Unitframes
	
	--Healh
	local nMaxHealth = newUnit:GetMaxHealth() or 0
	local nHealth = newUnit:GetHealth() or 0
	local healthBar = Bars:FindChild("Health:HealthBar")
	healthBar:SetMax(nMaxHealth)
	healthBar:SetProgress(nHealth)
	Bars:FindChild("Health:HealthEditBox"):SetText(NumberToText(nHealth))
	if nHealth/nMaxHealth >= 0.75 then
		healthBar:SetBarColor(Options[name].fullHealth)
	elseif nHealth/nMaxHealth >= 0.25 then
		healthBar:SetBarColor(Options[name].halfHealth)
	else
		healthBar:SetBarColor(Options[name].lowHealth)
	end
	
	
	--Shield
	local nShield = newUnit:GetShieldCapacity() or 0
	Bars:FindChild("Shield:ShieldEditBox"):SetText(NumberToTextSmall(nShield))
	
	--Focus
	local focusBar = Bars:FindChild("Focus:FocusBar")
	local nFocus = newUnit:GetMaxFocus() or 0
	if  nFocus > 0 then
		focusBar:SetMax(nFocus)
		focusBar:SetProgress(newUnit:GetFocus())
	else
		focusBar:SetMax(1)
		focusBar:SetProgress(1)
	end
	
	--HealingAbsorb
	local nHAbsorb = newUnit:GetHealingAbsorptionValue() or 0
	local HAbsorbBar = Bars:FindChild("Health:HealingAbsorb")
	if nHabrob ~= 0 then
		HAbsorbBar:SetMax(nMaxHealth)
		HAbsorbBar:SetProgress(nHAbsorb,1)
	else
		HAbsorbBar:SetProgress(0)
	end
	
	--Clamp
	local nHealthClampMin = newUnit:GetHealthFloor()
	local clampBar = Bars:FindChild("Health:HealthClampMin")
	if nHealthClampMin ~= 0 then
		clampBar:SetMax(nMaxHealth)
		clampBar:SetProgress(nHealthClampMin,1)
	else
		clampBar:SetProgress(0)
	end
	
	--PvP
	if newUnit:IsPvpFlagged() then
		Bars:FindChild("Health:PvP"):Show(true,true)
		Bars:FindChild("Health:Name"):SetTextColor("AddonError")
	else
		Bars:FindChild("Bars:Health:PvP"):Show(false,true)
		Bars:FindChild("Health:Name"):SetTextColor("UI_WindowTextDefault")
	end
	
	--Armor
	local nArmor  = newUnit:GetInterruptArmorValue() or 0
	if nArmor > 0 then
		Bars:FindChild("Armor"):Show(true,true)
		Bars:FindChild("Armor:EditBox"):SetText(tostring(nArmor))
	else
		Bars:FindChild("Armor"):Show(false,true)
	end
	
	--Moo
	local nVulnerable = newUnit:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability) or 0
	if nVulnerable > 0 then
		Bars:FindChild("Health:Moo"):SetMax(newUnit:GetCCStateTotalTime(Unit.CodeEnumCCState.Vulnerability))
    	Bars:FindChild("Health:Moo"):SetProgress(nVulnerable)
 	 else
    	Bars:FindChild("Health:Moo"):SetProgress(0)
	 end
	
	--CastBar
	if newUnit:IsCasting() then
		Bars:FindChild("CastBar"):Show(true)
		Bars:FindChild("CastBar:CastFill"):SetMax(newUnit:GetCastDuration())
		Bars:FindChild("CastBar:CastFill"):SetProgress(newUnit:GetCastElapsed())
		Bars:FindChild("CastBar:Label"):SetText(newUnit:GetCastName())
	else
		Bars:FindChild("CastBar"):Show(false)
	end
end

function BenikUI_Unitframes:UpdateTot(wndUnit,newUnit)
	local Options = self.Options.db.profile.Unitframes
	local Bars = wndUnit:FindChild("Frame:Bars")
	--Healh
	local nMaxHealth = newUnit:GetMaxHealth() or 0
	local nHealth = newUnit:GetHealth() or 0
	local healthBar = Bars:FindChild("Health:HealthBar")
	healthBar:SetMax(nMaxHealth)
	healthBar:SetProgress(nHealth,0)
	Bars:FindChild("Health:HealthEditBox"):SetText(NumberToText(nHealth))
	if nHealth/nMaxHealth >= 0.75 then
		healthBar:SetBarColor(Options["ToT"].fullHealth)
	elseif nHealth/nMaxHealth >= 0.25 then
		healthBar:SetBarColor(Options["ToT"].halfHealth)
	else
		healthBar:SetBarColor(Options["ToT"].lowHealth)
	end
	
	
	--Shield
	local nShield = newUnit:GetShieldCapacity()or 0
	Bars:FindChild("Shield:ShieldEditBox"):SetText(NumberToTextSmall(nShield))
	
	
	--HealingAbsorb
	local nHAbsorb = newUnit:GetHealingAbsorptionValue() or 0
	local HAbsorbBar = Bars:FindChild("Health:HealingAbsorb")
	if nHabrob ~= 0 then
		HAbsorbBar:SetMax(nMaxHealth)
		HAbsorbBar:SetProgress(nHAbsorb,1)
	else
		HAbsorbBar:SetProgress(0,0)
	end


	
	--Moo
	local nVulnerable = newUnit:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability) or 0
	if nVulnerable > 0 then
		Bars:FindChild("Health:Moo"):SetMax(newUnit:GetCCStateTotalTime(Unit.CodeEnumCCState.Vulnerability))
    	Bars:FindChild("Health:Moo"):SetProgress(nVulnerable)
 	 else
    	Bars:FindChild("Health:Moo"):SetProgress(0)
	 end

end


function BenikUI_Unitframes:OnSlowUpdate()
	-- Raid Marker
	--Player
	local player = GameLib.GetPlayerUnit()
	local wndRaidMarker = self.wndUnit:FindChild("Frame:RaidMarker")
	if wndRaidMarker then
		wndRaidMarker:SetSprite("")
		local nMarkerId = player and player:GetTargetMarker() or 0
		if player and nMarkerId ~= 0 then
			wndRaidMarker:SetSprite(kstrRaidMarkerToSprite[nMarkerId])
		end
	end
	--Target
	wndRaidMarker = self.wndTarget:FindChild("Frame:RaidMarker")
	if wndRaidMarker then
		wndRaidMarker:SetSprite("")
		local nMarkerId = self.unitTarget and self.unitTarget:GetTargetMarker() or 0
		if self.unitTarget and nMarkerId ~= 0 then
			wndRaidMarker:SetSprite(kstrRaidMarkerToSprite[nMarkerId])
		end
	end
	--AltTarget
	wndRaidMarker = self.wndAltTarget:FindChild("Frame:RaidMarker")
	if wndRaidMarker then
		wndRaidMarker:SetSprite("")
		local nMarkerId = self.unitTarget and self.unitTarget:GetTargetMarker() or 0
		if self.unitAltTarget and nMarkerId ~= 0 then
			wndRaidMarker:SetSprite(kstrRaidMarkerToSprite[nMarkerId])
		end
	end
	--BuffBars
	self.wndUnit:FindChild("Frame:Bars:HarmBuffBar"):SetUnit(player)
	self.wndUnit:FindChild("Frame:Bars:BeneBuffBar"):SetUnit(player)
end


function BenikUI_Unitframes:OnGenerateBuffTooltip(wndHandler, wndControl, eType, splBuff)
	if wndHandler == wndControl or eType ~= Tooltip.TooltipGenerateType_Spell then
		return
	end
	Tooltip.GetBuffTooltipForm(self, wndControl, splBuff, {bFutureSpell = false})
end

function BenikUI_Unitframes:OnMouseButtonDown(wndHandler, wndControl, eMouseButton, x, y)
	local unitToT = wndHandler:GetData()
	if eMouseButton == GameLib.CodeEnumInputMouse.Left and unitToT ~= nil then
		GameLib.SetTargetUnit(unitToT)
		return false
	end
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and unitToT ~= nil then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", nil, unitToT:GetName(), unitToT)
		return true
	end

	if IsDemo() then
		return true
	end

	return false
end


function BenikUI_Unitframes:OnPVPIconGenerateTooltip(wndHandler, wndControl)
	if self.unitTarget == nil or not self.unitTarget:IsValid() or not self.unitTarget:IsPvpFlagged() or wndHandler ~= wndControl then
		return
	end

	local strTooltip = ""
	if self.unitTarget == GameLib.GetPlayerUnit() then
		local tPvPInfo = GameLib.GetPvpFlagInfo()
		strTooltip = string.format("<T TextColor=\"UI_WindowTextDefault\">%s</T>", Apollo.GetString("TargetFrame_PvPBonus"))
		if tPvPInfo.nCooldown > 0 then
			strTooltip = strTooltip .. "<P></P>" .. string.format("<T TextColor=\"UI_WindowTextDefault\">%s</T>", String_GetWeaselString(Apollo.GetString("TargetFrame_PvPCooldown"), ConvertSecondsToTimer(tPvPInfo.nCooldown, 0)))
		elseif not tPvPInfo.bIsForced then
			strTooltip = strTooltip .. "<P></P>" .. string.format("<T TextColor=\"Disabled\">%s</T>", Apollo.GetString("TargetFrame_PvPOff"))
		else
			strTooltip = strTooltip .. "<P></P>" .. string.format("<T TextColor=\"Disabled\">%s</T>", Apollo.GetString("TargetFrame_PvPForced"))
		end
	else
		strTooltip = Apollo.GetString("TargetFrame_PvPMarked")
	end
	wndControl:SetTooltip(strTooltip)
end

function BenikUI_Unitframes:OnFocusSlashCommand()
	GameLib.GetPlayerUnit():SetAlternateTarget(GameLib.GetTargetUnit())
end

function BenikUI_Unitframes:OnWindowMoved( wndHandler, wndControl)
	local l,t,r,b = wndControl:GetAnchorOffsets()
	local Name = wndHandler:GetName()
	self.Options.db.profile.Unitframes[Name] = {l,t,r,b}
end

function BenikUI_Unitframes:OnListItemClick( wndHandler, wndControl, eMouseButton )
	for i,j in pairs(self.wndOption:GetChildren()) do
		if j:GetName() == wndHandler:GetText().."Controls" then
			j:Show(true)
		else
			j:Show(false)
		end
	end
end

function BenikUI_Unitframes:ColorPickerCallback(strColor)
	self.Options.db.profile.Unitframes[self.UpdateSave[1]][self.UpdateSave[2]] = strColor
	self.Update:SetBGColor(strColor)
	self:UpdateAll()
end

--Neeed to do refactor  (

function BenikUI_Unitframes:OnColorPlayer(wndHandler)
	local name = wndHandler:GetParent():GetName()
	self.UpdateSave = {"Player",name}
	self.Update = wndHandler
	self.colorPicker:Show(true)
  	self.colorPicker:ToFront()
end

function BenikUI_Unitframes:OnColorTarget(wndHandler)
	local name = wndHandler:GetParent():GetName()
	self.UpdateSave = {"Target",name}
	self.Update = wndHandler
	self.colorPicker:Show(true)
  	self.colorPicker:ToFront()
end

function BenikUI_Unitframes:OnColorFocus(wndHandler)
	local name = wndHandler:GetParent():GetName()
	self.UpdateSave = {"Focus",name}
	self.Update = wndHandler
	self.colorPicker:Show(true)
  	self.colorPicker:ToFront()
end

function BenikUI_Unitframes:OnColorToT(wndHandler)
	local name = wndHandler:GetParent():GetName()
	self.UpdateSave = {"ToT",name}
	self.Update = wndHandler
	self.colorPicker:Show(true)
  	self.colorPicker:ToFront()
end

-----------------------------------------------------------------------------------------------
-- Utils
-----------------------------------------------------------------------------------------------




-----------------------------------------------------------------------------------------------
-- BenikUI_Unitframes Instance
-----------------------------------------------------------------------------------------------
local BenikUI_UnitframesInst = BenikUI_Unitframes:new()
BenikUI_UnitframesInst:Init()
