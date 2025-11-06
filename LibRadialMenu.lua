LibRadialMenu = LibRadialMenu or {}



local LIBRADIAL_WHEEL = HOTBAR_CATEGORY_MAX_VALUE + 100
ZO_CreateStringId(string.format("SI_HOTBARCATEGORY%d",LIBRADIAL_WHEEL), "Addon Entries")

local UTILITY_WHEEL_CATEGORIES =
{
	HOTBAR_CATEGORY_QUICKSLOT_WHEEL,
	HOTBAR_CATEGORY_ALLY_WHEEL,
	HOTBAR_CATEGORY_MEMENTO_WHEEL,
	HOTBAR_CATEGORY_TOOL_WHEEL,
	HOTBAR_CATEGORY_EMOTE_WHEEL,
	LIBRADIAL_WHEEL,
}
local NUM_UTILITY_WHEEL_CATEGORIES = #UTILITY_WHEEL_CATEGORIES



function ZO_UtilityWheel_Shared:GetHotbarCategory()
	return UTILITY_WHEEL_CATEGORIES[self.currentHotbarCategoryIndex]
end

function ZO_UtilityWheel_Shared:GetNextHotbarCategoryIndex()
	return self.currentHotbarCategoryIndex % NUM_UTILITY_WHEEL_CATEGORIES + 1
end

function ZO_UtilityWheel_Shared:GetPreviousHotbarCategoryIndex()
	local categoryIndex = self.currentHotbarCategoryIndex - 1
	if categoryIndex == 0 then
		categoryIndex = NUM_UTILITY_WHEEL_CATEGORIES
	end
	return categoryIndex
end

function ZO_UtilityWheel_Shared:GetNextHotbarCategory()
	return UTILITY_WHEEL_CATEGORIES[self:GetNextHotbarCategoryIndex()]
end

function ZO_UtilityWheel_Shared:GetPreviousHotbarCategory()
	return UTILITY_WHEEL_CATEGORIES[self:GetPreviousHotbarCategoryIndex()]
end




local registeredEntries = { }
local addonNames = { }

function LibRadialMenu:RegisterAddon(addonId, addonName)
	addonNames[addonId] = addonName
	registeredEntries[addonId] = {}
end


function LibRadialMenu:RegisterEntry(addonId, entryName, entryId, entryIcon, entryCallback, entryDescription)
	if (type(registeredEntries[addonId]) ~= "table") or (type(entryCallback) ~= "function") then
		d(string.format("LibRadialMenu: Failed to register entry %s for addon %s", entryName, addonId))
		return
	end
	registeredEntries[addonId][entryId] = {
		name = entryName,
		icon = entryIcon,
		callback = entryCallback,
		description = entryDescription,
	}
end



local libRadialWheelEntries = {}


ZO_PreHook(ZO_UtilityWheel_Shared, "PopulateMenu", function(self)
	local hotbarCategory = self:GetHotbarCategory()
	--d("Populating "..GetString("SI_HOTBARCATEGORY",hotbarCategory))

	if hotbarCategory == LIBRADIAL_WHEEL then

		for i, entryData in ipairs(libRadialWheelEntries) do
			local entryAddon = registeredEntries[entryData.addon]
			if entryAddon and entryAddon[entryData.entry] and addonNames[entryData.addon] then
				local entry = entryAddon[entryData.entry]
				local addonName = addonNames[entryData.addon]
				local slotIcon = entry.icon or ""
				local slotname = string.format("%s\n%s", entry.name or entryData.entry, ZO_NORMAL_TEXT:Colorize(addonName))
				local callback = entry.callback
				self.menu:AddEntry(slotname, slotIcon, slotIcon, callback, {slotNum = i, name = slotname})
			else
				self.menu:AddEntry(ZO_UTILITY_SLOT_EMPTY_STRING, ZO_UTILITY_SLOT_EMPTY_TEXTURE, ZO_UTILITY_SLOT_EMPTY_TEXTURE, nil, { slotNum = i })
			end
		end

		self.previousCategoryControl:SetHidden(false)
		self.nextCategoryControl:SetHidden(false)

		self:RefreshCategories()
		return true
	end
	return false
end)








