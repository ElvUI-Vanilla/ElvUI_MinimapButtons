local E, L, V, P, G = unpack(ElvUI) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local EP = LibStub("LibElvUIPlugin-1.0");
local addon = E:NewModule("MinimapButtons", "AceHook-3.0", "AceTimer-3.0");

--Cache global variables
--Lua functions
local ceil, mod = math.ceil, math.mod
local find, format, len, split, sub = string.find, string.format, string.len, string.split, string.sub
local tinsert, getn = table.insert, table.getn
local ipairs, select, unpack = ipairs, select, unpack
--WoW API / Variables
local CreateFrame = CreateFrame
local UIFrameFadeIn, UIFrameFadeOut = UIFrameFadeIn, UIFrameFadeOut

local points = {
	["TOPLEFT"] = "TOPLEFT",
	["TOPRIGHT"] = "TOPRIGHT",
	["BOTTOMLEFT"] = "BOTTOMLEFT",
	["BOTTOMRIGHT"] = "BOTTOMRIGHT"
}

local positionValues = {
	TOPLEFT = "TOPLEFT",
	LEFT = "LEFT",
	BOTTOMLEFT = "BOTTOMLEFT",
	RIGHT = "RIGHT",
	TOPRIGHT = "TOPRIGHT",
	BOTTOMRIGHT = "BOTTOMRIGHT",
	CENTER = "CENTER",
	TOP = "TOP",
	BOTTOM = "BOTTOM"
}

P.general.minimap.buttons = {
	buttonsize = 26,
	buttonspacing = 1,
	backdropSpacing = 1,
	buttonsPerRow = 1,
	alpha = 1,
	point = "TOPLEFT",
	mouseover = false,
	backdrop = true,
	insideMinimap = {
		enable = true,
		position = "TOPLEFT",
		xOffset = 1,
		yOffset = -1
	}
}

local function ColorizeSettingName(settingName)
	return format("|cff1784d1%s|r", settingName)
end

local function GetOptions()
	if not E.Options.args.elvuiPlugins then
		E.Options.args.elvuiPlugins = {
			order = 50,
			type = "group",
			name = "|cff175581E|r|cffC4C4C4lvUI |r|cff175581P|r|cffC4C4C4lugins|r",
			args = {
				header = {
					order = 0,
					type = "header",
					name = "|cff175581E|r|cffC4C4C4lvUI |r|cff175581P|r|cffC4C4C4lugins|r"
				},
				buttonGrabberShortcut = {
					type = "execute",
					name = ColorizeSettingName(L["Minimap Buttons"]),
					func = function()
						if IsAddOnLoaded("ElvUI_Config") then
							local ACD = LibStub("AceConfigDialog-3.0")
							ACD:SelectGroup("ElvUI", "elvuiPlugins", "buttonGrabber")
						end
					end
				}
			}
		}
	elseif not E.Options.args.elvuiPlugins.args.buttonGrabberShortcut then
		E.Options.args.elvuiPlugins.args.buttonGrabberShortcut = {
			type = "execute",
			name = ColorizeSettingName(L["Minimap Buttons"]),
			func = function()
				if IsAddOnLoaded("ElvUI_Config") then
					local ACD = LibStub("AceConfigDialog-3.0")
					ACD:SelectGroup("ElvUI", "elvuiPlugins", "buttonGrabber")
				end
			end
		}
	end

 	E.Options.args.elvuiPlugins.args.buttonGrabber = {
		order = 10,
		type = "group",
		name = ColorizeSettingName(L["Minimap Buttons"]),
		get = function(info) return E.db.general.minimap.buttons[ info[getn(info)] ] end,
		set = function(info, value) E.db.general.minimap.buttons[ info[getn(info)] ] = value addon:UpdateLayout() addon:UpdateAlpha() end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Minimap Buttons"]
			},
			point = {
				order = 2,
				type = "select",
				name = L["Anchor Point"],
				desc = L["The first button anchors itself to this point on the bar."],
				values = points
			},
			backdrop = {
				order = 3,
				type = "toggle",
				name = L["Backdrop"]
			},
			mouseover = {
				order = 4,
				type = "toggle",
				name = L["Mouse Over"],
				desc = L["The frame is not shown unless you mouse over the frame."]
			},
			alpha = {
				order = 5,
				type = "range",
				name = L["Alpha"],
				min = 0, max = 1, step = 0.01
			},
			buttonsPerRow = {
				order = 6,
				type = "range",
				name = L["Buttons Per Row"],
				desc = L["The amount of buttons to display per row."],
				min = 1, max = 12, step = 1
			},
			buttonsPerRow = {
				order = 7,
				type = "range",
				name = L["Buttons Per Row"],
				desc = L["The amount of buttons to display per row."],
				min = 1, max = 12, step = 1
			},
			buttonsize = {
				order = 8,
				type = "range",
				name = L["Button Size"],
				min = 2, max = 60, step = 1
			},
			buttonspacing = {
				order = 9,
				type = "range",
				name = L["Button Spacing"],
				desc = L["The spacing between buttons."],
				min = -1, max = 24, step = 1
			},
			backdropSpacing = {
				order = 10,
				type = "range",
				name = L["Backdrop Spacing"],
				desc = L["The spacing between the backdrop and the buttons."],
				min = -1, max = 15, step = 1
			},
			insideMinimapGroup = {
				order = 11,
				type = "group",
				name = L["Inside Minimap"],
				guiInline = true,
				get = function(info) return E.db.general.minimap.buttons.insideMinimap[info[getn(info)]] end,
				set = function(info, value) E.db.general.minimap.buttons.insideMinimap[info[getn(info)]] = value addon:UpdatePosition() end,
				args = {
					enable = {
						order = 1,
						type = "toggle",
						name = L["Enable"],
					},
					position = {
						order = 2,
						type = "select",
						name = L["Position"],
						values = positionValues,
						disabled = function() return not E.db.general.minimap.buttons.insideMinimap.enable end
					},
					xOffset = {
						order = 3,
						type = "range",
						name = L["xOffset"],
						min = -20, max = 20, step = 1,
						disabled = function() return not E.db.general.minimap.buttons.insideMinimap.enable end
					},
					yOffset = {
						order = 4,
						type = "range",
						name = L["yOffset"],
						min = -20, max = 20, step = 1,
						disabled = function() return not E.db.general.minimap.buttons.insideMinimap.enable end
					}
				}
			}
		}
	}
