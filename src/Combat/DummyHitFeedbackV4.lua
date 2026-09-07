-- Reliable local hit feedback for managed Workspace.TestPlayers only.
-- Does not target or modify real Player.Character models.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local UIS=game:GetService("UserInputService")
    local LP=Players.LocalPlayer

    State.Combat.DummyHitNotifications=State.Combat.DummyHitNotifications~=false

    local old=UI.Gui:FindFirstChild("LvkHubDummyHitToastsV4")
    if old then old:Destroy() end
    local holder=Instance.new("Frame")
    holder.Name="LvkHubDummyHitToastsV4"
    holder.AnchorPoint=Vector2.new(1,0)
    holder.Position=UDim2.new(1,-16,0,18)
    holder.Size=UDim2.fromOffset(320,260)
    holder.BackgroundTransparency=1
    holder.ZIndex=240
    holder.Parent=UI.Gui
    local list=Instance.new("UIListLayout")
    list.HorizontalAlignment=Enum.HorizontalAlignment.Right
    list.Padding=UDim.new(0,6)
    list.Parent=holder

    local function round(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 5);c.Parent=o end
    local function toast(partName,damage,target)
        if not State.Combat.DummyHitNotifications then return end
        local f=Instance.new("Frame")
        f.Size=UDim2.fromOffset(296,58);f.BackgroundColor3=Color3.fromRGB(18,19,24);f.BorderSizePixel=0;f.ZIndex=241;f.Parent=holder;round(f,7)
        local s=Instance.new("UIStroke");s.Color=UI.Accent;s.Transparency=.12;s.Parent=f
        local t=Instance.new("TextLabel")
        t.BackgroundTransparency=1;t.Position=UDim2.fromOffset(12,5);t.Size=UDim2.new(1,-24,0,22);t.Font=Enum.Font.SourceSansSemibold;t.TextSize=14;t.TextColor3=Color3.fromRGB(242,242,246);t.TextXAlignment=Enum.TextXAlignment.Left;t.ZIndex=242;t.Parent=f
        t.Text="DUMMY HIT • "..tostring(partName)
        local b=t:Clone();b.Position=UDim2.fromOffset(12,28);b.Font=Enum.Font.SourceSans;b.TextSize=12;b.TextColor3=Color3.fromRGB(165,172,194);b.Text=tostring(target and target.Name or "TestDummy").."  •  -"..string.format("%.1f",damage).." HP";b.Parent=f
        task.delay(2.2,function() if f.Parent then f:Destroy() end end)
    end

    local WeaponStats=nil
    pcall(function()
        local a=ReplicatedStorage:FindFirstChild("WeaponSystemAssets")
        local m=a and a:FindFirstChild("Modules")
        local w=m and m:FindFirstChild("WeaponStats")
        if w then WeaponStats=require(w) end
    end)

    local function currentTool()
        local ch=LP.Character
        if not ch then return nil end
        for _,x in ipairs(ch:GetChildren()) do if x:IsA("Tool") and (x:FindFirstChild("WeaponConfig") or x:FindFirstChild("Ammo")) then return x end end
    end
    local function damageFor(partName)
        local base=25
        local tool=currentTool()
        if tool then
            for _,n in ipairs({"Damage","BaseDamage","BulletDamage"}) do
                local v=tool:GetAttribute(n);if typeof(v)=="number" then base=v break end
            end
            if WeaponStats and type(WeaponStats.Get)=="function" then
                local ok,st=pcall(function() return WeaponStats.Get(tool) end)
                if ok and type(st)=="table" then
                    for _,n in ipairs({"baseDamage","bulletDamage","damagePerShot","damage"}) do if typeof(st[n])=="number" then base=st[n] break end end
                    if tostring(partName):lower():find("head",1,true) then base*=tonumber(st.headshotMultiplier or st.headDamageMultiplier or 2) or 2 end
                end
            elseif tostring(partName):lower():find("head",1,true) then base*=2 end
        end
        return math.clamp(tonumber(base) or 25,1,500)
    end
    local function dummyFrom(inst)
        local p=inst
        while p and p~=Workspace do
            if p:IsA("Model") and Registry.IsBot(p) then return p end
            p=p.Parent
        end
    end
    local function targetPartName(inst,model)
        if not inst then return (State.Combat.AimPart or "Head") end
        if inst.Name=="Handle" then
            local w=inst:FindFirstChild("AccessoryWeld") or inst:FindFirstChildWhichIsA("Weld")
            if w and w.Part1 and w.Part1:IsDescendantOf(model) then return w.Part1.Name end
        end
        return inst.Name
    end
    local function muzzlePos()
        local tool=currentTool()
        if tool then
            local muzzle=tool:FindFirstChild("Muzzle",true)
            if muzzle then
                if muzzle:IsA("Attachment") then return muzzle.WorldPosition end
                if muzzle:IsA("BasePart") then return muzzle.Position end
            end
        end
        local cam=Workspace.CurrentCamera
        return cam and cam.CFrame.Position or nil
    end

    local last=0
    local function report(model,part)
        if not model or not Registry.IsBot(model) then return end
        local now=os.clock();if now-last<.035 then return end;last=now
        local pn=targetPartName(part,model)
        local dmg=damageFor(pn)
        toast(pn,dmg,model)
        if State.Local and State.Local.HitSound and shared.LvkHubPlayHitSound then task.defer(shared.LvkHubPlayHitSound) end
    end

    local function selectedTarget()
        local api=shared.LvkHubDummyAimAPI
        if type(api)=="table" and type(api.ChooseTarget)=="function" then
            local requireVisible=true
            if State.Combat.MagicBullets then requireVisible=not (State.Combat.MagicThroughWalls==true) end
            local m,p=api.ChooseTarget(requireVisible)
            if m and Registry.IsBot(m) then return m,p end
        end
    end

    local function rayReport(direction)
        if State.Combat.MagicBullets or State.Combat.SilentAim then
            local m,p=selectedTarget();if m then report(m,p);return end
        end
        local origin=muzzlePos();if not origin then return end
        local dir=direction
        local cam=Workspace.CurrentCamera
        if typeof(dir)~="Vector3" or dir.Magnitude<=0 then dir=cam and cam.CFrame.LookVector or nil end
        if not dir then return end
        local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={LP.Character,cam};rp.IgnoreWater=true
        local hit=Workspace:Raycast(origin,dir.Unit*20000,rp)
        if hit then local m=dummyFrom(hit.Instance);if m then report(m,hit.Instance) end end
    end

    local installed=false
    local lastBuilderShot=0
    local function findBuilder()
        local ps=LP:FindFirstChild("PlayerScripts");if not ps then return nil end
        for _,d in ipairs(ps:GetDescendants()) do if d:IsA("ModuleScript") and d.Name=="WeaponShotBuilder" then return d end end
    end
    local function install()
        if installed then return true end
        local mod=findBuilder();if not mod then return false end
        local ok,b=pcall(require,mod);if not ok or type(b)~="table" or type(b.GetSpreadDirection)~="function" then return false end
        local prev=b.GetSpreadDirection
        b.GetSpreadDirection=function(baseDirection,spreadState)
            local result=prev(baseDirection,spreadState)
            lastBuilderShot=os.clock()
            task.defer(rayReport,result or baseDirection)
            return result
        end
        installed=true;return true
    end
    task.spawn(function() while not installed do install();task.wait(.75) end end)

    UIS.InputBegan:Connect(function(i,processed)
        if i.UserInputType~=Enum.UserInputType.MouseButton1 or UIS:GetFocusedTextBox() then return end
        local started=os.clock()
        task.delay(.06,function()
            if lastBuilderShot<started then rayReport(nil) end
        end)
    end)
end
