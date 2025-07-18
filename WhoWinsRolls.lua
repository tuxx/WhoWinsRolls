-- WhoWinsRolls Addon for WoW Classic 1.15.7 (Fixed Version)
-- Tracks roll wins and losses against a specific player (including item rolls)

local addonName, addon = ...
local frame = CreateFrame("Frame")

-- Initialize saved variables
WhoWinsRollsDB = WhoWinsRollsDB or {
    targetPlayer = "",
    wins = 0,
    losses = 0,
    ties = 0,
    totalRolls = 0,
    wonItems = {},
    lostItems = {},
}

-- Migration: ensure ties field exists for existing databases
if WhoWinsRollsDB.ties == nil then
    WhoWinsRollsDB.ties = 0
end

-- Migration: ensure item tracking fields exist for existing databases
if WhoWinsRollsDB.wonItems == nil then
    WhoWinsRollsDB.wonItems = {}
end
if WhoWinsRollsDB.lostItems == nil then
    WhoWinsRollsDB.lostItems = {}
end

-- Local variables
local targetPlayer = WhoWinsRollsDB.targetPlayer
local myRolls = {}
local otherRolls = {}
local isTracking = false
local lastRollTime = 0
local ROLL_TIMEOUT = 10 -- 10 seconds timeout for rolls to be considered related
local currentRollSession = {} -- Track current roll session
local currentItemRollSession = {} -- Track current item roll session
local isItemRoll = false -- Track if current session is for item rolls
local currentItem = "" -- Track the current item being rolled for
local lastReportTime = 0
local REPORT_COOLDOWN = 5


-- Function to update local targetPlayer from saved data
local function UpdateTargetPlayer()
    targetPlayer = WhoWinsRollsDB.targetPlayer
end

-- Function to print messages
local function Print(msg)
    print("|cFF00FF00[WhoWinsRolls]|r " .. msg)
end

-- Function to save data
local function SaveData()
    WhoWinsRollsDB.targetPlayer = targetPlayer
    WhoWinsRollsDB.wins = WhoWinsRollsDB.wins
    WhoWinsRollsDB.losses = WhoWinsRollsDB.losses
    WhoWinsRollsDB.ties = WhoWinsRollsDB.ties
    WhoWinsRollsDB.totalRolls = WhoWinsRollsDB.totalRolls
    WhoWinsRollsDB.wonItems = WhoWinsRollsDB.wonItems
    WhoWinsRollsDB.lostItems = WhoWinsRollsDB.lostItems
end

-- Function to normalize player name (case-insensitive)
local function NormalizePlayerName(name)
    if not name then return "" end
    return string.lower((name:gsub("%-.*", "")))
end

-- Function to create clickable item link
local function CreateItemLink(itemName)
    if not itemName then return itemName end
    local _, itemLink = GetItemInfo(itemName)
    return itemLink or ("[" .. itemName .. "]")
end

-- Function to display statistics
local function ShowStats()
    UpdateTargetPlayer() -- Ensure we have the latest saved data
    if targetPlayer == "" then
        Print("No target player set. Use /whowinsrolls <name> to set a target.")
        return
    end

    local winRate = 0
    if WhoWinsRollsDB.totalRolls > 0 then
        winRate = (WhoWinsRollsDB.wins / WhoWinsRollsDB.totalRolls) * 100
    end

    Print("Statistics vs " .. targetPlayer .. ":")
    Print("  Wins: " .. WhoWinsRollsDB.wins)
    Print("  Losses: " .. WhoWinsRollsDB.losses)
    Print("  Ties: " .. WhoWinsRollsDB.ties)
    Print("  Total Rolls: " .. WhoWinsRollsDB.totalRolls)
    Print("  Win Rate: " .. string.format("%.1f", winRate) .. "%")
end

