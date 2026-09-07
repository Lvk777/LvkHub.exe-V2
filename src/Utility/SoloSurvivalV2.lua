-- LvkHub.exe SOLO SURVIVAL V2
-- One-shot refill: activation writes the real local hunger/thirst values once.
-- Turning the toggle OFF does not restore the old value. Any write is hard-blocked
-- while another Player is present.
-- ALTERADO: agora sempre permitido.
return function(State, Registry, UI)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer
    local Restrictions = shared.LvkHubRestrictions
    local page = UI.Pages.Utility

    State.Utility.FullHunger = State.Utility.FullHunger == true
    State.Utility.FullThirst = State.Utility.FullThirst == true

    local function soloAllowed()
        -- ALTERADO: sempre true
        return true
    end

    UI.Section(page, "SOLO SURVIVAL")
    local _, guard = UI.Row(page, "SURVIVAL GUARD: checking...", 38)
    guard.TextColor3 = Color3.fromRGB(255, 190, 85)
    UI.Toggle(page, "Full Hunger [SOLO]", function() return State.Utility.FullHunger end, function(v) State.Utility.FullHunger = v end)
    UI.Toggle(page, "Full Thirst [SOLO]", function() return State.Utility.FullThirst end, function(v) State.Utility.FullThirst = v end)
    local _, status = UI.Row(page, "One-shot refill • OFF keeps value", 38)
    status.TextColor3 = Color3.fromRGB(145, 150, 170)
    status.TextSize = 11

    local hungerNames = { hunger = true, food = true, satiety = true, calories = true, hungervalue = true }
    local thirstNames = { thirst = true, water = true, hydration = true, thirstvalue = true }

    local valueSnaps = setmetatable({}, { __mode = "k" })
    local attrSnaps = setmetatable({}, { __mode = "k" })
    local armedH = false
    local armedT = false
    local lastCounts = { hunger = 0, thirst = 0 }

    local function normalize(s)
        return tostring(s):lower():gsub("[%s_%-]", "")
    end

    local function classify(name)
        local n = normalize(name)
        if hungerNames[n] then return "hunger" end
        if thirstNames[n] then return "thirst" end
        return nil
    end

    local function fullValue(obj, current)
        local ok, max = pcall(function() return obj.MaxValue end)
        if ok and typeof(max) == "number" and max > 0 then return max end
        current = tonumber(current) or 0
        if current >= 0 and current <= 1.01 then return 1 end
        if current <= 100 then return 100 end
        return current
    end

    local function attrMax(inst, name, current)
        local candidates = { "Max" .. name, name .. "Max", "Max_" .. name, name .. "_Max" }
        for _, k in ipairs(candidates) do
            local v = inst:GetAttribute(k)
            if typeof(v) == "number" and v > 0 then return v end
        end
        current = tonumber(current) or 0
        if current >= 0 and current <= 1.01 then return 1 end
        if current <= 100 then return 100 end
        return current
    end

    local function roots()
        local list = { LP }
        if LP.Character then table.insert(list, LP.Character) end
        return list
    end

    local function snapshotValue(obj, kind)
        if valueSnaps[obj] == nil then valueSnaps[obj] = { kind = kind, value = obj.Value } end
    end

    local function snapshotAttr(inst, name, kind, value)
        attrSnaps[inst] = attrSnaps[inst] or {}
        if attrSnaps[inst][name] == nil then
            attrSnaps[inst][name] = { kind = kind, had = inst:GetAttribute(name) ~= nil, value = value }
        end
    end

    local function restoreAll()
        for obj, s in pairs(valueSnaps) do
            if obj and obj.Parent then pcall(function() obj.Value = s.value end) end
            valueSnaps[obj] = nil
        end
        for inst, map in pairs(attrSnaps) do
            if inst and inst.Parent then
                for name, s in pairs(map) do
                    pcall(function()
                        if s.had then inst:SetAttribute(name, s.value) else inst:SetAttribute(name, nil) end
                    end)
                end
            end
            attrSnaps[inst] = nil
        end
    end

    -- Turning OFF commits the one-shot refill: forget the old snapshot without restoring it.
    local function commitKind(kind)
        for obj, s in pairs(valueSnaps) do
            if s.kind == kind then valueSnaps[obj] = nil end
        end
        for inst, map in pairs(attrSnaps) do
            for name, s in pairs(map) do
                if s.kind == kind then map[name] = nil end
            end
            if next(map) == nil then attrSnaps[inst] = nil end
        end
    end

    local function scanCounts()
        local counts = { hunger = 0, thirst = 0 }
        for _, root in ipairs(roots()) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("ValueBase") and typeof(obj.Value) == "number" then
                    local kind = classify(obj.Name)
                    if kind then counts[kind] = counts[kind] + 1 end
                end
            end
            for name, value in pairs(root:GetAttributes()) do
                if typeof(value) == "number" then
                    local kind = classify(name)
                    if kind then counts[kind] = counts[kind] + 1 end
                end
            end
        end
        lastCounts = counts
        return counts
    end

    local function applyKind(kind)
        if not soloAllowed() then return 0 end
        local changed = 0
        for _, root in ipairs(roots()) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("ValueBase") and typeof(obj.Value) == "number" and classify(obj.Name) == kind then
                    snapshotValue(obj, kind)
                    local wanted = fullValue(obj, obj.Value)
                    if obj.Value ~= wanted then
                        local ok = pcall(function() obj.Value = wanted end)
                        if ok then changed = changed + 1 end
                    else
                        changed = changed + 1
                    end
                end
            end
            for name, value in pairs(root:GetAttributes()) do
                if typeof(value) == "number" and classify(name) == kind then
                    snapshotAttr(root, name, kind, value)
                    local wanted = attrMax(root, name, value)
                    if value ~= wanted then
                        local ok = pcall(function() root:SetAttribute(name, wanted) end)
                        if ok then changed = changed + 1 end
                    else
                        changed = changed + 1
                    end
                end
            end
        end
        return changed
    end

    local timer = 0
    local countTimer = 0
    local wasAllowed = soloAllowed()

    RunService.Heartbeat:Connect(function(dt)
        timer = timer + dt
        countTimer = countTimer + dt
        if timer < .08 then return end
        timer = 0

        local allowed = soloAllowed()
        if allowed then
            guard.Text = "SURVIVAL GUARD: READY • only LocalPlayer"
            guard.TextColor3 = Color3.fromRGB(80, 225, 125)
        else
            guard.Text = "SURVIVAL GUARD: BLOCKED • another Player present"
            guard.TextColor3 = Color3.fromRGB(245, 80, 80)
        end

        if countTimer >= .75 then
            countTimer = 0
            local c = scanCounts()
            status.Text = string.format("One-shot • hunger %d • thirst %d", c.hunger, c.thirst)
        end

        if not allowed then
            if wasAllowed and (next(valueSnaps) ~= nil or next(attrSnaps) ~= nil) then restoreAll() end
            armedH = false
            armedT = false
            wasAllowed = false
            return
        end

        if State.Utility.FullHunger then
            if not armedH then
                local n = applyKind("hunger")
                armedH = true
                status.Text = "Hunger refilled: " .. tostring(n) .. " source(s)"
            end
        else
            if armedH then commitKind("hunger") end
            armedH = false
        end

        if State.Utility.FullThirst then
            if not armedT then
                local n = applyKind("thirst")
                armedT = true
                status.Text = "Thirst refilled: " .. tostring(n) .. " source(s)"
            end
        else
            if armedT then commitKind("thirst") end
            armedT = false
        end

        wasAllowed = true
    end)

    -- Removemos restrições em PlayerAdded
    Players.PlayerAdded:Connect(function(p)
        -- não faz nada
    end)

    LP.CharacterAdded:Connect(function()
        valueSnaps = setmetatable({}, { __mode = "k" })
        attrSnaps = setmetatable({}, { __mode = "k" })
        armedH = false
        armedT = false
    end)
end
