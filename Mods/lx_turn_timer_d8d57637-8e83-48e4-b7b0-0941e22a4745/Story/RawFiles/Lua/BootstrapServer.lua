PersistentVars = {}
local paused = false

local function GetPersistentVar(var, fallbackValue)
    local variable = PersistentVars[var]
    if type(fallbackValue) == "number" then
        variable = tonumber(variable)
    end
    if variable == nil then variable = fallbackValue end
    return variable
end

local function GetTurnTime(isSummon)
    local turnTime = GetPersistentVar("turnTime", 60)
    local globalMultiplier = GetPersistentVar("globalMultiplier", 1)
    turnTime = math.floor(turnTime * globalMultiplier)
    if isSummon == 1 then
        local summonMultiplier = GetPersistentVar("summonTimeMultiplier", 0.5)
        turnTime = math.floor(turnTime * summonMultiplier)
    end
    local minimumTurnTime = GetPersistentVar("minimumTurnTime", 15)
    if turnTime < minimumTurnTime then turnTime = minimumTurnTime end
    return turnTime
end

local function SetTurnTimer(character, isBeginning)
    local isSummon = CharacterIsSummon(character)
    local isFollower = CharacterIsPartyFollower(character)
    if isSummon == 1 or isFollower == 1 then
        character = CharacterGetOwner(character)
    end
    if CharacterIsPlayer(character) == 0 then return end
    if isBeginning == 1 then
        local turnTime = GetTurnTime(isSummon)
        local rawBonus = GetVarInteger(character, "TMR_BonusRawTime")
        if rawBonus == nil then rawBonus = 0 end
        local multiplierBonus = GetVarFloat(character, "TMR_BonusMultiplierTime")
        if multiplierBonus == nil then multiplierBonus = 1 end
        turnTime = turnTime * multiplierBonus + rawBonus
        SetVarInteger(character, "LX_TimeRemaining", turnTime)
        Ext.PostMessageToClient(character, "LX_SetTurnTimer", tostring(turnTime))
    else
        local userID = Ext.GetCharacter(character).UserID
        if userID == -65536 and isSummon == 0 then TimerLaunch("LX_TurnCountdown", 1000); return end
        if paused then TimerLaunch("LX_TurnCountdown", 1000); return end
        local currentTime = GetVarInteger(character, "LX_TimeRemaining")
        SetVarInteger(character, "LX_TimeRemaining", currentTime-1)
        if currentTime-1 > -1 then
            Ext.PostMessageToClient(character, "LX_SetTurnTimer", tostring(currentTime-1))
            TimerLaunch("LX_TurnCountdown", 1000);
        else
            EndTurn(character)
        end
    end
end

local function TMR_OnSessionLoaded()
    Ext.Print("Turn Timer :",PersistentVars["turnTime"])
end

Ext.NewCall(SetTurnTimer, "LX_SetTurnTimer", "(GUIDSTRING)_Character, (INTEGER)_IsBeginning");
Ext.RegisterListener("SessionLoaded", TMR_OnSessionLoaded)

------ Console commands -------
local function ChangeTurnTime(time)
    PersistentVars["turnTime"] = tostring(time)
    print("Changed turn time to: "..time.." seconds.")
end

local function ChangeSummonTurnTimeMultiplier(multiplier)
    PersistentVars["summonTimeMultiplier"] = tostring(multiplier)
    print("Changed summon time multiplier to: "..multiplier)
end

local function PauseTimer()
    if not paused then
        paused = true
        print("Paused turn timer.")
    else
        paused = false
        print("Unpaused turn timer.")
    end
end

local function MinimumTurnTime(time)
    PersistentVars["minimumTurnTime"] = tostring(time)
    print("Changed minimum turn time to: ")
end

local function TMR_Help()
    print("Commands for Turn Timer mod :")
    print("- SetTurnTime <integer>              #Default : 60 | Change the turn time in seconds.")
    print("- PauseTimer                         #Pause the timer for all combats. Type the command again to unpause the timer.")
    print("- SetSummonTurnMultiplier <float>    #Default : 0.5 | Summons turn timer take the normal timer and multiply it by this value.")
    print("- SetMinimumTurnTime <integer>       #Default : 15 | Turn time cannot go below this value, even if the multipliers make it lower.")
end

local function TMR_consoleCmd(cmd, ...)
	local params = {...}
	for i=1,10,1 do
		local par = params[i]
		if par == nil then break end
		if type(par) == "string" then
			par = par:gsub("-", " ")
			par = par:gsub("\\ ", "-")
			params[i] = par
		end
	end
    if cmd == "SetTurnTime" then ChangeTurnTime(params[1]) end
    if cmd == "SetSummonTurnTimeMultiplier" then ChangeSummonTurnTimeMultiplier(params[1]) end
    if cmd == "PauseTimer" then PauseTimer() end
    if cmd == "SetMinimumTurnTime" then MinimumTurnTime(params[1]) end
    if cmd == "Help" then TMR_Help() end
end

Ext.RegisterConsoleCommand("SetTurnTime", TMR_consoleCmd)
Ext.RegisterConsoleCommand("SetSummonTurnTimeMultiplier", TMR_consoleCmd)
Ext.RegisterConsoleCommand("PauseTimer", TMR_consoleCmd)
Ext.RegisterConsoleCommand("SetMinimumTurnTime", TMR_consoleCmd)
Ext.RegisterConsoleCommand("TurnTimeMultiplier", TMR_consoleCmd)
Ext.RegisterConsoleCommand("Help", TMR_consoleCmd)
Ext.RegisterConsoleCommand("ChangePlayerTurnTime", TMR_consoleCmd)


