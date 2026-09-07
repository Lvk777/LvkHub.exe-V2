-- Strong local-player owner for the Visuals Preview viewport.
-- Keeps the LocalPlayer avatar in the preview even when test target selection changes.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local LP=Players.LocalPlayer
    local lastCharacter=nil
    local timer=0

    local function rebuild(frame)
        local vp=frame and frame:FindFirstChildWhichIsA("ViewportFrame",true)
        if not vp then return end
        local world=vp:FindFirstChildWhichIsA("WorldModel")
        local cam=vp.CurrentCamera or vp:FindFirstChildWhichIsA("Camera")
        local ch=LP.Character
        if not world or not cam or not ch then return end
        for _,x in ipairs(world:GetChildren()) do x:Destroy() end
        local old=ch.Archivable;ch.Archivable=true
        local ok,clone=pcall(function() return ch:Clone() end)
        ch.Archivable=old
        if not ok or not clone then return end
        clone.Name="LvkHubLocalPreviewAvatarV2"
        for _,d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool") or d:IsA("Highlight") then d:Destroy()
            elseif d:IsA("BasePart") then d.Anchored=true;d.CanCollide=false;d.CanTouch=false;d.CastShadow=false end
        end
        clone.Parent=world
        local okBox,cf,size=pcall(function() return clone:GetBoundingBox() end)
        if okBox then
            clone:PivotTo(CFrame.new(0,size.Y*.5,0)*cf.Rotation)
            local maxSize=math.max(size.X,size.Y,size.Z)
            cam.CFrame=CFrame.lookAt(Vector3.new(0,size.Y*.52,math.max(6.8,maxSize*1.85)),Vector3.new(0,size.Y*.48,0))
        else
            cam.CFrame=CFrame.lookAt(Vector3.new(0,2.5,8),Vector3.new(0,2.5,0))
        end
        lastCharacter=ch
    end

    local function polishText(frame)
        local header=frame:FindFirstChild("Header")
        if header then
            local labels={}
            for _,d in ipairs(header:GetChildren()) do if d:IsA("TextLabel") then table.insert(labels,d) end end
            table.sort(labels,function(a,b) return a.Position.Y.Offset<b.Position.Y.Offset end)
            if labels[1] then labels[1].Text="VISUALS PREVIEW" end
            if labels[2] then labels[2].Text="LOCAL PLAYER / DRAG" end
        end
        for _,d in ipairs(frame:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text:find("PREVIEW DUMMY",1,true) then
                d.Text=d.Text:gsub("PREVIEW DUMMY",LP.DisplayName or LP.Name)
            end
        end
    end

    RunService.RenderStepped:Connect(function(dt)
        timer+=dt
        if timer<.12 then return end
        timer=0
        local frame=UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
        if not frame then return end
        local vp=frame:FindFirstChildWhichIsA("ViewportFrame",true)
        local world=vp and vp:FindFirstChildWhichIsA("WorldModel")
        local localClone=world and world:FindFirstChild("LvkHubLocalPreviewAvatarV2")
        if LP.Character~=lastCharacter or not localClone then rebuild(frame) end
        polishText(frame)
    end)
end