end

local SkinnedButtons = {}

local IgnoreButtons = {
	"ElvConfigToggle",

	"BattlefieldMinimap",
	"ButtonCollectFrame",
	"GameTimeFrame",
	"MiniMapBattlefieldFrame",
	"MiniMapMailFrame",
	"MiniMapPing",
	"MiniMapRecordingButton",
	"MiniMapTracking",
	"MiniMapVoiceChatFrame",
	"MiniMapWorldMapButton",
	"Minimap",
	"MinimapBackdrop",
	"MinimapToggleButton",
	"MinimapZoneTextButton",
	"MinimapZoomIn",
	"MinimapZoomOut",
	"TimeManagerClockButton"
}

local GenericIgnores = {
	-- GatherMate
	"GatherMatePin",
	-- Gatherer
	"GatherNote",
	-- GuildMap2
	"GuildMap2Mini",
	-- HandyNotes
	"HandyNotesPin",
	-- LibRockConfig
	"LibRockConfig-1.0_MinimapButton",
	-- Nauticus
	"Naut_MiniMapIconButton",
}

local PartialIgnores = {
	"Node",
	"Note",
	"Pin",
}

local WhiteList = {
	"LibDBIcon",
}

function addon:CheckVisibility()
	local updateLayout = false

	for _, button in ipairs(SkinnedButtons) do
		if button:IsVisible() and button.hidden then
			button.hidden = false
			updateLayout = true
		elseif not button:IsVisible() and not button.hidden then
			button.hidden = true
			updateLayout = true
		end
	end

	return updateLayout
end

