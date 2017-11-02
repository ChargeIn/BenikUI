-----------------------------------------------------------------------------------------------
-- Client Lua Script for BenikUI_PathFrame
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "AbilityBook"
require "GameLib"
require "PlayerPathLib"
require "Tooltip"
require "Unit"

-----------------------------------------------------------------------------------------------
-- BenikUI_PathFrame Module Definition
-----------------------------------------------------------------------------------------------
local BenikUI_PathFrame = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local knBottomPadding = 36 -- MUST MATCH XML
local knTopPadding = 36 -- MUST MATCH XML
local knPathLASIndex = 10

local knSaveVersion = 1

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function BenikUI_PathFrame:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

function BenikUI_PathFrame:Init()
    Apollo.RegisterAddon(self, nil, nil, {"BenikUI_ActionBar", "Abilities"})
end

-----------------------------------------------------------------------------------------------
-- BenikUI_PathFrame OnLoad
-----------------------------------------------------------------------------------------------
function BenikUI_PathFrame:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("BenikUI_PathFrame.xml")

	self.nSelectedPathId = nil
	self.bHasPathAbilities = false
	self.ActionBar = Apollo.GetAddon("BenikUI_ActionBar")
end

function BenikUI_PathFrame:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	local tSavedData =
	{
		nSelectedPathId = self.nSelectedPathId,
		nSaveVersion = knSaveVersion,
	}

	return tSavedData
end

function BenikUI_PathFrame:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character or not tSavedData or not tSavedData.nSaveVersion or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end

	if tSavedData.nSelectedPathId then
		self.nSelectedPathId = tSavedData.nSelectedPathId
	end
end

function BenikUI_PathFrame:GetAsyncLoadStatus()
	if not (self.xmlDoc and self.xmlDoc:IsLoaded()) then
		return Apollo.AddonLoadStatus.Loading
	end

	if not self.unitPlayer then
		self.unitPlayer = GameLib.GetPlayerUnit()
	end

	if not self.unitPlayer then
		return Apollo.AddonLoadStatus.Loading
	end

	if not Tooltip and Tooltip.GetSpellTooltipForm then
		return Apollo.AddonLoadStatus.Loading
	end
	
	if self.ActionBar.wndMain == nil then
		return Apollo.AddonLoadStatus.Loading
	end

	if self:OnAsyncLoad() then
		return Apollo.AddonLoadStatus.Loaded
	end

	return Apollo.AddonLoadStatus.Loading
end

function BenikUI_PathFrame:OnAsyncLoad()
	if not Apollo.GetAddon("BenikUI_ActionBar") or not Apollo.GetAddon("Abilities") then
		return
	end
	Apollo.RegisterEventHandler("ChangeWorld", 								"OnChangeWorld", self)
	Apollo.RegisterEventHandler("PlayerCreated", 							"DrawPathAbilityList", self)
	Apollo.RegisterEventHandler("CharacterCreated", 						"DrawPathAbilityList", self)
	Apollo.RegisterEventHandler("UpdatePathXp", 							"DrawPathAbilityList", self)
	Apollo.RegisterEventHandler("AbilityBookChange", 						"DrawPathAbilityList", self)
	Apollo.RegisterEventHandler("OptionsUpdated_HUDPreferences",			"DrawPathAbilityList", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 				"OnTutorial_RequestUIAnchor", self)

	Apollo.RegisterTimerHandler("RefreshPathTimer", 						"DrawPathAbilityList", self)
	--Load Forms
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "PathFrameForm", self.ActionBar.wndMain:FindChild("PathButton"), self)

	self.wndMenu = self.wndMain:FindChild("PathSelectionMenu")
	self.wndMenu:Show(false)

	if self.nSelectedPathId then
		local tAbilities = AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Path)
		local bIsValidPathId = false

		for idx, tAbility in pairs(tAbilities) do
			if tAbility.bIsActive then
				bIsValidPathId = bIsValidPathId or tAbility.nId == self.nSelectedPathId
			end
		end

		self.nSelectedPathId = bIsValidPathId and self.nSelectedPathId or nil
	end

	self:DrawPathAbilityList()
	return true
end

