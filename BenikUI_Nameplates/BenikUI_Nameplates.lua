-----------------------------------------------------------------------------------------------
-- Client Lua Script for BenikUI_Nameplates
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "ChallengesLib"
require "Unit"
require "GameLib"
require "Apollo"
require "PathMission"
require "Quest"
require "Episode"
require "math"
require "string"
require "DialogSys"
require "PublicEvent"
require "PublicEventObjective"
require "CommunicatorLib"
require "GroupLib"
require "PlayerPathLib"
require "GuildLib"
require "GuildTypeLib"
require "AccountItemLib"
require "MatchingGameLib"

local BenikUI_Nameplates = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local karDisposition =
{
	tTextColors =
	{
		[Unit.CodeEnumDisposition.Hostile] 	= ApolloColor.new("DispositionHostile"),
		[Unit.CodeEnumDisposition.Neutral] 	= ApolloColor.new("DispositionNeutral"),
		[Unit.CodeEnumDisposition.Friendly] = ApolloColor.new("DispositionFriendly"),
	},

	tTargetPrimary =
	{
		[Unit.CodeEnumDisposition.Hostile] 	= "CRB_Nameplates:sprNP_BaseSelectedRed",
		[Unit.CodeEnumDisposition.Neutral] 	= "CRB_Nameplates:sprNP_BaseSelectedYellow",
		[Unit.CodeEnumDisposition.Friendly] = "CRB_Nameplates:sprNP_BaseSelectedGreen",
	},

	tTargetSecondary =
	{
		[Unit.CodeEnumDisposition.Hostile] 	= "sprNp_Target_HostileSecondary",
		[Unit.CodeEnumDisposition.Neutral] 	= "sprNp_Target_NeutralSecondary",
		[Unit.CodeEnumDisposition.Friendly] = "sprNp_Target_FriendlySecondary",
	},

	tHealthBar =
	{
		[Unit.CodeEnumDisposition.Hostile] 	= "CRB_Nameplates:sprNP_RedProg",
		[Unit.CodeEnumDisposition.Neutral] 	= "CRB_Nameplates:sprNP_YellowProg",
		[Unit.CodeEnumDisposition.Friendly] = "CRB_Nameplates:sprNP_GreenProg",
	},

	tHealthTextColor =
	{
		[Unit.CodeEnumDisposition.Hostile] 	= "ffff8585",
		[Unit.CodeEnumDisposition.Neutral] 	= "ffffdb57",
		[Unit.CodeEnumDisposition.Friendly] = "ff9bff80",
	},
}

local knHealthRed = 0.3
local knHealthYellow = 0.5

local knConMin = -4
local knConMax = 4
local karConColors =  -- differential value, color
{
	[-4] = ApolloColor.new("ConTrivial"),
	[-3] = ApolloColor.new("ConInferior"),
	[-2] = ApolloColor.new("ConMinor"),
	[-1] = ApolloColor.new("ConEasy"),
	[0] = ApolloColor.new("ConAverage"),
	[1] = ApolloColor.new("ConModerate"),
	[2] = ApolloColor.new("ConTough"),
	[3] = ApolloColor.new("ConHard"),
	[4] = ApolloColor.new("ConImpossible"),
}

local kcrScalingHex 	= "ffffbf80"
local kcrScalingCColor 	= CColor.new(1.0, 191/255, 128/255, 0.7)

local ksprHighLevel = "CRB_Nameplates:sprNP_HighLevel"
local ksprPvpTarget = "IconSprites:Icon_Windows_UI_CRB_Marker_Crosshair"

local karPathSprite =
{
	[PlayerPathLib.PlayerPathType_Soldier] 		= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSol",
	[PlayerPathLib.PlayerPathType_Settler] 		= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSet",
	[PlayerPathLib.PlayerPathType_Scientist] 	= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathSci",
	[PlayerPathLib.PlayerPathType_Explorer] 	= "CRB_TargetFrameRewardPanelSprites:sprTargetFrame_PathExp",
}

local knCharacterWidth 		= 8 -- the average width of a character in the font used. TODO: Not this.
local knRewardWidth 		= 23 -- the width of a reward icon + padding
local knTextHeight 			= 15 -- text window height
local knNameRewardWidth 	= 400 -- the width of the name/reward container
local knNameRewardHeight 	= 20 -- the width of the name/reward container
local knTargetRange 		= 40000 -- the distance^2 that normal nameplates should draw within (max targeting range)
local knNameplatePoolLimit	= 100 -- the window pool max size

-- Todo: break these out onto options
local kcrUnflaggedGroupmate				= ApolloColor.new("DispositionFriendlyUnflaggedDull")
local kcrUnflaggedGuildmate				= ApolloColor.new("DispositionGuildmateUnflagged")
local kcrUnflaggedAlly					= ApolloColor.new("DispositionFriendlyUnflagged")
local kcrFlaggedAlly					= ApolloColor.new("DispositionFriendly")
local kcrUnflaggedEnemyWhenUnflagged 	= ApolloColor.new("DispositionNeutral")
local kcrFlaggedEnemyWhenUnflagged		= ApolloColor.new("DispositionPvPFlagMismatch")
local kcrUnflaggedEnemyWhenFlagged		= ApolloColor.new("DispositionPvPFlagMismatch")
local kcrFlaggedEnemyWhenFlagged		= ApolloColor.new("DispositionHostile")
local kcrDeadColor 						= ApolloColor.new("DeathGrey")

local kcrDefaultTaggedColor = ApolloColor.new("DeathGrey")

-- Control types
-- 0 - custom
-- 1 - single check

local karSavedProperties =
{
	--General nameplate drawing
	["bShowMainObjectiveOnly"] = { default=true, nControlType=1, strControlName="MainShowObjectives" },
	["bShowMainGroupOnly"] = { default=true, nControlType=1, strControlName="MainShowGroup" },
	["bShowMyNameplate"] = { default=false, nControlType=1, strControlName="MainShowMine" },
	["bShowOrganization"] = { default=true, nControlType=1, strControlName="MainShowOrganization" },
	["bShowVendor"] = { default=true, nControlType=1, strControlName="MainShowVendors" },
	["bShowTaxi"] = { default=true, nControlType=1, strControlName="MainShowTaxis" },
	["bShowDispositionHostile"] = { default=true, nControlType=1, strControlName="MainShowDisposition_1" },
	["bShowDispositionNeutral"] = { default=false, nControlType=1, strControlName="MainShowDisposition_2" },
	["bShowDispositionFriendly"] = { default=false, nControlType=1, strControlName="MainShowDisposition_3" },
	["bShowDispositionFriendlyPlayer"] = { default=true, nControlType=1, strControlName="MainShowDisposition_FriendlyPlayer" },
	--Draw distance
	["nMaxRange"] = { default=70.0, nControlType=0 },
	["nMaxRangeSq"] = { default=4900.0, nControlType=0 }, -- Just a square of nMaxRange, no controls here
	--Individual
	["bShowNameMain"] = { default=true, nControlType=1, strControlName="IndividualShowName", fnCallback="OnSettingNameChanged" },
	["bShowTitle"] = { default=true, nControlType=1, strControlName="IndividualShowAffiliation", fnCallback="OnSettingTitleChanged" },
	["bShowCertainDeathMain"] = { default=true, nControlType=1, strControlName="IndividualShowCertainDeath" },
	["bShowCastBarMain"] = { default=false, nControlType=1, strControlName="IndividualShowCastBar" },
	["bShowRewardsMain"] = { default=true, nControlType=1, strControlName="IndividualShowRewardIcons", fnCallback="RequestUpdateAllNameplateRewards" },
	["bShowDuringSpeech"] = { default=true, nControlType=1, strControlName="IndividualShowDuringSpeech" },
	--Reward icons
	["bShowRewardTypeQuest"] = { default=true, nControlType=1, strControlName="ShowRewardTypeQuest", fnCallback="RequestUpdateAllNameplateRewards" },
	["bShowRewardTypeMission"] = { default=true, nControlType=1, strControlName="ShowRewardTypeMission", fnCallback="RequestUpdateAllNameplateRewards" },
	["bShowRewardTypeAchievement"] = { default=false, nControlType=1, strControlName="ShowRewardTypeAchievement", fnCallback="RequestUpdateAllNameplateRewards" },
	["bShowRewardTypeChallenge"] = { default=true, nControlType=1, strControlName="ShowRewardTypeChallenge", fnCallback="RequestUpdateAllNameplateRewards" },
	["bShowRewardTypeReputation"] = { default=false, nControlType=1, strControlName="ShowRewardTypeReputation", fnCallback="RequestUpdateAllNameplateRewards" },
	["bShowRewardTypePublicEvent"] = { default=true, nControlType=1, strControlName="ShowRewardTypePublicEvent", fnCallback="RequestUpdateAllNameplateRewards" },
	["bShowRivals"] = { default=true, nControlType=1, strControlName="ShowRewardTypeRival", fnCallback="RequestUpdateAllNameplateRewards" },
	["bShowFriends"] = { default=true, nControlType=1, strControlName="ShowRewardTypeFriend", fnCallback="RequestUpdateAllNameplateRewards" },
	--Info panel
	["bShowHealthMain"] = { default=false, nControlType=0, fnCallback="OnSettingHealthChanged" },
	["bShowHealthMainDamaged"] = { default=true, nControlType=0, fnCallback="OnSettingHealthChanged" },
	--target components
	["bShowMarkerTarget"] = { default=true, nControlType=1, strControlName="TargetedShowMarker" },
	["bShowNameTarget"] = { default=true, nControlType=1, strControlName="TargetedShowName", fnCallback="OnSettingNameChanged" },
	["bShowRewardsTarget"] = { default=true, nControlType=1, strControlName="TargetedShowRewards"},
	["bShowGuildNameTarget"] = { default=true, nControlType=1, strControlName="TargetedShowGuild", fnCallback="OnSettingTitleChanged" },
	["bShowHealthTarget"] = { default=true, nControlType=1, strControlName="TargetedShowHealth", fnCallback="OnSettingHealthChanged" },
	["bShowRangeTarget"] = { default=false, nControlType=0 },
	["bShowCastBarTarget"] = { default=true, nControlType=1, strControlName="TargetedShowCastBar" },
	--Non-targeted nameplates in combat
	["bHideInCombat"] = { default=false, nControlType=0 }
}

