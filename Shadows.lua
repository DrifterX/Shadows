--[[
* Addons - Copyright (c) 2021 Ashita Development Team
* Contact: https://www.ashitaxi.com/
* Contact: https://discord.gg/Ashita
*
* This file is part of Ashita.
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.
--]]

addon.name      = 'Shadows';
addon.author    = 'Drakeson';
addon.version   = '1.0';
addon.desc      = 'Displays remaining shadows and CD for Utsusemi.';
addon.link      = 'https://ashitaxi.com/';

require('common');
local settings  = require('settings');
local imgui     = require('imgui');
local fonts     = require('fonts');
-- local scaling   = require('scaling');

local defaultConfig = T{
};

local shadows = T{
    settings = settings.load(defaultConfig)
}

local ichiRecast = {
    timer = '00:00',
    color = {0.0, 1.0, 0.0, 1.0},
    remainingTime = 0,
    recastTime = 0,
};
local niRecast = {
    timer = '00:00',
    color = {0.0, 1.0, 0.0, 1.0},
    remainingTime = 0,
    recastTime = 0,
};

local colorConverter = imgui.ColorConvertU32ToFloat4;

local colors = T{
    redColor = {colorConverter(250), colorConverter(15), colorConverter(15), 1.0},
    orangeColor = {colorConverter(255), colorConverter(127), colorConverter(0), 1.0},
    yellowColor = {colorConverter(255), colorConverter(255), colorConverter(0), 1.0},
    greenColor = {colorConverter(36), colorConverter(252), colorConverter(3), 1.0},
    whiteColor = {1.0, 1.0, 1.0, 1.0},
}

-- local config = settings.load(defaultConfig);

-- resMgr = AshitaCore:GetResourceManager();

local function formatTimestamp(timer, maxTime)
    -- Timer is based on FPS, one tick of the timer is 1/60th of a second
    local timerInMilliseconds = timer * 50/3
    local timerInSeconds = timer / 60;
    local timerInMinutes = timer / 3600;
    local timerInHours = timer / 216000;
    local hours = math.floor(timerInHours);
    local minutes = math.floor(timerInMinutes - (hours * 60));
    local seconds = math.floor(timerInSeconds - (minutes + (hours * 60)) * 60)
    local displaySeconds = math.ceil(timerInSeconds - (minutes + (hours * 60)) * 60)
    local milliseconds = math.ceil(timerInMilliseconds -  ((seconds * 1000) + (minutes * 60000) + (hours * 60^2 * 1000)));
    local millisecondsFormatted = milliseconds / 10;
    local returnValue = {
        timer = '',
        color = {0, 0, 0, 0},
        remainingTime = 0,
        recastTime = 0,
    }
    if(seconds >= 10) then
        returnValue.timer = ('%0.2i:%0.2i'):fmt(minutes, displaySeconds);
        -- 245, 15, 15
        returnValue.color = colors.redColor;
    elseif (timer > 0 and seconds < 10) then
        returnValue.timer = ('%0.2i.%0.0f'):fmt(seconds, millisecondsFormatted);
        returnValue.color = colors.yellowColor;
    else
        returnValue.timer = '00:00'
        returnValue.color = colors.greenColor;
    end
    returnValue.remainingTime = timer / maxTime;
    returnValue.recastTime = maxTime;
    return returnValue
end

local function getShadowCount()
    local me = AshitaCore:GetMemoryManager():GetPlayer()
    local buffs = me:GetBuffs()
    for _, buff in pairs(buffs) do
        if buff == 66 then
            return {
                shadows = 1,
                color = colors.orangeColor;
            }
        elseif buff == 67 then
            return {
                shadows = 2,
                color = colors.yellowColor;
            };
        elseif buff == 444 then
            return {
                shadows = 2,
                -- 231, 247, 5
                color = colors.yellowColor;
            };
        elseif buff == 445 then
            return {
                shadows = 3,
                color = colors.whiteColor;
            };
        elseif buff == 446 then
            return {
                shadows = 4,
                color = colors.whiteColor;
            };
        else
            return{
                shadows = 0,
                -- 245, 15, 15
                color = colors.redColor;
            };
        end
    end
end

