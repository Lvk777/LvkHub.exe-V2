-- Repairs the Visuals Preview avatar rendering.
-- Preview-only: never registers this model as a combat/ESP target.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")

    local wantedName="vitor250407"
    local fixing=false
    local lastFix=0

    local function sanitize(model)
        for _,d in ipairs(model:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool") then
                d:Destroy()
            elseif d:IsA("BasePart") then
                d.Anchored=true
                d.CanCollide=false
                d.CanTouch=false
                d.CastShadow=false
            end
        end
    end

    local function buildAvatar()
        local plr=Players:FindFirstChild(wantedName)
        if plr and plr.Character then
            local old=plr.Character.Archivable
            plr.Character.Archivable=true
            local ok,clone=pcall(function() return plr.Character:Clone() end)
            plr.Character.Archivable=old
            if ok and clone then return clone end
        end

        local okId,userId=pcall(function() return Players:GetUserIdFromNameAsync(wantedName) end)
        if okId and userId then
            local okDesc,desc=pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
            if okDesc and desc then
                local okModel,model=pcall(function()
                    return Players:CreateHumanoidModelFromDescription(desc,Enum.HumanoidRigType.R15)
                end)
                if okModel and model then return model end
            end
        end
        return nil
    end

    local function fix()
        if fixing then return end
        local frame=UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
        if not frame then return end
        local vp=frame:FindFirstChildWhichIsA("ViewportFrame",true)
        if not vp then return end
        local world=vp:FindFirstChildWhichIsA("WorldModel")
        local cam=vp.CurrentCamera or vp:FindFirstChildWhichIsA("Camera")
        if not world or not cam then return end

        local existing=world:FindFirstChild("LvkHubPreviewAvatarV7")
        if existing and existing:IsA("Model") then return end

        fixing=true
        task.spawn(function()
            local model=buildAvatar()
            if model then
                for _,x in ipairs(world:GetChildren()) do
                    if x:IsA("Model") then x:Destroy() end
                end
                model.Name="LvkHubPreviewAvatarV7"
                sanitize(model)
                model.Parent=world
                model:PivotTo(CFrame.new(0,0,0))
                local ok,_,size=pcall(function() return model:GetBoundingBox() end)
                size=(ok and size) or Vector3.new(4,6,2)
                local y=math.max(1.8,size.Y*.42)
                local d=math.max(7.2,size.Y*1.35,size.X*2.1)
                cam.FieldOfView=32
                cam.CFrame=CFrame.lookAt(Vector3.new(0,y,-d),Vector3.new(0,y,0))
                vp.Ambient=Color3.fromRGB(210,210,220)
                vp.LightColor=Color3.fromRGB(255,255,255)
                vp.LightDirection=Vector3.new(-1,-1,1)
            end
            lastFix=os.clock()
            fixing=false
        end)
    end

    task.delay(1.25,fix)
    RunService.Heartbeat:Connect(function()
        if os.clock()-lastFix>1.5 then
            lastFix=os.clock()
            fix()
        end
    end)
end