local ktVIPIcons =
{
	[1] = "CRB_CN:CRB_CN_VIP1_D",
	[2] = "CRB_CN:CRB_CN_VIP2_D",
	[3] = "CRB_CN:CRB_CN_VIP3_D",
	[4] = "CRB_CN:CRB_CN_VIP4_D",
	[5] = "CRB_CN:CRB_CN_VIP5_D",
	[6] = "CRB_CN:CRB_CN_VIP6_D",
	[7] = "CRB_CN:CRB_CN_VIP7_D",
	[8] = "CRB_CN:CRB_CN_VIP8_D",
	[9] = "CRB_CN:CRB_CN_VIP9_D",
	[10] = "CRB_CN:CRB_CN_VIP10_D",
}

-----------------------------------------------------------------------------------------------
-- Local function reference declarations
-----------------------------------------------------------------------------------------------
local fnDrawHealth
local fnDrawRewards
local fnDrawCastBar
local fnDrawVulnerable
local fnColorNameplate
local fnDrawTargeting

function BenikUI_Nameplates:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.arPreloadUnits = {}
	o.bAddonRestoredOrLoaded = false

	o.arWindowPool = {}
	o.arUnit2Nameplate = {}
	o.arWnd2Nameplate = {}

	o.bPlayerInCombat = false
	o.guildDisplayed = nil
	o.guildWarParty = nil
	o.bRedrawRewardIcons = false

    return o
end

function BenikUI_Nameplates:Init()
    Apollo.RegisterAddon(self, true, "BenikUI_Nameplates", {"Tooltips", "RewardIcons"})
end

function BenikUI_Nameplates:OnDependencyError(strDependency, strError)
	return true
end

-----------------------------------------------------------------------------------------------
-- BenikUI_Nameplates OnLoad
-----------------------------------------------------------------------------------------------