local function getRecastTimer(spell, recastTime)
    local myRecastTimer  = AshitaCore:GetMemoryManager():GetRecast();
    local myAshitaResourceMgr = AshitaCore:GetResourceManager();
    for x = 0, 1024 do
        local id = x;
        local timer = myRecastTimer:GetSpellTimer(id);
        local spellResource = myAshitaResourceMgr:GetSpellById(id);
        local spellName;
        if(spellResource ~= nil) then
            spellName = spellResource.Name[1]
        end
        if (spellName == spell)  and (timer > 0) then
            if (timer > recastTime) then
                recastTime = timer
            end
            return formatTimestamp(timer, recastTime);
        end
    end
    return {
        timer = '00:00',
        color = colors.greenColor,
        remainingTime = 0,
        recastTime = 0,
    };
end

local function getRemainingTools()
    local inventory = AshitaCore:GetMemoryManager():GetInventory();
    local itemCount = T{
        numberOfItems = 0,
        color = colors.redColor,
    };

    for invSlot = 0,inventory:GetContainerCountMax(0) do
        local item = inventory:GetContainerItem(0, invSlot);
        if ((item ~= nil) and (item.Id == 1179)) then
            itemCount.numberOfItems = itemCount.numberOfItems + item.Count;
        end
    end
    if (itemCount.numberOfItems > 25) then
        itemCount.color = colors.whiteColor;
    elseif (itemCount.numberOfItems > 20) then
        itemCount.color = colors.yellowColor;
    elseif (itemCount.numberOfItems > 10) then
        itemCount.color = colors.orangeColor;
    end
    return itemCount;
end

--[[
* Registers a callback for the settings to monitor for character switches.
--]]
settings.register('settings', 'settings_update', function (s)
    if (s ~= nil) then
        shadows.settings = s;
    end

    -- Apply the font settings..
    if (shadows.font ~= nil) then
        shadows.font:apply(shadows.settings.font);
    end

    settings.save();
end);

--[[
* event: load
* desc : Event called when the addon is being loaded.
--]]
ashita.events.register('load', 'load_cb', function ()
    shadows.font = fonts.new(shadows.settings)

end);

--[[
* event: unload
* desc : Event called when the addon is being unloaded.
--]]
ashita.events.register('unload', 'unload_cb', function ()
    if (shadows.font ~= nil) then
        shadows.font:destroy();
        shadows.font = nil;
    end

    settings.save();
end);

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/shadows')) then
        return;
    end
end)

ashita.events.register('d3d_present', 'shadows_preset', function ()
    local character = AshitaCore:GetMemoryManager():GetPlayer();
    if(character:GetMainJob() ~= 13) and (character:GetSubJob() ~= 13) then
        return
    end
    shadows.settings.font.positionX = shadows.font.positionX;
    shadows.settings.font.positionY = shadows.font.positionY;

    local player = GetPlayerEntity();
	if (player == nil) then -- when zoning
		return;
	end
    --local windowSize = {300, 140};
    local windowSize = {123, 140};
    imgui.SetNextWindowBgAlpha(0.9);
    imgui.SetNextWindowSize(windowSize, ImGuiCond_Always);
    if (imgui.Begin('Shadows', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then
        local shadowCount = getShadowCount();
        ichiRecast = getRecastTimer("Utsusemi: Ichi", ichiRecast.recastTime);
        niRecast = getRecastTimer("Utsusemi: Ni", niRecast.recastTime);
        local toolsRemaining = getRemainingTools();
        imgui.SetWindowFontScale(3.3);
        --imgui.Text("Index ".. tostring(itemName.Id) .. " Container: " .. tostring(container))
        imgui.SetCursorPosX(50); imgui.TextColored(shadowCount.color, "" .. tostring(shadowCount.shadows));
        --imgui.Text("   " .. tostring(shadowCount));
        imgui.Separator();
        imgui.SetWindowFontScale(1.2);
        imgui.PushStyleColor(ImGuiCol_PlotHistogram, {0.0, 0.7, 0.0, 0.4});
        imgui.ProgressBar(ichiRecast.remainingTime, {-1.0, 0} ,""); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("  "));
        imgui.TextColored(ichiRecast.color, "Ichi: " .. tostring(ichiRecast.timer));
        imgui.ProgressBar(niRecast.remainingTime, {-1.0, 0} ,""); imgui.SameLine(); imgui.SetCursorPosX(imgui.CalcTextSize("  "));
        imgui.TextColored(niRecast.color, "Ni:   " .. tostring(niRecast.timer))
        imgui.PopStyleColor(1);
        imgui.Separator();
        imgui.Text("  Shihei: "); imgui.SameLine(); imgui.SetCursorPosX(86); -- imgui.CalcTextSize("  Shihei: ") = 84
        imgui.TextColored(toolsRemaining.color, "".. tostring(toolsRemaining.numberOfItems));
    end
    imgui.End();
end)