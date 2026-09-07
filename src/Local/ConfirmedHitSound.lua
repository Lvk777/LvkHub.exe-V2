-- LvkHub.exe confirmed HitSound for the current WeaponSystem.
-- Feedback only: listens to the same ReplicateHit route used by WeaponReplication.

return function(State)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer

    local function findGunModule(name)
        local ps=LP:FindFirstChild("PlayerScripts")
        if not ps then return nil end
        local client=ps:FindFirstChild("Client")
        local systems=client and client:FindFirstChild("Systems")
        local gun=systems and systems:FindFirstChild("GunSystem")
        local exact=gun and gun:FindFirstChild(name)
        if exact and exact:IsA("ModuleScript") then return exact end
        for _,d in ipairs(ps:GetDescendants()) do
            if d:IsA("ModuleScript") and d.Name==name then return d end
        end
        return nil
    end

    local function currentWeapon()
        local ch=LP.Character
        if not ch then return nil end
        for _,obj in ipairs(ch:GetChildren()) do
            if obj:IsA("Tool") and obj:FindFirstChild("WeaponConfig") then return obj end
        end
        return nil
    end

    local sound=Instance.new("Sound")
    sound.Name="LvkHubConfirmedHitSound"
    sound.SoundId="rbxassetid://91546829095879"
    sound.Volume=.85
    sound.Parent=Workspace.CurrentCamera or Workspace

    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if Workspace.CurrentCamera then sound.Parent=Workspace.CurrentCamera end
    end)

    local connected=false
    local function tryConnect()
        if connected then return true end
        local mod=findGunModule("BridgeRegistry")
        if not mod then return false end
        local ok,bridge=pcall(require,mod)
        if not ok or type(bridge)~="table" then return false end
        local sig=bridge.ReplicateHit
        if not sig or type(sig.Connect)~="function" then return false end

        local ok2=pcall(function()
            sig:Connect(function(weapon,hitData)
                if not State.Local.HitSound then return end
                local active=currentWeapon()
                if not active or weapon~=active then return end
                if type(hitData)~="table" or typeof(hitData.Instance)~="Instance" then return end
                sound.TimePosition=0
                sound:Play()
            end)
        end)
        connected=ok2
        return connected
    end

    task.spawn(function()
        while not connected do
            tryConnect()
            task.wait(.75)
        end
    end)
end