function BenikUI_Nameplates:OnLoad()
	Apollo.RegisterEventHandler("UnitCreated", 					"OnPreloadUnitCreated", self)

	self.xmlDoc = XmlDoc.CreateFromFile("BenikUI_Nameplates.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function BenikUI_Nameplates:OnPreloadUnitCreated(unitNew)
	self.arPreloadUnits[#self.arPreloadUnits + 1] = unitNew
end

function BenikUI_Nameplates:OnDocumentReady()
	Apollo.RemoveEventHandler("UnitCreated", self)

	if self.xmlDoc == nil then
		return
	end
	self.Options = Apollo.GetAddon("BenikUI")
	if self.Options == nil then
		Apollo.AddAddonErrorText(self, "Could not find main BanikUi Window.")
		return
	end
	--Register in Options
	self.Options:RegisterAddon("Nameplates")
	--Color Picker
	GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
	self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
	self.colorPicker:Show(false, true)
	
	
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("UnitCreated", 					"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 				"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("NextFrame", 					"OnFrame", self)

	Apollo.RegisterEventHandler("UnitTextBubbleCreate", 		"OnUnitTextBubbleToggled", self)
	Apollo.RegisterEventHandler("UnitTextBubblesDestroyed", 	"OnUnitTextBubbleToggled", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", 			"OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnEnteredCombat", self)
	Apollo.RegisterEventHandler("UnitNameChanged", 				"OnUnitNameChanged", self)
	Apollo.RegisterEventHandler("UnitGuildNameplateChanged", 	"OnUnitGuildNameplateChanged",self)
	Apollo.RegisterEventHandler("UnitLevelChanged", 			"OnUnitLevelChanged", self)
	Apollo.RegisterEventHandler("UnitMemberOfGuildChange", 		"OnUnitMemberOfGuildChange", self)
	Apollo.RegisterEventHandler("GuildChange", 					"OnGuildChange", self)
	Apollo.RegisterEventHandler("UnitGibbed",					"OnUnitGibbed", self)

	local tRewardUpdateEvents = {
		"QuestObjectiveUpdated", "QuestStateChanged", "ChallengeAbandon", "ChallengeLeftArea",
		"ChallengeFailTime", "ChallengeFailArea", "ChallengeActivate", "ChallengeCompleted",
		"ChallengeFailGeneric", "PublicEventObjectiveUpdate", "PublicEventUnitUpdate",
		"PlayerPathMissionUpdate", "FriendshipAdd", "FriendshipPostRemove", "FriendshipUpdate",
		"PlayerPathRefresh", "ContractObjectiveUpdated", "ContractStateChanged", "ChallengeUpdated"
	}

	for i, str in pairs(tRewardUpdateEvents) do
		Apollo.RegisterEventHandler(str, "RequestUpdateAllNameplateRewards", self)
	end

	Apollo.RegisterTimerHandler("VisibilityTimer", "OnVisibilityTimer", self)
	Apollo.CreateTimer("VisibilityTimer", 0.5, true)

	self.arUnit2Nameplate = {}
	self.arWnd2Nameplate = {}

	for property,tData in pairs(karSavedProperties) do
		if self[property] == nil then
			self[property] = tData.default
		end
	end
	self.bUseOcclusion = Apollo.GetConsoleVariable("ui.occludeNameplatePositions")

	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		local eGuildType = guildCurr:GetType()
		if eGuildType == GuildLib.GuildType_Guild then
			self.guildDisplayed = guildCurr
		end
		if eGuildType == GuildLib.GuildType_WarParty then
			self.guildWarParty = guildCurr
		end
	end

	-- Cache defaults
	local wndTemp = Apollo.LoadForm(self.xmlDoc, "NameplateNew", nil, self)
	self.nFrameLeft, self.nFrameTop, self.nFrameRight, self.nFrameBottom = wndTemp:FindChild("Container:Health:HealthBars:Health"):GetAnchorOffsets()
	self.nHealthWidth = self.nFrameRight - self.nFrameLeft
	wndTemp:Destroy()

	self:CreateUnitsFromPreload()
end

function BenikUI_Nameplates:SetTheme()
end

function BenikUI_Nameplates:LoadOptions(wnd)
	local MainGrid = wnd:FindChild("MainGrid")
	local OptList = wnd:FindChild("OptionsList")
	local general = Apollo.LoadForm(self.xmlDoc,"GeneralModule", MainGrid, self)
	
	--Setting Options
	for i,j in pairs(self.Options.db.profile.Nameplates) do
		if i ~= "friendly" and i~= "hostile" then
			general:FindChild(i):FindChild("Swatch"):SetBGColor(j)
		else
			general:FindChild(i):SetCheck(j)
		end
	end
end



		


function BenikUI_Nameplates:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	local tSave = {}
	for property,tData in pairs(karSavedProperties) do
		tSave[property] = self[property]
	end

	return tSave
end

function BenikUI_Nameplates:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	for property,tData in pairs(karSavedProperties) do
		if tSavedData[property] ~= nil then
			self[property] = tSavedData[property]
		end
	end

	self:CreateUnitsFromPreload()
end

function BenikUI_Nameplates:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("Nameplates_Options")})
end

function BenikUI_Nameplates:CreateUnitsFromPreload()
	if self.bAddonRestoredOrLoaded then
		self.unitPlayer = GameLib.GetPlayerUnit()

		-- Process units created while form was loading
		self.timerPreloadUnitCreateDelay = ApolloTimer.Create(0.5, true, "OnPreloadUnitCreateTimer", self)
		self:OnPreloadUnitCreateTimer()
	end
	self.bAddonRestoredOrLoaded = true
end

function BenikUI_Nameplates:OnPreloadUnitCreateTimer()
	local nCurrentTime = GameLib.GetTickCount()

	while #self.arPreloadUnits > 0 do
		local unit = table.remove(self.arPreloadUnits, #self.arPreloadUnits)
		if unit:IsValid() then
			self:OnUnitCreated(unit)
		end

		if GameLib.GetTickCount() - nCurrentTime > 250 then
			return
		end
	end

	self.timerPreloadUnitCreateDelay:Stop()
	self.arPreloadUnits = nil
	self.timerPreloadUnitCreateDelay = nil
end

function BenikUI_Nameplates:OnVisibilityTimer()
	self:UpdateAllNameplateVisibility()
end

function BenikUI_Nameplates:RequestUpdateAllNameplateRewards()
	self.bRedrawRewardIcons = true
end

function BenikUI_Nameplates:UpdateNameplateRewardInfo(tNameplate)
	local tFlags =
	{
		bVert = false,
		bHideQuests = not self.bShowRewardTypeQuest,
		bHideChallenges = not self.bShowRewardTypeChallenge,
		bHideMissions = not self.bShowRewardTypeMission,
		bHidePublicEvents = not self.bShowRewardTypePublicEvent,
		bHideRivals = not self.bShowRivals,
		bHideFriends = not self.bShowFriends
	}

	if RewardIcons ~= nil and RewardIcons.GetUnitRewardIconsForm ~= nil then
		RewardIcons.GetUnitRewardIconsForm(tNameplate.wnd.questRewards, tNameplate.unitOwner, tFlags)
	end
end

function BenikUI_Nameplates:UpdateAllNameplateVisibility()

	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:UpdateNameplateVisibility(tNameplate)
	end

	self.bRedrawRewardIcons = false
end

function BenikUI_Nameplates:UpdateNameplateVisibility(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local wndNameplate = tNameplate.wndNameplate

	local eDisposition = unitOwner:GetDispositionTo(self.unitPlayer)
	local nCon = self:HelperCalculateConValue(unitOwner)

	tNameplate.bOnScreen = wndNameplate:IsOnScreen()
	tNameplate.bOccluded = wndNameplate:IsOccluded()
	tNameplate.tActivation = unitOwner:GetActivationState()
	tNameplate.tRewardInfo = unitOwner:GetRewardInfo()
	--Top or Bot
	local bReposition = false
		if  unitOwner ~= self.unitPlayer then
			local locUnitOverhead = unitOwner:GetOverheadAnchor()
			if locUnitOverhead ~= nil then
				bReposition = not tNameplate.bOccluded and locUnitOverhead.y < 45
			end
		end
	wndNameplate:SetUnit(unitOwner, bReposition and 0 or 1)

	local bNewShow = self:HelperVerifyVisibilityOptions(tNameplate) and self:CheckDrawDistance(tNameplate)
	if bNewShow ~= tNameplate.bShow then
		wndNameplate:Show(bNewShow)
		tNameplate.bShow = bNewShow
	end

	if bNewShow or self.bRedrawRewardIcons or tNameplate.eDisposition ~= eDisposition then
		-- Disposition based update
		if eDisposition ~= tNameplate.eDisposition then
			tNameplate.wnd.targetMarkerArrow:SetSprite(karDisposition.tTargetSecondary[tNameplate.eDisposition])
		end

		-- Handle Certain Death icon
		local bShowCertainDeath = self.bShowCertainDeathMain -- Display if user preference is to display
			and tNameplate.eDisposition ~= Unit.CodeEnumDisposition.Friendly -- Display for hostile/neutral units
			and (tNameplate.bShowPvpMatch or unitOwner:IsCertainDeath()) -- Always show in PVP, or if Certain Death
			and unitOwner:ShouldShowNamePlate() -- Display if unit flagged to display
			and unitOwner:GetHealth() -- Display if unit has health value
			and not unitOwner:IsDead() -- Display if unit is not dead

		-- Only show/hide certain death icon if the state has changed
		if bShowCertainDeath ~= tNameplate.wnd.certainDeath:IsShown() then
			tNameplate.wnd.certainDeath:Show(bShowCertainDeath)
		end

		-- Does not need to update every frame
		local bShowScaled = unitOwner:IsScaled()
		if bShowScaled ~= tNameplate.wnd.targetScalingMark:IsShown() then
			tNameplate.wnd.targetScalingMark:Show(bShowScaled)
		end

		fnColorNameplate(self, tNameplate)

		fnDrawHealth(self, tNameplate)
		fnDrawTargeting(self, tNameplate)

		fnDrawRewards(self, tNameplate)
	end

	tNameplate.eDisposition = eDisposition
	tNameplate.nCon = nCon
end

function BenikUI_Nameplates:OnUnitCreated(unitNew) -- build main options here
	if unitNew == nil
		or not unitNew:IsValid()
		or not unitNew:ShouldShowNamePlate()
		or unitNew:GetType() == "Collectible"
		or unitNew:GetType() == "PinataLoot" then
		-- Never have nameplates
		return
	end

	local idUnit = unitNew:GetId()
	if self.arUnit2Nameplate[idUnit] ~= nil and self.arUnit2Nameplate[idUnit].wndNameplate:IsValid() then
		return
	end

	local wnd = nil
	local wndReferences = nil
	if next(self.arWindowPool) ~= nil then
		local poolEntry = table.remove(self.arWindowPool)
		wnd = poolEntry[1]
		wndReferences = poolEntry[2]
	end

	if wnd == nil or not wnd:IsValid() then
		wnd = Apollo.LoadForm(self.xmlDoc, "NameplateNew", "InWorldHudStratum", self)
		wndReferences = nil
	end

	wnd:Show(false, true)
	wnd:SetUnit(unitNew, 1)

	local strNewUnitType = unitNew:GetType()
	local uMatchMakingEntry = MatchingGameLib.GetQueueEntry()
	local tNameplate =
	{
		unitOwner 		= unitNew,
		idUnit 			= idUnit,
		wndNameplate	= wnd,
		bOnScreen 		= wnd:IsOnScreen(),
		bOccluded 		= wnd:IsOccluded(),
		bSpeechBubble 	= false,
		bIsTarget 		= GameLib.GetTargetUnit() == unitNew,
		bIsCluster 		= false,
		bIsCasting 		= false,
		bGibbed			= false,
		bIsPlayer		= strNewUnitType == "Player",
		bShowPvpMatch	= uMatchMakingEntry and uMatchMakingEntry:IsPvpGame() and (strNewUnitType == "Player" or strNewUnitType == "Esper Pet" or strNewUnitType == "Pet"),
		bIsGuildMember 	= self.guildDisplayed and self.guildDisplayed:IsUnitMember(unitNew) or false,
		bIsWarPartyMember = self.guildWarParty and self.guildWarParty:IsUnitMember(unitNew) or false,
		nVulnerableTime = 0,
		nCon			= self:HelperCalculateConValue(unitOwner),
		eDisposition	= unitNew:GetDispositionTo(self.unitPlayer),
		strUnitType		= strNewUnitType,
		tActivation		= unitNew:GetActivationState(),
		tRewardInfo		= unitNew:GetRewardInfo(),
		bShow			= false,
		wnd				= wndReferences,
		-- Window visibility
		bShowHealth		= true,
	}
	

	if wndReferences == nil then
		tNameplate.wnd =
		{
			health = wnd:FindChild("Container:Health"),
			castBar = wnd:FindChild("Container:CastBar"),
			vulnerable = wnd:FindChild("Container:Vulnerable"),
			level = wnd:FindChild("Level"),
			wndGuild = wnd:FindChild("Guild"),
			wndName = wnd:FindChild("NameRewardContainer:Name"),
			certainDeath = wnd:FindChild("TargetAndDeathContainer:CertainDeath"),
			targetScalingMark = wnd:FindChild("TargetScalingMark"),
			nameRewardContainer = wnd:FindChild("NameRewardContainer:RewardContainer"),
			healthHealthLabel = wnd:FindChild("Container:Health:HealthLabel"),
			castBarLabel = wnd:FindChild("Container:CastBar:Label"),
			castBarCastFill = wnd:FindChild("Container:CastBar:CastFill"),
			vulnerableVulnFill = wnd:FindChild("Container:Vulnerable:VulnFill"),
			questRewards = wnd:FindChild("NameRewardContainer:RewardContainer:QuestRewards"),
			targetMarkerArrow = wnd:FindChild("TargetAndDeathContainer:TargetMarkerArrow"),

			healthBar = wnd:FindChild("Container:Health:HealthBars:Health"),
			healingAbsorbBar = wnd:FindChild("Container:Health:HealthBars:HealingAbsorb"),
			absorbBar = wnd:FindChild("Container:Health:HealthBars:Absorb"),
			shieldBar = wnd:FindChild("Container:Health:HealthBars:Shield"),
			healthClampMin = wnd:FindChild("Container:Health:HealthBars:HealthClampMin"),
			healthClampMax = wnd:FindChild("Container:Health:HealthBars:HealthClampMax"),
		}
		tNameplate.wnd.shieldBar:SetBarColor(self.Options.db.profile.Nameplates.Shield)
	end
	

	if tNameplate.bShowPvpMatch then
		tNameplate.wnd.certainDeath:SetSprite(ksprPvpTarget)
	else
		tNameplate.wnd.certainDeath:SetSprite(ksprHighLevel)
	end

	self.arUnit2Nameplate[idUnit] = tNameplate
	self.arWnd2Nameplate[wnd:GetId()] = tNameplate

	self:UpdateNameplateRewardInfo(tNameplate)
	self:DrawName(tNameplate)
	self:DrawGuild(tNameplate)
	self:DrawLevel(tNameplate)
	self:DrawRewards(tNameplate)
	self:DrawTargeting(tNameplate)
	self:DrawHealth(tNameplate)
	

end

function BenikUI_Nameplates:OnUnitDestroyed(unitOwner)
	local idUnit = unitOwner:GetId()
	if self.arUnit2Nameplate[idUnit] == nil then
		return
	end

	local tNameplate = self.arUnit2Nameplate[idUnit]
	local wndNameplate = tNameplate.wndNameplate

	self.arWnd2Nameplate[wndNameplate:GetId()] = nil
	if #self.arWindowPool < knNameplatePoolLimit then
		wndNameplate:Show(false, true)
		wndNameplate:SetUnit(nil)
		table.insert(self.arWindowPool, {wndNameplate, tNameplate.wnd})
	else
		wndNameplate:Destroy()
	end
	self.arUnit2Nameplate[idUnit] = nil
end

function BenikUI_Nameplates:OnFrame()
	self.unitPlayer = GameLib.GetPlayerUnit()

	local fnHealth = BenikUI_Nameplates.DrawHealthShieldBar

	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		if tNameplate.bShow then
			if tNameplate.bShowHealth then
				fnHealth(self, tNameplate.wnd.health, tNameplate.unitOwner, tNameplate.eDisposition, tNameplate)
			end
			fnDrawVulnerable(self, tNameplate)
			fnDrawCastBar(self, tNameplate)
			
		end
	end
end

function BenikUI_Nameplates:ColorNameplate(tNameplate) -- Every frame
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner
	local wndNameplate = tNameplate.wndNameplate

	local eDisposition = tNameplate.eDisposition
	local nCon = tNameplate.nCon

	local crLevelColorToUse = karConColors[nCon]
	if tNameplate.wnd.targetScalingMark:IsShown() then
		crLevelColorToUse = kcrScalingCColor
	elseif unitOwner:GetLevel() == nil then
		crLevelColorToUse = karConColors[knConMin]
	end

	local crColorToUse = karDisposition.tTextColors[eDisposition]
	local unitController = unitOwner:GetUnitOwner() or unitOwner
	local strUnitType = unitOwner:GetType()

	if tNameplate.bIsPlayer or strUnitType == "Pet" or strUnitType == "Esper Pet" then
		if eDisposition == Unit.CodeEnumDisposition.Friendly or unitOwner:IsThePlayer() then
			crColorToUse = kcrUnflaggedAlly
			if unitController:IsPvpFlagged() then
				crColorToUse = kcrFlaggedAlly
			elseif unitController:IsInYourGroup() then
				crColorToUse = kcrUnflaggedGroupmate
			elseif tNameplate.bIsGuildMember then
				crColorToUse = kcrUnflaggedGuildmate
			end
		else
			local bIsUnitFlagged = unitController:IsPvpFlagged()
			local bAmIFlagged = GameLib.IsPvpFlagged()

			if not bAmIFlagged and not bIsUnitFlagged then
				crColorToUse = kcrUnflaggedEnemyWhenUnflagged
			elseif bAmIFlagged and not bIsUnitFlagged then
				crColorToUse = kcrUnflaggedEnemyWhenFlagged
			elseif not bAmIFlagged and bIsUnitFlagged then
				crColorToUse = kcrFlaggedEnemyWhenUnflagged
			elseif bAmIFlagged and bIsUnitFlagged then
				crColorToUse = kcrFlaggedEnemyWhenFlagged
			end
		end
	end

	if unitOwner:GetType() ~= "Player" and unitOwner:IsTagged() and not unitOwner:IsTaggedByMe() and not unitOwner:IsSoftKill() then
		crColorToUse = kcrDefaultTaggedColor
	end

	if unitOwner:IsDead() then
		crColorToUse = kcrDeadColor
		crLevelColorToUse = kcrDeadColor
	end

	tNameplate.wnd.level:SetTextColor(crLevelColorToUse)
	tNameplate.wnd.wndName:SetTextColor(crColorToUse)
	tNameplate.wnd.wndGuild:SetTextColor(crColorToUse)
end

function BenikUI_Nameplates:DrawName(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner
	local wndName = tNameplate.wnd.wndName
	local bUseTarget = tNameplate.bIsTarget
	local bShow = self.bShowNameMain
	if bUseTarget then
		bShow = self.bShowNameTarget
	end

	local bVisibilityChange = wndName:IsShown() ~= bShow
	if bVisibilityChange then
		wndName:Show(bShow)
	end

	local nPreviousHalfWidth = tNameplate.nBiggestHalf
	if bShow then
		local strNewName
		strNewName = unitOwner:GetName()

		if tNameplate.strName ~= strNewName then
			wndName:SetText(strNewName)
			tNameplate.strName = strNewName

		end
	end
end

function BenikUI_Nameplates:DrawGuild(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local wndGuild = tNameplate.wnd.wndGuild
	local bUseTarget = tNameplate.bIsTarget
	local bShow = self.bShowTitle
	if bUseTarget then
		bShow = self.bShowGuildNameTarget
	end

	local strNewGuild = unitOwner:GetAffiliationName()

	if bShow and strNewGuild ~= wndGuild:GetText() then
		wndGuild:SetTextRaw(strNewGuild)

		-- Need to consider name as well for the resize code
		local strNewName = unitOwner:GetName()
	end

	wndGuild:Show(bShow and strNewGuild ~= nil and strNewGuild ~= "")
	wndNameplate:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.RightOrBottom) -- Must be run if bShow is false as well
end

function BenikUI_Nameplates:DrawLevel(tNameplate)
	local unitOwner = tNameplate.unitOwner

	tNameplate.wnd.level:SetText(unitOwner:GetLevel() or "-")
end

function BenikUI_Nameplates:DrawHealth(tNameplate)
	local unitOwner = tNameplate.unitOwner

	local bShow = unitOwner:GetHealth() ~= nil and not unitOwner:IsDead()
	
	if bShow then
		local bUseTarget = tNameplate.bIsTarget
		if bUseTarget then
			bShow = self.bShowHealthTarget
		else
			if self.bShowHealthMain then
				bShow = true
			elseif self.bShowHealthMainDamaged then
				bShow = unitOwner:GetHealth() ~= unitOwner:GetMaxHealth()
			else
				bShow = false
			end
		end
	end
	
	--Vendors and Quests---------
	if tNameplate.tActivation.Vendor ~= nil then
		bShow = false
	end
	if tNameplate.tActivation.QuestNewMain ~= nil 
	or	tNameplate.tActivation.QuestReward ~= nil
	or	tNameplate.tActivation.QuestReceiving ~= nil
	or	tNameplate.tActivation.TalkTo ~= nil
	then
		bShow = false
	end
	
	if tNameplate.eDisposition == Unit.CodeEnumDisposition.Friendly and not tNameplate.bIsPlayer then
		bShow = false
	end
	--Friendly 
	if tNameplate.eDisposition == Unit.CodeEnumDisposition.Friendly and self.Options.db.profile.Nameplates.friendly then
		bShow = false
	end
	
	--Hostile
	--Friendly 
	if tNameplate.eDisposition == Unit.CodeEnumDisposition.Hostile and self.Options.db.profile.Nameplates.hostile then
		bShow = false
	end
	-------------------
	if bShow ~= tNameplate.wnd.health:IsShown() then
		tNameplate.wnd.health:Show(bShow)
		tNameplate.bShowHealth = bShow
	end
	
end

function BenikUI_Nameplates:DrawCastBar(tNameplate) -- Every frame
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	-- Casting; has some onDraw parameters we need to check
	tNameplate.bIsCasting = unitOwner:ShouldShowCastBar()

	local bShowTarget = tNameplate.bIsTarget

	local bShow = tNameplate.bIsCasting and self.bShowCastBarMain
	if tNameplate.bIsCasting and bShowTarget then
		bShow = self.bShowCastBarTarget
	end

	local wndCastBar = tNameplate.wnd.castBar
	if bShow ~= wndCastBar:IsShown() then
		wndCastBar:Show(bShow)
	end

	if bShow then
		local strCastName = unitOwner:GetCastName()
		if strCastName ~= tNameplate.strCastName then
			tNameplate.wnd.castBarLabel:SetText(strCastName)
			tNameplate.strCastName = strCastName
		end

		local nCastDuration = unitOwner:GetCastDuration()
		if nCastDuration ~= tNameplate.nCastDuration then
			tNameplate.wnd.castBarCastFill:SetMax(nCastDuration)
			tNameplate.nCastDuration = nCastDuration
		end

		local nCastElapsed = unitOwner:GetCastElapsed()
		if nCastElapsed ~= tNameplate.nCastElapsed then
			tNameplate.wnd.castBarCastFill:SetProgress(nCastElapsed)
			tNameplate.nCastElapsed = nCastElapsed
		end
	end
end

function BenikUI_Nameplates:DrawVulnerable(tNameplate) -- Every frame
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local bUseTarget = tNameplate.bIsTarget
	local wndVulnerable = tNameplate.wnd.vulnerable
	local bShow = false

	local nNewVulnerabilityTime = tNameplate.nVulnerabilityTime

	if (not bUseTarget and (self.bShowHealthMain or self.bShowHealthMainDamaged)) or (bUseTarget and self.bShowHealthTarget) then
		local nVulnerable = unitOwner:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)
		if nVulnerable == nil then
			bShow = false
		elseif nVulnerable == 0 and nVulnerable ~= tNameplate.nVulnerableTime then
			nNewVulnerabilityTime = 0 -- casting done, set back to 0
			bShow = false
		elseif nVulnerable ~= 0 and nVulnerable < tNameplate.nVulnerableTime then
			--tNameplate.wnd.healthBar:SetBarColor(xkcdBarneyPurple)
			tNameplate.wnd.vulnerableVulnFill:SetMax(tNameplate.nVulnerableTime)
			tNameplate.wnd.vulnerableVulnFill:SetProgress(nVulnerable)
			bShow = true
		end
	end

	if bShow ~= wndVulnerable:IsShown() then
		wndVulnerable:Show(bShow)
	end
end

function BenikUI_Nameplates:DrawRewards(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local bUseTarget = tNameplate.bIsTarget
	local bShow = self.bShowRewardsMain
	if bUseTarget then
		bShow = self.bShowRewardsTarget
	end

	if bShow ~= tNameplate.wnd.questRewards:IsShown() then
		tNameplate.wnd.questRewards:Show(bShow)
	end

	local nIcons = 0
	if tNameplate.wnd.questRewards:GetData() ~= nil then
		nIcons = tNameplate.wnd.questRewards:GetData().nIcons
	end
	if self.bRedrawRewardIcons then
		self:UpdateNameplateRewardInfo(tNameplate)
	end

	local tRewardsData = tNameplate.wnd.questRewards:GetData()
	if bShow and tRewardsData ~= nil and tRewardsData.nIcons ~= nil and tRewardsData.nIcons > 0 and tNameplate.nBiggestHalf ~= nil then
		local wndnameRewardContainer = tNameplate.wnd.nameRewardContainer
		local nLeft, nTop, nRight, nBottom = wndnameRewardContainer:GetAnchorOffsets()
		wndnameRewardContainer:SetAnchorOffsets(tNameplate.nBiggestHalf, nTop, tNameplate.nBiggestHalf + wndnameRewardContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop), nBottom)
	end
end

function BenikUI_Nameplates:DrawTargeting(tNameplate)
	local wndNameplate = tNameplate.wndNameplate
	local unitOwner = tNameplate.unitOwner

	local bUseTarget = tNameplate.bIsTarget

	local bShowTargetMarkerArrow = bUseTarget and self.bShowMarkerTarget and not tNameplate.wnd.health:IsShown()

	if tNameplate.wnd.targetMarkerArrow:IsShown() ~= bShowTargetMarkerArrow then
		tNameplate.wnd.targetMarkerArrow:Show(bShowTargetMarkerArrow, not bShowTargetMarkerArrow)
	end
end

function BenikUI_Nameplates:CheckDrawDistance(tNameplate)
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner

	if not unitOwner or not unitPlayer then
	    return false
	end

	local tPosTarget = unitOwner:GetPosition()
	local tPosPlayer = unitPlayer:GetPosition()

	if tPosTarget == nil or tPosPlayer == nil then
		return
	end

	local nDeltaX = tPosTarget.x - tPosPlayer.x
	local nDeltaY = tPosTarget.y - tPosPlayer.y
	local nDeltaZ = tPosTarget.z - tPosPlayer.z

	local nDistance = (nDeltaX * nDeltaX) + (nDeltaY * nDeltaY) + (nDeltaZ * nDeltaZ)

	if tNameplate.bIsTarget or tNameplate.bIsCluster then
		return nDistance < knTargetRange
	else
		return nDistance < self.nMaxRangeSq
	end
end

function BenikUI_Nameplates:HelperVerifyVisibilityOptions(tNameplate)
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner

	if (not unitOwner:ShouldShowNamePlate() and not tNameplate.bIsTarget)
		or ((self.bUseOcclusion and tNameplate.bOccluded) or not tNameplate.bOnScreen)
		or (tNameplate.bGibbed or (tNameplate.bSpeechBubble and not self.bShowDuringSpeech)) then
		return false
	end

	if unitOwner == self.unitPlayer then
		return tNameplate.bIsTarget or (self.bShowMyNameplate and not unitOwner:IsDead())
	end

	local eDisposition = tNameplate.eDisposition
	local tActivation = tNameplate.tActivation

	-- if you stare into the abyss the abyss stares back into you
	if tNameplate.bIsTarget
		or (not (self.bPlayerInCombat and self.bHideInCombat)
			and ((self.bShowMainObjectiveOnly and tNameplate.bIsObjective)
				or (self.bShowMainGroupOnly and unitOwner:IsInYourGroup())
				or (self.bShowDispositionHostile and eDisposition == Unit.CodeEnumDisposition.Hostile)
				or (self.bShowDispositionNeutral and eDisposition == Unit.CodeEnumDisposition.Neutral)
				or (self.bShowDispositionFriendly and eDisposition == Unit.CodeEnumDisposition.Friendly)
				or (self.bShowDispositionFriendlyPlayer and eDisposition == Unit.CodeEnumDisposition.Friendly and tNameplate.bIsPlayer)
				or (self.bShowVendor and tActivation.Vendor ~= nil)
				or (self.bShowTaxi and (tActivation.FlightPathSettler ~= nil or tActivation.FlightPath ~= nil or tActivation.FlightPathNew))
				or (self.bShowOrganization and tNameplate.bIsGuildMember)
				or (self.bShowMainObjectiveOnly and ((tActivation.QuestReward ~= nil)
					or (tActivation.QuestNew ~= nil or tActivation.QuestNewMain ~= nil)
					or (tActivation.QuestReceiving ~= nil)
					or (tActivation.TalkTo ~= nil))
				)
			)
		) then

		return true
	end

	if self.bShowMainObjectiveOnly and tNameplate.tRewardInfo ~= nil then
		for idx, tReward in pairs(tNameplate.tRewardInfo) do
			if tReward.eType == Unit.CodeEnumRewardInfoType.Quest
				or tReward.eType == Unit.CodeEnumRewardInfoType.Contract
				or tReward.eType == Unit.CodeEnumRewardInfoType.PublicEvent then
				return true
			end
		end
	end

	return false
end

function BenikUI_Nameplates:DrawHealthShieldBar(wndHealth, unitOwner, eDisposition, tNameplate) -- Every frame
	local nHealthCurr = unitOwner:GetHealth()

	if tNameplate.strUnitType == "Simple" or nHealthCurr == nil then
		if nHealthCurr ~= tNameplate.nHealthCurr then
			tNameplate.wnd.healthBar:SetAnchorPoints(0, 0, 1, 1)
			tNameplate.wnd.healthHealthLabel:SetText("")
		end

		tNameplate.nHealthCurr = nHealthCurr
		return
	end

	local nHealthMax 	= unitOwner:GetMaxHealth()
	local nShieldCurr 	= unitOwner:GetShieldCapacity()
	local nShieldMax 	= unitOwner:GetShieldCapacityMax()
	local nAbsorbCurr 	= 0
	local nAbsorbMax 	= unitOwner:GetAbsorptionMax()
	if nAbsorbMax > 0 then
		nAbsorbCurr = unitOwner:GetAbsorptionValue() -- Since it doesn't clear when the buff drops off
	end
	local nHealingAbsorb = unitOwner:GetHealingAbsorptionValue()
	local nHealthClampMin = unitOwner:GetHealthFloor()
	local nHealthClampMax = unitOwner:GetHealthCeiling()

	local nTotalMax = nHealthMax + nShieldMax + nAbsorbMax

	if unitOwner:IsDead() then
		nHealthCurr = 0
	end
	local nHealthTintType = 0
	local Option = self.Options.db.profile.Nameplates
	if unitOwner:IsInCCState(Unit.CodeEnumCCState.Vulnerability) then
		nHealthTintType = 3
	elseif nHealthCurr / nHealthMax <= knHealthRed then
		tNameplate.wnd.healthBar:SetBarColor(Option.lowHealth)
		nHealthTintType = 2
	elseif nHealthCurr / nHealthMax <= knHealthYellow then
		tNameplate.wnd.healthBar:SetBarColor(Option.halfHealth)
		nHealthTintType = 1
	else
		tNameplate.wnd.healthBar:SetBarColor(Option.fullHealth)
	end
	
	local nNewVulnerabilityTime = unitOwner:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability) or 0

	if nNewVulnerabilityTime > 0 then
		tNameplate.wnd.healthBar:SetBarColor(Option.Moo)
	end

	if nHealthTintType ~= tNameplate.nHealthTintType then
		--tNameplate.wnd.healthBar:SetFullSprite(nHealthTintType == 3 and "CRB_Nameplates:sprNP_PurpleProg" or karDisposition.tHealthBar[tNameplate.eDisposition])
		tNameplate.nHealthTintType = nHealthTintType
	end

	if nHealthMax ~= tNameplate.nHealthMax or nShieldMax ~= tNameplate.nShieldMax or nAbsorbMax ~= tNameplate.nAbsorbMax then
		local nPointHealthRight = nHealthMax / nTotalMax
		local nPointShieldRight = (nHealthMax + nShieldMax) / nTotalMax

		if nShieldMax > 0 and nPointShieldRight - nPointHealthRight < 0.2 then
			nPointHealthRight = nPointHealthRight - (0.2 - (nPointShieldRight - nPointHealthRight))
		end

		tNameplate.wnd.healingAbsorbBar:Show(nHealingAbsorb ~= 0)
		tNameplate.wnd.shieldBar:Show(nShieldMax ~= 0)
		tNameplate.wnd.absorbBar:Show(nAbsorbMax ~= 0)

		tNameplate.wnd.healthBar:SetAnchorPoints(0, 0, nPointHealthRight, 1)
		tNameplate.wnd.healingAbsorbBar:SetAnchorPoints(0, 0, nPointHealthRight, 1)
		tNameplate.wnd.healthClampMin:SetAnchorPoints(0, 0, nPointHealthRight, 1)
		tNameplate.wnd.healthClampMax:SetAnchorPoints(0, 0, nPointHealthRight, 1)
		tNameplate.wnd.shieldBar:SetAnchorPoints(nPointHealthRight, 0, nPointShieldRight, 1)
		tNameplate.wnd.absorbBar:SetAnchorPoints(nPointShieldRight, 0, 1, 1)

		tNameplate.wnd.shieldBar:SetMax(nShieldMax)
		tNameplate.wnd.absorbBar:SetMax(nAbsorbMax)
	end

	tNameplate.wnd.healthBar:SetMax(nHealthMax + nHealingAbsorb)
	tNameplate.wnd.healthBar:SetProgress(nHealthCurr, (nHealthMax + nHealingAbsorb) * 4)
	tNameplate.wnd.healthBar:Show(nHealthCurr > 0)

	tNameplate.wnd.healingAbsorbBar:SetMax(nHealthMax + nHealingAbsorb)
	tNameplate.wnd.healingAbsorbBar:SetProgress(nHealthCurr + nHealingAbsorb, (nHealthMax + nHealingAbsorb) * 4)
	tNameplate.wnd.healingAbsorbBar:Show(nHealthCurr > 0 and nHealingAbsorb > 0)

	tNameplate.wnd.healthClampMin:SetMax(nHealthMax + nHealingAbsorb)
	tNameplate.wnd.healthClampMin:SetProgress(nHealthClampMin)
	tNameplate.wnd.healthClampMin:Show(nHealthClampMin > 0)

	tNameplate.wnd.healthClampMax:SetMax(nHealthMax + nHealingAbsorb)
	tNameplate.wnd.healthClampMax:SetProgress(nHealthClampMax)
	tNameplate.wnd.healthClampMax:Show(nHealthClampMax ~= nHealthMax)

	tNameplate.wnd.shieldBar:EnableGlow(nShieldCurr > 0 and nShieldCurr ~= nShieldMax)
	tNameplate.wnd.shieldBar:SetProgress(nShieldCurr, nShieldMax * 4)
	tNameplate.wnd.shieldBar:Show(nHealthCurr > 0 and nShieldCurr > 0)

	tNameplate.wnd.absorbBar:SetProgress(nAbsorbCurr, nAbsorbMax * 4)
	tNameplate.wnd.absorbBar:Show(nHealthCurr > 0 and nAbsorbCurr > 0)

	-- Text
	if nHealthMax ~= tNameplate.nHealthMax or nHealthCurr ~= tNameplate.nHealthCurr or nShieldCurr ~= tNameplate.nShieldCurr then
		local strHealthMax = self:HelperFormatBigNumber(nHealthMax)
		local strHealthCurr = self:HelperFormatBigNumber(nHealthCurr)
		local strShieldCurr = self:HelperFormatBigNumber(nShieldCurr)

		local strText = nHealthMax == nHealthCurr and strHealthMax or String_GetWeaselString(Apollo.GetString("TargetFrame_HealthText"), strHealthCurr, strHealthMax)
		if nShieldMax > 0 and nShieldCurr > 0 then
			strText = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthShieldText"), strText, strShieldCurr)
		end
		tNameplate.wnd.healthHealthLabel:SetText(strText)
	end

	tNameplate.nHealthCurr = nHealthCurr
	tNameplate.nHealthMax = nHealthMax
	tNameplate.nHealingAbsorb = nHealingAbsorb
	tNameplate.nShieldCurr = nShieldCurr
	tNameplate.nShieldMax = nShieldMax
	tNameplate.nAbsorbCurr = nAbsorbCurr
	tNameplate.nAbsorbMax = nAbsorbMax
	tNameplate.nTotalMax = nTotalMax
end

function BenikUI_Nameplates:HelperFormatBigNumber(nArg)
	if nArg < 1000 then
		strResult = tostring(nArg)
	elseif nArg < 1000000 then
		if math.floor(nArg%1000/100) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_ShortNumberWhole"), math.floor(nArg / 1000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_ShortNumberFloat"), nArg / 1000)
		end
	elseif nArg < 1000000000 then
		if math.floor(nArg%1000000/100000) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_MillionsNumberWhole"), math.floor(nArg / 1000000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_MillionsNumberFloat"), nArg / 1000000)
		end
	elseif nArg < 1000000000000 then
		if math.floor(nArg%1000000/100000) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_BillionsNumberWhole"), math.floor(nArg / 1000000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_BillionsNumberFloat"), nArg / 1000000)
		end
	else
		strResult = tostring(nArg)
	end
	return strResult
