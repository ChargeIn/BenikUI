-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChargeUI
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Apollo"

-----------------------------------------------------------------------------------------------
-- ChargeUI Module
-----------------------------------------------------------------------------------------------
--[[
This modul contain all the savedata form the other addons
	Every Modul contains following functions for updating:
	SetWindows() -- Calls the the last saved window offset for the calling module and applies them
	SetTheme() -- Updates the main theme color
	LoadOptions(Wndow) -- Load the OptionsMenu in the give Window
]]
-----------------------------------------------------------------------------------------------
-- ChargeUI Module Definition
-----------------------------------------------------------------------------------------------
local ChargeUI = {}

local Customise = {"Info","Menu","ActionBar","ShortcutBar","NeedVsGreed","MiniMap","Unitframes","Resources"}


--Default Option
local tChargeUIDefaults = {
	char = {
		currentProfile = nil,
	},
	profile = {
		general = {
			ThemeColor = "xkcdOrange",
		},
		Info = {
			Essences = true,
			FPS = true,
			Latency = true,
			Platin = true,
			XP = true,
			PathXP = true,
			["Renown"] 						= true,
			["Elder Gem"]	 				= true,
			["Vouchers"]	 				= false,
			["Prestige"]	 				= true,
			["Shade Silver"	] 				= false,
			["Glory"] 						= true,
			["ColdCash"] 					= false,
			["Triploons"] 					= true,
			["Realm Transfer"] 				= false,
			["Character Rename Token"] 		= false,
			["Fortune Coin"] 				= false,
			["OmniBits"] 					= true,
			["NCoin"] 						= false,
			["Cosmic Reward Point"] 		= false,
			["Service Token"] 				= true,
			["Protobucks"] 					= false,
			["Giant Point"] 				= false,
			["Character Boost Token"] 		= false,
			["Protostar Promissory Note"] 	= false,

		},
		NeedVsGreed = {
			Anchor = {378,-689,650,-380},
			bNonNeedable = true,
			bDyes = true,
			bAutoGreed = true,
			Ilvl = 70,
			bSign = true,
			bSurvivalist = true,
		},
		Resources = {
			Engineer = {
				BarColor = 		"xkcdLightKhaki",
				InZone = 		"xkcdAcidGreen",
				TextZone =		"xkcdOrange",
			},
			Esper = {
				BarColor =		"xkcdLightKhaki",
			},
			Medic = {
				BarColor =		"xkcdLightKhaki",
			},
			Slinger = {
				BarColor =		"xkcdLightKhaki",
				Innate =		"xkcdAcidGreen",
			},
			Warrior = {
				BarColor = 		"xkcdLightKhaki",
				InZone = 		"xkcdAcidGreen",
				TextZone =		"xkcdOrange",
			},
			Stalker = {
				BarColor =		"xkcdLightKhaki",
				Innate =		"xkcdDarkMagenta",
			},
		},
		FloatText = {
			DMG = 16777215,
			Crit =  16776960,
			Heal = 65280,
			HealShield = 49151,
			DMGTaken = 8388608,
			},
		Nameplates = {
			fullHealth = 		"xkcdDarkSlateBlue",
			halfHealth = 		"xkcdOrange",
			lowHealth = 		"xkcdDarkRed",
			Shield =			"CeruleanBlue",
			AbsorbBar = 		"Amber",
			Moo = 				"xkcdDarkMagenta",
			friendly =			true,
			hostile =			false,
			},
		Unitframes = {
			--nText = 2,
			UnitFrame = 		{-446,-327,-110,-270},
			AltTargetFrame = 	{-165,-432, 170,-375},
			TargetFrame =		{ 109,-327, 444,-270},
			HarmBuffBarPlayer = 	{ -363,-378,-110,-354},
			HarmBuffBarTarget = 	{ 109,-378,362,-354},
			HarmBuffBarAltTarget =	{ -165,-483,88,-459},
			General =			{
				Model =			true,
				},
			Player = 			{
				HealthText =		"white",
				fullHealth = 		"xkcdDarkSlateBlue",
				halfHealth = 		"xkcdOrange",
				lowHealth = 		"xkcdDarkRed",
				HealthClamp = 		"white",
				HealingAbsorb = 	"xkcdLipstickRed",
				Moo = 				"xkcdDarkMagenta",
				Shield =			"xkcdOrange",
				Focus = 			"xkcdOrange",
				Armor = 			"xkcdOrange",
				},
			Target = 			{
				HealthText =		"white",
				fullHealth = 		"xkcdDarkSlateBlue",
				halfHealth = 		"xkcdOrange",
				lowHealth = 		"xkcdDarkRed",
				HealthClamp = 		"white",
				HealingAbsorb = 	"xkcdLipstickRed",
				Moo = 				"xkcdDarkMagenta",
				Shield =			"xkcdOrange",
				Focus = 			"xkcdOrange",
				Armor = 			"xkcdOrange",
				},
			Focus = 			{
				HealthText =		"white",
				fullHealth = 		"xkcdDarkSlateBlue",
				halfHealth = 		"xkcdOrange",
				lowHealth = 		"xkcdDarkRed",
				HealthClamp = 		"white",
				HealingAbsorb = 	"xkcdLipstickRed",
				Moo = 				"xkcdDarkMagenta",
				Shield =			"xkcdOrange",
				Focus = 			"xkcdOrange",
				Armor = 			"xkcdOrange",
				},
			ToT = 			{
				HealthText =		"white",
				fullHealth = 		"xkcdDarkSlateBlue",
				halfHealth = 		"xkcdOrange",
				lowHealth = 		"xkcdDarkRed",
				HealthClamp = 		"white",
				HealingAbsorb = 	"xkcdLipstickRed",
				Moo = 				"xkcdDarkMagenta",
				Shield =			"xkcdOrange",
				Focus = 			"xkcdOrange",
				},
			},
		},
	}


