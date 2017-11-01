-----------------------------------------------------------------------------------------------
-- Client Lua Script for BenikUI_Info
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
require "Apollo"
 
-----------------------------------------------------------------------------------------------
-- BenikUI_Info Module Definition
-----------------------------------------------------------------------------------------------
local BenikUI_Info = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function BenikUI_Info:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function BenikUI_Info:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- BenikUI_Info OnLoad
-----------------------------------------------------------------------------------------------
function BenikUI_Info:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("BenikUI_Info.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- BenikUI_Info OnDocLoaded
-----------------------------------------------------------------------------------------------
function BenikUI_Info:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "BenikUI_InfoForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		Apollo.LoadSprites("NewSprite.xml")
	    self.wndMain:Show(true, true)
	
		--Events
		Apollo.RegisterEventHandler("NextFrame","OnFrame",self)


		self:LoadWindow()
		-- Do additional Addon initialization here
	end
end

local  round =  function(num, idp)
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end

-----------------------------------------------------------------------------------------------
-- BenikUI_Info Functions
-----------------------------------------------------------------------------------------------
function BenikUI_Info:LoadWindow()
	local MainGrid = self.wndMain:FindChild("MainGrid")

	--[[FPS
	dt = {
		["type"]		= "dataFeed",
		["strLabel"]	= "FPS: ",
		["crLabel"]		= ApolloColor.new("UI_TextHoloBody"),
		["crText"]		= ApolloColor.new("white"),
		["imgIcon"]		= "CRB_Basekit:kitIcon_Holo_HazardProximity",
		["OnUpdate"]	= function()

			--what about tooltip?
			--and ops menu? <- put that in a diff part

			local text = round(GameLib.GetFrameRate(), 1)
			
			local crText = "ff00ff00" --green
			if text <= 59 then
				crText = "ffffff00" --yellow
			elseif text <= 25 then
				crText = "ffff0000" --red
			end
			self.DataTexts.FPS.crText = crText
			
			return text			
		end
	}]]
	local fps = Apollo.LoadForm(self.xmlDoc, "ListItem", MainGrid, self)
	fps:FindChild("Text"):SetText("FPS: "..tostring(round(GameLib.GetFrameRate(), 1)))
	fps:FindChild("ProgressBar"):SetMax(200)
	fps:FindChild("ProgressBar"):SetProgress(round(GameLib.GetFrameRate(), 1))
end

function BenikUI_Info:OnFrame()
	local fps = self.wndMain:FindChild("ListItem")
	fps:FindChild("Text"):SetText("FPS: "..tostring(round(GameLib.GetFrameRate(), 1)))
	fps:FindChild("ProgressBar"):SetMax(200)
	fps:FindChild("ProgressBar"):SetProgress(round(GameLib.GetFrameRate(), 1))
end
-----------------------------------------------------------------------------------------------
-- BenikUI_InfoForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function BenikUI_Info:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function BenikUI_Info:OnCancel()
	self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- BenikUI_Info Instance
-----------------------------------------------------------------------------------------------
local BenikUI_InfoInst = BenikUI_Info:new()
BenikUI_InfoInst:Init()
