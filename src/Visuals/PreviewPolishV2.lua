-- Adds an interactive HP scrubber to the local TestPlayers preview.
-- Camera/model placement is owned by UnifiedTestVisualsV5.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")

    local attached=false
    local dragging=false
    local healthBar=nil

    local function currentTarget()
        local m=State.Combat and State.Combat.SelectedBot or nil
        if m and Registry.IsBot(m) then return m end
        for x in pairs(Registry.Bots) do if Registry.IsBot(x) then return x end end
        return nil
    end

    local function setHealthFromX(x)
        if not healthBar then return end
        local m=currentTarget(); local hum=m and Registry.HumanoidOf(m)
        if not hum then return end
        local t=math.clamp((x-healthBar.AbsolutePosition.X)/math.max(1,healthBar.AbsoluteSize.X),0,1)
        hum.Health=hum.MaxHealth*t
    end

    local function attach()
        if attached then return end
        local preview=UI.Gui:FindFirstChild("LvkHubUnifiedPreviewV4")
        if not preview then return end
        for _,f in ipairs(preview:GetChildren()) do
            if f:IsA("Frame") and f.Position.Y.Offset>=295 and f.AbsoluteSize.Y<=12 and f.AbsoluteSize.X>80 then
                healthBar=f
                break
            end
        end
        if not healthBar then return end
        healthBar.Active=true
        healthBar.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; setHealthFromX(i.Position.X) end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then setHealthFromX(i.Position.X) end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end)
        attached=true
    end

    local t=0
    RunService.Heartbeat:Connect(function(dt)
        t+=dt
        if t<.20 then return end
        t=0
        attach()
    end)
end
