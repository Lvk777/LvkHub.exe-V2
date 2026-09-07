-- LvkHub.exe Combat
--
-- ============================================================================
-- TEST PLAYERS / NPC DUMMIES ONLY
-- ============================================================================
-- Combat consumes Registry.Bots, which is populated only from Workspace.TestPlayers.
-- Real Roblox Player.Character models are excluded by Registry and are never
-- returned by Registry.IsBot().
--
-- Aimbot, Silent Aim and Magic Bullets share one Aim FOV gate. WallCheck can
-- additionally require an unobstructed camera-to-target ray. Magic Bullets has a
-- separate "Magic Through Walls" test mode for local TestPlayers dummies only.
-- ============================================================================

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

    UI.Section(page,"TEST PLAYERS / NPC DUMMIES")
    local _,sourceLabel=UI.Row(page,"Target source: Workspace.TestPlayers")
    sourceLabel.TextColor3=Color3.fromRGB(150,200,255)
    local _,countLabel=UI.Row(page,"Test targets: 0")
    countLabel.TextColor3=Color3.fromRGB(120,220,170)

    local function allowed()
        return Registry.PracticeAllowed and Registry.PracticeAllowed() or false
    end

    local function updateCount()
        local n=Registry.CountBots and Registry.CountBots() or 0
        countLabel.Text="Test targets: "..tostring(n).." • real Players excluded"
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

    -- ------------------------------------------------------------------------
    -- FOV DRAWING
    -- ------------------------------------------------------------------------
    local guiParent=(gethui and gethui()) or CoreGui
    local oldFov=guiParent:FindFirstChild("LvkHubAimFOV")
    if oldFov then pcall(function() oldFov:Destroy() end) end

    local fovGui=Instance.new("ScreenGui")
    fovGui.Name="LvkHubAimFOV"
    fovGui.IgnoreGuiInset=true
    fovGui.ResetOnSpawn=false
    fovGui.DisplayOrder=995
    fovGui.Parent=guiParent

    local fovCircle=Instance.new("Frame")
    fovCircle.Name="Circle"
    fovCircle.AnchorPoint=Vector2.new(.5,.5)
    fovCircle.BackgroundTransparency=1
    fovCircle.BorderSizePixel=0
    fovCircle.Parent=fovGui

    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(1,0)
    corner.Parent=fovCircle

    local stroke=Instance.new("UIStroke")
    stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    stroke.Thickness=1.25
    stroke.Transparency=.08
    stroke.Color=Color3.fromRGB(119,120,255)
    stroke.Parent=fovCircle

    local function fovCenter(cam)
        return cam and cam.ViewportSize/2 or Vector2.zero
    end

    local function refreshFovCircle()
        local cam=Workspace.CurrentCamera
        if not cam then fovCircle.Visible=false; return end
        local radius=math.clamp(State.Combat.AimFOV or 180,20,800)
        local c=fovCenter(cam)
        fovCircle.Position=UDim2.fromOffset(c.X,c.Y)
        fovCircle.Size=UDim2.fromOffset(radius*2,radius*2)
        fovCircle.Visible=State.Combat.ShowAimFOV==true
    end

    local function targetPart(model)
        if not allowed() or not model or not Registry.IsBot(model) then return nil end
        if (State.Combat.AimPart or "Head")=="Torso" then
            return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or Registry.RootOf(model)
        end
        return model:FindFirstChild("Head") or Registry.RootOf(model)
    end

    local function fovScreenDistance(part)
        local cam=Workspace.CurrentCamera
        if not cam or not part then return nil end
        local s,on=cam:WorldToViewportPoint(part.Position)
        if not on or s.Z<=0 then return nil end
        local c=fovCenter(cam)
        local px=(Vector2.new(s.X,s.Y)-c).Magnitude
        return px,s
    end

    local function visibleToCamera(model,part)
        local cam=Workspace.CurrentCamera
        if not cam or not model or not part then return false end
        local origin=cam.CFrame.Position
        local direction=part.Position-origin
        if direction.Magnitude<0.05 then return true end

        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        local exclude={model}
        if LP.Character then table.insert(exclude,LP.Character) end
        if cam then table.insert(exclude,cam) end
        params.FilterDescendantsInstances=exclude
        params.IgnoreWater=true

        local result=Workspace:Raycast(origin,direction,params)
        return result==nil
    end

    local function eligible(model,part,requireVisible)
        local px=fovScreenDistance(part)
        if not px or px>math.clamp(State.Combat.AimFOV or 180,20,800) then return nil end
        if requireVisible and not visibleToCamera(model,part) then return nil end
        return px
    end

    local function selectedTargetInsideFOV(requireVisible)
        local model=State.Combat.SelectedBot
        if model and Registry.IsBot(model) then
            local p=targetPart(model)
            if p and eligible(model,p,requireVisible) then return model,p end
        end
        return nil
    end

    -- Shared selector for Aimbot / Silent Aim / Magic Bullets.
    -- No minimum/maximum world distance: FOV + optional wall check are the gates.
    local function chooseFovTarget(requireVisible)
        if not allowed() then return nil end

        local sm,sp=selectedTargetInsideFOV(requireVisible)
        if sm and sp then return sm,sp end

        local best,bestPart,bestPx=nil,nil,math.huge
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then
                local p=targetPart(model)
                if p then
                    local px=eligible(model,p,requireVisible)
                    if px and px<bestPx then
                        bestPx=px
                        best=model
                        bestPart=p
                    end
                end
            end
        end
        return best,bestPart
    end

    -- ------------------------------------------------------------------------
    -- GunTesting local GunPlugin adapter for TEST DUMMIES ONLY.
    -- Silent Aim respects Wall Check when enabled.
    -- Magic Bullets respects Wall Check unless Magic Through Walls is enabled.
    -- ------------------------------------------------------------------------
    local GunPlugin=nil
    local originalLook=nil
    local installing=false

    local function findGunPluginModule()
        local ps=LP:FindFirstChild("PlayerScripts")
        if not ps then return nil end
        local gc=ps:FindFirstChild("GunController")
        local events=gc and gc:FindFirstChild("Events")
        local exact=events and events:FindFirstChild("GunPlugin")
        if exact and exact:IsA("ModuleScript") then return exact end
        for _,d in ipairs(ps:GetDescendants()) do
            if d:IsA("ModuleScript") and d.Name=="GunPlugin" then return d end
        end
        return nil
    end

    local function installGunPlugin()
        if GunPlugin or installing or not allowed() then return GunPlugin~=nil end
        installing=true
        local mod=findGunPluginModule()
        if mod then
            local ok,g=pcall(require,mod)
            if ok and type(g)=="table" and type(g.GetWorldLookAtPos)=="function" then
                GunPlugin=g
                originalLook=g.GetWorldLookAtPos
                g.GetWorldLookAtPos=function(self,...)
                    if allowed() then
                        if State.Combat.MagicBullets then
                            local requireVisible=not State.Combat.MagicThroughWalls
                            local _,p=chooseFovTarget(requireVisible)
                            if p then return p.Position end
                        elseif State.Combat.SilentAim then
                            local _,p=chooseFovTarget(State.Combat.WallCheck==true)
                            if p then return p.Position end
                        end
                    end
                    return originalLook(self,...)
                end
            end
        end
        installing=false
        return GunPlugin~=nil
    end

    task.spawn(function()
        while UI.Gui.Parent and not GunPlugin do
            if allowed() then installGunPlugin() end
            task.wait(.5)
        end
    end)

    local originalSizes=setmetatable({}, {__mode="k"})
    local antiSpin=0
    local hitboxWas=false
    local countTimer=0

    RunService:BindToRenderStep("LvkHubBotAimbot",Enum.RenderPriority.Last.Value+500,function(dt)
        refreshFovCircle()

        local cam=Workspace.CurrentCamera
        if allowed() and State.Combat.Aimbot and cam then
            local _,p=chooseFovTarget(State.Combat.WallCheck==true)
            if p then
                local wanted=CFrame.lookAt(cam.CFrame.Position,p.Position)
                cam.CFrame=cam.CFrame:Lerp(wanted,.32)
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
        if countTimer>=1 then
            countTimer=0
            updateCount()
        end

        if allowed() and State.Combat.HitBoxes then
            for model in pairs(Registry.Bots) do
                if Registry.IsBot(model) then
                    local p=targetPart(model)
                    if p and p:IsA("BasePart") then
                        if originalSizes[p]==nil then
                            originalSizes[p]={Size=p.Size,CanCollide=p.CanCollide}
                        end
                        local n=math.max(2,State.Combat.HitboxSize or 6)
                        p.Size=Vector3.new(n,n,n)
                        p.CanCollide=false
                    end
                end
            end
        elseif hitboxWas then
            for p,state in pairs(originalSizes) do
                if p and p.Parent then
                    p.Size=state.Size
                    p.CanCollide=state.CanCollide
                end
                originalSizes[p]=nil
            end
        end
        hitboxWas=allowed() and State.Combat.HitBoxes or false
    end)
end