--[[
	
	
	       _        ____     ____   ____   ____   ___      __________      ___   ____
	      dM.      6MMMMb\  6MMMMb\ `MM'  6MMMMb/ `MM\     `M'`MM'`MM\     `M'  6MMMMb/
	     ,MMb     6M'    ` 6M'    `  MM  8P    YM  MMM\     M  MM  MMM\     M  8P    YM
	     d'YM.    MM       MM        MM 6M      Y  M\MM\    M  MM  M\MM\    M 6M      Y
	    ,P `Mb    YM.      YM.       MM MM         M \MM\   M  MM  M \MM\   M MM
	    d'  YM.    YMMMMb   YMMMMb   MM MM         M  \MM\  M  MM  M  \MM\  M MM
	   ,P   `Mb        `Mb      `Mb  MM MM     ___ M   \MM\ M  MM  M   \MM\ M MM     ___
	   d'    YM.        MM       MM  MM MM     `M' M    \MM\M  MM  M    \MM\M MM     `M'
	  ,MMMMMMMMb        MM       MM  MM YM      M  M     \MMM  MM  M     \MMM YM      M
	  d'      YM. L    ,M9 L    ,M9  MM  8b    d9  M      \MM  MM  M      \MM  8b    d9
	_dM_     _dMM_MYMMMM9  MYMMMM9  _MM_  YMMMM9  _M_      \M _MM__M_      \M   YMMMM9
	
	
	
]]





local CHECKED_ICON = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"

local function IsSelected(data)
	return data.isActive
end


local function SetupProfileItem(control, data, ...)
	ZO_SharedGamepadEntry_OnSetup(control, data, ...)
	control.statusIndicator = control:GetNamedChild("StatusIndicator")
	if IsSelected(data) then
		control.statusIndicator:AddIcon(CHECKED_ICON)
		control.statusIndicator:Show()
	end
	control.icon = control:GetNamedChild("Icon")
	control.icon:AddIcon(data.icon)
	control.icon:Show()
end

local function SetupHeader(control, data, ...)
	ZO_SharedGamepadEntry_OnSetup(control, data, ...)
	control:SetText(data.addonName)
end