-----------------------------------------------------------------------------------------------
-- BenikUI_PathFrame Functions
-----------------------------------------------------------------------------------------------
function BenikUI_PathFrame:DrawPathAbilityList()
	if not self.unitPlayer then
		return
	end

	local tAbilities = AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Path)
	if not tAbilities then
		return
	end

	local wndList = self.wndMenu:FindChild("Content")
	wndList:DestroyChildren()

	local nSelectedIdNew = 0

	local nCount = 0
	local nListHeight = 0
	for _, tAbility in pairs(tAbilities) do
		if tAbility.bIsActive then
			local splCurr = tAbility.tTiers[tAbility.nCurrentTier].splObject
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "PathBtn", wndList, self)
			nCount = nCount + 1

			if tAbility.nId == self.nSelectedPathId then
				nSelectedIdNew = self.nSelectedPathId
			end

			if nSelectedIdNew == 0 then
				nSelectedIdNew = tAbility.nId
			end

			local nLeft, nTop, nRight, nBottom = wndCurr:GetAnchorOffsets()
			nListHeight = nListHeight + wndCurr:GetHeight()
			wndCurr:FindChild("PathBtnIcon"):SetSprite(splCurr:GetIcon())
			wndCurr:SetData(tAbility.nId)
			if Tooltip and Tooltip.GetSpellTooltipForm then
				wndCurr:SetTooltipDoc(nil)
				Tooltip.GetSpellTooltipForm(self, wndCurr, splCurr)
			end
		end
	end

	if nSelectedIdNew ~= 0 then
		self.nSelectedPathId = nSelectedIdNew
	end

	if self.nSelectedPathId ~= ActionSetLib.GetCurrentActionSet()[10] then
		self:HelperSetPathAbility(self.nSelectedPathId)
	end

	self.bHasPathAbilities = nCount > 0

	if self.bHasPathAbilities then
		--Toggle Visibility based on ui preference
		local unitPlayer = GameLib.GetPlayerUnit()
		local nVisibility = Apollo.GetConsoleVariable("hud.SkillsBarDisplay")

		if nVisibility == 2 then --always off
			self.wndMain:Show(false)
		elseif nVisibility == 3 then --on in combat
			self.wndMain:Show(unitPlayer:IsInCombat())
		elseif nVisibility == 4 then --on out of combat
			self.wndMain:Show(not unitPlayer:IsInCombat())
		else
			self.wndMain:Show(true)
		end
	else
		self.wndMain:Show(false)
	end

	local nHeight = wndList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nLeft, nTop, nRight, nBottom = self.wndMenu:GetAnchorOffsets()
	self.wndMenu:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
end

function BenikUI_PathFrame:HelperSetPathAbility(nAbilityId)
	local tActionSet = ActionSetLib.GetCurrentActionSet()
	if not tActionSet or not nAbilityId then
		return false
	end

	tActionSet[knPathLASIndex] = nAbilityId
	local tResult = ActionSetLib.RequestActionSetChanges(tActionSet)

	if tResult.eResult ~= ActionSetLib.CodeEnumLimitedActionSetResult.Ok then
		return false
	end


	Event_FireGenericEvent("PathAbilityUpdated", nAbilityId)
	self.nSelectedPathId = nAbilityId

	return true
end

function BenikUI_PathFrame:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors =
	{
		[GameLib.CodeEnumTutorialAnchor.PathAbility]	= true,
	}

	if not tAnchors[eAnchor] or not self.wndMain or not self.wndMain:IsVisible() then
		return
	end

	local tAnchorMapping =
	{
		[GameLib.CodeEnumTutorialAnchor.PathAbility] 	= self.wndMain,
	}

	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

-----------------------------------------------------------------------------------------------
-- PathFrameForm Functions
-----------------------------------------------------------------------------------------------
function BenikUI_PathFrame:OnGenerateTooltip(wndControl, wndHandler, eType, arg1, arg2)
	if eType ~= Tooltip.TooltipGenerateType_Spell then
		return
	end

	if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
		Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
	end
end


function BenikUI_PathFrame:OnPathBtn(wndControl, wndHandler)
	local result = self:HelperSetPathAbility(wndControl:GetData())

	self.nSelectedPathId = result and wndControl:GetData() or nil

	self.wndMenu:Show(false)
end

function BenikUI_PathFrame:OnCloseBtn()
	self.wndMenu:Show(false)
end

function BenikUI_PathFrame:OnChangeWorld()
	self.wndMenu:Show(false)
end


function BenikUI_PathFrame:OnPathButtonUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if eMouseButton == 1 then
		self.wndMenu:Show(not self.wndMenu:IsShown())
		self.wndMenu:ToFront()
	end
end

-----------------------------------------------------------------------------------------------
-- BenikUI_PathFrame Instance
-----------------------------------------------------------------------------------------------
local PathFrameInst = BenikUI_PathFrame:new()
PathFrameInst:Init()