end

function BenikUI_Nameplates:SetBarValue(wndBar, fMin, fValue, fMax)
	wndBar:SetMax(fMax)
	wndBar:SetFloor(fMin)
	wndBar:SetProgress(fValue)
end

function BenikUI_Nameplates:HelperCalculateConValue(unitTarget)
	if unitTarget == nil or not unitTarget:IsValid() or self.unitPlayer == nil or not self.unitPlayer:IsValid() then
		return knConMin
	end

	local nUnitCon = self.unitPlayer:GetLevelDifferential(unitTarget)
	return math.min(math.max(knConMin, nUnitCon), knConMax)
end

-----------------------------------------------------------------------------------------------
-- Nameplate Events
-----------------------------------------------------------------------------------------------

function BenikUI_Nameplates:OnNameplateNameClick(wndHandler, wndCtrl, eMouseButton)
	local tNameplate = self.arWnd2Nameplate[wndHandler:GetId()]
	if tNameplate == nil then
		return
	end

	local unitOwner = tNameplate.unitOwner
	if GameLib.GetTargetUnit() ~= unitOwner and eMouseButton == GameLib.CodeEnumInputMouse.Left then
		GameLib.SetTargetUnit(unitOwner)
	end
end

function BenikUI_Nameplates:OnWorldLocationOnScreen(wndHandler, wndControl, bOnScreen)
	local tNameplate = self.arWnd2Nameplate[wndHandler:GetId()]
	if tNameplate ~= nil then
		tNameplate.bOnScreen = bOnScreen
		self:UpdateNameplateVisibility(tNameplate)
	end