-- Function to set target player
local function SetTargetPlayer(name)
    UpdateTargetPlayer() -- Ensure we have the latest saved data
    if name and name ~= "" then
        local normalizedName = NormalizePlayerName(name)
        local currentTarget = NormalizePlayerName(targetPlayer)

        if normalizedName ~= currentTarget then
            WhoWinsRollsDB.wins = 0
            WhoWinsRollsDB.losses = 0
            WhoWinsRollsDB.ties = 0
            WhoWinsRollsDB.totalRolls = 0
            WhoWinsRollsDB.wonItems = {}
            WhoWinsRollsDB.lostItems = {}
        end

        targetPlayer = name
        WhoWinsRollsDB.targetPlayer = targetPlayer
        Print("Now tracking rolls against: " .. targetPlayer)
        SaveData()
    else
        Print("Please provide a player name: /whowinsrolls <name>")
    end
end

local function ResetStats()
    UpdateTargetPlayer() -- Ensure we have the latest saved data
    WhoWinsRollsDB.wins = 0
    WhoWinsRollsDB.losses = 0
    WhoWinsRollsDB.ties = 0
    WhoWinsRollsDB.totalRolls = 0
    WhoWinsRollsDB.wonItems = {}
    WhoWinsRollsDB.lostItems = {}
    SaveData()
    Print("Statistics reset.")
end

-- Function to display item history
local function ShowItemHistory()
    UpdateTargetPlayer() -- Ensure we have the latest saved data
    if targetPlayer == "" then
        Print("No target player set. Use /whowinsrolls <name> to set a target.")
        return
    end

    Print("Item History vs " .. targetPlayer .. ":")
    
    if #WhoWinsRollsDB.wonItems == 0 and #WhoWinsRollsDB.lostItems == 0 then
        Print("  No items tracked yet.")
        return
    end

    if #WhoWinsRollsDB.wonItems > 0 then
        Print("  Items Won:")
        for i, itemData in ipairs(WhoWinsRollsDB.wonItems) do
            local dateStr = date("%Y-%m-%d %H:%M", itemData.timestamp)
            local itemLink = CreateItemLink(itemData.item)
            local msg = string.format("    |cFF00FF00%s|r - I won this (me: %d, %s: %d) [%s]",
                itemLink or itemData.item,
                itemData.myRoll or 0,
                targetPlayer,
                itemData.targetRoll or 0,
                dateStr)
            Print(msg)
        end
    end
    
    if #WhoWinsRollsDB.lostItems > 0 then
        Print("  Items Lost:")
        for i, itemData in ipairs(WhoWinsRollsDB.lostItems) do
            local dateStr = date("%Y-%m-%d %H:%M", itemData.timestamp)
            local itemLink = CreateItemLink(itemData.item)
            local msg = string.format("    |cFFFF0000%s|r - I lost this (me: %d, %s: %d) [%s]",
                itemLink or itemData.item,
                itemData.myRoll or 0,
                targetPlayer,
                itemData.targetRoll or 0,
                dateStr)
            Print(msg)
        end
    end
    
end

-- Function to send report to target player
local function SendReportToTarget()
    UpdateTargetPlayer()
    if targetPlayer == "" then
        Print("No target player set. Use /whowinsrolls <name> to set a target.")
        return
    end

    if (GetTime() - lastReportTime) < REPORT_COOLDOWN then
        Print("Please wait a few seconds before sending another report.")
        return
    end
    lastReportTime = GetTime()

    if #WhoWinsRollsDB.wonItems == 0 and #WhoWinsRollsDB.lostItems == 0 then
        SendChatMessage("[WhoWinsRolls] No items tracked yet.", "WHISPER", nil, targetPlayer)
        return
    end

    SendChatMessage("[WhoWinsRolls] Reporting items rolled", "WHISPER", nil, targetPlayer)

    for _, itemData in ipairs(WhoWinsRollsDB.wonItems) do
        local itemLink = CreateItemLink(itemData.item)
        local msg = string.format("  %s - I won this (me: %d, you: %d)",
            itemLink or itemData.item,
            itemData.myRoll or 0,
            itemData.targetRoll or 0)
        SendChatMessage(msg, "WHISPER", nil, targetPlayer)
    end

    for _, itemData in ipairs(WhoWinsRollsDB.lostItems) do
        local itemLink = CreateItemLink(itemData.item)
        local msg = string.format("  %s - I lost this (me: %d, you: %d)",
            itemLink or itemData.item,
            itemData.myRoll or 0,
            itemData.targetRoll or 0)
        SendChatMessage(msg, "WHISPER", nil, targetPlayer)
    end

    Print("Item report sent to " .. targetPlayer)
