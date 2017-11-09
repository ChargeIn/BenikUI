-----------------------------------------------------------------------------------------------
-- Client Lua Script for BenikUI_NeedVsGreed
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"
 
-----------------------------------------------------------------------------------------------
-- BenikUI_NeedVsGreed Module Definition
-----------------------------------------------------------------------------------------------
local BenikUI_NeedVsGreed = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local ktEvalColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= ApolloColor.new("ItemQuality_Inferior"),
	[Item.CodeEnumItemQuality.Average] 			= ApolloColor.new("ItemQuality_Average"),
	[Item.CodeEnumItemQuality.Good] 			= ApolloColor.new("ItemQuality_Good"),
	[Item.CodeEnumItemQuality.Excellent] 		= ApolloColor.new("ItemQuality_Excellent"),
	[Item.CodeEnumItemQuality.Superb] 			= ApolloColor.new("ItemQuality_Superb"),
	[Item.CodeEnumItemQuality.Legendary] 		= ApolloColor.new("ItemQuality_Legendary"),
	[Item.CodeEnumItemQuality.Artifact]		 	= ApolloColor.new("ItemQuality_Artifact"),
}
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function BenikUI_NeedVsGreed:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function BenikUI_NeedVsGreed:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- BenikUI_NeedVsGreed OnLoad
-----------------------------------------------------------------------------------------------
function BenikUI_NeedVsGreed:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("BenikUI_NeedVsGreed.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- BenikUI_NeedVsGreed OnDocLoaded
-----------------------------------------------------------------------------------------------
function BenikUI_NeedVsGreed:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "NeedVsGreedForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		self.Options = Apollo.GetAddon("BenikUI")
		if self.Options == nil then
			Apollo.AddAddonErrorText(self, "Could not find main BanikUi Window.")
			return
		end
		--Register in Options
		self.Options:RegisterAddon("NeedVsGreed")
		
	    self.wndMain:Show(true, true)

		--Events
		Apollo.RegisterEventHandler("LootRollUpdate",		"OnGroupLoot", self)
	    Apollo.RegisterEventHandler("LootRollWon", 			"OnLootRollWon", self)
	    Apollo.RegisterEventHandler("LootRollAllPassed", 	"OnLootRollAllPassed", self)
		Apollo.RegisterTimerHandler("WinnerCheckTimer", 	"OnOneSecTimer", self)
		Apollo.RegisterEventHandler("LootRollSelected", 	"OnLootRollSelected", self)
		Apollo.RegisterEventHandler("LootRollPassed", 		"OnLootRollPassed", self)
		Apollo.RegisterEventHandler("LootRoll", 			"OnLootRoll", self)
		
		--Form
		Apollo.CreateTimer("WinnerCheckTimer", 1.0, false)
		Apollo.StopTimer("WinnerCheckTimer")
		--Loading
		if GameLib.GetLootRolls() then
			self:OnGroupLoot()
		end
		self:SetWindows()
	end
end

function BenikUI_NeedVsGreed:SetWindows()
	local l,t,r,b = unpack(self.Options.db.profile.NeedVsGreed.Anchor)
	self.wndMain:SetAnchorOffsets(l,t,r,b)
end

function BenikUI_NeedVsGreed:SetTheme()
end

function BenikUI_NeedVsGreed:LoadOptions(wnd)
	self.wndMain:SetSprite("")
	self.wndMain:SetStyle("Moveable",false)
	
	local MainGrid = wnd:FindChild("MainGrid")
	local OptList = wnd:FindChild("OptionsList")

	self.wndOption = Apollo.LoadForm(self.xmlDoc, "OptionsFrame", MainGrid,self)
	
	--Filling Options
	for i,j in pairs(self.Options.db.profile.NeedVsGreed) do
		local next = self.wndOption:FindChild(i)
		if next ~= nil then
			next:SetCheck(j)
		end
	end
	--Set up ilvl
	local bar = self.wndOption:FindChild("Scale_Ilvl"):FindChild("SliderBar")
	bar:SetMinMax(1, 170, 1)
	bar:SetValue(self.Options.db.profile.NeedVsGreed.Ilvl)
	self.wndOption:FindChild("Scale_Ilvl"):FindChild("EditBox"):SetText(tostring(self.Options.db.profile.NeedVsGreed.Ilvl))
end

function BenikUI_NeedVsGreed:OnGroupLoot()
	self.tLootRolls = GameLib.GetLootRolls()
	if not self.tLootRolls or #self.tLootRolls <= 0 then
		self.tLootRolls = nil
		return
	end
	Sound.Play(Sound.PlayUIWindowNeedVsGreedOpen)
	local Grid = self.wndMain:FindChild("Grid")
	Grid:DestroyChildren()
	
	local Options = self.Options.db.profile.NeedVsGreed
	
	--Check Loot for Auto Greed and rules
	for idx, tCurrentElement in pairs(self.tLootRolls) do
				
		--Non needable
		if Options.bNonNeedable and not GameLib.IsNeedRollAllowed(tCurrentElement.nLootId) then
			GameLib.RollOnLoot(tCurrentElement.nLootId, false)
			self.tLootRolls[idx] = nil
		end
		
		--No Dyes
		if Options.bDyes then
			local type = tCurrentElement.itemDrop:GetItemCategoryName()
			if type == "Dyes" then
				local details = tCurrentElement.itemDrop:GetDetailedInfo()["tPrimary"]
				if details["arUnlocks"]~= nil and details["arUnlocks"][1]["bUnlocked"] then
					GameLib.PassOnLoot(tCurrentElement.nLootId)
					self.tLootRolls[idx] = nil
				end
			end
		end
		
		--No Signs of X
		if Options.bSign then
			local name = tCurrentElement.itemDrop:GetName()
			local a,b,c = unpack(self:Split(name," "))
			if a == "Sign" and b == "of" and c~= "Fusion" then
				GameLib.PassOnLoot(tCurrentElement.nLootId)
				self.tLootRolls[idx] = nil
			end
		end
		--No Tailor stuff
		if Options.bSurvivalist then
			local type = tCurrentElement.itemDrop:GetItemCategoryName()
			if type == "Survivalist" then
				GameLib.PassOnLoot(tCurrentElement.nLootId)
				self.tLootRolls[idx] = nil
			end
		end
		--Gear under ilvl ....
		if bAutoGreed then
			local type = tCurrentElement.itemDrop:GetItemFamilyName()
			local item = tCurrentElement.itemDrop
			local Ilvl = Options.Ilvl
			if type == "Gear" or type == "Armor" or type == "Weapon" then
				local details = item:GetDetailedInfo()["tPrimary"]
				local ilvl = details["nItemLevel"]
				if ilvl <= Ilvl and details["arSpells"] ~= nil then
					GameLib.RollOnLoot(tCurrentElement.nLootId, false)
					self.tLootRolls[idx] = nil
				end
			end
		end
	end
	
	
	
	--Add Loot to Grid
	for idx, tCurrentElement in pairs(self.tLootRolls) do
		local itemCurrent = tCurrentElement.itemDrop
		local itemModData = tCurrentElement.tModData
		local tGlyphData = tCurrentElement.tSigilData
		local newItem = Apollo.LoadForm(self.xmlDoc, "ListItem", Grid, self)
		newItem:SetName(tostring(tCurrentElement.nLootId))
		newItem:SetData(tCurrentElement.nLootId)
		newItem:FindChild("Icon"):SetSprite(itemCurrent:GetIcon())
		newItem:FindChild("Icon"):SetData(itemCurrent)
		newItem:FindChild("Name"):SetText(itemCurrent:GetName())
		newItem:FindChild("Name"):SetTextColor(ktEvalColors[itemCurrent:GetItemQuality()])
		local itemEquipped = itemCurrent:GetEquippedItemForItemType()
		local nTimeLeft = math.floor(tCurrentElement.nTimeLeft / 1000)
		local nTimeLeftSecs = nTimeLeft % 60
		local nTimeLeftMins = math.floor(nTimeLeft / 60)

		local strTimeLeft = tostring(nTimeLeftMins)
		if nTimeLeft < 0 then
			strTimeLeft = "0:00"
		elseif nTimeLeftSecs < 10 then
			strTimeLeft = strTimeLeft .. ":0" .. tostring(nTimeLeftSecs)
		else
			strTimeLeft = strTimeLeft .. ":" .. tostring(nTimeLeftSecs)
		end
		newItem:FindChild("Timer"):SetText(strTimeLeft)
		Tooltip.GetItemTooltipForm(self, newItem:FindChild("Icon"), itemCurrent, {bPrimary = true, bSelling = false, itemCompare = itemEquipped, itemModData = itemModData, tGlyphData = tGlyphData})
	end
	Grid:ArrangeChildrenVert()
	Apollo.StartTimer("WinnerCheckTimer")
end

function BenikUI_NeedVsGreed:OnOneSecTimer()
	self.tLootRolls = GameLib.GetLootRolls()
	if self.tLootRolls == nil then 
		return
	end
	local Grid = self.wndMain:FindChild("Grid")
	for idx, tCurrentElement in pairs(self.tLootRolls) do
		local newItem = Grid:FindChild(tostring(tCurrentElement.nLootId))
		if newItem ~= nil then
			local nTimeLeft = math.floor(tCurrentElement.nTimeLeft / 1000)
			local nTimeLeftSecs = nTimeLeft % 60
			local nTimeLeftMins = math.floor(nTimeLeft / 60)
	
			local strTimeLeft = tostring(nTimeLeftMins)
			if nTimeLeft < 0 then
				strTimeLeft = "0:00"
			elseif nTimeLeftSecs < 10 then
				strTimeLeft = strTimeLeft .. ":0" .. tostring(nTimeLeftSecs)
			else
				strTimeLeft = strTimeLeft .. ":" .. tostring(nTimeLeftSecs)
			end
			newItem:FindChild("Timer"):SetText(strTimeLeft)
		end
	end

	if self.tLootRolls and #self.tLootRolls > 0 then
		Apollo.StartTimer("WinnerCheckTimer")
	else
		self.bTimerRunning = false
	end
end

-----------------------------------------------------------------------------------------------
-- Chat Message Events
-----------------------------------------------------------------------------------------------

function BenikUI_NeedVsGreed:OnLootRollAllPassed(tLootInfo)
	local strResult = String_GetWeaselString(Apollo.GetString("NeedVsGreed_EveryonePassed"), tLootInfo.itemLoot:GetChatLinkString())
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", strResult)
end

function BenikUI_NeedVsGreed:OnLootRollWon(tLootInfo)
	local strNeedOrGreed = nil
	if tLootInfo.bNeed then
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_NeedRoll")
	else
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_GreedRoll")
	end
	
	local strItem = tLootInfo.itemLoot:GetChatLinkString()
	local nCount = tLootInfo.itemLoot:GetStackCount()
	if nCount > 1 then
		strItem = String_GetWeaselString(Apollo.GetString("CombatLog_MultiItem"), nCount, strItem)
	end
	
	local strResult = String_GetWeaselString(Apollo.GetString("NeedVsGreed_ItemWon"), tLootInfo.strPlayer, strItem, strNeedOrGreed)
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", strResult)
end

function BenikUI_NeedVsGreed:OnLootRollSelected(tLootInfo)
	local strNeedOrGreed = nil
	if tLootInfo.bNeed then
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_NeedRoll")
	else
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_GreedRoll")
	end

	local strResult = String_GetWeaselString(Apollo.GetString("NeedVsGreed_LootRollSelected"), tLootInfo.strPlayer, strNeedOrGreed, tLootInfo.itemLoot:GetChatLinkString())
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", strResult)
end

function BenikUI_NeedVsGreed:OnLootRollPassed(tLootInfo)
	local strResult = String_GetWeaselString(Apollo.GetString("NeedVsGreed_PlayerPassed"), tLootInfo.strPlayer, tLootInfo.itemLoot:GetChatLinkString())
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", strResult)
end

function BenikUI_NeedVsGreed:OnLootRoll(tLootInfo)
	local strNeedOrGreed = nil
	if tLootInfo.bNeed then
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_NeedRoll")
	else
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_GreedRoll")
	end

	local strResult = String_GetWeaselString(Apollo.GetString("NeedVsGreed_OnLootRoll"), tLootInfo.strPlayer, tLootInfo.nRoll, tLootInfo.itemLoot:GetChatLinkString(), strNeedOrGreed)
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", strResult)
end

---------------------------------------------------------------------------------------------------
-- ListItem Functions
---------------------------------------------------------------------------------------------------

function BenikUI_NeedVsGreed:OnGiantItemIconMouseUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and wndHandler:GetData() then
		Event_FireGenericEvent("GenericEvent_ContextMenuItem", wndHandler:GetData())
	end
end

function BenikUI_NeedVsGreed:OnNeedBtn( wndHandler, wndControl, eMouseButton )
	GameLib.RollOnLoot(wndControl:GetParent():GetData(), true)
	wndControl:GetParent():Destroy()
	self.wndMain:FindChild("Grid"):ArrangeChildrenVert()
end

function BenikUI_NeedVsGreed:OnGreedBtn( wndHandler, wndControl, eMouseButton )
	GameLib.RollOnLoot(wndControl:GetParent():GetData(), false)
	wndControl:GetParent():Destroy()
	self.wndMain:FindChild("Grid"):ArrangeChildrenVert()
end

function BenikUI_NeedVsGreed:OnPassBtn( wndHandler, wndControl, eMouseButton )
		GameLib.PassOnLoot(wndControl:GetParent():GetData())
		wndControl:GetParent():Destroy()
		self.wndMain:FindChild("Grid"):ArrangeChildrenVert()
end

--thanks to Johan Lindström (Jabbit-EU, Joxye Nadrax / Wildstar) for the Split Function
-- Compatibility: Lua-5.1
function BenikUI_NeedVsGreed:Split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

--to lazy to rename :^)
function BenikUI_NeedVsGreed:OnShowModel(wndHandler)
	local name = wndHandler:GetName()
	self.Options.db.profile.NeedVsGreed[name] = wndHandler:IsChecked()