end

function BenikUI_Nameplates:OnUnitOcclusionChanged(wndHandler, wndControl, bOccluded)
	local tNameplate = self.arWnd2Nameplate[wndHandler:GetId()]
	if tNameplate ~= nil then
		tNameplate.bOccluded = bOccluded
		self:UpdateNameplateVisibility(tNameplate)
	end
end

-----------------------------------------------------------------------------------------------
-- System Events
-----------------------------------------------------------------------------------------------

function BenikUI_Nameplates:OnUnitTextBubbleToggled(tUnitArg, strText, nRange)
	local tNameplate = self.arUnit2Nameplate[tUnitArg:GetId()]
	if tNameplate ~= nil then
		tNameplate.bSpeechBubble = strText ~= nil and strText ~= ""
		self:UpdateNameplateVisibility(tNameplate)
	end
end

function BenikUI_Nameplates:OnEnteredCombat(unitChecked, bInCombat)
	if unitChecked == self.unitPlayer then
		self.bPlayerInCombat = bInCombat
	end
end

function BenikUI_Nameplates:OnUnitGibbed(unitUpdated)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		tNameplate.bGibbed = true
		self:UpdateNameplateVisibility(tNameplate)
	end
end

function BenikUI_Nameplates:OnUnitNameChanged(unitUpdated, strNewName)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		self:DrawName(tNameplate)
	end