local function SetupProfiles(dialog, activeCriteria, slotIndex)
	dialog.info.parametricList = {}
	local template = "LibRadialMenuAssigningEntry"
	local headerTemplate = "ZO_GamepadOptionsMenuEntryHeaderTemplate"

	local addons = {}
	for i,v in pairs(registeredEntries) do
		addons[#addons+1] = i
	end
	table.sort(addons)


	for i,addon in ipairs(addons) do
		local addonTable = registeredEntries[addon]

		local addonEntries = {}
		for i,v in pairs(addonTable) do
			addonEntries[#addonEntries+1] = i
		end
		table.sort(addonEntries)


		local addonName = addonNames[addon]
		local entryData = ZO_GamepadEntryData:New(addonName)
		entryData.setup = SetupHeader
		entryData.addonName = addonName

		local listItem = {
			template = headerTemplate,
			entryData = entryData,
		}
		table.insert(dialog.info.parametricList, listItem)

		for j,entryId in pairs(addonEntries) do
			local entry = addonTable[entryId]
			local icon = entry.icon or ""
			local name = entry.name or entryData.entry
			local description = entry.description

			local entryData = ZO_GamepadEntryData:New(name)
			entryData:SetFontScaleOnSelection(false)
			entryData:SetIconTintOnSelection(true)
			entryData.setup = SetupProfileItem
			entryData.name = name
			entryData.entryId = entryId
			entryData.addonName = addonName
			entryData.addonId = addon
			entryData.icon = icon
			entryData.description = description
			entryData.isActive = activeCriteria(addon, entryId)

			local listItem = {
				template = template,
				entryData = entryData,
			}
			table.insert(dialog.info.parametricList, listItem)
		end
	end
	dialog:setupFunc()
	dialog.entryList:SetSelectedDataByEval(IsSelected)
end

ESO_Dialogs["LibProfileAssignDialogue"] = {
	canQueue = true,
	gamepadInfo = {
		dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
	},
	setup = function(dialog)
		local entry = libRadialWheelEntries[dialog.data.slotIndex]
		SetupProfiles(dialog, function(addonId, entryId)
			return (entry ~= nil) and (entry.entry == entryId) and (entry.addon == addonId)
		end, dialog.data.slotIndex)
	end,
	title = {
		text = function(dialog) return string.format("Assign an entry for slot %d.", dialog.data.slotIndex) end,
	},
	buttons = {
		{
			text = function(dialog)
				local data = dialog.entryList:GetTargetData()
				if data and data.isActive then
					return GetString(SI_DIALOG_REMOVE)
				end
				return GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN)
			end,
			callback = function(dialog)
				local data = dialog.entryList:GetTargetData()
				if data.addonId and data.entryId then
					if data.isActive then
						libRadialWheelEntries[dialog.data.slotIndex] = { }
					else
						libRadialWheelEntries[dialog.data.slotIndex] = {
							entry = data.entryId,
							addon = data.addonId
						}
					end
					ZO_Dialogs_ReleaseDialogOnButtonPress("LibProfileAssignDialogue")
					if LibHarvensAddonSettings.list then
						LibHarvensAddonSettings.list:RefreshVisible()
					end
				end
			end,
		},
		{
			text = SI_DIALOG_EXIT,
			callback = function()
				ZO_Dialogs_ReleaseDialogOnButtonPress("LibProfileAssignDialogue")
			end
		}
	},
	blockDialogReleaseOnPress = true,
	parametricListOnSelectionChangedCallback = function(dialog)
		local data = dialog.entryList:GetTargetData()
		if data.addonName and data.icon then
			local headerData =
	        {
	            titleText = data.addonName,
	            messageText = string.format("|t27:27:%s|t %s\n\n%s", data.icon, data.name, data.description),
	            messageTextAlignment = TEXT_ALIGN_LEFT,
	        }
	        GAMEPAD_TOOLTIPS:ShowGenericHeader(GAMEPAD_LEFT_DIALOG_TOOLTIP, headerData)
			ZO_GenericGamepadDialog_ShowTooltip(dialog)
		else
			ZO_GenericGamepadDialog_HideTooltip(dialog)
		end
		
	end
}











--[[
	
	
	  ____   __________ __________ __________ _______      ___   ____     ____
	 6MMMMb\ `MMMMMMMMM MMMMMMMMMM MMMMMMMMMM `MM'`MM\     `M'  6MMMMb/  6MMMMb\
	6M'    `  MM      \ /   MM   \ /   MM   \  MM  MMM\     M  8P    YM 6M'    `
	MM        MM            MM         MM      MM  M\MM\    M 6M      Y MM
	YM.       MM    ,       MM         MM      MM  M \MM\   M MM        YM.
	 YMMMMb   MMMMMMM       MM         MM      MM  M  \MM\  M MM         YMMMMb
	     `Mb  MM    `       MM         MM      MM  M   \MM\ M MM     ___     `Mb
	      MM  MM            MM         MM      MM  M    \MM\M MM     `M'      MM
	      MM  MM            MM         MM      MM  M     \MMM YM      M       MM
	L    ,M9  MM      /     MM         MM      MM  M      \MM  8b    d9 L    ,M9
	MYMMMM9  _MMMMMMMMM    _MM_       _MM_    _MM__M_      \M   YMMMM9  MYMMMM9
	
	
	
]]



LibRadialMenu.settings = LibHarvensAddonSettings:AddAddon("Lib Radial Menu")
local settings = LibRadialMenu.settings



local getLabel = function(entryData, index)
	local entryAddon = registeredEntries[entryData.addon]
	if entryAddon and entryAddon[entryData.entry] and addonNames[entryData.addon] then
		local entry = entryAddon[entryData.entry]
		local addonName = addonNames[entryData.addon]
		local slotIcon = entry.icon or ""
		local slotname = entry.name or entryData.entry
		local description = entry.description
    	return string.format("Slot %d: |t27:27:%s|t %s", index, slotIcon, slotname)
	else
		return string.format("Slot %d:", index)
	end
end

local getTooltip = function(entryData)
	local entryAddon = registeredEntries[entryData.addon]
	if entryAddon and entryAddon[entryData.entry] and addonNames[entryData.addon] then
		local entry = entryAddon[entryData.entry]
		local addonName = addonNames[entryData.addon]
		local slotIcon = entry.icon or ""
		local slotname = entry.name or entryData.entry
		local description = entry.description
    	return string.format("%s\n\n|t27:27:%s|t %s\n\n%s", addonName, slotIcon, slotname, description)
	else
		return "Nothing is assigned to this slot yet!"
	end
end



function LibRadialMenu.UpdateSettingsMenu()
	settings:Clear()

	local settingsTable = {
		{
			type = LibHarvensAddonSettings.ST_SLIDER,
			label = "Amount of Slots",
			tooltip = "Set the amount of entries on the quickslot wheel.",
			setFunction = function(value)
				LibRadialMenu.vars.numSlots = value
			end,
			getFunction = function()
				return LibRadialMenu.vars.numSlots
			end,
			default = 12,
			min = 2,
			max = 25,
			step = 1,
		},
		{
		    type = LibHarvensAddonSettings.ST_BUTTON,
		    label = "Refresh Settings Menu",
		    tooltip = "After changing how many entries are present on the quickslot wheel, please press this button to update the below assignment buttons!",
			clickHandler = LibRadialMenu.UpdateSettingsMenu,
		},
		{
			type = LibHarvensAddonSettings.ST_SECTION,
			label = "Assign Slots",
		},
	}


	for i,v in pairs(LibRadialMenu.vars.slots) do
		if i > LibRadialMenu.vars.numSlots then
			LibRadialMenu.vars.slots[i] = nil
		end
	end

	for i=1,LibRadialMenu.vars.numSlots do
		if (type(LibRadialMenu.vars.slots[i]) ~= "table") then
			LibRadialMenu.vars.slots[i] = {}
		end
	end

	libRadialWheelEntries = LibRadialMenu.vars.slots

	for i=1,#libRadialWheelEntries do
		settingsTable[#settingsTable+1] = {
		    type = LibHarvensAddonSettings.ST_BUTTON,
		    label = function()
		    	return getLabel(libRadialWheelEntries[i], i)
		    end,
		    buttonText = GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN), 
		    tooltip = function()
		    	return getTooltip(libRadialWheelEntries[i])
		    end,
			clickHandler = function() ZO_Dialogs_ShowPlatformDialog("LibProfileAssignDialogue", {slotIndex=i}) end,
		}
	end
	settings:AddSettings(settingsTable)
	if LibHarvensAddonSettings.list then
		settings:CreateControls()
	end

end





LibRadialMenu:RegisterAddon("libradialmenu", "LibRadialMenu")
LibRadialMenu:RegisterEntry("libradialmenu", "Open Settings", "opensettings", "esoui/art/skillsadvisor/advisor_tabicon_settings_up.dds",
	function()
		if (LibHarvensAddonSettings.initialized ~= true) and (LibHarvensAddonSettings.scrollList == nil)  then
			LibHarvensAddonSettings:Initialize()
		end
		settings:Select()
		local headerData = {}
		headerData.titleText = settings.name
		headerData.subtitleText = settings.version
		headerData.messageText = zo_strformat(GetString(SI_ADD_ON_AUTHOR_LINE), "@M0R_Gaming")
		ZO_GamepadGenericHeader_RefreshData(LibHarvensAddonSettings.scrollList.header, headerData)
		SCENE_MANAGER:Push("LibHarvensAddonSettingsScene")
	end,
	"Opens the settings page for Lib Radial Menu.")




LibRadialMenu.name = "LibRadialMenu"


function LibRadialMenu.OnAddOnLoaded(event, addonName)

	if addonName ~= LibRadialMenu.name then return end

	LibRadialMenu:Initialize()
end
 

local defaultSettings = {
	numSlots = 12,
	slots = {}
}

-------------------------------------------------------------------------------------------------
--  Initialize Function --
-------------------------------------------------------------------------------------------------
function LibRadialMenu:Initialize()

	LibRadialMenu.vars = ZO_SavedVars:NewAccountWide("RadialMenuSlots", 1, nil, defaultSettings)

	if ZO_IsTableEmpty(LibRadialMenu.vars.slots) then -- insert default if first install
		LibRadialMenu.vars.slots[LibRadialMenu.vars.numSlots] = {addon="libradialmenu",entry="opensettings"}
	end

	libRadialWheelEntries = LibRadialMenu.vars.slots
	LibRadialMenu.UpdateSettingsMenu()

	EVENT_MANAGER:UnregisterForEvent(LibRadialMenu.name, EVENT_ADD_ON_LOADED)
end
 
-------------------------------------------------------------------------------------------------
--  Register Events --
-------------------------------------------------------------------------------------------------
EVENT_MANAGER:RegisterForEvent(LibRadialMenu.name, EVENT_ADD_ON_LOADED, LibRadialMenu.OnAddOnLoaded)