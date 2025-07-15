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
}

-- Migration: ensure ties field exists for existing databases
if WhoWinsRollsDB.ties == nil then
    WhoWinsRollsDB.ties = 0
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
end

-- Function to normalize player name (case-insensitive)
local function NormalizePlayerName(name)
    if not name then return "" end
    return string.lower((name:gsub("%-.*", "")))
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
    SaveData()
    Print("Statistics reset.")
end

local function ClearRollTracking()
    myRolls = {}
    otherRolls = {}
    isTracking = false
    lastRollTime = 0
    currentRollSession = {}
    currentItemRollSession = {}
    isItemRoll = false
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
        elseif myRoll < targetRoll then
            WhoWinsRollsDB.losses = WhoWinsRollsDB.losses + 1
            Print("LOSS! You rolled " .. myRoll .. " vs " .. targetPlayer .. "'s " .. targetRoll)
        else
            WhoWinsRollsDB.ties = WhoWinsRollsDB.ties + 1
            Print("TIE! Both rolled " .. myRoll)
        end
        SaveData()
    end
    ClearRollTracking()
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
        return
    end

    local roll, item, player = TryParseItemRoll(message)
    if roll and player then
        isItemRoll = true
        local normName = NormalizePlayerName(player)
        currentItemRollSession[normName] = roll
        lastRollTime = currentTime

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
    elseif command == "help" then
        Print("Commands:")
        Print("/whowinsrolls <name> - Set target player to track")
        Print("/whowinsrolls - Show current statistics")
        Print("/whowinsrolls reset - Reset all statistics")
        Print("/whowinsrolls help - Show this help")
    else
        SetTargetPlayer(command)
    end
end

Print("WhoWinsRolls loaded. Type /whowinsrolls <name> to start tracking rolls against a player.")
UpdateTargetPlayer()