function addon:GrabMinimapButtons()
	for i = 1, Minimap:GetNumChildren() do
		local object = select(i, Minimap:GetChildren())

		if object and object:IsObjectType("Button") and object:GetName() then
			self:SkinMinimapButton(object)
		end
	end

	for i = 1, MinimapBackdrop:GetNumChildren() do
		local object = select(i, MinimapBackdrop:GetChildren())

		if object and object:IsObjectType("Button") and object:GetName() then
			self:SkinMinimapButton(object)
		end
	end

	if AtlasButtonFrame then self:SkinMinimapButton(AtlasButton) end
	if AtlasLootMinimapButtonFrame then self:SkinMinimapButton(AtlasLootMinimapButton) end
	if FishingBuddyMinimapFrame then self:SkinMinimapButton(FishingBuddyMinimapButton) end
	if HealBot_MMButton then self:SkinMinimapButton(HealBot_MMButton) end

	if self:CheckVisibility() or self.needupdate then
		self:UpdateLayout()
	end
end

function addon:SkinMinimapButton(button)
	if not button or button.isSkinned then return end

	local name = button:GetName()
	if not name then return end

	if button:IsObjectType("Button") then
		local validIcon = false

		for i = 1, getn(WhiteList) do
			if sub(name, 1, len(WhiteList[i])) == WhiteList[i] then validIcon = true break end
		end

		if not validIcon then
			for i = 1, getn(IgnoreButtons) do
				if name == IgnoreButtons[i] then return end
			end

			for i = 1, getn(GenericIgnores) do
				if sub(name, 1, len(GenericIgnores[i])) == GenericIgnores[i] then return end
			end

			for i = 1, getn(PartialIgnores) do
				if find(name, PartialIgnores[i]) ~= nil then return end
			end
		end

		button:SetPushedTexture(nil)
		button:SetHighlightTexture(nil)
		button:SetDisabledTexture(nil)
	end

	for i = 1, button:GetNumRegions() do
		local region = select(i, button:GetRegions())

		if region:GetObjectType() == "Texture" then
			local texture = region:GetTexture()

			if texture and (find(texture, "Border") or find(texture, "Background") or find(texture, "AlphaMask")) then
				region:SetTexture(nil)
			else
				if name == "BagSync_MinimapButton" then
					region:SetTexture("Interface\\AddOns\\BagSync\\media\\icon")
				elseif name == "DBMMinimapButton" then
					region:SetTexture("Interface\\Icons\\INV_Helmet_87")
				elseif name == "OutfitterMinimapButton" then
					if region:GetTexture() == "Interface\\Addons\\Outfitter\\Textures\\MinimapButton" then
						region:SetTexture("Interface\\Icons\\INV_Chest_Cloth_43")
					end
				elseif name == "SmartBuff_MiniMapButton" then
					region:SetTexture("Interface\\Icons\\Spell_Nature_Purge")
				elseif name == "VendomaticButtonFrame" then
					region:SetTexture("Interface\\Icons\\INV_Misc_Rabbit_2")
				end

				region:ClearAllPoints()
				E:SetInside(region)
				region:SetTexCoord(unpack(E.TexCoords))
				HookScript(button, "OnLeave", function() region:SetTexCoord(unpack(E.TexCoords)) end)

				region:SetDrawLayer("ARTWORK")
				region.SetPoint = function() return end
			end
		end
	end

	button:SetParent(self.frame)
	button:SetFrameLevel(self.frame:GetFrameLevel() + 2)

	E:SetTemplate(button, "Default")
	button:SetScript("OnDragStart", nil)
	button:SetScript("OnDragStop", nil)
	HookScript(button, "OnEnter", self.OnEnter)
	HookScript(button, "OnLeave", self.OnLeave)

	button.isSkinned = true
	tinsert(SkinnedButtons, button)
	self.needupdate = true
end

function addon:GetVisibleList()
	local tab = {}
	for _, button in ipairs(SkinnedButtons) do
		if button:IsVisible() then
			tinsert(tab, button)
		end
	end

	return tab
end

