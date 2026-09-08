-- LvkHub.exe SOLO SESSION WEAPON MODS
-- Local/session weapon modifiers with live compatibility diagnostics.
return function(State, Registry, UI)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer
    local page = UI.Pages.Combat

    State.Combat.NoRecoil = State.Combat.NoRecoil == true
    State.Combat.InfiniteAmmo = State.Combat.InfiniteAmmo == true
    State.Combat.FastReload = State.Combat.FastReload == true
    State.Combat.FastReloadMultiplier = tonumber(State.Combat.FastReloadMultiplier) or 4

    local function SoloWeaponModsAllowed()
        return true
    end
    shared.LvkHubSoloWeaponModsAllowed = SoloWeaponModsAllowed

    UI.Section(page, "SOLO SESSION WEAPON MODS")
    local _, guardLabel = UI.Row(page, "WEAPON MODS: checking...")
    guardLabel.TextColor3 = Color3.fromRGB(255, 190, 85)
    local _, explain = UI.Row(page, "Client values may be validated separately by the server", 42)
    explain.TextWrapped = true
    explain.TextColor3 = Color3.fromRGB(150, 155, 170)
    explain.TextSize = 12

    UI.Toggle(page, "No Recoil [LOCAL]", function() return State.Combat.NoRecoil end, function(v) State.Combat.NoRecoil = v end)
    UI.Toggle(page, "Infinite Ammo [LOCAL]", function() return State.Combat.InfiniteAmmo end, function(v) State.Combat.InfiniteAmmo = v end)
    UI.Toggle(page, "Fast Reload [LOCAL]", function() return State.Combat.FastReload end, function(v) State.Combat.FastReload = v end)
    UI.Number(page, "Reload Mult.", function() return State.Combat.FastReloadMultiplier end, function(v)
        State.Combat.FastReloadMultiplier = math.clamp(tonumber(v) or 4, 1, 10)
    end, 1, 10)

    local _, ammoStatus = UI.Row(page, "Ammo: equip a weapon", 38)
    ammoStatus.TextColor3 = Color3.fromRGB(145, 150, 170)
    ammoStatus.TextSize = 11
    ammoStatus.TextWrapped = true

    local attrOriginal = {}
    local attrCaptured = {}
    local function captureAttr(name)
        if attrCaptured[name] then return end
        attrCaptured[name] = true
        attrOriginal[name] = { had = LP:GetAttribute(name) ~= nil, value = LP:GetAttribute(name) }
    end
    local function restoreAttr(name)
        if not attrCaptured[name] then return end
        local snap = attrOriginal[name]
        if snap and snap.had then LP:SetAttribute(name, snap.value) else LP:SetAttribute(name, nil) end
        attrCaptured[name] = nil
        attrOriginal[name] = nil
    end

    local ammoSnapshots = setmetatable({}, { __mode = "k" })
    local function snapshotValue(obj)
        if obj and ammoSnapshots[obj] == nil then ammoSnapshots[obj] = obj.Value end
    end
    local function restoreAmmoSnapshots()
        for obj, value in pairs(ammoSnapshots) do
            if obj and obj.Parent then pcall(function() obj.Value = value end) end
            ammoSnapshots[obj] = nil
        end
    end

    local function currentWeapon()
        local char = LP.Character
        if not char then return nil end
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") and (obj:FindFirstChild("WeaponConfig") or obj:GetAttribute("InventoryManagedTool") == true) then
                return obj
            end
        end
    end

    local function maxOf(valueObj)
        if not valueObj then return nil end
        local ok, max = pcall(function() return valueObj.MaxValue end)
        return ok and typeof(max) == "number" and max or nil
    end

    local function ammoObjects(tool)
        local ammo = tool and tool:FindFirstChild("Ammo")
        return ammo and ammo:FindFirstChild("MagAmmo"),
            ammo and ammo:FindFirstChild("ArcadeAmmoPool"),
            tool and tool:FindFirstChild("Chambered"),
            tool and tool:FindFirstChild("BoltReady")
    end

    local function applyInfiniteAmmo()
        local tool = currentWeapon()
        if not tool then return false end
        local mag, pool, chambered, boltReady = ammoObjects(tool)
        local touched = false

        if mag and mag:IsA("ValueBase") then
            snapshotValue(mag)
            local maximum = maxOf(mag)
            if maximum then
                local ok = pcall(function() mag.Value = maximum end)
                touched = touched or ok
            end
        end
        if pool and pool:IsA("ValueBase") then
            snapshotValue(pool)
            local maximum = maxOf(pool)
            if maximum then
                local ok = pcall(function() pool.Value = maximum end)
                touched = touched or ok
            end
        end
        if chambered and chambered:IsA("BoolValue") then
            snapshotValue(chambered)
            local ok = pcall(function() chambered.Value = true end)
            touched = touched or ok
        end
        if boltReady and boltReady:IsA("BoolValue") then
            snapshotValue(boltReady)
            local ok = pcall(function() boltReady.Value = true end)
            touched = touched or ok
        end
        return touched
    end

    local function restoreAllWeaponMods()
        restoreAttr("ProfessionBenefit_weaponRecoilMultiplier")
        restoreAttr("ProfessionBenefit_reloadSpeedMultiplier")
        restoreAmmoSnapshots()
    end

    local function updateStatus()
        local tool = currentWeapon()
        if not tool then
            guardLabel.Text = "WEAPON MODS: no equipped weapon"
            guardLabel.TextColor3 = Color3.fromRGB(245, 170, 80)
            ammoStatus.Text = "Ammo: equip a weapon"
            return
        end

        local mag, pool = ammoObjects(tool)
        if not mag or not mag:IsA("ValueBase") then
            guardLabel.Text = "WEAPON MODS: ammo path unavailable"
            guardLabel.TextColor3 = Color3.fromRGB(245, 80, 80)
            ammoStatus.Text = tool.Name .. " • Ammo.MagAmmo not found"
            return
        end

        guardLabel.Text = "WEAPON MODS: local weapon path ready"
        guardLabel.TextColor3 = Color3.fromRGB(80, 225, 125)
        local magMax = maxOf(mag)
        local poolMax = pool and pool:IsA("ValueBase") and maxOf(pool) or nil
        local text = string.format("%s • client mag %.0f/%s", tool.Name, tonumber(mag.Value) or 0, magMax and string.format("%.0f", magMax) or "?")
        if pool and pool:IsA("ValueBase") then
            text ..= string.format(" • pool %.0f/%s", tonumber(pool.Value) or 0, poolMax and string.format("%.0f", poolMax) or "?")
        end
        if State.Combat.InfiniteAmmo then
            text ..= " • LOCAL value only; server ammo may differ"
        end
        ammoStatus.Text = text
    end

    local wasAllowed = SoloWeaponModsAllowed()
    local timer = 0
    local statusTimer = 0
    updateStatus()

    RunService.Heartbeat:Connect(function(dt)
        timer += dt
        statusTimer += dt
        if timer < 0.06 then return end
        timer = 0

        local allowed = SoloWeaponModsAllowed()
        if allowed ~= wasAllowed then
            if not allowed then restoreAllWeaponMods() end
            wasAllowed = allowed
        end
        if not allowed then return end

        if State.Combat.NoRecoil then
            captureAttr("ProfessionBenefit_weaponRecoilMultiplier")
            if LP:GetAttribute("ProfessionBenefit_weaponRecoilMultiplier") ~= 0 then
                LP:SetAttribute("ProfessionBenefit_weaponRecoilMultiplier", 0)
            end
        else
            restoreAttr("ProfessionBenefit_weaponRecoilMultiplier")
        end

        if State.Combat.FastReload then
            captureAttr("ProfessionBenefit_reloadSpeedMultiplier")
            local wanted = math.clamp(tonumber(State.Combat.FastReloadMultiplier) or 4, 1, 10)
            if LP:GetAttribute("ProfessionBenefit_reloadSpeedMultiplier") ~= wanted then
                LP:SetAttribute("ProfessionBenefit_reloadSpeedMultiplier", wanted)
            end
        else
            restoreAttr("ProfessionBenefit_reloadSpeedMultiplier")
        end

        if State.Combat.InfiniteAmmo then
            applyInfiniteAmmo()
        elseif next(ammoSnapshots) ~= nil then
            restoreAmmoSnapshots()
        end

        if statusTimer >= .35 then
            statusTimer = 0
            updateStatus()
        end
    end)

    LP.CharacterAdded:Connect(function()
        restoreAmmoSnapshots()
        task.defer(updateStatus)
    end)
end