end


local function ClearRollTracking()
    local myRoll = currentItemRollSession[NormalizePlayerName(UnitName("player"))] or currentRollSession[NormalizePlayerName(UnitName("player"))]
    local targetRoll = currentItemRollSession[NormalizePlayerName(targetPlayer)] or currentRollSession[NormalizePlayerName(targetPlayer)]

    if isTracking and (myRoll or targetRoll) and not (myRoll and targetRoll) then
        Print("Roll tracking timed out – only one player rolled.")
    end

    myRolls = {}
    otherRolls = {}
    isTracking = false
    lastRollTime = 0
    currentRollSession = {}
    currentItemRollSession = {}
    isItemRoll = false
    currentItem = ""
end


local function TryParseItemRoll(message)
    local r, i, p
    r, i, p = message:match("Greed Roll %- (%d+) for (.+) by (.+)")
    if r then return tonumber(r), i, p end
    r, i, p = message:match("Need Roll %- (%d+) for (.+) by (.+)")
    if r then return tonumber(r), i, p end
    p, r, i = message:match("(.+) rolls (%d+) on (.+)")
    if p then return tonumber(r), i, p end
    p, r, i = message:match("(.+) rolls (%d+) for (.+)")
    if p then return tonumber(r), i, p end
    return nil
end

local function ProcessRollResults()
    UpdateTargetPlayer() -- Ensure we have the latest saved data
    if targetPlayer == "" then return end
    local rollSession = isItemRoll and currentItemRollSession or currentRollSession
    local myRoll = rollSession[NormalizePlayerName(UnitName("player"))]
    local targetRoll = rollSession[NormalizePlayerName(targetPlayer)]

    if myRoll and targetRoll then
        WhoWinsRollsDB.totalRolls = WhoWinsRollsDB.totalRolls + 1
        if myRoll > targetRoll then
            WhoWinsRollsDB.wins = WhoWinsRollsDB.wins + 1
            Print("WIN! You rolled " .. myRoll .. " vs " .. targetPlayer .. "'s " .. targetRoll)
            -- Track won item if this was an item roll
            if isItemRoll and currentItem ~= "" then
                table.insert(WhoWinsRollsDB.wonItems, {
                    item = currentItem,
                    timestamp = time(),
                    myRoll = myRoll,
                    targetRoll = targetRoll
                })
                Print("  Item won: " .. currentItem)
            end
        elseif myRoll < targetRoll then
            WhoWinsRollsDB.losses = WhoWinsRollsDB.losses + 1
            Print("LOSS! You rolled " .. myRoll .. " vs " .. targetPlayer .. "'s " .. targetRoll)
            -- Track lost item if this was an item roll
            if isItemRoll and currentItem ~= "" then
                table.insert(WhoWinsRollsDB.lostItems, {
                    item = currentItem,
                    timestamp = time(),
                    myRoll = myRoll,
                    targetRoll = targetRoll
                })

                Print("  Item lost: " .. currentItem)
            end
        else
            WhoWinsRollsDB.ties = WhoWinsRollsDB.ties + 1
            Print("TIE! Both rolled " .. myRoll)
        end
        SaveData()
    end
    ClearRollTracking()
end

