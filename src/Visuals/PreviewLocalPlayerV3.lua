-- Visuals Preview local-player owner V3.
-- Keeps a neutral, front-facing LocalPlayer clone in the preview and mirrors Chams.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local LP=Players.LocalPlayer
    local lastCharacter=nil
    local previewClone=nil
    local previewHighlight=nil
    local timer=0

    local function neutralize(model)
        if not model then return end
        for _,d in ipairs(model:GetDescendants()) do
            if d:IsA("Motor6D") then
                d.Transform=CFrame.new()
            elseif d:IsA("BasePart") then
                d.Anchored=true
                d.CanCollide=false
                d.CanTouch=false
                d.CastShadow=false
                d.AssemblyLinearVelocity=Vector3.zero
                d.AssemblyAngularVelocity=Vector3.zero
            end
        end
    end

    local function rebuild(frame)
        local vp=frame and frame:FindFirstChildWhichIsA("ViewportFrame",true)
        if not vp then return end
        local world=vp:FindFirstChildWhichIsA("WorldModel")
        local cam=vp.CurrentCamera or vp:FindFirstChildWhichIsA("Camera")
        local ch=LP.Character
        if not world or not cam or not ch then return end

        for _,x in ipairs(world:GetChildren()) do x:Destroy() end

        local old=ch.Archivable
        ch.Archivable=true
        local ok,clone=pcall(function() return ch:Clone() end)
        ch.Archivable=old
        if not ok or not clone then return end

        clone.Name="LvkHubLocalPreviewAvatarV3"
        for _,d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool") or d:IsA("Highlight") then
                d:Destroy()
            end
        end
        neutralize(clone)
        clone.Parent=world

        local okBox,_,size=pcall(function() return clone:GetBoundingBox() end)
        if okBox then
            -- Force a fixed neutral orientation. Roblox characters face -Z by default,
            -- so rotate 180 degrees to face a camera placed on +Z.
            clone:PivotTo(CFrame.new(0,size.Y*.5,0)*CFrame.Angles(0,math.rad(180),0))
            neutralize(clone)
            local maxSize=math.max(size.X,size.Y,size.Z)
            local focus=Vector3.new(0,size.Y*.50,0)
            cam.CFrame=CFrame.lookAt(Vector3.new(0,size.Y*.51,math.max(6.8,maxSize*1.9)),focus)
        else
            clone:PivotTo(CFrame.new(0,2.5,0)*CFrame.Angles(0,math.rad(180),0))
            cam.CFrame=CFrame.lookAt(Vector3.new(0,2.5,8),Vector3.new(0,2.5,0))
        end

        previewHighlight=Instance.new("Highlight")
        previewHighlight.Name="LvkHubLocalPreviewChamsV3"
        previewHighlight.Adornee=clone
        previewHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        previewHighlight.FillTransparency=.62
        previewHighlight.OutlineTransparency=.03
        previewHighlight.Enabled=false
        previewHighlight.Parent=world

        previewClone=clone
        lastCharacter=ch
    end

    local function polish(frame)
        local header=frame:FindFirstChild("Header")
        if header then
            local labels={}
            for _,d in ipairs(header:GetChildren()) do
                if d:IsA("TextLabel") then table.insert(labels,d) end
            end
            table.sort(labels,function(a,b) return a.Position.Y.Offset<b.Position.Y.Offset end)
            if labels[1] then labels[1].Text="VISUALS PREVIEW" end
            if labels[2] then labels[2].Text="LOCAL PLAYER / DRAG" end
        end

        for _,d in ipairs(frame:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text:find("PREVIEW DUMMY",1,true) then
                d.Text=d.Text:gsub("PREVIEW DUMMY",LP.DisplayName or LP.Name)
            end
        end

        local cfg=State.Visuals._V5Config or {}
        if previewClone and previewClone.Parent then neutralize(previewClone) end
        if previewHighlight and previewHighlight.Parent then
            local on=State.Visuals.Chams==true
            local color=cfg.ChamsColor or Color3.fromRGB(119,120,255)
            previewHighlight.Enabled=on
            previewHighlight.FillColor=color
            previewHighlight.OutlineColor=color
            previewHighlight.FillTransparency=math.clamp((cfg.ChamsTransparency or 62)/100,0,1)
            previewHighlight.OutlineTransparency=.03
        end
    end

    RunService.RenderStepped:Connect(function(dt)
        timer+=dt
        if timer<.08 then return end
        timer=0

        local frame=UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
        if not frame then return end
        local vp=frame:FindFirstChildWhichIsA("ViewportFrame",true)
        local world=vp and vp:FindFirstChildWhichIsA("WorldModel")
        local localClone=world and world:FindFirstChild("LvkHubLocalPreviewAvatarV3")

        if LP.Character~=lastCharacter or not localClone then
            rebuild(frame)
        end
        polish(frame)
    end)
end