end

function BenikUI_Nameplates:OnUnitLevelChanged(unitUpdating)
	local tNameplate = self.arUnit2Nameplate[unitUpdating:GetId()]
	if tNameplate ~= nil then
		self:DrawLevel(tNameplate)
	end
end

function BenikUI_Nameplates:OnGuildChange()
	self.guildDisplayed = nil
	self.guildWarParty = nil
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		local eGuildType = guildCurr:GetType()
		if eGuildType == GuildLib.GuildType_Guild then
			self.guildDisplayed = guildCurr
		end
		if eGuildType == GuildLib.GuildType_WarParty then
			self.guildWarParty = guildCurr
		end
	end

	for key, tNameplate in pairs(self.arUnit2Nameplate) do
		local unitOwner = tNameplate.unitOwner
		tNameplate.bIsGuildMember = self.guildDisplayed and self.guildDisplayed:IsUnitMember(unitOwner) or false
		tNameplate.bIsWarPartyMember = self.guildWarParty and self.guildWarParty:IsUnitMember(unitOwner) or false
	end
end

function BenikUI_Nameplates:OnUnitGuildNameplateChanged(unitUpdated)
	local tNameplate = self.arUnit2Nameplate[unitUpdated:GetId()]
	if tNameplate ~= nil then
		self:DrawGuild(tNameplate)
	end