local function SimulateItemRoll(myRoll, targetRoll, itemName)
    UpdateTargetPlayer()
    isItemRoll = true
    currentItem = itemName
    lastRollTime = GetTime()

    local myName = NormalizePlayerName(UnitName("player"))
    local target = NormalizePlayerName(targetPlayer)

    currentItemRollSession[myName] = tonumber(myRoll)
    currentItemRollSession[target] = tonumber(targetRoll)

    isTracking = true

    if myRoll and targetRoll then
        ProcessRollResults()
    end
end

frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:SetScript("OnEvent", function(self, event, message)
    local currentTime = GetTime()
    if lastRollTime > 0 and (currentTime - lastRollTime) > ROLL_TIMEOUT then
        ClearRollTracking()
    end

    if message:find("You have selected Greed for:") or message:find("You have selected Need for:") then
        isItemRoll = true
        lastRollTime = currentTime
        -- Try to extract item name from the message
        local item = message:match("You have selected Greed for: (.+)") or message:match("You have selected Need for: (.+)")
        if item then
            currentItem = item
        end
        return
    end

    local roll, item, player = TryParseItemRoll(message)
    if roll and player then
        isItemRoll = true
        local normName = NormalizePlayerName(player)
        currentItemRollSession[normName] = roll
        lastRollTime = currentTime
        
        -- Set the current item if we haven't already
        if currentItem == "" and item then
            currentItem = item
        end

        if normName == NormalizePlayerName(UnitName("player")) or normName == NormalizePlayerName(targetPlayer) then
            isTracking = true
        end

        local hasMyRoll = currentItemRollSession[NormalizePlayerName(UnitName("player"))] ~= nil
        local hasTargetRoll = currentItemRollSession[NormalizePlayerName(targetPlayer)] ~= nil
        if isTracking and hasMyRoll and hasTargetRoll then
            ProcessRollResults()
        end
        return
    end

    local p, r = message:match("(.+) rolls (%d+) %((%d+)%-(%d+)%)")
    if p and r then
        local normName = NormalizePlayerName(p)
        currentRollSession[normName] = tonumber(r)
        lastRollTime = currentTime

        if normName == NormalizePlayerName(UnitName("player")) or normName == NormalizePlayerName(targetPlayer) then
            isTracking = true
        end

        local hasMyRoll = currentRollSession[NormalizePlayerName(UnitName("player"))] ~= nil
        local hasTargetRoll = currentRollSession[NormalizePlayerName(targetPlayer)] ~= nil
        if isTracking and hasMyRoll and hasTargetRoll then
            ProcessRollResults()
        end
    end
end)

SLASH_WHOWINSROLLS1 = "/whowinsrolls"
SLASH_WHOWINSROLLS2 = "/wwr"

SlashCmdList["WHOWINSROLLS"] = function(msg)
    local command, arg = strsplit(" ", msg, 2)
    if command == "" then
        ShowStats()
    elseif command == "reset" then
        ResetStats()
    elseif command == "items" then
        ShowItemHistory()
    elseif command == "report" then
        SendReportToTarget()
    elseif command == "help" then
        Print("Commands:")
        Print("/whowinsrolls <name> - Set target player to track")
        Print("/whowinsrolls - Show current statistics")
        Print("/whowinsrolls items - Show item win/loss history")
        Print("/whowinsrolls report - Send statistics to target player")
        Print("/whowinsrolls reset - Reset all statistics")
        Print("/whowinsrolls help - Show this help")
    elseif command == "testgreed" and arg then
        local item, myRoll, targetRoll = arg:match("(.+)%s+(%d+)%s+(%d+)")
        if item and myRoll and targetRoll then
            SimulateItemRoll(tonumber(myRoll), tonumber(targetRoll), item)
        else
            Print("Usage: /wwr testgreed <item name> <your roll> <target roll>")
        end
    else
        SetTargetPlayer(command)
    end
end

Print("WhoWinsRolls loaded. Type /whowinsrolls <name> to start tracking rolls against a player.")
UpdateTargetPlayer()
