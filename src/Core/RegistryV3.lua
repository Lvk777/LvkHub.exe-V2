-- LvkHub.exe Registry V3
-- Responsibility: discover/cache raw local practice candidates + vehicles.
-- IMPORTANT: this module does NOT decide whether a candidate is an allowed target.
-- Target authorization belongs to src/Core/TargetProvider.lua + src/Restrictions/Policy.lua.

return function(SourcePolicy)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local Registry = {
        Candidates = setmetatable({}, { __mode = "k" }),
        Vehicles = setmetatable({}, { __mode = "k" }),
        VehicleFolder = nil,
        TestPlayersFolder = nil,
        _connections = {},
        _listeners = {},
        Version = 3,
    }

    local function disconnectAll()
        for _, c in ipairs(Registry._connections) do pcall(function() c:Disconnect() end) end
        table.clear(Registry._connections)
    end

    local function emitTargetsChanged()
        for fn in pairs(Registry._listeners) do
            task.defer(function() pcall(fn) end)
        end
    end

    function Registry.SubscribeTargetsChanged(fn)
        if type(fn) ~= "function" then return function() end end
        Registry._listeners[fn] = true
        return function() Registry._listeners[fn] = nil end
    end

    function Registry.RootOf(model)
        if not model then return nil end
        return model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("UpperTorso")
            or model:FindFirstChild("Torso")
            or model.PrimaryPart
            or model:FindFirstChildWhichIsA("BasePart")
    end

    function Registry.HumanoidOf(model)
        return model and model:FindFirstChildOfClass("Humanoid") or nil
    end

    local function validRig(model)
        return model and model:IsA("Model")
            and Registry.HumanoidOf(model) ~= nil
            and Registry.RootOf(model) ~= nil
    end

    local function ensureTestFolder()
        local f = Workspace:FindFirstChild("TestPlayers")
        if not f then
            f = Instance.new("Folder")
            f.Name = "TestPlayers"
            f:SetAttribute("LvkHubManagedFolder", true)
            f.Parent = Workspace
        end
        Registry.TestPlayersFolder = f
        return f
    end

    function Registry.GetSourceLabel()
        return "Workspace.Players" -- ALTERADO
    end

    local function sourceFolder()
        local f = Workspace:FindFirstChild("Players")
        if f and (f:IsA("Folder") or f:IsA("Model")) then return f end
        return nil
    end

    local function canCloneSource(model)
        return type(SourcePolicy) == "table"
            and type(SourcePolicy.CanCloneSource) == "function"
            and select(2, pcall(SourcePolicy.CanCloneSource, model)) == true
    end

    local function inventorySnapshotFromClone(clone)
        local names, seen = {}, {}
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Tool") and not seen[d.Name] then
                seen[d.Name] = true
                table.insert(names, d.Name)
                if #names >= 4 then break end
            end
        end

        local old = clone:FindFirstChild("LvkHubDummyInventory")
        if old then old:Destroy() end
        local folder = Instance.new("Folder")
        folder.Name = "LvkHubDummyInventory"
        folder:SetAttribute("LvkHubLocalSnapshot", true)
        folder.Parent = clone
        for i = 1, 4 do
            local slot = Instance.new("StringValue")
            slot.Name = "Slot" .. i
            slot.Value = names[i] or "Empty"
            slot.Parent = folder
        end
    end

    local function sanitizeClone(clone)
        inventorySnapshotFromClone(clone)
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                d:Destroy()
            elseif d:IsA("Tool") then
                d:Destroy()
            elseif d:IsA("BasePart") then
                d.Anchored = true
                d.CanCollide = false
                d.CanTouch = false
                d.Massless = true
            end
        end
    end

    local function placement(index)
        local ch = LocalPlayer.Character
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        if root then
            local col = (index - 1) % 4
            local row = math.floor((index - 1) / 4)
            return root.CFrame * CFrame.new((col - 1.5) * 6, 0, -18 - row * 7)
        end
        return CFrame.new(index * 6, 10, 0)
    end

    -- ALTERADO: cloneRig agora retorna nil para não criar clones
    local function cloneRig(source, index)
        return nil
    end

    local syncing = false
    local function syncPracticeClones()
        -- ALTERADO: desativado para não criar clones
        return
    end

    local function rebuildCandidates()
        table.clear(Registry.Candidates)
        -- ALTERADO: popula com Players em vez de TestPlayers
        local folder = Workspace:FindFirstChild("Players")
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if validRig(child) then
                    Registry.Candidates[child] = { kind = "practice_dummy", source = child.Name }
                end
            end
        end
        emitTargetsChanged()
    end

    function Registry.RefreshTargets()
        rebuildCandidates()
        return Registry.CountCandidates()
    end

    function Registry.GetCandidates()
        local out = {}
        for model in pairs(Registry.Candidates) do
            if Registry.IsCandidate(model) then table.insert(out, model) end
        end
        table.sort(out, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)
        return out
    end

    function Registry.IsCandidate(model)
        return model ~= nil
            and Registry.Candidates[model] ~= nil
            and model:IsDescendantOf(Workspace)
            and validRig(model)
    end

    function Registry.CountCandidates()
        local n = 0
        for model in pairs(Registry.Candidates) do
            if Registry.IsCandidate(model) then n = n + 1 else Registry.Candidates[model] = nil end
        end
        return n
    end

    function Registry.GetCandidateMeta(model)
        return Registry.Candidates[model]
    end

    function Registry.GetDummyInventory(model)
        local slots = { "Empty", "Empty", "Empty", "Empty" }
        if not Registry.IsCandidate(model) then return slots end
        local folder = model:FindFirstChild("LvkHubDummyInventory")
        if not folder then return slots end
        for i = 1, 4 do
            local v = folder:FindFirstChild("Slot" .. i)
            if v and v:IsA("StringValue") then slots[i] = v.Value end
        end
        return slots
    end

    local function rescanVehicles()
        table.clear(Registry.Vehicles)
        Registry.VehicleFolder = Workspace:FindFirstChild("Vehicles")
        if not Registry.VehicleFolder then return end
        for _, m in ipairs(Registry.VehicleFolder:GetChildren()) do
            if m:IsA("Model") then Registry.Vehicles[m] = true end
        end
    end

    function Registry.CountVehicles()
        local n = 0
        for m in pairs(Registry.Vehicles) do
            if m and m.Parent then n = n + 1 else Registry.Vehicles[m] = nil end
        end
        return n
    end

    function Registry.Refresh()
        disconnectAll()
        Registry.RefreshTargets()
        rescanVehicles()

        local src = sourceFolder()
        if src then
            table.insert(Registry._connections, src.ChildAdded:Connect(function() task.defer(Registry.RefreshTargets) end))
            table.insert(Registry._connections, src.ChildRemoved:Connect(function() task.defer(Registry.RefreshTargets) end))
        end

        -- Não ouvimos mais TestPlayers
        local tf = ensureTestFolder()
        table.insert(Registry._connections, tf.ChildAdded:Connect(function() task.defer(rebuildCandidates) end))
        table.insert(Registry._connections, tf.ChildRemoved:Connect(function() task.defer(rebuildCandidates) end))

        table.insert(Registry._connections, Workspace.ChildAdded:Connect(function(child)
            if child.Name == "Players" then task.defer(Registry.Refresh)
            elseif child.Name == "Vehicles" then task.defer(rescanVehicles) end
        end))
        table.insert(Registry._connections, Workspace.ChildRemoved:Connect(function(child)
            if child == Registry.VehicleFolder then Registry.VehicleFolder = nil; table.clear(Registry.Vehicles) end
        end))

        table.insert(Registry._connections, Players.PlayerAdded:Connect(function() task.defer(Registry.RefreshTargets) end))
        table.insert(Registry._connections, Players.PlayerRemoving:Connect(function() task.defer(Registry.RefreshTargets) end))
    end

    Registry.Refresh()
    return Registry
end