end

function BenikUI_NeedVsGreed:OnWindowMoved( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	local l,t,r,b = wndControl:GetAnchorOffsets()
	self.Options.db.profile.NeedVsGreed.Anchor = {l,t,r,b}
end

function BenikUI_NeedVsGreed:OnColumnsSlideChange( wndHandler, wndControl, fNewValue, fOldValue )
	self.Options.db.profile.NeedVsGreed.Ilvl = fNewValue
	wndControl:GetParent():FindChild("EditBox"):SetText(tostring(math.floor(fNewValue)))
end

function BenikUI_NeedVsGreed:OnShowMain( wndHandler, wndControl, eMouseButton )
	local text = wndControl:GetText()
	if text ==  "Show" then
		self.wndMain:SetSprite("AbilitiesSprites:spr_StatVertProgBase")
		self.wndMain:SetStyle("Moveable",true)
		wndHandler:SetText("Hide")
	else
		self.wndMain:SetSprite("")
		self.wndMain:SetStyle("Moveable",false)
		wndHandler:SetText("Show")
	end
end

-----------------------------------------------------------------------------------------------
-- BenikUI_NeedVsGreed Instance
-----------------------------------------------------------------------------------------------
local BenikUI_NeedVsGreedInst = BenikUI_NeedVsGreed:new()
BenikUI_NeedVsGreedInst:Init()