function addon:UpdateLayout()
	if getn(SkinnedButtons) < 1 then return end

	local db = E.db.general.minimap.buttons
	local VisibleButtons = self:GetVisibleList()

	if getn(VisibleButtons) < 1 then
		E:Size(self.frame, db.buttonsize + (db.buttonspacing * 2))
		self.frame.backdrop:Hide()
		return
	end

	if not self.frame.backdrop:IsShown() then
		self.frame.backdrop:Show()
	end

	local backdropSpacing = db.backdropSpacing or db.buttonspacing
	local numButtons = getn(VisibleButtons)
	local buttonsPerRow = db.buttonsPerRow
	local numColumns = ceil(numButtons / buttonsPerRow)

	if numButtons < buttonsPerRow then
		buttonsPerRow = numButtons
	end

	local barWidth = (db.buttonsize * buttonsPerRow) + (db.buttonspacing * (buttonsPerRow - 1)) + ((db.backdrop == true and (E.Border + backdropSpacing) or E.Spacing)*2)
	local barHeight = (db.buttonsize * numColumns) + (db.buttonspacing * (numColumns - 1)) + ((db.backdrop == true and (E.Border + backdropSpacing) or E.Spacing)*2)
	E:Size(self.frame, barWidth, barHeight)
	E:Size(self.frame.mover, barWidth, barHeight)

	if db.backdrop == true then
		self.frame.backdrop:Show()
	else
		self.frame.backdrop:Hide()
	end

	local horizontalGrowth, verticalGrowth
	if db.point == "TOPLEFT" or db.point == "TOPRIGHT" then
		verticalGrowth = "DOWN"
	else
		verticalGrowth = "UP"
	end

	if db.point == "BOTTOMLEFT" or db.point == "TOPLEFT" then
		horizontalGrowth = "RIGHT"
	else
		horizontalGrowth = "LEFT"
	end

	local firstButtonSpacing = (db.backdrop == true and (E.Border + backdropSpacing) or E.Spacing)
	for i, button in ipairs(VisibleButtons) do
		local lastButton = VisibleButtons[i - 1]
		local lastColumnButton = VisibleButtons[i - buttonsPerRow]
		E:Size(button, db.buttonsize)
		button:ClearAllPoints()

		if i == 1 then
			local x, y
			if db.point == "BOTTOMLEFT" then
				x, y = firstButtonSpacing, firstButtonSpacing
			elseif db.point == "TOPRIGHT" then
				x, y = -firstButtonSpacing, -firstButtonSpacing
			elseif db.point == "TOPLEFT" then
				x, y = firstButtonSpacing, -firstButtonSpacing
			else
				x, y = -firstButtonSpacing, firstButtonSpacing
			end

			button:SetPoint(db.point, self.frame, db.point, x, y)
		elseif mod(i - 1, buttonsPerRow) == 0 then
			local x = 0
			local y = -db.buttonspacing
			local buttonPoint, anchorPoint = "TOP", "BOTTOM"
			if verticalGrowth == "UP" then
				y = db.buttonspacing
				buttonPoint = "BOTTOM"
				anchorPoint = "TOP"
			end
			button:SetPoint(buttonPoint, lastColumnButton, anchorPoint, x, y)
		else
			local x = db.buttonspacing
			local y = 0
			local buttonPoint, anchorPoint = "LEFT", "RIGHT"
			if horizontalGrowth == "LEFT" then
				x = -db.buttonspacing
				buttonPoint = "RIGHT"
				anchorPoint = "LEFT"
			end

			button:SetPoint(buttonPoint, lastButton, anchorPoint, x, y)
		end
	end

	self.needupdate = false
end

function addon:UpdatePosition()
	local db = E.db.general.minimap.buttons.insideMinimap

	if db.enable then
		self.frame:ClearAllPoints()
		self.frame:SetPoint(db.position, Minimap, db.position, db.xOffset, db.yOffset)

		E:DisableMover(self.frame.mover:GetName())
	else
		self.frame:ClearAllPoints()
		self.frame:SetAllPoints(self.frame.mover)

		E:EnableMover(self.frame.mover:GetName())
	end
end

function addon:UpdateAlpha()
	if E.db.general.minimap.buttons.mouseover then
		self.frame:SetAlpha(0)
	else
		self.frame:SetAlpha(E.db.general.minimap.buttons.alpha)
	end
end

function addon:OnEnter()
	if E.db.general.minimap.buttons.mouseover then
		UIFrameFadeIn(ElvUI_MinimapButtonGrabber, 0.1, ElvUI_MinimapButtonGrabber:GetAlpha(), E.db.general.minimap.buttons.alpha)
	end
end

function addon:OnLeave()
	if E.db.general.minimap.buttons.mouseover then
		UIFrameFadeOut(ElvUI_MinimapButtonGrabber, 0.1, ElvUI_MinimapButtonGrabber:GetAlpha(), 0)
	end
