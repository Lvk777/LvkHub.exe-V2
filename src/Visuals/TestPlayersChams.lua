-- LvkHub.exe TestPlayers Chams
-- Dedicated one-Highlight-per-dummy renderer for Workspace.TestPlayers only.
-- Loaded BEFORE legacy Visuals/Main.lua so these Highlights get renderer slots first.
-- This avoids duplicate Chams/ESP-pack Highlights exhausting Roblox's Highlight budget
-- when many local test dummies exist.

return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local BLUE=Color3.fromRGB(119,120,255)

    local highlights=setmetatable({}, {__mode="k"})

    local function testFolder()
        return Workspace:FindFirstChild("TestPlayers")
    end

    local function valid(model)
        local folder=testFolder()
        if not folder or not model or not model:IsA("Model") or not model:IsDescendantOf(folder) then
            return false
        end
        if Registry.IsRealPlayerCharacter and Registry.IsRealPlayerCharacter(model) then
            return false
        end
        local hum=Registry.HumanoidOf and Registry.HumanoidOf(model)
        local root=Registry.RootOf and Registry.RootOf(model)
        return hum~=nil and root~=nil and hum.Health>0
    end

    local function make(model)
        local h=highlights[model]
        if h and h.Parent then return h end

        h=Instance.new("Highlight")
        h.Name="LvkHubUnifiedTestChams"
        h.Adornee=model
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.FillColor=BLUE
        h.OutlineColor=BLUE
        h.FillTransparency=.58
        h.OutlineTransparency=0
        h.Enabled=false
        h.Parent=model
        highlights[model]=h
        return h
    end

    local function prime()
        local folder=testFolder()
        if not folder then return end
        for _,model in ipairs(folder:GetChildren()) do
            if valid(model) then make(model) end
        end
    end

    prime()

    local timer=0
    RunService.Heartbeat:Connect(function(dt)
        timer+=dt
        if timer<.20 then return end
        timer=0

        local enabled=State.Visuals.Chams==true or State.Visuals.ESP==true
        local folder=testFolder()
        local live=setmetatable({}, {__mode="k"})

        if folder then
            for _,model in ipairs(folder:GetChildren()) do
                if valid(model) then
                    live[model]=true
                    local h=make(model)
                    h.Adornee=model
                    h.FillColor=BLUE
                    h.OutlineColor=BLUE
                    h.FillTransparency=.58
                    h.OutlineTransparency=0
                    h.Enabled=enabled
                end
            end
        end

        for model,h in pairs(highlights) do
            if not live[model] or not h or not h.Parent then
                if h then pcall(function() h:Destroy() end) end
                highlights[model]=nil
            elseif not enabled then
                h.Enabled=false
            end
        end
    end)
end
