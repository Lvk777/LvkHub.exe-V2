-- LvkHub.exe RUNTIME HEALTH MONITOR V1
-- Safe diagnostics + recovery for LvkHub-owned runtime state only.
-- Does not modify remotes, server state, anti-cheat, game services, Humanoid values, or vehicle ownership.
return function(State, Registry, TargetProvider, UI)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local LP = Players.LocalPlayer
    local page = UI.Pages.Utility or UI.Pages.Local

    State.Utility = State.Utility or {}
    if State.Utility.RuntimeHealthEnabled == nil then State.Utility.RuntimeHealthEnabled = true end
    if State.Utility.RuntimeHealthAutoRepair == nil then State.Utility.RuntimeHealthAutoRepair = true end

    UI.Section(page, "RUNTIME HEALTH")
    UI.Toggle(page, "Runtime Health", function()
        return State.Utility.RuntimeHealthEnabled
    end, function(v)
        State.Utility.RuntimeHealthEnabled = v == true
    end)

    UI.Toggle(page, "Auto-repair LvkHub [SAFE]", function()
        return State.Utility.RuntimeHealthAutoRepair
    end, function(v)
        State.Utility.RuntimeHealthAutoRepair = v == true
    end)

    local _, coreLabel = UI.Row(page, "Core: checking...", 38)
    local _, targetLabel = UI.Row(page, "Targets: checking...", 38)
    local _, gameLabel = UI.Row(page, "Game paths: checking...", 42)
    local _, repairLabel = UI.Row(page, "Recovery: idle", 38)

    for _, label in ipairs({coreLabel, targetLabel, gameLabel, repairLabel}) do
        label.TextColor3 = Color3.fromRGB(145, 150, 170)
        label.TextSize = 11
        label.TextWrapped = true
    end

    local health = {
        Version = 1,
        Enabled = true,
        Checks = {},
        LastSnapshot = nil,
        LastRepair = nil,
        RepairCount = 0,
        ConsecutiveTargetFailures = 0,
    }
    shared.LvkHubRuntimeHealth = health

    local function safeCall(fn, ...)
        if type(fn) ~= "function" then return false, "missing function" end
        return pcall(fn, ...)
    end

    local function countPlayersWithCharacters()
        local n = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then n += 1 end
        end
        return n
    end

    local function findWeaponShotBuilder()
        local ps = LP and LP:FindFirstChild("PlayerScripts")
        if not ps then return nil end
        for _, d in ipairs(ps:GetDescendants()) do
            if d:IsA("ModuleScript") and d.Name == "WeaponShotBuilder" then
                return d
            end
        end
        return nil
    end

    local function currentWeapon()
        local ch = LP and LP.Character
        if not ch then return nil end
        for _, obj in ipairs(ch:GetChildren()) do
            if obj:IsA("Tool") and (obj:FindFirstChild("WeaponConfig") or obj:GetAttribute("InventoryManagedTool") == true) then
                return obj
            end
        end
        return nil
    end

    local function currentWeaponPathStatus()
        local tool = currentWeapon()
        if not tool then return "no weapon equipped", true end

        local cfg = tool:FindFirstChild("WeaponConfig")
        local ammo = tool:FindFirstChild("Ammo")
        local mag = ammo and ammo:FindFirstChild("MagAmmo")

        if not cfg then return tool.Name .. ": WeaponConfig missing", false end
        if not ammo then return tool.Name .. ": Ammo missing", false end
        if not mag or not mag:IsA("ValueBase") then return tool.Name .. ": Ammo.MagAmmo missing", false end
        return tool.Name .. ": weapon path ready", true
    end

    local function vehiclePathStatus()
        local folder = Workspace:FindFirstChild("Vehicles")
        if not folder then return "Workspace.Vehicles missing", false, 0 end
        local n = 0
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") then n += 1 end
        end
        return string.format("Vehicles ready (%d models)", n), true, n
    end

    local function targetHealth()
        local expected = countPlayersWithCharacters()
        local candidateCount = nil
        local targetCount = nil
        local regOK = type(Registry) == "table"
        local tpOK = type(TargetProvider) == "table"

        if regOK and type(Registry.CountCandidates) == "function" then
            local ok, value = pcall(Registry.CountCandidates)
            if ok then candidateCount = tonumber(value) end
        end

        if tpOK and type(TargetProvider.GetTargets) == "function" then
            local ok, list = pcall(TargetProvider.GetTargets)
            if ok and type(list) == "table" then targetCount = #list end
        end

        local healthy = regOK and tpOK and candidateCount ~= nil and targetCount ~= nil
        if expected > 0 and candidateCount == 0 then healthy = false end

        return {
            expected = expected,
            candidates = candidateCount,
            targets = targetCount,
            registry = regOK,
            provider = tpOK,
            healthy = healthy,
        }
    end

    local function coreHealth()
        local requiredRegistry = {
            "RefreshTargets", "GetCandidates", "IsCandidate", "CountCandidates", "RootOf", "HumanoidOf"
        }
        local requiredProvider = {
            "Rebuild", "GetTargets", "IsTarget", "RootOf", "HumanoidOf"
        }

        local missing = {}
        if type(Registry) ~= "table" then
            table.insert(missing, "Registry")
        else
            for _, name in ipairs(requiredRegistry) do
                if type(Registry[name]) ~= "function" then table.insert(missing, "Registry." .. name) end
            end
        end

        if type(TargetProvider) ~= "table" then
            table.insert(missing, "TargetProvider")
        else
            for _, name in ipairs(requiredProvider) do
                if type(TargetProvider[name]) ~= "function" then table.insert(missing, "TargetProvider." .. name) end
            end
        end

        if type(UI) ~= "table" or not UI.Gui or not UI.Main or not UI.Pages then
            table.insert(missing, "UI")
        end

        return #missing == 0, missing
    end

    local function snapshot()
        local coreOK, missing = coreHealth()
        local targets = targetHealth()
        local weaponText, weaponOK = currentWeaponPathStatus()
        local vehiclesText, vehiclesOK, vehicleCount = vehiclePathStatus()
        local shotBuilder = findWeaponShotBuilder()
        local hunger = LP and LP:GetAttribute("Hunger")
        local thirst = LP and LP:GetAttribute("Thirst")

        local data = {
            time = os.clock(),
            coreOK = coreOK,
            missing = missing,
            targets = targets,
            weapon = {ok = weaponOK, text = weaponText},
            weaponShotBuilder = shotBuilder and shotBuilder:GetFullName() or nil,
            vehicles = {ok = vehiclesOK, text = vehiclesText, count = vehicleCount},
            hungerPath = typeof(hunger) == "number",
            thirstPath = typeof(thirst) == "number",
            uiAlive = UI and UI.Gui and UI.Gui.Parent ~= nil or false,
        }

        health.LastSnapshot = data
        health.Checks = data
        return data
    end

    local function repairInternal(reason)
        local repaired = {}
        local errors = {}

        -- Restore shared reference if another local script cleared it.
        if shared.LvkHubTargetProvider ~= TargetProvider and type(TargetProvider) == "table" then
            shared.LvkHubTargetProvider = TargetProvider
            table.insert(repaired, "shared target provider")
        end

        if type(Registry) == "table" then
            if type(Registry.RefreshTargets) == "function" then
                local ok, err = pcall(Registry.RefreshTargets)
                if ok then table.insert(repaired, "registry targets") else table.insert(errors, tostring(err)) end
            elseif type(Registry.Refresh) == "function" then
                local ok, err = pcall(Registry.Refresh)
                if ok then table.insert(repaired, "registry") else table.insert(errors, tostring(err)) end
            end
        end

        if type(TargetProvider) == "table" and type(TargetProvider.Rebuild) == "function" then
            local ok, err = pcall(TargetProvider.Rebuild)
            if ok then table.insert(repaired, "target provider") else table.insert(errors, tostring(err)) end
        end

        health.RepairCount += 1
        health.LastRepair = {
            time = os.clock(),
            reason = reason or "manual",
            repaired = repaired,
            errors = errors,
        }

        return #errors == 0, repaired, errors
    end

    health.Snapshot = snapshot
    health.RepairInternal = repairInternal

    UI.Button(page, "Run health check", "CHECK", function(b)
        local data = snapshot()
        b.Text = data.coreOK and "OK" or "ISSUES"
        task.wait(.5)
        b.Text = "CHECK"
    end)

    UI.Button(page, "Repair LvkHub internals", "REPAIR", function(b)
        local ok = repairInternal("manual")
        b.Text = ok and "DONE" or "ISSUES"
        task.wait(.6)
        b.Text = "REPAIR"
    end)

    local function paint(data)
        if not State.Utility.RuntimeHealthEnabled then
            health.Enabled = false
            coreLabel.Text = "Core: monitor off"
            targetLabel.Text = "Targets: monitor off"
            gameLabel.Text = "Game paths: monitor off"
            repairLabel.Text = "Recovery: monitor off"
            return
        end

        health.Enabled = true

        if data.coreOK then
            coreLabel.Text = "Core: Registry + TargetProvider + UI ready"
            coreLabel.TextColor3 = Color3.fromRGB(80, 225, 125)
        else
            coreLabel.Text = "Core issue: " .. table.concat(data.missing or {}, ", ")
            coreLabel.TextColor3 = Color3.fromRGB(245, 80, 80)
        end

        local t = data.targets
        targetLabel.Text = string.format(
            "Targets: players %d • candidates %s • provider %s",
            t.expected or 0,
            t.candidates == nil and "n/a" or tostring(t.candidates),
            t.targets == nil and "n/a" or tostring(t.targets)
        )
        targetLabel.TextColor3 = t.healthy and Color3.fromRGB(80, 225, 125) or Color3.fromRGB(245, 170, 80)

        local shotText = data.weaponShotBuilder and "ShotBuilder OK" or "ShotBuilder missing"
        local survivalText = (data.hungerPath and data.thirstPath) and "Vitals paths OK" or "Vitals paths changed"
        gameLabel.Text = data.weapon.text .. " • " .. shotText .. " • " .. data.vehicles.text .. " • " .. survivalText
        gameLabel.TextColor3 = (data.weapon.ok and data.vehicles.ok and data.weaponShotBuilder)
            and Color3.fromRGB(80, 225, 125)
            or Color3.fromRGB(245, 170, 80)

        if health.LastRepair then
            repairLabel.Text = string.format(
                "Recovery: %d run(s) • last %s",
                health.RepairCount,
                tostring(health.LastRepair.reason or "unknown")
            )
        else
            repairLabel.Text = "Recovery: no repairs needed yet"
        end
        repairLabel.TextColor3 = Color3.fromRGB(145, 150, 170)
    end

    local timer = 0
    local autoTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        timer += dt
        autoTimer += dt
        if timer < .75 then return end
        timer = 0

        local data = snapshot()
        paint(data)

        if not State.Utility.RuntimeHealthEnabled then return end

        if data.targets.healthy then
            health.ConsecutiveTargetFailures = 0
        else
            health.ConsecutiveTargetFailures += 1
        end

        -- Conservative auto-recovery: only refresh LvkHub-owned caches after
        -- multiple consecutive failed checks. It never changes game/server state.
        if State.Utility.RuntimeHealthAutoRepair
            and health.ConsecutiveTargetFailures >= 3
            and autoTimer >= 3
        then
            autoTimer = 0
            repairInternal("target cache unhealthy")
            health.ConsecutiveTargetFailures = 0
        end
    end)

    Players.PlayerAdded:Connect(function()
        health.ConsecutiveTargetFailures = 0
    end)

    Players.PlayerRemoving:Connect(function()
        health.ConsecutiveTargetFailures = 0
    end)

    LP.CharacterAdded:Connect(function()
        health.ConsecutiveTargetFailures = 0
        task.delay(.75, function()
            if State.Utility.RuntimeHealthAutoRepair then
                repairInternal("character respawn")
            end
        end)
    end)

    task.defer(function()
        paint(snapshot())
    end)
end