end

function BenikUI_Nameplates:OnUnitMemberOfGuildChange(unitOwner)
	local tNameplate = self.arUnit2Nameplate[unitOwner:GetId()]
	if tNameplate ~= nil then
		self:DrawGuild(tNameplate)
		tNameplate.bIsGuildMember = self.guildDisplayed and self.guildDisplayed:IsUnitMember(unitOwner) or false
		tNameplate.bIsWarPartyMember = self.guildWarParty and self.guildWarParty:IsUnitMember(unitOwner) or false
	end
end

function BenikUI_Nameplates:OnTargetUnitChanged(unitOwner) -- build targeted options here; we get this event when a creature attacks, too
	for idx, tNameplateOther in pairs(self.arUnit2Nameplate) do
		local bIsTarget = tNameplateOther.bIsTarget
		local bIsCluster = tNameplateOther.bIsCluster

		tNameplateOther.bIsTarget = false
		tNameplateOther.bIsCluster = false

		if bIsTarget or bIsCluster then
			self:DrawHealth(tNameplateOther)
			self:DrawName(tNameplateOther)
			self:DrawGuild(tNameplateOther)
			self:DrawLevel(tNameplateOther)
			self:UpdateNameplateRewardInfo(tNameplateOther)
			self:DrawTargeting(tNameplateOther)
		end
	end

	if unitOwner == nil then
		return
	end

	local tNameplate = self.arUnit2Nameplate[unitOwner:GetId()]
	if tNameplate == nil then
		return
	end

	if GameLib.GetTargetUnit() == unitOwner then
		tNameplate.bIsTarget = true
		self:DrawHealth(tNameplate)
		self:DrawName(tNameplate)
		self:DrawGuild(tNameplate)
		self:DrawLevel(tNameplate)
		self:DrawTargeting(tNameplate)
		self:UpdateNameplateRewardInfo(tNameplate)

		local tCluster = unitOwner:GetClusterUnits()
		if tCluster ~= nil then
			tNameplate.bIsCluster = true

			for idx, unitCluster in pairs(tCluster) do
				local tNameplateOther = self.arUnit2Nameplate[unitCluster:GetId()]
				if tNameplateOther ~= nil then
					tNameplateOther.bIsCluster = true
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Options
-----------------------------------------------------------------------------------------------
function BenikUI_Nameplates:OnConfigure()
	self:OnNameplatesOn()
end

function BenikUI_Nameplates:OnNameplatesOn()
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "NameplatesForm", nil, self)
	self.wndOptionsMain = Apollo.LoadForm(self.xmlDoc, "StandardModule", self.wndMain:FindChild("ContentMain"), self)
	self.wndOptionsTargeted = Apollo.LoadForm(self.xmlDoc, "TargetedModule", self.wndMain:FindChild("ContentTarget"), self)
	self.wndMain:FindChild("ContentMain"):Show(true)
	self.wndMain:FindChild("ContentTarget"):Show(false)
	self.wndMain:FindChild("ContentToggleContainer:NormalViewCheck"):SetCheck(true)

	for property,tData in pairs(karSavedProperties) do
		if tData.nControlType == 1 then
			local wndControl = self.wndMain:FindChild(tData.strControlName)
			if wndControl ~= nil then
				wndControl:SetData(property)
			end
		end
	end

	local ePath = PlayerPathLib.GetPlayerPathType()
	self.wndOptionsMain:FindChild("ShowRewardTypeMission"):FindChild("Icon"):SetSprite(karPathSprite[ePath])

	self:RefreshNameplatesConfigure()
	self.wndMain:Invoke()

	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("Nameplates_Options")})
end

