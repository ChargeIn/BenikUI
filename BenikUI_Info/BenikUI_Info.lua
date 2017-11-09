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
		
		--Timer
		self.UpdateTimer = ApolloTimer.Create(1, true, "OnTimer", self)

		self:LoadWindow()
		-- Var
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
	MainGrid:DestroyChildren()
	self.List = {}
	--FPS
	local FPS = Apollo.LoadForm(self.xmlDoc, "ListItem", MainGrid, self)
	FPS:FindChild("ProgressBar"):SetMax(70)
	FPS:FindChild("Text"):SetText("FPS: ")
	FPS:FindChild("Icon"):SetSprite("")
	self.List["FPS"] = {
		wnd = FPS,
		Update = function(wnd)
			local fps = round(GameLib.GetFrameRate(), 1)
			wnd:FindChild("Progress"):SetText(tostring(fps))
			wnd:FindChild("ProgressBar"):SetProgress(fps)
			if fps < 20 then
				wnd:FindChild("Progress"):SetTextColor("BrightRed")
				wnd:FindChild("ProgressBar"):SetBarColor("BrightRed")
			elseif fps < 50 then
				wnd:FindChild("Progress"):SetTextColor("AttributeName")
				wnd:FindChild("ProgressBar"):SetBarColor("AttributeName")
			else
				wnd:FindChild("Progress"):SetTextColor("AddonOk")
				wnd:FindChild("ProgressBar"):SetBarColor("AddonOk")
			end
		end,
	}
	
	--Essences
	local Number_of_Currencies = 14
	for i = 11, Number_of_Currencies, 1 do
		if i ~= 8 then -- 8 = Gold 
			local Currency = GameLib.GetPlayerCurrency(i)
			local info =  Currency:GetDenomInfo()[1]
			local NewCurrency = Apollo.LoadForm(self.xmlDoc, "ListItem", MainGrid, self)
			NewCurrency:FindChild("Text"):SetText("")
			NewCurrency:FindChild("Icon"):SetSprite(info.strSprite)
			NewCurrency:FindChild("ProgressBar"):SetMax(10000)
			self.List[info.strName] = {
				wnd = NewCurrency,
				Update = function(wnd)
					local nACurrency = GameLib.GetPlayerCurrency(i)
					local amount = nACurrency:GetAmount()
					wnd:FindChild("Progress"):SetText(tostring(amount))
					wnd:FindChild("ProgressBar"):SetProgress(amount)
					if amount < 2500 then
						wnd:FindChild("Progress"):SetTextColor("BrightRed")
						wnd:FindChild("ProgressBar"):SetBarColor("BrightRed")
					elseif amount < 5000 then
						wnd:FindChild("Progress"):SetTextColor("AttributeName")
						wnd:FindChild("ProgressBar"):SetBarColor("AttributeName")
					else
						wnd:FindChild("Progress"):SetTextColor("AddonOk")
						wnd:FindChild("ProgressBar"):SetBarColor("AddonOk")
					end
				end
			}
		end
	end
	MainGrid:ArrangeChildrenHorz()
end

function BenikUI_Info:OnTimer()
	for i,j in pairs(self.List) do
		j.Update(j.wnd,j.Text)
	end
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