end

local function EnchantrixIconFix()
	if not Enchantrix or EnxMiniMapIcon then return end

	local settings = Enchantrix.Settings
	local oldButton = Enchantrix.MiniIcon

	local newButton = CreateFrame("Button", "EnxMiniMapIcon", Minimap)
	E:Size(newButton, 20)
	newButton:SetToplevel(true)
	newButton:SetFrameStrata("LOW")
	E:Point(newButton, "RIGHT", Minimap, "LEFT", 0, 0)
	newButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	newButton.icon = oldButton.icon
	newButton.icon:SetTexCoord(0.2, 0.84, 0.13, 0.87)
	newButton.icon:SetParent(newButton)
	E:Point(newButton.icon, "TOPLEFT", newButton, "TOPLEFT", 0, 0)

	newButton.mask = oldButton.mask
	newButton.mask:SetParent(newButton)
	E:Point(newButton.mask, "TOPLEFT", newButton, "TOPLEFT", -8, 8)

	newButton:SetScript("OnClick", oldButton:GetScript("OnClick"))

	oldButton:SetMovable(false)
	oldButton:SetParent(UIParent)
	E:Point(oldButton, "TOPRIGHT", UIParent)
	oldButton:Hide()

	oldButton:SetScript("OnMouseDown", nil)
	oldButton:SetScript("OnMouseUp", nil)
	oldButton:SetScript("OnDragStart", nil)
	oldButton:SetScript("OnDragStop", nil)
	oldButton:SetScript("OnClick", nil)
	oldButton:SetScript("OnUpdate", nil)

	Enchantrix.MiniIcon = newButton

	function Enchantrix.MiniIcon.Reposition()
		if settings.GetSetting("miniicon.enable") then
			newButton:Show()
		else
			newButton:Hide()
		end
	end
end

function addon:FixButtons()
	if IsAddOnLoaded("Atlas") then
		function AtlasButton_Toggle()
			if AtlasButton:IsVisible() then
				AtlasButton:Hide()
				AtlasOptions.AtlasButtonShown = false
			else
				AtlasButton:Show()
				AtlasOptions.AtlasButtonShown = true
			end
			AtlasOptions_Init()
		end
	end

	if IsAddOnLoaded("DBM-Core") then
		local button = DBMMinimapButton
		if not button then return end

		if button:GetScript("OnMouseDown") then
			button:SetScript("OnMouseDown", nil)
			button:SetScript("OnMouseUp", nil)
		end
	end

	if IsAddOnLoaded("Enchantrix") then
		EnchantrixIconFix()
	end
end

function addon:Initialize()
	EP:RegisterPlugin("ElvUI_MinimapButtons", GetOptions)

	local db = E.db.general.minimap.buttons
	local backdropSpacing = db.backdropSpacing or db.buttonspacing

	self.frame = CreateFrame("Button", "ElvUI_MinimapButtonGrabber", UIParent)
	E:Size(self.frame, db.buttonsize + (backdropSpacing * 2))
	self.frame:SetPoint("TOPRIGHT", MMHolder, "BOTTOMRIGHT", 0, 0)
	self.frame:SetFrameStrata("LOW")
	self.frame:SetClampedToScreen(true)
	E:CreateBackdrop(self.frame, "Default")

	self.frame.backdrop:SetPoint("TOPLEFT", self.frame, "TOPLEFT", E.Spacing, -E.Spacing)
	self.frame.backdrop:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -E.Spacing, E.Spacing)
	self.frame.backdrop:Hide()

	E:CreateMover(self.frame, "MinimapButtonGrabberMover", L["Minimap Button Grabber"], nil, nil, nil, "ALL,GENERAL")

	if self.frame.mover:GetScript("OnSizeChanged") then
		self.frame.mover:SetScript("OnSizeChanged", nil)
	end

	self:UpdateAlpha()
	self:UpdatePosition()

	self.frame:SetScript("OnEnter", self.OnEnter)
	self.frame:SetScript("OnLeave", self.OnLeave)

	self:ScheduleRepeatingTimer("GrabMinimapButtons", 5)

	self:FixButtons()
end

local function InitializeCallback()
	addon:Initialize()
end

E:RegisterModule(addon:GetName(), InitializeCallback)
