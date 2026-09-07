-- Runtime target-index repair.
-- Target authorization and candidate enumeration are delegated to the loaded policy.
return function(Registry)
    local Workspace=game:GetService("Workspace")
    local Policy=shared.LvkHubTargetRestrictions

    if not Registry then return end

    local function policyReady()
        return type(Policy)=="table"
            and type(Policy.IsAllowedTarget)=="function"
            and type(Policy.GetCandidates)=="function"
    end

    function Registry.IsRealPlayerCharacter(model)
        if not policyReady() then return true end
        if type(Policy.IsRealPlayerCharacter)~="function" then return true end
        local ok,result=pcall(Policy.IsRealPlayerCharacter,model)
        if not ok then return true end
        return result==true
    end

    function Registry.TargetAllowed(model)
        if not policyReady() then return false end
        local ok,result=pcall(Policy.IsAllowedTarget,model)
        return ok and result==true
    end

    function Registry.PracticeAllowed()
        return policyReady()
    end

    local function valid(model)
        if not model or not model:IsA("Model") then return false end
        if not Registry.TargetAllowed(model) then return false end
        local hum=Registry.HumanoidOf and Registry.HumanoidOf(model)
        local root=Registry.RootOf and Registry.RootOf(model)
        return hum~=nil and root~=nil and hum.Health>0
    end

    local function candidates()
        if not policyReady() then return {} end
        local ok,list=pcall(Policy.GetCandidates)
        if not ok or type(list)~="table" then return {} end
        return list
    end

    function Registry.RebuildTargetIndex()
        table.clear(Registry.Bots)
        local n=0
        for _,model in ipairs(candidates()) do
            if valid(model) then
                Registry.Bots[model]=true
                n+=1
            end
        end
        return n
    end

    local originalRefresh=Registry.RefreshTargets
    function Registry.RefreshTargets()
        -- Keep the existing local-dummy synchronization step, then let policy alone
        -- decide which resulting models are legal target candidates.
        if type(originalRefresh)=="function" then pcall(originalRefresh) end
        return Registry.RebuildTargetIndex()
    end

    function Registry.IsBot(model)
        return model~=nil
            and model:IsDescendantOf(Workspace)
            and Registry.Bots[model]==true
            and valid(model)
    end

    function Registry.CountBots()
        local n=0
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then n+=1 else Registry.Bots[model]=nil end
        end
        return n
    end

    local watched=setmetatable({}, {__mode="k"})
    local function bindRoot(root)
        if not root or watched[root] then return end
        watched[root]=true
        root.ChildAdded:Connect(function() task.defer(Registry.RebuildTargetIndex) end)
        root.ChildRemoved:Connect(function() task.defer(Registry.RebuildTargetIndex) end)
    end

    local function bindPolicyRoots()
        if not policyReady() or type(Policy.GetWatchRoots)~="function" then return end
        local ok,roots=pcall(Policy.GetWatchRoots)
        if not ok or type(roots)~="table" then return end
        for _,root in ipairs(roots) do bindRoot(root) end
    end

    Workspace.ChildAdded:Connect(function()
        task.defer(function()
            bindPolicyRoots()
            Registry.RebuildTargetIndex()
        end)
    end)
    Workspace.ChildRemoved:Connect(function()
        task.defer(Registry.RebuildTargetIndex)
    end)

    bindPolicyRoots()
    Registry.RefreshTargets()
    task.spawn(function()
        for _,delay in ipairs({0.10,0.30,0.70,1.30,2.20}) do
            task.wait(delay)
            bindPolicyRoots()
            Registry.RefreshTargets()
        end
    end)
end
