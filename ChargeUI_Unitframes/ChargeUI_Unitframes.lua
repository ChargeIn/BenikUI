-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChargeUI_Unitframes
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Unit"
require "GameLib"
require "Apollo"
require "PathMission"
require "P2PTrading"

-----------------------------------------------------------------------------------------------
-- ChargeUI_Unitframes Module Definition
-----------------------------------------------------------------------------------------------
local ChargeUI_Unitframes = {}

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
function ChargeUI_Unitframes:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here

    return o
end

function ChargeUI_Unitframes:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


-----------------------------------------------------------------------------------------------
-- ChargeUI_Unitframes OnLoad
-----------------------------------------------------------------------------------------------
function ChargeUI_Unitframes:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("ChargeUI_Unitframes.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	Apollo.LoadSprites("NewSprite.xml")
end

-----------------------------------------------------------------------------------------------
-- ChargeUI_Unitframes OnDocLoaded
-----------------------------------------------------------------------------------------------
function ChargeUI_Unitframes:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndUnit = Apollo.LoadForm(self.xmlDoc, "UnitFrame", nil, self)
		self.UnitFrameHarmBuffBar = Apollo.LoadForm(self.xmlDoc, "HarmBuffBar", nil, self)
		self.UnitFrameHarmBuffBar:SetName("Unit")
		self.wndTarget = Apollo.LoadForm(self.xmlDoc, "TargetFrame", nil, self)
		self.TargetFrameHarmBuffBar = Apollo.LoadForm(self.xmlDoc, "HarmBuffBar", nil, self)
		self.TargetFrameHarmBuffBar:SetName("Target")
		self.wndAltTarget = Apollo.LoadForm(self.xmlDoc, "TargetFrame", nil, self)
		self.AltTargetFrameHarmBuffBar = Apollo.LoadForm(self.xmlDoc, "HarmBuffBar", nil, self)
		self.AltTargetFrameHarmBuffBar:SetName("AltTarget")
		self.wndAltTarget:SetName("AltTargetFrame")
		self.wndAltTarget:FindChild("MouseCatcher"):SetText("AltTarget Frame")
		self.wndAltTarget:FindChild("MouseCatcherToT"):SetText("AltTarget ToT Frame")
		self.Options = Apollo.GetAddon("ChargeUI")
		if self.Options == nil then
			Apollo.AddAddonErrorText(self, "Could not find main BanikUi Window.")
			return
		end
	    self.wndUnit:Show(true, true)
		self.UnitFrameHarmBuffBar:Show(true,true)
		self.TargetFrameHarmBuffBar:Show(true,true)
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

function ChargeUI_Unitframes:StartCustomise()
	self.wndUnit:FindChild("MouseCatcher"):Show(true)
	self.wndUnit:SetStyle("IgnoreMouse",false)
	self.wndUnit:SetStyle("Moveable",true)
	self.wndUnit:SetStyle("Sizable",true)
	
	self.UnitFrameHarmBuffBar:FindChild("MouseCatcher"):Show(true)
	self.UnitFrameHarmBuffBar:SetStyle("IgnoreMouse",false)
	self.UnitFrameHarmBuffBar:SetStyle("Moveable",true)
	self.UnitFrameHarmBuffBar:SetStyle("Sizable",true)
	
	self.wndTarget:Show(true)
	self.wndTarget:FindChild("MouseCatcher"):Show(true)
	self.wndTarget:SetStyle("IgnoreMouse",false)
	self.wndTarget:SetStyle("Moveable",true)
	self.wndTarget:SetStyle("Sizable",true)
	
	self.TargetFrameHarmBuffBar:Show(true)
	self.TargetFrameHarmBuffBar:FindChild("MouseCatcher"):Show(true)
	self.TargetFrameHarmBuffBar:SetStyle("IgnoreMouse",false)
	self.TargetFrameHarmBuffBar:SetStyle("Moveable",true)
	self.TargetFrameHarmBuffBar:SetStyle("Sizable",true)
	
	self.wndTarget:FindChild("ToT"):Show(true)
	self.wndTarget:FindChild("ToT:MouseCatcherToT"):Show(true)
	self.wndTarget:FindChild("ToT"):SetStyle("IgnoreMouse",false)
	self.wndTarget:FindChild("ToT"):SetStyle("Moveable",true)
	self.wndTarget:FindChild("ToT"):SetStyle("Sizable",true)
	
	self.wndAltTarget:Show(true)
	self.wndAltTarget:FindChild("MouseCatcher"):Show(true)
	self.wndAltTarget:SetStyle("IgnoreMouse",false)
	self.wndAltTarget:SetStyle("Moveable",true)
	self.wndAltTarget:SetStyle("Sizable",true)
	
	self.AltTargetFrameHarmBuffBar:Show(true)
	self.AltTargetFrameHarmBuffBar:FindChild("MouseCatcher"):Show(true)
	self.AltTargetFrameHarmBuffBar:SetStyle("IgnoreMouse",false)
	self.AltTargetFrameHarmBuffBar:SetStyle("Moveable",true)
	self.AltTargetFrameHarmBuffBar:SetStyle("Sizable",true)
	
	self.wndAltTarget:FindChild("ToT"):Show(true)
	self.wndAltTarget:FindChild("ToT:MouseCatcherToT"):Show(true)
	self.wndAltTarget:FindChild("ToT"):SetStyle("IgnoreMouse",false)
	self.wndAltTarget:FindChild("ToT"):SetStyle("Moveable",true)
	self.wndAltTarget:FindChild("ToT"):SetStyle("Sizable",true)
end

function ChargeUI_Unitframes:EndCustomise()
	self.wndUnit:FindChild("MouseCatcher"):Show(false)
	self.wndUnit:SetStyle("IgnoreMouse",true)
	self.wndUnit:SetStyle("Moveable",false)
	self.wndUnit:SetStyle("Sizable",false)
	
	self.UnitFrameHarmBuffBar:FindChild("MouseCatcher"):Show(false)
	self.UnitFrameHarmBuffBar:SetStyle("IgnoreMouse",true)
	self.UnitFrameHarmBuffBar:SetStyle("Moveable",false)
	self.UnitFrameHarmBuffBar:SetStyle("Sizable",false)
	
	if self.unitTarget == nil then
		self.wndTarget:Show(false)
	end
	self.wndTarget:FindChild("MouseCatcher"):Show(false)
	self.wndTarget:SetStyle("IgnoreMouse",true)
	self.wndTarget:SetStyle("Moveable",false)
	self.wndTarget:SetStyle("Sizable",false)
	
	if self.unitTarget == nil then
		self.TargetFrameHarmBuffBar:Show(false)
	end
	self.TargetFrameHarmBuffBar:FindChild("MouseCatcher"):Show(false)
	self.TargetFrameHarmBuffBar:SetStyle("IgnoreMouse",true)
	self.TargetFrameHarmBuffBar:SetStyle("Moveable",false)
	self.TargetFrameHarmBuffBar:SetStyle("Sizable",false)
	 
	self.wndTarget:FindChild("ToT:MouseCatcherToT"):Show(false)
	self.wndTarget:FindChild("ToT"):SetStyle("IgnoreMouse",true)
	self.wndTarget:FindChild("ToT"):SetStyle("Moveable",false)
	self.wndTarget:FindChild("ToT"):SetStyle("Sizable",false)
	
	
	if self.unitAltTarget== nil then
		self.wndAltTarget:Show(false)
	end
	self.wndAltTarget:FindChild("MouseCatcher"):Show(false)
	self.wndAltTarget:SetStyle("IgnoreMouse",true)
	self.wndAltTarget:SetStyle("Moveable",false)
	self.wndAltTarget:SetStyle("Sizable",false)
	
	if self.unitAltTarget == nil then
		self.AltTargetFrameHarmBuffBar:Show(false)
	end
	self.AltTargetFrameHarmBuffBar:FindChild("MouseCatcher"):Show(false)
	self.AltTargetFrameHarmBuffBar:SetStyle("IgnoreMouse",true)
	self.AltTargetFrameHarmBuffBar:SetStyle("Moveable",false)
	self.AltTargetFrameHarmBuffBar:SetStyle("Sizable",false)	
	
	self.wndAltTarget:FindChild("ToT:MouseCatcherToT"):Show(false)
	self.wndAltTarget:FindChild("ToT"):SetStyle("IgnoreMouse",true)
	self.wndAltTarget:FindChild("ToT"):SetStyle("Moveable",false)
	self.wndAltTarget:FindChild("ToT"):SetStyle("Sizable",false)
end

function ChargeUI_Unitframes:SaveWindows()
	--Unit Frame
	local l,t,r,b = self.wndUnit:GetAnchorOffsets()
	self.Options.db.profile.Unitframes.UnitFrame = {l,t,r,b}
	--Target Frame
	l,t,r,b = self.wndTarget:GetAnchorOffsets()
	self.Options.db.profile.Unitframes.TargetFrame = {l,t,r,b}
	--AltTarget Frame
	l,t,r,b = self.wndAltTarget:GetAnchorOffsets()
	self.Options.db.profile.Unitframes.AltTargetFrame = {l,t,r,b}
	--Unit DebuffBar
	l,t,r,b = self.UnitFrameHarmBuffBar:GetAnchorOffsets()
	self.Options.db.profile.Unitframes.HarmBuffBarPlayer = {l,t,r,b} 
	--Target DebuffBar
	l,t,r,b = self.TargetFrameHarmBuffBar:GetAnchorOffsets()
	self.Options.db.profile.Unitframes.HarmBuffBarTarget = {l,t,r,b}
	--AltTarget DebuffBar   
	l,t,r,b = self.AltTargetFrameHarmBuffBar:GetAnchorOffsets()
	self.Options.db.profile.Unitframes.HarmBuffBarAltTarget = {l,t,r,b}  
end

function ChargeUI_Unitframes:OnMouseCatcherClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	local Addon = Apollo.GetAddon("ChargeUI")
	if Addon ~= nil then
		Addon:OnWindowClick(wndControl:GetParent())
	end
end

function ChargeUI_Unitframes:SetWindows()
	local WindowOpt = self.Options.db.profile.Unitframes
	
	self.TargetFrameHarmBuffBar:FindChild("MouseCatcher"):SetText("Target DebuffBar")
	self.UnitFrameHarmBuffBar:FindChild("MouseCatcher"):SetText("Player DebuffBar")
	self.AltTargetFrameHarmBuffBar:FindChild("MouseCatcher"):SetText("AltTarget DebuffBar")
	--Unit
	local l,t,r,b = unpack(WindowOpt.UnitFrame)
	self.wndUnit:SetAnchorOffsets(l,t,r,b)
	l,t,r,b = unpack(WindowOpt.HarmBuffBarPlayer)
	self.UnitFrameHarmBuffBar:SetAnchorOffsets(l,t,r,b)
	--Target
	l,t,r,b = unpack(WindowOpt.TargetFrame)
	self.wndTarget:SetAnchorOffsets(l,t,r,b)
	l,t,r,b = unpack(WindowOpt.HarmBuffBarTarget)
	self.TargetFrameHarmBuffBar:SetAnchorOffsets(l,t,r,b)
	--AltTarget
	l,t,r,b = unpack(WindowOpt.AltTargetFrame)
	self.wndAltTarget:SetAnchorOffsets(l,t,r,b)
	l,t,r,b = unpack(WindowOpt.HarmBuffBarAltTarget)
	self.AltTargetFrameHarmBuffBar:SetAnchorOffsets(l,t,r,b)
end

function ChargeUI_Unitframes:SetTheme()
	self:UpdateAll()
end

function ChargeUI_Unitframes:UpdateAll()
	--Player
	self:ThemeUpdate(self.wndUnit,"Player")
	--Target
	self:ThemeUpdate(self.wndTarget,"Target")
	--Focus
	self:ThemeUpdate(self.wndAltTarget,"Focus")
	--ToT
	self:ThemeUpdateToT()
end

function ChargeUI_Unitframes:ThemeUpdateToT()
	local Options = self.Options.db.profile.Unitframes["ToT"]
	local wnd = self.wndTarget:FindChild("ToT")
	wnd:FindChild("HealthEditBox"):SetTextColor(Options.HealthText)
	wnd:FindChild("ShieldEditBox"):SetTextColor(Options.Shield)
	wnd:FindChild("HealthClampMin"):SetBarColor(Options.HealthClamp)
	wnd:FindChild("HealthClampMax"):SetBarColor(Options.HealthClamp)
	wnd:FindChild("HealingAbsorb"):SetBarColor(Options.HealingAbsorb)
	wnd:FindChild("Moo"):SetBarColor(Options.Moo)
	wnd:FindChild("FocusBar"):SetBarColor(Options.Focus)
end

function ChargeUI_Unitframes:ThemeUpdate(wnd,name)
	local Options = self.Options.db.profile.Unitframes[name]
	wnd:FindChild("HealthEditBox"):SetTextColor(Options.HealthText)
	wnd:FindChild("ShieldEditBox"):SetTextColor(Options.Shield)
	wnd:FindChild("HealthClampMin"):SetBarColor(Options.HealthClamp)
	wnd:FindChild("HealthClampMax"):SetBarColor(Options.HealthClamp)
	wnd:FindChild("HealingAbsorb"):SetBarColor(Options.HealingAbsorb)
	wnd:FindChild("Moo"):SetBarColor(Options.Moo)
	wnd:FindChild("FocusBar"):SetBarColor(Options.Focus)
	wnd:FindChild("Armor"):SetBGColor(Options.Armor)
	wnd:FindChild("Frame:Bars:Armor:EditBox"):SetTextColor(Options.Armor)
end

function ChargeUI_Unitframes:LoadOptions(wnd)
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
		elseif i == "General" then
			next:FindChild("Model"):SetCheck(j.Model)
		end
	end
end

function ChargeUI_Unitframes:LoadPlayer()
	--Model Window
	local player = GameLib.GetPlayerUnit()
	local model  = self.wndUnit:FindChild("Frame:PicModel:TargetModel")
	model:SetCostume(player)
	model:SetData(player)

	--Model
	self.wndUnit:FindChild("PicModel"):Show(self.Options.db.profile.Unitframes.General.Model)
	--Name
	self.wndUnit:FindChild("Frame:Bars:Health:Name"):SetText(player:GetName())
	--BuffBars
	self.UnitFrameHarmBuffBar:FindChild("HarmBuffBar"):SetUnit(player)
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
			ClassText:SetText("Stalker")
		end
	else
		ClassText:SetText("")
	end
	--Target
	self.unitTarget = player:GetTarget()

	if self.unitTarget ~= nil then
		self:LoadTarget()
	else
		if not self.wndTarget:FindChild("MouseCatcher"):IsShown() then
			self.wndTarget:Show(false,true)
			self.TargetFrameHarmBuffBar:Show(false,true)
		end
	end

	--AltTarget
	self.unitAltTarget = player:GetAlternateTarget()
	if self.unitAltTarget ~= nil then
		self:LoadAltTarget()
	end
end

function ChargeUI_Unitframes:LoadTarget()
	--Model Window
	local player = self.unitTarget
	local model  = self.wndTarget:FindChild("Frame:PicModel:TargetModel")

	--Model
	self.wndTarget:FindChild("PicModel"):Show(self.Options.db.profile.Unitframes.General.Model)
	model:SetCostume(player)
	model:SetData(player)

	--Name
	self.wndTarget:FindChild("Frame:Bars:Health:Name"):SetText(player:GetName())
	--BuffBars
	self.TargetFrameHarmBuffBar:FindChild("HarmBuffBar"):SetUnit(player)
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
	self.TargetFrameHarmBuffBar:Show(true,true)
end

function ChargeUI_Unitframes:LoadToT()
	--Model Window
	local player = self.unitToT
	local model  = self.wndTarget:FindChild("ToT:PicModel:TargetModelMini")

	--Model
	self.wndTarget:FindChild("ToT:PicModel"):Show(self.Options.db.profile.Unitframes.General.Model)
	model:SetCostume(player)
	model:SetData(player)

	--Name
	self.wndTarget:FindChild("ToT"):FindChild("Bars:Health:Name"):SetText(player:GetName())
	self.wndTarget:FindChild("ToT"):Show(true,true)

	--FocusBar
	self.wndTarget:FindChild("ToT:Bars:Focus:FocusBar"):SetMax(1)
	self.wndTarget:FindChild("ToT:Bars:Focus:FocusBar"):SetProgress(1)
end

function ChargeUI_Unitframes:LoadAltTarget()
	--Model Window
	local player = GameLib.GetPlayerUnit():GetAlternateTarget()
	local model  = self.wndAltTarget:FindChild("Frame:PicModel:TargetModel")

	--Model
	self.wndAltTarget:FindChild("PicModel"):Show(self.Options.db.profile.Unitframes.General.Model)
	model:SetCostume(player)
	model:SetData(player)

	--Name
	self.wndAltTarget:FindChild("Frame:Bars:Health:Name"):SetText(player:GetName())
	--BuffBars
	self.AltTargetFrameHarmBuffBar:FindChild("HarmBuffBar"):SetUnit(player)
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
	self.AltTargetFrameHarmBuffBar:Show(true,true)
end


function ChargeUI_Unitframes:OnFrame()
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
			if not self.wndTarget:FindChild("MouseCatcher"):IsShown() then
				self.wndTarget:Show(false,false)
				self.TargetFrameHarmBuffBar:Show(false)
			end
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
			self.wndAltTarget:Show(false,true)
			self.AltTargetFrameHarmBuffBar:Show(false)
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


function ChargeUI_Unitframes:UpdatedFrame(wndUnit, newUnit,name)
	local Bars = wndUnit:FindChild("Frame:Bars")
	local Options = self.Options.db.profile.Unitframes

	--Healh
	local nMaxHealth = newUnit:GetMaxHealth() or 0
	local nHealth = newUnit:GetHealth() or 0
	local healthBar = Bars:FindChild("Health:HealthBar")
	healthBar:SetMax(nMaxHealth)
	healthBar:SetProgress(nHealth)
	Bars:FindChild("Health:HealthEditBox"):SetText(NumberToText(nHealth))
	if nHealth/nMaxHealth >= 0.5 then
		healthBar:SetBarColor(Options[name].fullHealth)
	elseif nHealth/nMaxHealth >= 0.3 then
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
		clampBar:SetProgress(nHealthClampMin)
	else
		clampBar:SetProgress(0)
	end
	local nHealthClampMax = newUnit:GetHealthCeiling()or 0
	clampBar = Bars:FindChild("Health:HealthClampMax")
	if nHealthClampMax ~= 0 then
		clampBar:SetMax(nMaxHealth)
		clampBar:SetProgress(nMaxHealth-nHealthClampMax)
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

function ChargeUI_Unitframes:UpdateTot(wndUnit,newUnit)
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


function ChargeUI_Unitframes:OnSlowUpdate()
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
	self.UnitFrameHarmBuffBar:FindChild("HarmBuffBar"):SetUnit(player)
	self.wndUnit:FindChild("Frame:Bars:BeneBuffBar"):SetUnit(player)
end


function ChargeUI_Unitframes:OnGenerateBuffTooltip(wndHandler, wndControl, eType, splBuff)
	if wndHandler == wndControl or eType ~= Tooltip.TooltipGenerateType_Spell then
		return
	end
	Tooltip.GetBuffTooltipForm(self, wndControl, splBuff, {bFutureSpell = false})
end

function ChargeUI_Unitframes:OnMouseButtonDown(wndHandler, wndControl, eMouseButton, x, y)
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


function ChargeUI_Unitframes:OnPVPIconGenerateTooltip(wndHandler, wndControl)
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

function ChargeUI_Unitframes:OnFocusSlashCommand()
	GameLib.GetPlayerUnit():SetAlternateTarget(GameLib.GetTargetUnit())
end

function ChargeUI_Unitframes:OnWindowMoved( wndHandler, wndControl)
	local l,t,r,b = wndControl:GetAnchorOffsets()
	local Name = wndHandler:GetName()
	local l2,t2,r2,b2 = unpack(self.Options.db.profile.Unitframes[Name])
	if Name == "UnitFrame" then
		local l3,t3,r3,b3 = self.UnitFrameHarmBuffBar:GetAnchorOffsets()
		self.UnitFrameHarmBuffBar:SetAnchorOffsets(l3+(l-l2),t3+(t-t2),r3+(r-r2),b3+(b-b2))
	elseif Name == "TargetFrame" then
		local l3,t3,r3,b3 = self.TargetFrameHarmBuffBar:GetAnchorOffsets()
		self.TargetFrameHarmBuffBar:SetAnchorOffsets(l3+(l-l2),t3+(t-t2),r3+(r-r2),b3+(b-b2))
	else
		local l3,t3,r3,b3 = self.AltTargetFrameHarmBuffBar:GetAnchorOffsets()
		self.AltTargetFrameHarmBuffBar:SetAnchorOffsets(l3+(l-l2),t3+(t-t2),r3+(r-r2),b3+(b-b2))
	end
	self.Options.db.profile.Unitframes[Name] = {l,t,r,b}
	
end

function ChargeUI_Unitframes:OnListItemClick( wndHandler, wndControl, eMouseButton )
	for i,j in pairs(self.wndOption:GetChildren()) do
		if j:GetName() == wndHandler:GetText().."Controls" then
			j:Show(true)
		else
			j:Show(false)
		end
	end
end

function ChargeUI_Unitframes:ColorPickerCallback(strColor)
	self.Options.db.profile.Unitframes[self.UpdateSave[1]][self.UpdateSave[2]] = strColor
	self.Update:SetBGColor(strColor)
	self:UpdateAll()
end

--Neeed to do refactor  (

function ChargeUI_Unitframes:OnColorPlayer(wndHandler)
	local name = wndHandler:GetParent():GetName()
	self.UpdateSave = {"Player",name}
	self.Update = wndHandler
	self.colorPicker:Show(true)
  	self.colorPicker:ToFront()
end

function ChargeUI_Unitframes:OnColorTarget(wndHandler)
	local name = wndHandler:GetParent():GetName()
	self.UpdateSave = {"Target",name}
	self.Update = wndHandler
	self.colorPicker:Show(true)
  	self.colorPicker:ToFront()
end

function ChargeUI_Unitframes:OnColorFocus(wndHandler)
	local name = wndHandler:GetParent():GetName()
	self.UpdateSave = {"Focus",name}
	self.Update = wndHandler
	self.colorPicker:Show(true)
  	self.colorPicker:ToFront()
end

function ChargeUI_Unitframes:OnColorToT(wndHandler)
	local name = wndHandler:GetParent():GetName()
	self.UpdateSave = {"ToT",name}
	self.Update = wndHandler
	self.colorPicker:Show(true)
  	self.colorPicker:ToFront()
end


function ChargeUI_Unitframes:OnShowModel( wndHandler, wndControl, eMouseButton )
	self.Options.db.profile.Unitframes.General.Model = wndHandler:IsChecked()
	self:LoadPlayer()
	if self.unitTarget~= nil then
		self:LoadTarget()
	end
end

function ChargeUI_Unitframes:OnDebuffBarMoved( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	local name = wndControl:GetName()
	local l,t,r,b = wndControl:GetAnchorOffsets()
	if name == "Unit" then
		self.Options.db.profile.Unitframes.HarmBuffBarPlayer = {l,t,r,b}
	elseif name == "Target" then
		self.Options.db.profile.Unitframes.HarmBuffBarTarget = {l,t,r,b}
	else
		self.Options.db.profile.Unitframes.HarmBuffBarAltTarget = {l,t,r,b}
	end
end
-----------------------------------------------------------------------------------------------
-- Utils
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- ChargeUI_Unitframes Instance
-----------------------------------------------------------------------------------------------
local ChargeUI_UnitframesInst = ChargeUI_Unitframes:new()
ChargeUI_UnitframesInst:Init()
