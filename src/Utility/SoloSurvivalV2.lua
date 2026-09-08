-- LvkHub.exe SOLO SURVIVAL V2
-- Client-side refill helper with live authority diagnostics.
return function(State, Registry, UI)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer
    local page = UI.Pages.Utility

    State.Utility.FullHunger = State.Utility.FullHunger == true
    State.Utility.FullThirst = State.Utility.FullThirst == true

    local function soloAllowed()
        return true
    end

    UI.Section(page, "SOLO SURVIVAL")
    local _, guard = UI.Row(page, "SURVIVAL: checking local values...", 38)
    guard.TextColor3 = Color3.fromRGB(255, 190, 85)
    UI.Toggle(page, "Full Hunger [SOLO]", function() return State.Utility.FullHunger end, function(v) State.Utility.FullHunger = v end)
    UI.Toggle(page, "Full Thirst [SOLO]", function() return State.Utility.FullThirst end, function(v) State.Utility.FullThirst = v end)
    local _, status = UI.Row(page, "Local values • monitoring authority", 42)
    status.TextColor3 = Color3.fromRGB(145, 150, 170)
    status.TextSize = 11
    status.TextWrapped = true

    local hungerNames = { hunger = true, food = true, satiety = true, calories = true, hungervalue = true }
    local thirstNames = { thirst = true, water = true, hydration = true, thirstvalue = true }

    local valueSnaps = setmetatable({}, { __mode = "k" })
    local attrSnaps = setmetatable({}, { __mode = "k" })
    local armedH = false
    local armedT = false
    local attemptedH = 0
    local attemptedT = 0

    local function normalize(s)
        return tostring(s):lower():gsub("[%s_%-]", "")
    end

    local function classify(name)
        local n = normalize(name)
        if hungerNames[n] then return "hunger" end
        if thirstNames[n] then return "thirst" end
        return nil
    end

    local function roots()
        local list = { LP }
        if LP.Character then table.insert(list, LP.Character) end
        return list
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

    local function snapshotValue(obj, kind)
        if valueSnaps[obj] == nil then valueSnaps[obj] = { kind = kind, value = obj.Value } end
    end

    local function snapshotAttr(inst, name, kind, value)
        attrSnaps[inst] = attrSnaps[inst] or {}
        if attrSnaps[inst][name] == nil then
            attrSnaps[inst][name] = { kind = kind, had = inst:GetAttribute(name) ~= nil, value = value }
        end
    end

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

    local function applyKind(kind)
        if not soloAllowed() then return 0 end
        local changed = 0
        for _, root in ipairs(roots()) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("ValueBase") and typeof(obj.Value) == "number" and classify(obj.Name) == kind then
                    snapshotValue(obj, kind)
                    local wanted = fullValue(obj, obj.Value)
                    local ok = pcall(function() obj.Value = wanted end)
                    if ok then changed += 1 end
                end
            end
            for name, value in pairs(root:GetAttributes()) do
                if typeof(value) == "number" and classify(name) == kind then
                    snapshotAttr(root, name, kind, value)
                    local wanted = attrMax(root, name, value)
                    local ok = pcall(function() root:SetAttribute(name, wanted) end)
                    if ok then changed += 1 end
                end
            end
        end
        return changed
    end

    local function readKind(kind)
        -- Prefer LocalPlayer attributes because current builds expose Hunger/Thirst there.
        for _, root in ipairs(roots()) do
            for name, value in pairs(root:GetAttributes()) do
                if typeof(value) == "number" and classify(name) == kind then
                    return tonumber(value), attrMax(root, name, value), root:GetFullName() .. ".@" .. name
                end
            end
        end
        for _, root in ipairs(roots()) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("ValueBase") and typeof(obj.Value) == "number" and classify(obj.Name) == kind then
                    return tonumber(obj.Value), fullValue(obj, obj.Value), obj:GetFullName()
                end
            end
        end
        return nil, nil, nil
    end

    local function fmt(value, maximum)
        if value == nil then return "n/a" end
        if maximum then return string.format("%.1f/%.1f", value, maximum) end
        return string.format("%.1f", value)
    end

    local function updateStatus()
        local h, hm = readKind("hunger")
        local t, tm = readKind("thirst")
        local hControlled = State.Utility.FullHunger and attemptedH > 0 and hm and h and h < hm - .01
        local tControlled = State.Utility.FullThirst and attemptedT > 0 and tm and t and t < tm - .01

        if hControlled or tControlled then
            guard.Text = "SURVIVAL: server is restoring one or more values"
            guard.TextColor3 = Color3.fromRGB(245, 170, 80)
        else
            guard.Text = "SURVIVAL: local values available"
            guard.TextColor3 = Color3.fromRGB(80, 225, 125)
        end

        local suffix = ""
        if hControlled then suffix ..= " • Hunger server-controlled" end
        if tControlled then suffix ..= " • Thirst server-controlled" end
        status.Text = "Hunger " .. fmt(h, hm) .. " • Thirst " .. fmt(t, tm) .. suffix
    end

    local timer = 0
    local statusTimer = 0

    RunService.Heartbeat:Connect(function(dt)
        timer += dt
        statusTimer += dt
        if timer < .08 then return end
        timer = 0

        if State.Utility.FullHunger then
            if not armedH then
                applyKind("hunger")
                attemptedH = os.clock()
                armedH = true
            end
        else
            if armedH then commitKind("hunger") end
            armedH = false
            attemptedH = 0
        end

        if State.Utility.FullThirst then
            if not armedT then
                applyKind("thirst")
                attemptedT = os.clock()
                armedT = true
            end
        else
            if armedT then commitKind("thirst") end
            armedT = false
            attemptedT = 0
        end

        if statusTimer >= .35 then
            statusTimer = 0
            updateStatus()
        end
    end)

    LP.CharacterAdded:Connect(function()
        valueSnaps = setmetatable({}, { __mode = "k" })
        attrSnaps = setmetatable({}, { __mode = "k" })
        armedH = false
        armedT = false
        attemptedH = 0
        attemptedT = 0
        task.defer(updateStatus)
    end)

    task.defer(updateStatus)
end
