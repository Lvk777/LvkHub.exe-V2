-- LvkHub.exe WeaponSystem dummy adapter
-- Local Workspace.TestPlayers practice only.
-- WeaponShotBuilder is observed as the shot hook, but the real direction returned
-- to the game is preserved. Silent Aim / Magic Bullets are simulated only against
-- local TestPlayers, so Roblox Player.Character models are never redirected to.

return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")

    local LP=Players.LocalPlayer
    local page=UI.Pages.Combat

    if State.Combat.DummyHitNotifications==nil then State.Combat.DummyHitNotifications=true end
    if State.Combat.DummyInventoryVisible==nil then State.Combat.DummyInventoryVisible=false end

    local function allowed()
        return Registry.PracticeAllowed and Registry.PracticeAllowed() or false
    end

    local function chooseTarget(requireVisible)
        local api=shared.LvkHubDummyAimAPI
        if api and type(api.ChooseTarget)=="function" then
            return api.ChooseTarget(requireVisible)
        end
        return nil
    end

    -- Small local toast ----------------------------------------------------
    local toastHolder=UI.Gui:FindFirstChild("LvkHubDummyHitToasts")
    if toastHolder then toastHolder:Destroy() end
    toastHolder=Instance.new("Frame")
    toastHolder.Name="LvkHubDummyHitToasts"
    toastHolder.AnchorPoint=Vector2.new(1,0)
    toastHolder.Position=UDim2.new(1,-18,0,18)
    toastHolder.Size=UDim2.fromOffset(300,220)
    toastHolder.BackgroundTransparency=1
    toastHolder.Parent=UI.Gui
    local toastList=Instance.new("UIListLayout")
    toastList.FillDirection=Enum.FillDirection.Vertical
    toastList.HorizontalAlignment=Enum.HorizontalAlignment.Right
    toastList.VerticalAlignment=Enum.VerticalAlignment.Top
    toastList.Padding=UDim.new(0,6)
    toastList.Parent=toastHolder

    local function notify(title,body)
        if not State.Combat.DummyHitNotifications then return end
        local frame=Instance.new("Frame")
        frame.Size=UDim2.fromOffset(278,54)
        frame.BackgroundColor3=Color3.fromRGB(20,20,22)
        frame.BorderSizePixel=0
        frame.Parent=toastHolder
        local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,6) c.Parent=frame
        local st=Instance.new("UIStroke") st.Color=Color3.fromRGB(119,120,255) st.Thickness=1 st.Transparency=.15 st.Parent=frame
        local bar=Instance.new("Frame")
        bar.Size=UDim2.fromOffset(3,38)
        bar.Position=UDim2.fromOffset(7,8)
        bar.BorderSizePixel=0
        bar.BackgroundColor3=Color3.fromRGB(119,120,255)
        bar.Parent=frame
        local bc=Instance.new("UICorner") bc.CornerRadius=UDim.new(1,0) bc.Parent=bar
        local t=Instance.new("TextLabel")
        t.BackgroundTransparency=1
        t.Position=UDim2.fromOffset(17,5)
        t.Size=UDim2.new(1,-23,0,20)
        t.Font=Enum.Font.SourceSansSemibold
        t.TextSize=14
        t.TextColor3=Color3.fromRGB(235,235,235)
        t.TextXAlignment=Enum.TextXAlignment.Left
        t.Text=title
        t.Parent=frame
        local b=Instance.new("TextLabel")
        b.BackgroundTransparency=1
        b.Position=UDim2.fromOffset(17,25)
        b.Size=UDim2.new(1,-23,0,22)
        b.Font=Enum.Font.SourceSans
        b.TextSize=13
        b.TextColor3=Color3.fromRGB(170,175,190)
        b.TextXAlignment=Enum.TextXAlignment.Left
        b.Text=body
        b.Parent=frame
        task.delay(2.2,function()
            if frame and frame.Parent then frame:Destroy() end
        end)
    end

    -- Inventory Viewer -----------------------------------------------------
    UI.Section(page,"DUMMY FEEDBACK")
    UI.Toggle(page,"Hit Notifications",function() return State.Combat.DummyHitNotifications end,function(v)
        State.Combat.DummyHitNotifications=v
    end)

    local _,invTargetLabel=UI.Row(page,"Inventory target: AUTO")
    invTargetLabel.TextColor3=Color3.fromRGB(150,200,255)

    local slotFrames={}
    local slotLabels={}
    for i=1,4 do
        local f,l=UI.Row(page,"Slot "..i..": Empty")
        f.Visible=false
        slotFrames[i]=f
        slotLabels[i]=l
    end

    UI.Button(page,"Inventory Viewer","SHOW/HIDE",function()
        State.Combat.DummyInventoryVisible=not State.Combat.DummyInventoryVisible
        for _,f in ipairs(slotFrames) do f.Visible=State.Combat.DummyInventoryVisible end
    end)

    local function inventoryTarget()
        local selected=State.Combat.SelectedBot
        if selected and Registry.IsBot(selected) then return selected end
        local list={}
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then table.insert(list,model) end
        end
        table.sort(list,function(a,b) return a.Name<b.Name end)
        return list[1]
    end

    local function refreshInventory()
        local model=inventoryTarget()
        if not model then
            invTargetLabel.Text="Inventory target: none"
            for i=1,4 do slotLabels[i].Text="Slot "..i..": Empty" end
            return
        end
        invTargetLabel.Text="Inventory target: "..model.Name
        local slots=Registry.GetDummyInventory and Registry.GetDummyInventory(model) or {"Empty","Empty","Empty","Empty"}
        for i=1,4 do slotLabels[i].Text="Slot "..i..": "..tostring(slots[i] or "Empty") end
    end

    -- WeaponSystem discovery ----------------------------------------------
    local function findWeaponShotBuilder()
        local ps=LP:FindFirstChild("PlayerScripts")
        if not ps then return nil end
        local client=ps:FindFirstChild("Client")
        local systems=client and client:FindFirstChild("Systems")
        local gun=systems and systems:FindFirstChild("GunSystem")
        local vm=gun and gun:FindFirstChild("WeaponViewmodelController")
        local exact=vm and vm:FindFirstChild("WeaponShotBuilder")
        if exact and exact:IsA("ModuleScript") then return exact end
        for _,d in ipairs(ps:GetDescendants()) do
            if d:IsA("ModuleScript") and d.Name=="WeaponShotBuilder" then return d end
        end
        return nil
    end

    local WeaponStats=nil
    pcall(function()
        local assets=ReplicatedStorage:FindFirstChild("WeaponSystemAssets")
        local mods=assets and assets:FindFirstChild("Modules")
        local ws=mods and mods:FindFirstChild("WeaponStats")
        if ws then WeaponStats=require(ws) end
    end)

    local function currentTool()
        local ch=LP.Character
        return ch and ch:FindFirstChildWhichIsA("Tool") or nil
    end

    local function statNumber(stats,keys)
        if type(stats)~="table" then return nil end
        for _,k in ipairs(keys) do
            local v=stats[k]
            if typeof(v)=="number" then return v end
        end
        local d=stats.damage
        if type(d)=="table" then
            for _,k in ipairs({"base","default","body","torso","nearDamage","damage"}) do
                if typeof(d[k])=="number" then return d[k] end
            end
        end
        return nil
    end

    local function practiceDamage(partName)
        local tool=currentTool()
        local stats=nil
        if tool and WeaponStats and type(WeaponStats.Get)=="function" then
            pcall(function() stats=WeaponStats.Get(tool) end)
        end

        local base=statNumber(stats,{"baseDamage","bulletDamage","damagePerShot","damage","Damage"})
        if not base and tool then
            for _,a in ipairs({"Damage","BaseDamage","MeleeDamage"}) do
                local v=tool:GetAttribute(a)
                if typeof(v)=="number" then base=v break end
            end
        end
        base=tonumber(base) or 25

        local mult=1
        local lower=string.lower(partName or "")
        if lower:find("head",1,true) then
            mult=(type(stats)=="table" and (stats.headshotMultiplier or stats.headDamageMultiplier or stats.headMultiplier)) or 2
        elseif lower:find("arm",1,true) or lower:find("leg",1,true) then
            mult=(type(stats)=="table" and (stats.limbDamageMultiplier or stats.limbMultiplier)) or 1
        end
        return math.clamp(base*(tonumber(mult) or 1),1,500)
    end

    local function dummyFromInstance(inst)
        local cur=inst
        while cur and cur~=Workspace do
            if cur:IsA("Model") and Registry.IsBot(cur) then return cur end
            cur=cur.Parent
        end
        return nil
    end

    local function bodyPartName(inst,model)
        if not inst then return "Unknown" end
        if inst.Name=="Handle" then
            local accessory=inst:FindFirstAncestorWhichIsA("Accessory")
            if accessory then
                local weld=inst:FindFirstChild("AccessoryWeld") or inst:FindFirstChildWhichIsA("Weld")
                if weld and weld.Part1 and weld.Part1:IsDescendantOf(model) then return weld.Part1.Name end
            end
        end
        return inst.Name
    end

    local lastDamageAt=setmetatable({}, {__mode="k"})
    local function applyDummyHit(model,inst)
        if not model or not Registry.IsBot(model) then return end
        local hum=Registry.HumanoidOf(model)
        if not hum or hum.Health<=0 then return end

        local now=os.clock()
        if lastDamageAt[hum] and now-lastDamageAt[hum]<0.025 then return end
        lastDamageAt[hum]=now

        local partName=bodyPartName(inst,model)
        local damage=practiceDamage(partName)
        local old=hum.Health
        hum.Health=math.max(0,old-damage)
        local dealt=old-hum.Health

        notify("DUMMY HIT • "..partName,string.format("%s  -%.1f HP  (%.1f → %.1f)",model.Name,dealt,old,hum.Health))

        if hum.Health<=0 then
            task.delay(1.5,function()
                if model and model.Parent and hum and hum.Parent then hum.Health=hum.MaxHealth end
            end)
        end
    end

    local function raycastNormalDummy(origin,direction)
        if typeof(origin)~="Vector3" or typeof(direction)~="Vector3" or direction.Magnitude<=0 then return end
        local params=RaycastParams.new()
        params.IgnoreWater=true
        params.FilterType=Enum.RaycastFilterType.Exclude
        local exclude={}
        if LP.Character then table.insert(exclude,LP.Character) end
        if Workspace.CurrentCamera then table.insert(exclude,Workspace.CurrentCamera) end
        params.FilterDescendantsInstances=exclude
        local result=Workspace:Raycast(origin,direction.Unit*20000,params)
        if not result then return end
        local model=dummyFromInstance(result.Instance)
        if model then applyDummyHit(model,result.Instance) end
    end

    local installed=false
    local builder=nil
    local originalResolve=nil
    local originalSpread=nil
    local shotContext=nil

    local function install()
        if installed or not allowed() then return installed end
        local mod=findWeaponShotBuilder()
        if not mod then return false end

        local ok,t=pcall(require,mod)
        if not ok or type(t)~="table" or type(t.ResolveBaseDirection)~="function" or type(t.GetSpreadDirection)~="function" then
            return false
        end

        builder=t
        originalResolve=t.ResolveBaseDirection
        originalSpread=t.GetSpreadDirection

        -- ResolveBaseDirection is used only as a reliable local shot context hook.
        -- We preserve its original return value, so outgoing game/server shot data
        -- is not redirected by this dummy practice adapter.
        t.ResolveBaseDirection=function(p1)
            local base=originalResolve(p1)
            local origin=p1 and (p1.shotOrigin or p1.serverShotOrigin) or nil
            if typeof(origin)~="Vector3" then
                local cam=p1 and p1.camera or Workspace.CurrentCamera
                origin=cam and cam.CFrame.Position or nil
            end

            local target,targetPart=nil,nil
            local throughWalls=false
            if allowed() and State.Combat.MagicBullets then
                throughWalls=State.Combat.MagicThroughWalls==true
                target,targetPart=chooseTarget(not throughWalls)
            elseif allowed() and State.Combat.SilentAim then
                target,targetPart=chooseTarget(State.Combat.WallCheck==true)
            end

            shotContext={
                origin=origin,
                target=(target and Registry.IsBot(target)) and target or nil,
                part=targetPart,
                throughWalls=throughWalls,
                time=os.clock(),
            }
            return base
        end

        -- Preserve the real spread/direction. For local dummies only, simulate the
        -- practice hit selected by Silent Aim/Magic Bullets. With neither enabled,
        -- a normal ray against the actual returned direction detects manual hits.
        t.GetSpreadDirection=function(baseDirection,spreadState)
            local result=originalSpread(baseDirection,spreadState)
            local ctx=shotContext
            if ctx and ctx.origin and os.clock()-ctx.time<0.30 then
                if ctx.target and ctx.part and Registry.IsBot(ctx.target) then
                    task.defer(applyDummyHit,ctx.target,ctx.part)
                elseif result then
                    task.defer(raycastNormalDummy,ctx.origin,result)
                end
            end
            return result
        end

        shared.LvkHubWeaponSystemDummyAdapter={
            Module=mod,
            Builder=builder,
            Installed=true,
            DummyOnly=true,
            PreservesRealShotDirection=true,
        }
        installed=true
        return true
    end

    task.spawn(function()
        for _=1,40 do
            if install() then
                notify("WeaponSystem adapter","Dummy Silent Aim / Magic Bullets ready")
                break
            end
            task.wait(.25)
        end
    end)

    local timer=0
    RunService.Heartbeat:Connect(function(dt)
        timer+=dt
        if timer>=.35 then
            timer=0
            refreshInventory()
            if not installed then install() end
        end
    end)

    refreshInventory()
end