-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ChargeUI:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here

    return o
end

function ChargeUI:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, true, "ChargeUI", nil)
end

function ChargeUI:OnConfigure()
--Callback form Optionmenu
	self:ShowOptions()
end


-----------------------------------------------------------------------------------------------
-- ChargeUI OnLoad
-----------------------------------------------------------------------------------------------
function ChargeUI:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("ChargeUI.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, tChargeUIDefaults)
end

-----------------------------------------------------------------------------------------------
-- ChargeUI OnDocLoaded
-----------------------------------------------------------------------------------------------
function ChargeUI:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ChargeUIForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		self.CustomiseWnd = Apollo.LoadForm(self.xmlDoc, "CustomiseWnd", nil, self)
		local GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
	  	self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
		self.colorPicker:Show(false,true)
	    self.wndMain:Show(false, true)
		self.CustomiseWnd:Show(false,true)

		--Commands
		Apollo.RegisterSlashCommand("ChargeUI","ShowOptions",self)
		Apollo.RegisterSlashCommand("CUI","ShowOptions",self)

		--Var
		self.RegAddons = {"Customise","Thanks"}
		self.CurrAddon = nil
		self.CurrWnd = nil
	end
end

-----------------------------------------------------------------------------------------------
-- ChargeUI Functions
-----------------------------------------------------------------------------------------------
function ChargeUI:RegisterAddon(Name)
	self.RegAddons = self.RegAddons or {}
	table.insert(self.RegAddons,Name)
end

function ChargeUI:OnListItemClick( wndHandler, wndControl, eMouseButton )
	local Name = wndControl:GetText()
	local MainGrid = self.wndMain:FindChild("MainGrid")
	MainGrid:DestroyChildren()

	if Name == "Thanks" then
		Apollo.LoadForm(self.xmlDoc,"ThanksOption", MainGrid, self)
	elseif Name == "Customise" then
		Apollo.LoadForm(self.xmlDoc,"CustomiseOption", MainGrid, self)
	else
		self.CurrAddon = Apollo.GetAddon("ChargeUI_"..Name)

		if self.CurrAddon ~= nil then
			self.CurrAddon:LoadOptions(self.wndMain)
		else
			MainGrid:SetText("Could not load "..Name.."-Options")
		end
	end
end


-----------------------------------------------------------------------------------------------
-- ChargeUIForm Functions
-----------------------------------------------------------------------------------------------
function ChargeUI:ShowOptions()
	local oList = self.wndMain:FindChild("OptionsList")
	oList:DestroyChildren()
	for i,j in pairs(self.RegAddons) do
		local newOption = Apollo.LoadForm(self.xmlDoc,"ListItem", oList, self)
		newOption:SetText(j)
	end

	oList:ArrangeChildrenVert()
	self.wndMain:FindChild("MainGrid"):SetText("")
	self.wndMain:Invoke()
end

-- when the Cancel button is clicked
function ChargeUI:OnCancel()
	self.wndMain:Close() -- hide the window
end

function ChargeUI:OnHomePress( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("OptionsList"):DestroyChildren()
	self.wndMain:FindChild("MainGrid"):DestroyChildren()
	self:ShowOptions()
end

function ChargeUI:StartCustomise( wndHandler, wndControl, eMouseButton )
	self.wndMain:Close()
	self.CustomiseWnd:Invoke()
	
	if self.CurrWnd ~= nil then
		self.CustomiseWnd:FindChild("Text:EditBox"):SetText("Window: "..self.CurrWnd:GetText())
	else
		self.CustomiseWnd:FindChild("Text:EditBox"):SetText("Select a Window")
	end
	
	for i,j in pairs(Customise) do
		local Addon = Apollo.GetAddon("ChargeUI_"..j)
		if Addon ~= nil then
			Addon:StartCustomise()
		end
	end
	
	self:UpdateWindow()
end

function ChargeUI:EndCustomise( wndHandler, wndControl, eMouseButton )
	self.CustomiseWnd:Close()
	
	for i,j in pairs(Customise) do
		local Addon = Apollo.GetAddon("ChargeUI_"..j)
		if Addon ~= nil then
			Addon:EndCustomise()
			Addon:SaveWindows()
		end
	end
end

function ChargeUI:OnWindowClick(wnd)
	self.CurrWnd = wnd
	if self.CurrWnd:FindChild("MouseCatcher")~= nil then
		self.CustomiseWnd:FindChild("Text:EditBox"):SetText("Window: "..self.CurrWnd:FindChild("MouseCatcher"):GetText())
	else
		self.CustomiseWnd:FindChild("Text:EditBox"):SetText("Window: "..self.CurrWnd:FindChild("MouseCatcherToT"):GetText())
	end
	self:UpdateWindow()
end

function ChargeUI:OnUp( wndHandler, wndControl, eMouseButton )
	local l,t,r,b = self.CurrWnd:GetAnchorOffsets()
	local name = wndHandler:GetName()
	if name == "Left" then
		l = l+1
	elseif name == "Top" then
		t = t+1
	elseif name == "Bottom" then
		b = b+1
	else
		r = r+1
	end
	self.CurrWnd:SetAnchorOffsets(l,t,r,b)
	self:UpdateWindow()
end

function ChargeUI:OnDown( wndHandler, wndControl, eMouseButton )
	local l,t,r,b = self.CurrWnd:GetAnchorOffsets()
	local name = wndHandler:GetName()
	if name == "Left" then
		l = l-1
	elseif name == "Top" then
		t = t-1
	elseif name == "Bottom" then
		b = b-1
	else
		r = r-1
	end
	self.CurrWnd:SetAnchorOffsets(l,t,r,b)
	self:UpdateWindow()
end

function ChargeUI:UpdateWindow()
	local l,t,r,b
	if self.CurrWnd ~= nil then
		l,t,r,b = self.CurrWnd:GetAnchorOffsets()
	else
		l = 0
		t = 0
		r = 0
		b = 0
	end
	self.CustomiseWnd:FindChild("ELeft"):SetText(tostring(l))
	self.CustomiseWnd:FindChild("ERight"):SetText(tostring(r))
	self.CustomiseWnd:FindChild("ETop"):SetText(tostring(t))
	self.CustomiseWnd:FindChild("EBottom"):SetText(tostring(b))
end

function ChargeUI:EditBoxChanged( wndHandler, wndControl, strText )
	if strText ~= nil then
		local number = tonumber(strText)
		if tonumber ~= nil then
			local name = wndHandler:GetName()
			local l,t,r,b = self.CurrWnd:GetAnchorOffsets()
			
			if name == "ELeft" then
				l = number
			elseif name == "ERight" then
				r = number
			elseif name == "ETop" then
				t = number
			else
				b = number
			end
			self.CurrWnd:SetAnchorOffsets(l,t,r,b)
		end
	end
end


-----------------------------------------------------------------------------------------------
-- ChargeUI Instance
-----------------------------------------------------------------------------------------------
local ChargeUIInst = ChargeUI:new()
ChargeUIInst:Init()
