-- LvkHub.exe Combat V2
-- Active combat shell for local Workspace.TestPlayers dummies only.
-- No GunPlugin adapter is used here. WeaponSystem shot redirection lives in
-- src/Combat/WeaponSystemDummyAdapter.lua.

return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local CoreGui=game:GetService("CoreGui")

    local LP=Players.LocalPlayer
    local page=UI.Pages.Combat

    State.Combat.SelectedBot=nil
    State.Combat.AimFOV=State.Combat.AimFOV or 180
    if State.Combat.ShowAimFOV==nil then State.Combat.ShowAimFOV=true end
    if State.Combat.WallCheck==nil then State.Combat.WallCheck=true end
    if State.Combat.MagicThroughWalls==nil then State.Combat.MagicThroughWalls=false end

    local function allowed()
        return Registry.PracticeAllowed and Registry.PracticeAllowed() or false
    end

    local function targetPart(model)
        if not allowed() or not model or not Registry.IsBot(model) then return nil end
        if (State.Combat.AimPart or "Head")=="Torso" then
            return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or Registry.RootOf(model)
        end
        return model:FindFirstChild("Head") or Registry.RootOf(model)
    end

    local function fovCenter(cam)
        return cam and cam.ViewportSize/2 or Vector2.zero
    end

    local function fovDistance(part)
        local cam=Workspace.CurrentCamera
        if not cam or not part then return nil end
        local s,on=cam:WorldToViewportPoint(part.Position)
        if not on or s.Z<=0 then return nil end
        return (Vector2.new(s.X,s.Y)-fovCenter(cam)).Magnitude
    end

    local function visible(model,part)
        local cam=Workspace.CurrentCamera
        if not cam or not model or not part then return false end
        local origin=cam.CFrame.Position
        local dir=part.Position-origin
        if dir.Magnitude<0.05 then return true end
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        local exclude={model,cam}
        if LP.Character then table.insert(exclude,LP.Character) end
        params.FilterDescendantsInstances=exclude
        params.IgnoreWater=true
        return Workspace:Raycast(origin,dir,params)==nil
    end

    local function chooseTarget(requireVisible)
        if not allowed() then return nil end
        local radius=math.clamp(State.Combat.AimFOV or 180,20,800)

        local selected=State.Combat.SelectedBot
        if selected and Registry.IsBot(selected) then
            local p=targetPart(selected)
            local px=p and fovDistance(p)
            if px and px<=radius and (not requireVisible or visible(selected,p)) then
                return selected,p
            end
        end

        local best,bestPart,bestPx=nil,nil,math.huge
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then
                local p=targetPart(model)
                local px=p and fovDistance(p)
                if px and px<=radius and px<bestPx and (not requireVisible or visible(model,p)) then
                    best,bestPart,bestPx=model,p,px
                end
            end
        end
        return best,bestPart
    end

    -- Expose a tiny dummy-only selector API to the WeaponSystem adapter.
    shared.LvkHubDummyAimAPI={
        ChooseTarget=chooseTarget,
        TargetPart=targetPart,
        Visible=visible,
    }

    UI.Section(page,"TEST PLAYERS / NPC DUMMIES")
    local _,sourceLabel=UI.Row(page,"Target source: Workspace.TestPlayers")
    sourceLabel.TextColor3=Color3.fromRGB(150,200,255)
    local _,countLabel=UI.Row(page,"Test targets: 0")
    countLabel.TextColor3=Color3.fromRGB(120,220,170)

    local function updateCount()
        countLabel.Text="Test targets: "..tostring(Registry.CountBots and Registry.CountBots() or 0).." • real Players excluded"
    end
    updateCount()

    UI.Section(page,"Aim FOV")
    UI.Toggle(page,"Show FOV",function() return State.Combat.ShowAimFOV end,function(v) State.Combat.ShowAimFOV=v end)
    UI.Number(page,"FOV Radius",function() return State.Combat.AimFOV end,function(v)
        State.Combat.AimFOV=math.clamp(tonumber(v) or 180,20,800)
    end,20,800)
    UI.Toggle(page,"Wall Check",function() return State.Combat.WallCheck end,function(v) State.Combat.WallCheck=v end)
    UI.Toggle(page,"Magic Through Walls",function() return State.Combat.MagicThroughWalls end,function(v) State.Combat.MagicThroughWalls=v end)

    UI.Section(page,"Combat")
    local _,targetLabel=UI.Row(page,"Target dummy: AUTO")
    targetLabel.TextColor3=Color3.fromRGB(150,200,255)

    UI.Button(page,"Target Dummy","NEXT",function()
        if Registry.RefreshTargets then Registry.RefreshTargets() end
        updateCount()
        local list={}
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then table.insert(list,model) end
        end
        table.sort(list,function(a,b) return a.Name<b.Name end)
        if #list==0 then
            State.Combat.SelectedBot=nil
            targetLabel.Text="Target dummy: AUTO • 0 found"
            return
        end
        local idx=table.find(list,State.Combat.SelectedBot) or 0
        State.Combat.SelectedBot=list[idx%#list+1]
        targetLabel.Text="Target dummy: "..State.Combat.SelectedBot.Name
    end)

    local function setGuarded(key,v)
        State.Combat[key]=(v and allowed()) or false
    end

    UI.Toggle(page,"Aimbot",function() return State.Combat.Aimbot end,function(v) setGuarded("Aimbot",v) end)
    UI.Toggle(page,"Silent Aim",function() return State.Combat.SilentAim end,function(v) setGuarded("SilentAim",v) end)
    UI.Toggle(page,"Magic Bullets",function() return State.Combat.MagicBullets end,function(v) setGuarded("MagicBullets",v) end)
    UI.Toggle(page,"HitBoxes",function() return State.Combat.HitBoxes end,function(v) setGuarded("HitBoxes",v) end)
    UI.Number(page,"HitBox Size",function() return State.Combat.HitboxSize end,function(v) State.Combat.HitboxSize=v end,2,20)
    UI.Dropdown(page,"Aim Part",{"Head","Torso"},function() return State.Combat.AimPart or "Head" end,function(v) State.Combat.AimPart=v end)
    UI.Toggle(page,"AntiAim",function() return State.Combat.AntiAim end,function(v) State.Combat.AntiAim=v end)

    local guiParent=(gethui and gethui()) or CoreGui
    local old=guiParent:FindFirstChild("LvkHubAimFOV")
    if old then pcall(function() old:Destroy() end) end

    local fovGui=Instance.new("ScreenGui")
    fovGui.Name="LvkHubAimFOV"
    fovGui.IgnoreGuiInset=true
    fovGui.ResetOnSpawn=false
    fovGui.DisplayOrder=995
    fovGui.Parent=guiParent

    local circle=Instance.new("Frame")
    circle.AnchorPoint=Vector2.new(.5,.5)
    circle.BackgroundTransparency=1
    circle.BorderSizePixel=0
    circle.Parent=fovGui
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(1,0)
    c.Parent=circle
    local s=Instance.new("UIStroke")
    s.Thickness=1.25
    s.Transparency=.08
    s.Color=Color3.fromRGB(119,120,255)
    s.Parent=circle

    local originalSizes=setmetatable({}, {__mode="k"})
    local antiSpin=0
    local hitboxWas=false
    local countTimer=0

    RunService:BindToRenderStep("LvkHubBotAimbotV2",Enum.RenderPriority.Last.Value+500,function(dt)
        local cam=Workspace.CurrentCamera
        if cam then
            local r=math.clamp(State.Combat.AimFOV or 180,20,800)
            local center=fovCenter(cam)
            circle.Position=UDim2.fromOffset(center.X,center.Y)
            circle.Size=UDim2.fromOffset(r*2,r*2)
            circle.Visible=State.Combat.ShowAimFOV==true
        else
            circle.Visible=false
        end

        if allowed() and State.Combat.Aimbot and cam then
            local _,p=chooseTarget(State.Combat.WallCheck==true)
            if p then
                cam.CFrame=cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position,p.Position),.32)
            end
        end

        local ch=LP.Character
        if State.Combat.AntiAim and ch then
            antiSpin=(antiSpin+dt*3)%(math.pi*2)
            local root=ch:FindFirstChild("HumanoidRootPart")
            local waist=(ch:FindFirstChild("UpperTorso") and ch.UpperTorso:FindFirstChild("Waist")) or (root and root:FindFirstChild("RootJoint"))
            if waist and waist:IsA("Motor6D") then
                waist.Transform=CFrame.Angles(0,math.sin(antiSpin)*.25,0)
            end
        end
    end)

    RunService.Heartbeat:Connect(function(dt)
        countTimer+=dt
        if countTimer>=1 then countTimer=0; updateCount() end

        if allowed() and State.Combat.HitBoxes then
            for model in pairs(Registry.Bots) do
                if Registry.IsBot(model) then
                    local p=targetPart(model)
                    if p and p:IsA("BasePart") then
                        if originalSizes[p]==nil then originalSizes[p]={Size=p.Size,CanCollide=p.CanCollide} end
                        local n=math.max(2,State.Combat.HitboxSize or 6)
                        p.Size=Vector3.new(n,n,n)
                        p.CanCollide=false
                    end
                end
            end
        elseif hitboxWas then
            for p,st in pairs(originalSizes) do
                if p and p.Parent then p.Size=st.Size; p.CanCollide=st.CanCollide end
                originalSizes[p]=nil
            end
        end
        hitboxWas=allowed() and State.Combat.HitBoxes or false
    end)
end
