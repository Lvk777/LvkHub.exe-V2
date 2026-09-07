-- Opens every ••• panel directly below the Mouse TP row in Movement.
-- Also keeps the local cosmetic BulletTracer attached to the weapon muzzle
-- when V7 had to fall back to a camera-origin anchor.
return function(State, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer

    local oldOpen=UI.OpenDockedPanel
    if type(oldOpen)~="function" then return end

    local function mouseTPBottom()
        local movement=UI.Windows and UI.Windows.Movement
        local page=UI.Pages and UI.Pages.Movement
        if not movement then return nil,nil end

        local x=movement.AbsolutePosition.X
        local y=movement.AbsolutePosition.Y+movement.AbsoluteSize.Y+14

        if page then
            for _,child in ipairs(page:GetChildren()) do
                if child:IsA("Frame") then
                    local label=child:FindFirstChildWhichIsA("TextLabel")
                    if label and label.Text=="Mouse TP" then
                        y=child.AbsolutePosition.Y+child.AbsoluteSize.Y+14
                        break
                    end
                end
            end
        end
        return x,y
    end

    local function place(panel)
        if not panel or not panel.Parent or UI.ActiveDockedPanel~=panel then return end
        local x,y=mouseTPBottom()
        if not x then return end
        panel.Position=UDim2.fromOffset(x,y)
    end

    UI.OpenDockedPanel=function(panel)
        oldOpen(panel)
        task.defer(place,panel)
        task.delay(.03,place,panel)
        task.delay(.10,place,panel)
        task.delay(.25,place,panel)
    end

    ----------------------------------------------------------------------
    -- Cosmetic tracer start correction: use the actual equipped weapon /
    -- first-person viewmodel muzzle. Never substitute the camera position.
    ----------------------------------------------------------------------
    local function worldPos(obj)
        if obj and obj:IsA("Attachment") then return obj.WorldPosition end
        if obj and obj:IsA("BasePart") then return obj.Position end
        return nil
    end

    local function modelMuzzle(root)
        if not root then return nil end
        local muzzle=root:FindFirstChild("Muzzle",true)
        local p=worldPos(muzzle)
        if p then return p end
        local grip=root:FindFirstChild("Grip",true)
        if grip and grip:IsA("BasePart") then
            return grip.Position+grip.CFrame.LookVector*math.max(.4,grip.Size.Z*.5)
        end
        local handle=root:FindFirstChild("Handle",true)
        if handle and handle:IsA("BasePart") then
            return handle.Position+handle.CFrame.LookVector*math.max(.4,handle.Size.Z*.5)
        end
        return nil
    end

    local function weaponMuzzle()
        -- Prefer the first-person viewmodel because it visually matches what
        -- the player sees on screen.
        local cam=Workspace.CurrentCamera
        if cam then
            local best=nil
            for _,obj in ipairs(cam:GetChildren()) do
                if obj:IsA("Model") or obj:IsA("Folder") then
                    local p=modelMuzzle(obj)
                    if p then best=p break end
                end
            end
            if best then return best end
        end

        local ch=LP.Character
        if ch then
            for _,obj in ipairs(ch:GetChildren()) do
                if obj:IsA("Tool") then
                    local p=modelMuzzle(obj)
                    if p then return p end
                end
            end
        end
        return nil
    end

    local watchedFolder=nil
    local connection=nil

    local function fixAnchor(part)
        if not part or not part:IsA("BasePart") then return end
        task.defer(function()
            task.wait()
            if not part.Parent then return end
            local beam=part:FindFirstChildWhichIsA("Beam")
            if not beam then return end -- only the start anchor owns the Beam
            local muzzle=weaponMuzzle()
            if muzzle then part.CFrame=CFrame.new(muzzle) end
        end)
    end

    local function watchTracerFolder()
        local folder=Workspace:FindFirstChild("LvkHubBulletTracersV7")
        if folder==watchedFolder then return end
        if connection then connection:Disconnect(); connection=nil end
        watchedFolder=folder
        if folder then
            for _,child in ipairs(folder:GetChildren()) do fixAnchor(child) end
            connection=folder.ChildAdded:Connect(fixAnchor)
        end
    end

    Workspace.ChildAdded:Connect(function(child)
        if child.Name=="LvkHubBulletTracersV7" then task.defer(watchTracerFolder) end
    end)
    task.defer(watchTracerFolder)
end
