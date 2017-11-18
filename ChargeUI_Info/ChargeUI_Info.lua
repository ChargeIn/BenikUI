-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChargeUI_Info
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "Apollo"
require "PlayerPathLib"

-----------------------------------------------------------------------------------------------
-- ChargeUI_Info Module Definition
-----------------------------------------------------------------------------------------------
local ChargeUI_Info = {}

local tPathIcons = {
		[PlayerPathLib.PlayerPathType_Explorer] = "CRB_MinimapSprites:sprMM_SmallIconExplorer",
		[PlayerPathLib.PlayerPathType_Scientist] = "CRB_MinimapSprites:sprMM_SmallIconScientist",
		[PlayerPathLib.PlayerPathType_Settler] = "CRB_MinimapSprites:sprMM_SmallIconSettler",
		[PlayerPathLib.PlayerPathType_Soldier] = "CRB_MinimapSprites:sprMM_SmallIconSoldier",
	}
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ChargeUI_Info:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here

    return o
end

function ChargeUI_Info:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


-----------------------------------------------------------------------------------------------
-- ChargeUI_Info OnLoad
-----------------------------------------------------------------------------------------------
function ChargeUI_Info:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("ChargeUI_Info.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- ChargeUI_Info OnDocLoaded
-----------------------------------------------------------------------------------------------
function ChargeUI_Info:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ChargeUI_InfoForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		Apollo.LoadSprites("NewSprite.xml")
	    self.wndMain:Show(true, true)
		self.Options = Apollo.GetAddon("ChargeUI")
		if self.Options == nil then
			Apollo.AddAddonErrorText(self, "Could not find main BanikUi Window.")
			return
		end
		--Register in Options
		self.Options:RegisterAddon("Info")
		--Events
		Apollo.RegisterEventHandler("NextFrame","OnFrame",self)

		--Timer
		self.UpdateTimer = ApolloTimer.Create(1, true, "OnTimer", self)

		self:LoadWindow()
		-- Var
	end
end

function ChargeUI_Info:SetTheme()
end

function ChargeUI_Info:LoadOptions(wnd)
	local MainGrid = wnd:FindChild("MainGrid")
	local OptList = wnd:FindChild("OptionsList")
	self.wndOption = Apollo.LoadForm(self.xmlDoc, "OptionsFrame", MainGrid,self)
	local Grid = self.wndOption:FindChild("Grid")
	--Loading Grid
	for i,j in pairs(self.Options.db.profile.Info) do
		local newOpt = Apollo.LoadForm(self.xmlDoc, "OptionItem", Grid,self)
		newOpt:SetText(i)
		newOpt:SetCheck(j)
	end
	Grid:ArrangeChildrenVert()
end

local  round =  function(num, idp)
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end

-----------------------------------------------------------------------------------------------
-- ChargeUI_Info Functions
-----------------------------------------------------------------------------------------------
function ChargeUI_Info:LoadWindow()
	local Options = self.Options.db.profile.Info
	local MainGrid = self.wndMain:FindChild("MainGrid")
	MainGrid:DestroyChildren()
	self.List = {}
	--FPS
	if Options.FPS then
		local FPS = Apollo.LoadForm(self.xmlDoc, "ListItem", MainGrid, self)
		FPS:FindChild("Text"):SetText("FPS: ")
		FPS:FindChild("Icon"):SetSprite("")
		local fps = round(GameLib.GetFrameRate(), 1)
		FPS:FindChild("Progress"):SetText(tostring(fps))
		if fps < 20 then
			FPS:FindChild("Progress"):SetTextColor("BrightRed")
		elseif fps < 50 then
			FPS:FindChild("Progress"):SetTextColor("AttributeName")
		else
			FPS:FindChild("Progress"):SetTextColor("AddonOk")
		end
		self.List["FPS"] = {
			wnd = FPS,
			Update = function(wnd)
				local fps = round(GameLib.GetFrameRate(), 1)
				wnd:FindChild("Progress"):SetText(tostring(fps))
				if fps < 20 then
					wnd:FindChild("Progress"):SetTextColor("BrightRed")
				elseif fps < 50 then
					wnd:FindChild("Progress"):SetTextColor("AttributeName")
				else
					wnd:FindChild("Progress"):SetTextColor("AddonOk")
				end
			end,
		}
	end

	--Latency
	if Options.Latency then
		local Ping = Apollo.LoadForm(self.xmlDoc, "ListItem", MainGrid, self)
		Ping:FindChild("Text"):SetText("Ping: ")
		Ping:FindChild("Icon"):SetSprite("")
		local PingTime = GameLib.GetPingTime()
		Ping:FindChild("Progress"):SetText(PingTime.." ms")
		if PingTime < 40 then
			Ping:FindChild("Progress"):SetTextColor("AddonOk")
		elseif PingTime < 100 then
			Ping:FindChild("Progress"):SetTextColor("AttributeName")
		else
			Ping:FindChild("Progress"):SetTextColor("BrightRed")
		end
		self.List["Ping"] = {
			wnd = Ping,
			Update = function(wnd)
				local Ping = GameLib.GetPingTime()
				wnd:FindChild("Progress"):SetText(Ping.." ms")
				if Ping < 40 then
					wnd:FindChild("Progress"):SetTextColor("AddonOk")
				elseif Ping < 100 then
					wnd:FindChild("Progress"):SetTextColor("AttributeName")
				else
					wnd:FindChild("Progress"):SetTextColor("BrightRed")
				end
			end,
		}
	end

	--Essences
	if Options.Essences then
		local Number_of_Currencies = 14
		for i = 11, Number_of_Currencies, 1 do
			if i ~= 8 then -- 8 = Gold
				local Currency = GameLib.GetPlayerCurrency(i)
				local info =  Currency:GetDenomInfo()[1]
				local NewCurrency = Apollo.LoadForm(self.xmlDoc, "ListItem", MainGrid, self)
				NewCurrency:FindChild("Text"):SetText("")
				NewCurrency:FindChild("Icon"):SetSprite(info.strSprite)
				NewCurrency:SetTooltip(info.strName)
				local nACurrency = GameLib.GetPlayerCurrency(i)
				local amount = nACurrency:GetAmount()
					NewCurrency:FindChild("Progress"):SetText(tostring(amount))
				if amount < 4000 then
					NewCurrency:FindChild("Progress"):SetTextColor("BrightRed")
				elseif amount < 7000 then
					NewCurrency:FindChild("Progress"):SetTextColor("AttributeName")
				else
					NewCurrency:FindChild("Progress"):SetTextColor("AddonOk")
				end
				self.List[info.strName] = {
					wnd = NewCurrency,
					Update = function(wnd)
						local nACurrency = GameLib.GetPlayerCurrency(i)
						local amount = nACurrency:GetAmount()
						wnd:FindChild("Progress"):SetText(tostring(amount))
						if amount < 4000 then
							wnd:FindChild("Progress"):SetTextColor("BrightRed")
						elseif amount < 7000 then
							wnd:FindChild("Progress"):SetTextColor("AttributeName")
						else
							wnd:FindChild("Progress"):SetTextColor("AddonOk")
						end
					end
				}
			end
		end
	end

	--XP
	if Options.XP then
		local EXP =	 Apollo.LoadForm(self.xmlDoc, "ListItem", MainGrid, self)
		EXP:FindChild("Text"):SetText("XP:")
		EXP:FindChild("Icon"):SetSprite("")
		local lvl = GameLib.GetPlayerLevel()
		local text
		local nLvl				= GameLib.GetPlayerLevel()
		local nXpTotal			= GetXp()
		local nXpPercent		= GetXpPercentToNextLevel()
		local nXpMax			= GetXpToNextLevel()
		local nXpToCurrentLvl	= GetXpToCurrentLevel()
		local nXp				= (nXpTotal - nXpToCurrentLvl)
		-- Also do kills to level
		if nLvl == 50 then
			EXP:FindChild("Progress"):SetText("Max")
		else
			text = round(nXpPercent, 2).."%"
			EXP:FindChild("Progress"):SetText(text)
		end
		self.List["EXP"] = {
			wnd = EXP,
			Update = function(wnd)
				local lvl = GameLib.GetPlayerLevel()
				local text
				local nLvl				= GameLib.GetPlayerLevel()
				local nXpTotal			= GetXp()
				local nXpPercent		= GetXpPercentToNextLevel()
				local nXpMax			= GetXpToNextLevel()
				local nXpToCurrentLvl	= GetXpToCurrentLevel()
				local nXp				= (nXpTotal - nXpToCurrentLvl)
				-- Also do kills to level
				if nLvl == 50 then
					wnd:FindChild("Progress"):SetText("Max")
				else
					text = round(nXpPercent, 2).."%"
					wnd:FindChild("Progress"):SetText(text)
				end
			end
		}
	end

	--Path
	if Options.PathXP then
		local EXP =	 Apollo.LoadForm(self.xmlDoc, "ListItem", MainGrid, self)
		EXP:FindChild("Text"):SetText("")
		EXP:FindChild("Icon"):SetSprite(tPathIcons[PlayerPathLib.GetPlayerPathType()])
		local lvl = PlayerPathLib.GetPathLevel()
		local text
		local nLvl				= PlayerPathLib.GetPathLevel() or 0
		local nXpMax			= PlayerPathLib.GetPathXPAtLevel(PlayerPathLib.GetPathLevel()) or 0
		local nXp				= PlayerPathLib.GetPathXP() or 0
		-- Also do kills to level
		if nLvl == 30 then
			EXP:FindChild("Progress"):SetText("Max")
		else
			text = round(nXp/nXpMax, 2).."%"
			EXP:FindChild("Progress"):SetText(text)
		end
		self.List["PEXP"] = {
			wnd = EXP,
			Update = function(wnd)
				local lvl = PlayerPathLib.GetPathLevel()
				local text
				local nLvl				= PlayerPathLib.GetPathLevel() or 0
				local nXpMax			= PlayerPathLib.GetPathXPAtLevel(PlayerPathLib.GetPathLevel()) or 0
				local nXp				= PlayerPathLib.GetPathXP() or 0
				-- Also do kills to level
				if nLvl == 30 then
					wnd:FindChild("Progress"):SetText("Max")
				else
					text = round(nXp/nXpMax, 2).."%"
					wnd:FindChild("Progress"):SetText(text)
				end
			end
		}
	end

	--Character Currencies (Essences Extra to save memory)
	for i = 2, 14, 1 do -- only 10 since Exxences are 11-14
		if i ~= 8 then -- 8 = Gold
			local Currency = GameLib.GetPlayerCurrency(i)
			local info =  Currency:GetDenomInfo()[1]
			if Options[info.strName] then
				local wnd = Apollo.LoadForm(self.xmlDoc, "CashWindowSmall", MainGrid, self)
				wnd:SetTooltip(info.strName)
	 			wnd:SetAmount(GameLib.GetPlayerCurrency(i),true)
				self.List[info.strName] = {
					wnd = wnd,
					Update = function(wnd)
						wnd:SetAmount(GameLib.GetPlayerCurrency(i),true)
					end
				}
			end
		end
	end

	--Account Currencies
	for i = 1, 14, 1 do
		if i ~=10 and i ~= 4 then
			local ACurrency = AccountItemLib.GetAccountCurrency(i)
			local AInfo =  ACurrency:GetDenomInfo()[1]
			if Options[AInfo.strName] then
				local wnd = Apollo.LoadForm(self.xmlDoc, "CashWindowSmall", MainGrid, self)
				wnd:SetTooltip(AInfo.strName)
	 			wnd:SetAmount(AccountItemLib.GetAccountCurrency(i))
				self.List[AInfo.strName] = {
					wnd = wnd,
					Update = function(wnd)
						wnd:SetAmount(AccountItemLib.GetAccountCurrency(i))
					end
				}
			end
		end
	end

	--Platin
	if Options.Platin then
		local Platin = Apollo.LoadForm(self.xmlDoc, "CashWindow", MainGrid, self)
		Platin:SetTooltip("Platin")
	 	Platin:SetAmount(GameLib.GetPlayerCurrency(),true)
		self.List["Platin"] = {
			wnd = Platin,
			Update = function(wnd)
				wnd:SetAmount(GameLib.GetPlayerCurrency(),true)
			end,
		}
	end

	MainGrid:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function ChargeUI_Info:OptionChanged( wndHandler, wndControl, eMouseButton )
	local name = wndControl:GetText()
	self.Options.db.profile.Info[name] = wndControl:IsChecked()
	self:LoadWindow()
end

function ChargeUI_Info:OnTimer()
	for i,j in pairs(self.List) do
		j.Update(j.wnd,j.Text)
	end
end
-----------------------------------------------------------------------------------------------
-- ChargeUI_InfoForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function ChargeUI_Info:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function ChargeUI_Info:OnCancel()
	self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- ChargeUI_Info Instance
-----------------------------------------------------------------------------------------------
local ChargeUI_InfoInst = ChargeUI_Info:new()
ChargeUI_InfoInst:Init()
