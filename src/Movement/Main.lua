-- Basic local movement helpers. No anti-cheat bypass/evasion logic.

return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Movement

    UI.Section(page,"Movement")
    UI.Toggle(page,"Fly",function() return State.Movement.Fly end,function(v) State.Movement.Fly=v end)
    UI.Number(page,"Fly Speed",function() return State.Movement.FlySpeed or 65 end,function(v) State.Movement.FlySpeed=v end,10,300)
    UI.Toggle(page,"CarFly",function() return State.Movement.CarFly end,function(v) State.Movement.CarFly=v end)
    UI.Number(page,"CarFly Speed",function() return State.Movement.CarFlySpeed or 90 end,function(v) State.Movement.CarFlySpeed=v end,10,400)
    UI.Toggle(page,"Noclip",function() return State.Movement.Noclip end,function(v) State.Movement.Noclip=v end)
    UI.Toggle(page,"Speed",function() return State.Movement.Speed end,function(v) State.Movement.Speed=v end)
    UI.Number(page,"WalkSpeed",function() return State.Movement.SpeedValue end,function(v) State.Movement.SpeedValue=v end,16,120)
    UI.Toggle(page,"Mouse TP (Alt + click)",function() return State.Movement.MouseTP end,function(v) State.Movement.MouseTP=v end)

    local _,status=UI.Row(page,"Fly: WASD + Space/Ctrl  •  CarFly: WASD + E/Q")
    status.TextColor3=Color3.fromRGB(160,170,200)

    local noclipOriginal=setmetatable({}, {__mode="k"})
    local flyAttachment,flyVelocity,flyOrientation=nil,nil,nil

    -- IMPORTANT: when Speed is OFF the hub must not write Humanoid.WalkSpeed at all.
    -- The old code forced 16 every Heartbeat, which broke games that use Shift sprint
    -- and could interfere with movement/jump controllers even with every toggle disabled.
    local speedActive=false
    local speedHumanoid=nil
    local speedOriginal=nil

    local function character()
        return LP.Character, LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"), LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    end

    local function restoreSpeed()
        if speedActive and speedHumanoid and speedHumanoid.Parent and speedOriginal~=nil then
            pcall(function() speedHumanoid.WalkSpeed=speedOriginal end)
        end
        speedActive=false
        speedHumanoid=nil
        speedOriginal=nil
    end

    local function ensureFly(root)
        if flyVelocity and flyVelocity.Parent and flyAttachment and flyAttachment.Parent==root then return end
        if flyVelocity then flyVelocity:Destroy() end
        if flyOrientation then flyOrientation:Destroy() end
        if flyAttachment then flyAttachment:Destroy() end
        flyAttachment=Instance.new("Attachment"); flyAttachment.Name="LvkHubFlyAttachment"; flyAttachment.Parent=root
        flyVelocity=Instance.new("LinearVelocity"); flyVelocity.Name="LvkHubFlyVelocity"; flyVelocity.Attachment0=flyAttachment; flyVelocity.RelativeTo=Enum.ActuatorRelativeTo.World; flyVelocity.MaxForce=math.huge; flyVelocity.VectorVelocity=Vector3.zero; flyVelocity.Parent=root
        flyOrientation=Instance.new("AlignOrientation"); flyOrientation.Name="LvkHubFlyOrientation"; flyOrientation.Attachment0=flyAttachment; flyOrientation.Mode=Enum.OrientationAlignmentMode.OneAttachment; flyOrientation.MaxTorque=math.huge; flyOrientation.Responsiveness=25; flyOrientation.Parent=root
    end
    local function clearFly()
        if flyVelocity then flyVelocity:Destroy(); flyVelocity=nil end
        if flyOrientation then flyOrientation:Destroy(); flyOrientation=nil end
        if flyAttachment then flyAttachment:Destroy(); flyAttachment=nil end
    end

    local function moveVector(cam,upKey,downKey)
        local f=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
        if f.Magnitude>0 then f=f.Unit end
        local r=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)
        if r.Magnitude>0 then r=r.Unit end
        local v=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then v+=f end
        if UIS:IsKeyDown(Enum.KeyCode.S) then v-=f end
        if UIS:IsKeyDown(Enum.KeyCode.D) then v+=r end
        if UIS:IsKeyDown(Enum.KeyCode.A) then v-=r end
        if upKey and UIS:IsKeyDown(upKey) then v+=Vector3.yAxis end
        if downKey and UIS:IsKeyDown(downKey) then v-=Vector3.yAxis end
        return v.Magnitude>0 and v.Unit or Vector3.zero
    end

    local function seatedVehicle(hum)
        local seat=hum and hum.SeatPart
        if not seat then return nil,nil end
        local model=seat:FindFirstAncestorOfClass("Model")
        if not model then return nil,nil end
        local root=seat:IsA("BasePart") and seat or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
        return model,root
    end

    UIS.InputBegan:Connect(function(input,processed)
        if processed or not State.Movement.MouseTP then return end
        if input.UserInputType==Enum.UserInputType.MouseButton1 and (UIS:IsKeyDown(Enum.KeyCode.LeftAlt) or UIS:IsKeyDown(Enum.KeyCode.RightAlt)) then
            local cam=Workspace.CurrentCamera; local _,hum,root=character(); if not cam or not hum or not root then return end
            local mouse=UIS:GetMouseLocation(); local ray=cam:ViewportPointToRay(mouse.X,mouse.Y)
            local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={LP.Character}
            local hit=Workspace:Raycast(ray.Origin,ray.Direction*10000,params)
            if hit then root.CFrame=CFrame.new(hit.Position+Vector3.new(0,3,0),hit.Position+Vector3.new(0,3,0)+root.CFrame.LookVector) end
        end
    end)

    RunService.Heartbeat:Connect(function()
        local ch,hum,root=character()

        if State.Movement.Speed and hum then
            if not speedActive or speedHumanoid~=hum then
                restoreSpeed()
                speedActive=true
                speedHumanoid=hum
                speedOriginal=hum.WalkSpeed
            end
            local wanted=State.Movement.SpeedValue or 32
            if math.abs(hum.WalkSpeed-wanted)>.01 then hum.WalkSpeed=wanted end
        elseif speedActive then
            restoreSpeed()
        end

        if ch then
            if State.Movement.Noclip then
                for _,p in ipairs(ch:GetDescendants()) do
                    if p:IsA("BasePart") then
                        if noclipOriginal[p]==nil then noclipOriginal[p]=p.CanCollide end
                        p.CanCollide=false
                    end
                end
            else
                for p,v in pairs(noclipOriginal) do
                    if p and p.Parent then p.CanCollide=v end
                    noclipOriginal[p]=nil
                end
            end
        end

        local cam=Workspace.CurrentCamera
        if State.Movement.Fly and root and hum and cam then
            ensureFly(root)
            local v=moveVector(cam,Enum.KeyCode.Space,Enum.KeyCode.LeftControl)
            flyVelocity.VectorVelocity=v*math.max(10,State.Movement.FlySpeed or 65)
            local flat=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
            if flat.Magnitude>0 then flyOrientation.CFrame=CFrame.lookAt(root.Position,root.Position+flat.Unit) end
        else
            clearFly()
        end

        if State.Movement.CarFly and hum and cam then
            local _,vroot=seatedVehicle(hum)
            if vroot then
                local dir=moveVector(cam,Enum.KeyCode.E,Enum.KeyCode.Q)
                local speed=math.max(10,State.Movement.CarFlySpeed or 90)
                if dir.Magnitude>0 then vroot.AssemblyLinearVelocity=dir*speed else vroot.AssemblyLinearVelocity=Vector3.zero end
                local flat=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
                if flat.Magnitude>0 then vroot.CFrame=CFrame.lookAt(vroot.Position,vroot.Position+flat.Unit) end
            end
        end
    end)

    LP.CharacterAdded:Connect(function()
        restoreSpeed()
        clearFly()
        table.clear(noclipOriginal)
    end)
end
