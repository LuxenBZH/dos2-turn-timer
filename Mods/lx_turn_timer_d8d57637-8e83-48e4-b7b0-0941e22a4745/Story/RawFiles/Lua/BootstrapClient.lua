local function SetupTimer(call, arg1)
    local playerBar = Ext.GetBuiltinUI("Public/Game/GUI/statusConsole.swf")
    playerBar:Invoke("setTurnTimer", tonumber(arg1))
end

Ext.RegisterNetListener("LX_SetTurnTimer", SetupTimer)