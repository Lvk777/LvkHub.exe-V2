-- LvkHub.exe SERVER STATE MONITOR V1
-- Read-only diagnostics for client-observed state changes.
-- This module does not modify Humanoid, root velocity, position, remotes, or game attributes.
return function(State, Registry, UI)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")

    local LP = Players.LocalPlayer
    local page = UI.Pages.Utility or UI.Pages.Local

    State.Utility = State.Utility or {}
    State.Utility.ServerMonitor = State.Utility.ServerMonitor == true

    UI.Section(page, "SERVER STATE MONITOR")
    UI.Toggle(page, "Server Monitor [READ ONLY]", function()
        return State.Utility.ServerMonitor
    end, function(v)
        State.Utility.ServerMonitor = v == true
    end)

    local _, wsLabel = UI.Row(page, "WalkSpeed: monitor off", 38)
    local _, motionLabel = UI.Row(page, "Motion: monitor off", 38)
    local _, stateLabel = UI.Row(page, "State: monitor off", 42)

    for _, label in ipairs({wsLabel, motionLabel, stateLabel}) do
        label.TextColor3 = Color3.fromRGB(145, 150, 170)
        label.TextSize = 11
        label.TextWrapped = true
    end

    local monitor = {
        Version = 1,
        Enabled = false,
        WalkSpeedCorrections = 0,
        LastWalkSpeedCorrection = nil,
        LastSnapshot = nil,
    }
    shared.LvkHubServerMonitor = monitor

    local humConnection = nil
    local currentHumanoid = nil
    local suppressUntil = 0
    local lastExpectedWalkSpeed = nil
    local lastObservedWalkSpeed = nil

    local function character()
        local ch = LP.Character
        if not ch then return nil, nil, nil end
        return ch, ch:FindFirstChildOfClass("Humanoid"), ch:FindFirstChild("HumanoidRootPart")
    end

    local function expectedWalkSpeed(hum)
        if not hum then return nil end
        if State.Movement and State.Movement.Speed then
            return tonumber(State.Movement.SpeedValue) or hum.WalkSpeed
        end
        return nil
    end

    local function expectedFlySpeed()
        if State.Movement and State.Movement.Fly then
            return math.max(10, tonumber(State.Movement.FlySpeed) or 65)
        end
        return nil
    end

    local function disconnectHumanoid()
        if humConnection then
            pcall(function() humConnection:Disconnect() end)
            humConnection = nil
        end
        currentHumanoid = nil
    end

    local function bindHumanoid(hum)
        if hum == currentHumanoid then return end
        disconnectHumanoid()
        currentHumanoid = hum
        if not hum then return end

        lastObservedWalkSpeed = hum.WalkSpeed
        humConnection = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if not State.Utility.ServerMonitor or not hum.Parent then return end

            local now = os.clock()
            local observed = hum.WalkSpeed
            local expected = expectedWalkSpeed(hum)
            local previous = lastObservedWalkSpeed
            lastObservedWalkSpeed = observed

            -- Only classify a correction while the LvkHub Speed feature is asking
            -- for a concrete value. This remains observational: no write is made.
            if expected and math.abs(observed - expected) > 0.05 and now >= suppressUntil then
                monitor.WalkSpeedCorrections += 1
                monitor.LastWalkSpeedCorrection = {
                    time = now,
                    expected = expected,
                    observed = observed,
                    previous = previous,
                }
                -- Debounce bursts caused by one replicated/state transition.
                suppressUntil = now + 0.12
            end
        end)
    end

    local function readVitals()
        local hunger = LP:GetAttribute("Hunger")
        local thirst = LP:GetAttribute("Thirst")
        local maxHunger = LP:GetAttribute("MaxHunger")
        local maxThirst = LP:GetAttribute("MaxThirst")
        return hunger, thirst, maxHunger, maxThirst
    end

    local function readAmmo(ch)
        if not ch then return nil end
        local tool = ch:FindFirstChildOfClass("Tool")
        if not tool then return nil end
        local ammo = tool:FindFirstChild("Ammo")
        local mag = ammo and ammo:FindFirstChild("MagAmmo")
        local pool = ammo and ammo:FindFirstChild("ArcadeAmmoPool")
        if not mag or not mag:IsA("ValueBase") then return {tool = tool.Name} end

        local magMax = nil
        pcall(function() magMax = mag.MaxValue end)
        local poolMax = nil
        if pool and pool:IsA("ValueBase") then pcall(function() poolMax = pool.MaxValue end) end

        return {
            tool = tool.Name,
            mag = tonumber(mag.Value),
            magMax = tonumber(magMax),
            pool = pool and pool:IsA("ValueBase") and tonumber(pool.Value) or nil,
            poolMax = tonumber(poolMax),
        }
    end

    local function snapshot()
        local ch, hum, root = character()
        if hum ~= currentHumanoid then bindHumanoid(hum) end

        local expectedWS = expectedWalkSpeed(hum)
        local observedWS = hum and hum.WalkSpeed or nil
        local requestedFly = expectedFlySpeed()
        local actualVelocity = root and root.AssemblyLinearVelocity or nil
        local actualSpeed = actualVelocity and actualVelocity.Magnitude or nil
        local hunger, thirst, maxHunger, maxThirst = readVitals()
        local ammo = readAmmo(ch)

        local data = {
            time = os.clock(),
            character = ch and ch:GetFullName() or nil,
            walkSpeedRequested = expectedWS,
            walkSpeedObserved = observedWS,
            walkSpeedCorrections = monitor.WalkSpeedCorrections,
            flyRequested = requestedFly,
            assemblyVelocity = actualVelocity,
            assemblySpeed = actualSpeed,
            hunger = tonumber(hunger),
            thirst = tonumber(thirst),
            maxHunger = tonumber(maxHunger),
            maxThirst = tonumber(maxThirst),
            ammo = ammo,
        }
        monitor.LastSnapshot = data
        return data
    end

    monitor.Snapshot = snapshot
    monitor.ResetCounters = function()
        monitor.WalkSpeedCorrections = 0
        monitor.LastWalkSpeedCorrection = nil
    end

    local function fmt(n, decimals)
        n = tonumber(n)
        if not n then return "n/a" end
        return string.format(decimals and "%.1f" or "%.0f", n)
    end

    local function paint(data)
        if not State.Utility.ServerMonitor then
            monitor.Enabled = false
            wsLabel.Text = "WalkSpeed: monitor off"
            motionLabel.Text = "Motion: monitor off"
            stateLabel.Text = "State: monitor off"
            return
        end

        monitor.Enabled = true

        if data.walkSpeedRequested then
            local mismatch = data.walkSpeedObserved and math.abs(data.walkSpeedObserved - data.walkSpeedRequested) > 0.05
            wsLabel.Text = string.format(
                "WalkSpeed requested %s • observed %s • corrections %d%s",
                fmt(data.walkSpeedRequested),
                fmt(data.walkSpeedObserved),
                data.walkSpeedCorrections or 0,
                mismatch and " • MISMATCH" or ""
            )
            wsLabel.TextColor3 = mismatch and Color3.fromRGB(245, 170, 80) or Color3.fromRGB(80, 225, 125)
        else
            wsLabel.Text = "WalkSpeed observed " .. fmt(data.walkSpeedObserved) .. " • Speed feature OFF"
            wsLabel.TextColor3 = Color3.fromRGB(145, 150, 170)
        end

        if data.flyRequested then
            motionLabel.Text = string.format(
                "Fly requested %s • observed assembly speed %s • diagnostic only",
                fmt(data.flyRequested),
                fmt(data.assemblySpeed, true)
            )
        else
            motionLabel.Text = "Motion observed " .. fmt(data.assemblySpeed, true) .. " • Fly OFF"
        end
        motionLabel.TextColor3 = Color3.fromRGB(145, 150, 170)

        local vitals = string.format(
            "Hunger %s/%s • Thirst %s/%s",
            fmt(data.hunger, true), fmt(data.maxHunger, true),
            fmt(data.thirst, true), fmt(data.maxThirst, true)
        )
        local ammoText = " • Ammo n/a"
        if data.ammo then
            if data.ammo.mag ~= nil then
                ammoText = string.format(
                    " • %s mag %s/%s",
                    tostring(data.ammo.tool or "weapon"),
                    fmt(data.ammo.mag), fmt(data.ammo.magMax)
                )
            else
                ammoText = " • " .. tostring(data.ammo.tool or "weapon") .. " ammo path n/a"
            end
        end
        stateLabel.Text = vitals .. ammoText
        stateLabel.TextColor3 = Color3.fromRGB(145, 150, 170)
    end

    local timer = 0
    RunService.Heartbeat:Connect(function(dt)
        timer += dt
        if timer < 0.20 then return end
        timer = 0
        paint(snapshot())
    end)

    LP.CharacterAdded:Connect(function()
        disconnectHumanoid()
        suppressUntil = os.clock() + 1
        task.delay(.25, function()
            local _, hum = character()
            bindHumanoid(hum)
        end)
    end)

    local _, initialHum = character()
    bindHumanoid(initialHum)
    task.defer(function() paint(snapshot()) end)
end