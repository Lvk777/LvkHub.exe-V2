-- LvkHub.exe TargetProvider
-- Single target-facing API for Combat / Visuals / target UI / practice adapters.
-- Registry discovers candidates; Policy authorizes them; consumers see only this provider.

return function(Registry, TargetPolicy)
    local Workspace=game:GetService("Workspace")

    local Provider={
        Registry=Registry,
        Policy=TargetPolicy,
        Targets=setmetatable({}, {__mode="k"}),
        Version=1,
    }
    -- Compatibility alias so existing target modules can stay almost unchanged.
    Provider.Bots=Provider.Targets
    Provider.Vehicles=Registry and Registry.Vehicles or setmetatable({}, {__mode="k"})
    Provider.VehicleFolder=Registry and Registry.VehicleFolder or nil

    local function policyReady()
        return type(TargetPolicy)=="table"
            and type(TargetPolicy.IsAllowedTarget)=="function"
            and type(TargetPolicy.IsRealPlayerCharacter)=="function"
    end

    local function authorizedCandidate(model)
        if not policyReady() then return false end
        if not Registry or type(Registry.IsCandidate)~="function" or not Registry.IsCandidate(model) then return false end
        local hum=Registry.HumanoidOf and Registry.HumanoidOf(model)
        local root=Registry.RootOf and Registry.RootOf(model)
        if not hum or not root then return false end
        local ok,allowed=pcall(TargetPolicy.IsAllowedTarget,model)
        return ok and allowed==true
    end

    local function alive(model)
        local hum=Registry and Registry.HumanoidOf and Registry.HumanoidOf(model)
        return hum~=nil and hum.Health>0
    end

    function Provider.Rebuild()
        table.clear(Provider.Targets)
        if not policyReady() or not Registry or type(Registry.GetCandidates)~="function" then return 0 end
        local n=0
        for _,model in ipairs(Registry.GetCandidates()) do
            if authorizedCandidate(model) then
                Provider.Targets[model]=true
                if alive(model) then n+=1 end
            end
        end
        Provider.VehicleFolder=Registry.VehicleFolder
        Provider.Vehicles=Registry.Vehicles
        return n
    end

    function Provider.RefreshTargets()
        if Registry and type(Registry.RefreshTargets)=="function" then pcall(Registry.RefreshTargets) end
        return Provider.Rebuild()
    end

    function Provider.Refresh()
        if Registry and type(Registry.Refresh)=="function" then pcall(Registry.Refresh) end
        return Provider.Rebuild()
    end

    function Provider.GetTargets()
        local out={}
        for model in pairs(Provider.Targets) do
            if Provider.IsTarget(model) then table.insert(out,model)
            elseif not authorizedCandidate(model) then Provider.Targets[model]=nil end
        end
        table.sort(out,function(a,b) return string.lower(a.Name)<string.lower(b.Name) end)
        return out
    end

    function Provider.IsTarget(model)
        return model~=nil
            and Provider.Targets[model]==true
            and model:IsDescendantOf(Workspace)
            and authorizedCandidate(model)
            and alive(model)
    end

    function Provider.CountTargets()
        local n=0
        for model in pairs(Provider.Targets) do
            if not authorizedCandidate(model) then
                Provider.Targets[model]=nil
            elseif alive(model) then
                n+=1
            end
        end
        return n
    end

    function Provider.PracticeAllowed()
        return policyReady()
    end

    function Provider.IsRealPlayerCharacter(model)
        if not policyReady() then return true end
        local ok,result=pcall(TargetPolicy.IsRealPlayerCharacter,model)
        if not ok then return true end
        return result==true
    end

    function Provider.TargetAllowed(model)
        return Provider.IsTarget(model)
    end

    function Provider.TargetPolicyStatus(model)
        if not policyReady() then return false,"target policy unavailable" end
        if type(TargetPolicy.Describe)=="function" then
            local ok,a,b=pcall(TargetPolicy.Describe,model)
            if ok then return a,b end
        end
        return Provider.IsTarget(model),Provider.IsTarget(model) and "allowed target" or "blocked target"
    end

    function Provider.RootOf(model)
        return Registry and Registry.RootOf and Registry.RootOf(model) or nil
    end

    function Provider.HumanoidOf(model)
        return Registry and Registry.HumanoidOf and Registry.HumanoidOf(model) or nil
    end

    function Provider.GetDummyInventory(model)
        if not authorizedCandidate(model) then return {"Empty","Empty","Empty","Empty"} end
        return Registry and Registry.GetDummyInventory and Registry.GetDummyInventory(model) or {"Empty","Empty","Empty","Empty"}
    end

    function Provider.GetSourceLabel()
        return Registry and Registry.GetSourceLabel and Registry.GetSourceLabel() or "TargetProvider"
    end

    function Provider.CountVehicles()
        return Registry and Registry.CountVehicles and Registry.CountVehicles() or 0
    end

    function Provider.GetCandidateMeta(model)
        return Registry and Registry.GetCandidateMeta and Registry.GetCandidateMeta(model) or nil
    end

    -- Compatibility methods used by current Combat/Visuals modules.
    Provider.IsBot=Provider.IsTarget
    Provider.CountBots=Provider.CountTargets

    if Registry and type(Registry.SubscribeTargetsChanged)=="function" then
        Registry.SubscribeTargetsChanged(function() Provider.Rebuild() end)
    end

    Provider.RefreshTargets()
    return Provider
end