function BenikUI_Nameplates:OnOptionsClosed(wndHandler, wndControl)
	if self.wndMain ~= nil and self.wndMain:IsValid() then
		self.wndMain:Close()
		self.wndMain:Destroy()
		self.wndMain = nil
		self.wndOptionsMain = nil
		self.wndOptionsTargeted = nil

		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("Nameplates_Options")})
	end
end

function BenikUI_Nameplates:RefreshNameplatesConfigure()
	-- Generic managed controls
	for property,tData in pairs(karSavedProperties) do
		if tData.nControlType == 1 and self[property] ~= nil then
			local wndControl = self.wndMain:FindChild(tData.strControlName)
			if wndControl ~= nil then
				wndControl:SetCheck(self[property])
			end
		end
	end
	--Draw distance
	if self.nMaxRange ~= nil then
		self.wndOptionsMain:FindChild("ShowOptionsBacker:DrawDistanceSlider"):SetValue(self.nMaxRange)
		self.wndOptionsMain:FindChild("ShowOptionsBacker:DrawDistanceLabel"):SetText(String_GetWeaselString(Apollo.GetString("Nameplates_DrawDistance"), self.nMaxRange))
	end
	--Info panel
	if self.bShowHealthMain ~= nil and self.bShowHealthMainDamaged ~= nil then self.wndMain:FindChild("MainShowHealthBarAlways"):SetCheck(self.bShowHealthMain and not self.bShowHealthMainDamaged) end
	if self.bShowHealthMain ~= nil and self.bShowHealthMainDamaged ~= nil then self.wndMain:FindChild("MainShowHealthBarDamaged"):SetCheck(not self.bShowHealthMain and self.bShowHealthMainDamaged) end
	if self.bShowHealthMain ~= nil and self.bShowHealthMainDamaged ~= nil then self.wndMain:FindChild("MainShowHealthBarNever"):SetCheck(not self.bShowHealthMain and not self.bShowHealthMainDamaged) end
	--target components
	if self.bShowMarkerTarget ~= nil then self.wndMain:FindChild("MainHideInCombatOff"):SetCheck(not self.bHideInCombat) end
	--General nameplate occlustion
	self.wndOptionsMain:FindChild("ShowOptionsBacker:MainUseOcclusion"):SetCheck(Apollo.GetConsoleVariable("ui.occludeNameplatePositions"))
end

function BenikUI_Nameplates:OnNormalViewCheck(wndHandler, wndCtrl)
	self.wndMain:FindChild("ContentMain"):Show(true)
	self.wndMain:FindChild("ContentTarget"):Show(false)
end

function BenikUI_Nameplates:OnTargetViewCheck(wndHandler, wndCtrl)
	self.wndMain:FindChild("ContentMain"):Show(false)
	self.wndMain:FindChild("ContentTarget"):Show(true)
end

function BenikUI_Nameplates:OnCancel()
	self.wndMain:Close()
end

function BenikUI_Nameplates:OnDrawDistanceSlider(wndNameplate, wndHandler, nValue, nOldvalue)
	self.wndOptionsMain:FindChild("DrawDistanceLabel"):SetText(String_GetWeaselString(Apollo.GetString("Nameplates_DrawDistance"), nValue))
	self.nMaxRange = nValue-- set new constant, apply math
	self.nMaxRangeSq = nValue * nValue
end

function BenikUI_Nameplates:OnMainShowHealthBarAlways(wndHandler, wndCtrl)
	self:HelperOnMainShowHealthSettingChanged(true, false)
end

function BenikUI_Nameplates:OnMainShowHealthBarDamaged(wndHandler, wndCtrl)
	self:HelperOnMainShowHealthSettingChanged(false, true)
end

function BenikUI_Nameplates:OnMainShowHealthBarNever(wndHandler, wndCtrl)
	self:HelperOnMainShowHealthSettingChanged(false, false)
end

function BenikUI_Nameplates:HelperOnMainShowHealthSettingChanged(bShowHealthMain, bShowHealthMainDamaged)
	self.bShowHealthMain = bShowHealthMain
	self.bShowHealthMainDamaged = bShowHealthMainDamaged
end

function BenikUI_Nameplates:OnMainHideInCombat(wndHandler, wndCtrl)
	self.bHideInCombat = wndCtrl:IsChecked() -- onDraw
end

function BenikUI_Nameplates:OnMainHideInCombatOff(wndHandler, wndCtrl)
	self.bHideInCombat = not wndCtrl:IsChecked() -- onDraw
end

function BenikUI_Nameplates:OnGenericSingleCheck(wndHandler, wndControl, eMouseButton)
	local strSettingName = wndControl:GetData()
	if strSettingName ~= nil then
		self[strSettingName] = wndControl:IsChecked()
		local fnCallback = karSavedProperties[strSettingName].fnCallback
		if fnCallback ~= nil then
			self[fnCallback](self)
		end
	end
end

function BenikUI_Nameplates:OnFriendlyPlayersSingleCheck(wndHandler, wndControl, eMouseButton)
	local strSettingName = wndControl:GetData()
	if strSettingName ~= nil then
		self["bShowDispositionFriendlyPlayer"] = wndControl:IsChecked()
		local fnCallback = karSavedProperties["bShowDispositionFriendlyPlayer"].fnCallback
		if fnCallback ~= nil then
			self[fnCallback](self)
		end
	end
	if not wndControl:IsChecked() then
		if strSettingName ~= nil then
			self["bShowDispositionFriendly"] = false
			local fnCallback = karSavedProperties["bShowDispositionFriendly"].fnCallback
			if fnCallback ~= nil then
				self[fnCallback](self)
			end
		end
	end

	if self.wndOptionsMain:FindChild("MainShowDisposition_FriendlyPlayer"):IsChecked() then
		self.wndOptionsMain:FindChild("MainShowDisposition_3"):Enable(true)
		self.wndOptionsMain:FindChild("MainShowDisposition_3"):SetBGColor("white")
	else
		self.wndOptionsMain:FindChild("MainShowDisposition_3"):Enable(false)
		self.wndOptionsMain:FindChild("MainShowDisposition_3"):SetCheck(false)
		self.wndOptionsMain:FindChild("MainShowDisposition_3"):SetBGColor("UI_AlphaPercent50")
	end
end

function BenikUI_Nameplates:OnSettingNameChanged()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:DrawName(tNameplate)
	end
end

function BenikUI_Nameplates:OnSettingTitleChanged()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:DrawGuild(tNameplate)
	end
end

function BenikUI_Nameplates:OnSettingHealthChanged()
	for idx, tNameplate in pairs(self.arUnit2Nameplate) do
		self:DrawLevel(tNameplate)
	end
end

function BenikUI_Nameplates:OnOcclusionCheck(wndHandler, wndControl, eMouseButton)
	local bUseOcclusion = wndControl:IsChecked()
	Apollo.SetConsoleVariable("ui.occludeNameplatePositions", bUseOcclusion)
	self.bUseOcclusion = bUseOcclusion
end

-----------------------------------------------------------------------------------------------
-- Local function reference assignments
-----------------------------------------------------------------------------------------------
fnDrawHealth = BenikUI_Nameplates.DrawHealth
fnDrawRewards = BenikUI_Nameplates.DrawRewards
fnDrawCastBar = BenikUI_Nameplates.DrawCastBar
fnDrawVulnerable = BenikUI_Nameplates.DrawVulnerable
fnColorNameplate = BenikUI_Nameplates.ColorNameplate
fnDrawTargeting = BenikUI_Nameplates.DrawTargeting


---------------------------------------------------------------------------------------------------
-- GeneralModule Functions
---------------------------------------------------------------------------------------------------

function BenikUI_Nameplates:OnShowHealth( wndHandler, wndControl, eMouseButton )
	local name = wndHandler:GetName()
	self.Options.db.profile.Nameplates[name] = wndControl:IsChecked()	
end

function BenikUI_Nameplates:OnColorNameplates( wndHandler, wndControl, eMouseButton )
	local name = wndHandler:GetParent():GetName()
	self.UpdateSave = name
	self.Update = wndControl
	self.colorPicker:Show(true)
  	self.colorPicker:ToFront()
end

function BenikUI_Nameplates:ColorPickerCallback(strColor)
	self.Options.db.profile.Nameplates[self.UpdateSave] = strColor
	self.Update:SetBGColor(strColor)
	self:UpdateAll()
end

-----------------------------------------------------------------------------------------------
-- BenikUI_Nameplates Instance
-----------------------------------------------------------------------------------------------
local NameplatesInst = BenikUI_Nameplates:new()
NameplatesInst:Init()
