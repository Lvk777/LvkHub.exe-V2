-- Reliable local TestPlayers hit sound. No real-player targeting or damage.
-- This is the single HitSound playback owner for the current loader.
-- ALTERADO: agora observa Players reais.
return function(State, Registry, UI)
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")

    local function removeLegacySounds(parent)
        if not parent then return end
        for _, name in ipairs({ "LvkHubHitSoundV2", "LvkHubHitSoundV3", "LvkHubHitSoundV4", "LvkHubDummyHitSoundV2" }) do
            local old = parent:FindFirstChild(name)
            if old then pcall(function() old:Destroy() end) end
        end
    end

    removeLegacySounds(Workspace.CurrentCamera)
    removeLegacySounds(Workspace)

    local sound = Instance.new("Sound")
    sound.Name = "LvkHubDummyHitSoundV2"
    sound.SoundId = "rbxassetid://91546829095879"
    sound.Volume = .85
    sound.Parent = Workspace.CurrentCamera or Workspace

    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if Workspace.CurrentCamera then
            removeLegacySounds(Workspace.CurrentCamera)
            sound.Parent = Workspace.CurrentCamera
        end
    end)

    local lastPlay = 0
    local function play()
        if not State.Local.HitSound then return end
        local now = os.clock()
        -- Adapter feedback + health fallback can observe the same practice hit.
        -- One debounce prevents the same hit from sounding twice.
        if now - lastPlay < .09 then return end
        lastPlay = now
        if Workspace.CurrentCamera and sound.Parent ~= Workspace.CurrentCamera then sound.Parent = Workspace.CurrentCamera end
        pcall(function()
            sound.TimePosition = 0
            sound:Play()
        end)
    end

    shared.LvkHubPlayHitSound = play

    local health = setmetatable({}, { __mode = "k" })
    local timer = 0
    RunService.Heartbeat:Connect(function(dt)
        timer = timer + dt
        if timer < .04 then return end
        timer = 0
        if not State.Local.HitSound then return end
        -- ALTERADO: varre Players reais
        for _, plr in ipairs(Players:GetPlayers()) do
            local model = plr.Character
            if model and Registry.IsBot(model) then
                local hum = Registry.HumanoidOf(model)
                if hum then
                    local prev = health[hum]
                    if prev ~= nil and hum.Health < prev then play() end
                    health[hum] = hum.Health
                end
            end
        end
    end)
end
