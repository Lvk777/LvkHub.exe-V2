-- Keeps Car ESP state synchronized, including stale highlights/billboards from older builds.

return function(State, Registry)
    local RunService=game:GetService("RunService")

    local highlightNames={
        YokaiPreservedCarESP=true,
        LvkHubCarESP=true,
        GunTestingLiteCarESP=true,
    }
    local labelNames={
        YokaiPreservedCarLabel=true,
        LvkHubCarESPLabel=true,
        GunTestingLiteCarESPLabel=true,
    }

    local function forceOff(model)
        if not model or not model.Parent then return end
        for _,d in ipairs(model:GetDescendants()) do
            if d:IsA("Highlight") and highlightNames[d.Name] then
                d.Enabled=false
            elseif d:IsA("BillboardGui") and labelNames[d.Name] then
                d.Enabled=false
            end
        end
        for _,d in ipairs(model:GetChildren()) do
            if d:IsA("Highlight") and highlightNames[d.Name] then d.Enabled=false end
        end
    end

    local was=State.Visuals.CarESP
    local acc=0
    RunService.Heartbeat:Connect(function(dt)
        acc+=dt
        if acc<.10 then return end
        acc=0
        local now=State.Visuals.CarESP==true
        if not now then
            for model in pairs(Registry.Vehicles) do forceOff(model) end
        elseif not was then
            -- Main Visuals renderer will re-enable the registered car visuals.
        end
        was=now
    end)
end
