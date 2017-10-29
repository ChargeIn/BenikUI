-----------------------------------------------------------------------------------------------
-- Client Lua Script for BenikUI
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"

-----------------------------------------------------------------------------------------------
-- BenikUI Module
-----------------------------------------------------------------------------------------------
--[[
This modul contain all the savedata form the other addons
	Every Modul contains following functions for updating:
	SetWindows() -- Calls the the last saved window offset for the calling module and applies them
	SetTheme() -- Updates the main theme color
	LoadOptions(Wndow) -- Load the OptionsMenu in the give Window
]]
-----------------------------------------------------------------------------------------------
-- BenikUI Module Definition
-----------------------------------------------------------------------------------------------
local BenikUI = {} 


--Default Option
local tBenikUIDefaults = {
	char = {
		currentProfile = nil,
	},
	profile = {
		general = {
			ThemeColor = "xkcdOrange",
		},
		Unitframes = {
			--nText = 2,
			UnitFrame = 		{-467,-327,-109,-223},
			AltTargetFrame = 	{-165,-432, 193,-328},
			TargetFrame =		{ 109,-327, 467,-223},
			Player = 			{
				HealthText =		"white",
				fullHealth = 		"black",
				halfHealth = 		"black",
				lowHealth = 		"red",
				HealthClamp = 		"white",
				HealingAbsorb = 	"xkcdLipstickRed",
				Moo = 				"xkcdDarkMagenta",
				Shield =			"xkcdOrange",
				Focus = 			"xkcdOrange",
				Armor = 			"xkcdOrange",
				},
			Target = 			{
				HealthText =		"white",
				fullHealth = 		"black",
				halfHealth = 		"black",
				lowHealth = 		"red",
				HealthClamp = 		"white",
				HealingAbsorb = 	"xkcdLipstickRed",
				Moo = 				"xkcdDarkMagenta",
				Shield =			"xkcdOrange",
				Focus = 			"xkcdOrange",
				Armor = 			"xkcdOrange",
				},
			Focus = 			{
				HealthText =		"white",
				fullHealth = 		"black",
				halfHealth = 		"black",
				lowHealth = 		"red",
				HealthClamp = 		"white",
				HealingAbsorb = 	"xkcdLipstickRed",
				Moo = 				"xkcdDarkMagenta",
				Shield =			"xkcdOrange",
				Focus = 			"xkcdOrange",
				Armor = 			"xkcdOrange",
				},	
			ToT = 			{
				HealthText =		"white",
				fullHealth = 		"black",
				halfHealth = 		"black",
				lowHealth = 		"red",
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
function BenikUI:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function BenikUI:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- BenikUI OnLoad
-----------------------------------------------------------------------------------------------
function BenikUI:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("BenikUI.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, tBenikUIDefaults)
end

-----------------------------------------------------------------------------------------------
-- BenikUI OnDocLoaded
-----------------------------------------------------------------------------------------------
function BenikUI:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "BenikUIForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		local GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
	  	self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
		self.colorPicker:Show(false,true)
	    self.wndMain:Show(false, true)

		--Commands
		Apollo.RegisterSlashCommand("BenikUI","ShowOptions",self)
		Apollo.RegisterSlashCommand("BUI","ShowOptions",self)
		
		--Var
		self.RegAddons ={}
		self.CurrAddon = nil
	end
end

-----------------------------------------------------------------------------------------------
-- BenikUI Functions
-----------------------------------------------------------------------------------------------
function BenikUI:RegisterAddon(Name)
	table.insert(self.RegAddons,Name)
end

function BenikUI:OnListItemClick( wndHandler, wndControl, eMouseButton )
	local Name = wndControl:GetText()
	local MainGrid = self.wndMain:FindChild("MainGrid")
	MainGrid:DestroyChildren()
	
	if Name == "Thanks" then
		Apollo.LoadForm(self.xmlDoc,"ThanksOption", MainGrid, self)
	else
		self.CurrAddon = Apollo.GetAddon("BenikUI_"..Name)	
		
		if self.CurrAddon ~= nil then
			self.CurrAddon:LoadOptions(self.wndMain)
		else
			MainGrid:SetText("Could not load "..Name.."-Options")
		end
	end
end


-----------------------------------------------------------------------------------------------
-- BenikUIForm Functions
-----------------------------------------------------------------------------------------------
function BenikUI:ShowOptions()
	local oList = self.wndMain:FindChild("OptionsList")
	oList:DestroyChildren()
	for i,j in pairs(self.RegAddons) do
		local newOption = Apollo.LoadForm(self.xmlDoc,"ListItem", oList, self)
		newOption:SetText(j)
	end
	--Thanks
	local newOption = Apollo.LoadForm(self.xmlDoc,"ListItem", oList, self)
	newOption:SetText("Thanks")
	
	oList:ArrangeChildrenVert()
	self.wndMain:FindChild("MainGrid"):SetText("")
	self.wndMain:Invoke()
end

-- when the Cancel button is clicked
function BenikUI:OnCancel()
	self.wndMain:Close() -- hide the window
end

function BenikUI:OnHomePress( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("OptionsList"):DestroyChildren()
	self.wndMain:FindChild("MainGrid"):DestroyChildren()
	self:ShowOptions()
end


-----------------------------------------------------------------------------------------------
-- BenikUI Instance
-----------------------------------------------------------------------------------------------
local BenikUIInst = BenikUI:new()
BenikUIInst:Init()
