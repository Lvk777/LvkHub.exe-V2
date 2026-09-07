-- LvkHub.exe WeaponSystem dummy adapter V3
-- LOCAL Workspace.TestPlayers practice only.
-- Real game shot direction is preserved; hit feedback/damage is simulated only on local dummies.

return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local UIS=game:GetService("UserInputService")

    local LP=Players.LocalPlayer
    local page=UI.Pages.Combat

    if State.Combat.DummyHitNotifications==nil then State.Combat.DummyHitNotifications=true end
    if State.Combat.DummyInventoryVisible==nil then State.Combat.DummyInventoryVisible=false end

    local function allowed()
        return Registry.PracticeAllowed and Registry.PracticeAllowed() or false
    end

    local function chooseTarget(requireVisible)
        local api=shared.LvkHubDummyAimAPI
        if api and type(api.ChooseTarget)=="function" then return api.ChooseTarget(requireVisible) end
        return nil
    end

    local function rounded(obj,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 5)
        c.Parent=obj
    end

    local function drag(frame,handle)
        local dragging=false
        local startMouse,startPos
        handle.Active=true
        handle.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=true
                startMouse=input.Position
                startPos=frame.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local d=input.Position-startMouse
                frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end)
    end

    ------------------------------------------------------------------------
    -- Hit toasts.
    ------------------------------------------------------------------------
    local oldToasts=UI.Gui:FindFirstChild("LvkHubDummyHitToastsV3")
    if oldToasts then oldToasts:Destroy() end
    local toastHolder=Instance.new("Frame")
    toastHolder.Name="LvkHubDummyHitToastsV3"
    toastHolder.AnchorPoint=Vector2.new(1,0)
    toastHolder.Position=UDim2.new(1,-18,0,18)
    toastHolder.Size=UDim2.fromOffset(320,250)
    toastHolder.BackgroundTransparency=1
    toastHolder.ZIndex=120
    toastHolder.Parent=UI.Gui
    local toastList=Instance.new("UIListLayout")
    toastList.FillDirection=Enum.FillDirection.Vertical
    toastList.HorizontalAlignment=Enum.HorizontalAlignment.Right
    toastList.VerticalAlignment=Enum.VerticalAlignment.Top
    toastList.Padding=UDim.new(0,6)
    toastList.Parent=toastHolder

    local function notify(title,body)
        if not State.Combat.DummyHitNotifications then return end
        local f=Instance.new("Frame")
        f.Size=UDim2.fromOffset(294,58)
        f.BackgroundColor3=Color3.fromRGB(18,19,24)
        f.BorderSizePixel=0
        f.ZIndex=121
        f.Parent=toastHolder
        rounded(f,7)
        local st=Instance.new("UIStroke")
        st.Color=Color3.fromRGB(119,120,255)
        st.Transparency=.12
        st.Parent=f
        local bar=Instance.new("Frame")
        bar.Position=UDim2.fromOffset(7,8)
        bar.Size=UDim2.fromOffset(3,42)
        bar.BorderSizePixel=0
        bar.BackgroundColor3=Color3.fromRGB(119,120,255)
        bar.ZIndex=122
        bar.Parent=f
        rounded(bar,2)
        local t=Instance.new("TextLabel")
        t.BackgroundTransparency=1
        t.Position=UDim2.fromOffset(17,5)
        t.Size=UDim2.new(1,-24,0,22)
        t.Font=Enum.Font.SourceSansSemibold
        t.TextSize=14
        t.TextColor3=Color3.fromRGB(240,240,244)
        t.TextXAlignment=Enum.TextXAlignment.Left
        t.Text=title
        t.ZIndex=122
        t.Parent=f
        local b=Instance.new("TextLabel")
        b.BackgroundTransparency=1
        b.Position=UDim2.fromOffset(17,28)
        b.Size=UDim2.new(1,-24,0,20)
        b.Font=Enum.Font.SourceSans
        b.TextSize=12
        b.TextColor3=Color3.fromRGB(165,170,190)
        b.TextXAlignment=Enum.TextXAlignment.Left
        b.Text=body
        b.ZIndex=122
        b.Parent=f
        task.delay(2.3,function() if f and f.Parent then f:Destroy() end end)
    end

    ------------------------------------------------------------------------
    -- Draggable 4-slot inventory viewer. Reads only local dummy snapshot.
    ------------------------------------------------------------------------
    UI.Section(page,"DUMMY FEEDBACK")
    UI.Toggle(page,"Hit Notifications",function() return State.Combat.DummyHitNotifications end,function(v) State.Combat.DummyHitNotifications=v end)

    local oldInv=UI.Gui:FindFirstChild("LvkHubDummyInventoryV3")
    if oldInv then oldInv:Destroy() end
    local inv=Instance.new("Frame")
    inv.Name="LvkHubDummyInventoryV3"
    inv.Size=UDim2.fromOffset(286,290)
    inv.Position=UDim2.new(1,-304,0,286)
    inv.BackgroundColor3=Color3.fromRGB(15,16,20)
    inv.BorderSizePixel=0
    inv.Visible=false
    inv.ZIndex=100
    inv.Parent=UI.Gui
    rounded(inv,8)
    local invStroke=Instance.new("UIStroke")
    invStroke.Color=Color3.fromRGB(70,72,88)
    invStroke.Transparency=.12
    invStroke.Parent=inv

    local invHeader=Instance.new("Frame")
    invHeader.Size=UDim2.new(1,0,0,44)
    invHeader.BackgroundColor3=Color3.fromRGB(20,21,27)
    invHeader.BorderSizePixel=0
    invHeader.ZIndex=101
    invHeader.Parent=inv
    rounded(invHeader,8)
    local accent=Instance.new("Frame")
    accent.Position=UDim2.fromOffset(8,10)
    accent.Size=UDim2.fromOffset(3,24)
    accent.BackgroundColor3=Color3.fromRGB(119,120,255)
    accent.BorderSizePixel=0
    accent.ZIndex=102
    accent.Parent=invHeader
    rounded(accent,2)
    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Position=UDim2.fromOffset(18,3)
    title.Size=UDim2.new(1,-26,0,20)
    title.Font=Enum.Font.SourceSansSemibold
    title.TextSize=14
    title.TextColor3=Color3.fromRGB(240,240,244)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Text="DUMMY INVENTORY"
    title.ZIndex=102
    title.Parent=invHeader
    local sub=Instance.new("TextLabel")
    sub.BackgroundTransparency=1
    sub.Position=UDim2.fromOffset(18,22)
    sub.Size=UDim2.new(1,-26,0,15)
    sub.Font=Enum.Font.SourceSans
    sub.TextSize=10
    sub.TextColor3=Color3.fromRGB(135,140,158)
    sub.TextXAlignment=Enum.TextXAlignment.Left
    sub.Text="DRAG • LOCAL SNAPSHOT • 4 SLOTS"
    sub.ZIndex=102
    sub.Parent=invHeader
    drag(inv,invHeader)

    local targetLabel=Instance.new("TextLabel")
    targetLabel.Position=UDim2.fromOffset(12,52)
    targetLabel.Size=UDim2.new(1,-92,0,25)
    targetLabel.BackgroundTransparency=1
    targetLabel.Font=Enum.Font.SourceSansSemibold
    targetLabel.TextSize=12
    targetLabel.TextColor3=Color3.fromRGB(180,195,255)
    targetLabel.TextXAlignment=Enum.TextXAlignment.Left
    targetLabel.Text="Target: AUTO"
    targetLabel.ZIndex=101
    targetLabel.Parent=inv

    local nextButton=Instance.new("TextButton")
    nextButton.AnchorPoint=Vector2.new(1,0)
    nextButton.Position=UDim2.new(1,-12,0,54)
    nextButton.Size=UDim2.fromOffset(64,22)
    nextButton.BackgroundColor3=Color3.fromRGB(35,36,44)
    nextButton.BorderSizePixel=0
    nextButton.Font=Enum.Font.SourceSansSemibold
    nextButton.TextSize=11
    nextButton.TextColor3=Color3.fromRGB(220,220,228)
    nextButton.Text="NEXT"
    nextButton.ZIndex=102
    nextButton.Parent=inv
    rounded(nextButton,4)

    local slotNames={}
    for i=1,4 do
        local y=84+(i-1)*47
        local card=Instance.new("Frame")
        card.Position=UDim2.fromOffset(12,y)
        card.Size=UDim2.new(1,-24,0,39)
        card.BackgroundColor3=Color3.fromRGB(23,24,30)
        card.BorderSizePixel=0
        card.ZIndex=101
        card.Parent=inv
        rounded(card,6)
        local num=Instance.new("TextLabel")
        num.Position=UDim2.fromOffset(7,7)
        num.Size=UDim2.fromOffset(28,25)
        num.BackgroundColor3=Color3.fromRGB(119,120,255)
        num.BorderSizePixel=0
        num.Font=Enum.Font.SourceSansBold
        num.TextSize=12
        num.TextColor3=Color3.fromRGB(255,255,255)
        num.Text=tostring(i)
        num.ZIndex=102
        num.Parent=card
        rounded(num,5)
        local name=Instance.new("TextLabel")
        name.Position=UDim2.fromOffset(44,0)
        name.Size=UDim2.new(1,-52,1,0)
        name.BackgroundTransparency=1
        name.Font=Enum.Font.SourceSans
        name.TextSize=13
        name.TextColor3=Color3.fromRGB(225,225,232)
        name.TextXAlignment=Enum.TextXAlignment.Left
        name.Text="Empty"
        name.ZIndex=102
        name.Parent=card
        slotNames[i]=name
    end

    local footer=Instance.new("TextLabel")
    footer.Position=UDim2.fromOffset(12,272)
    footer.Size=UDim2.new(1,-24,0,14)
    footer.BackgroundTransparency=1
    footer.Font=Enum.Font.Code
    footer.TextSize=9
    footer.TextColor3=Color3.fromRGB(105,110,128)
    footer.TextXAlignment=Enum.TextXAlignment.Left
    footer.Text="Workspace.TestPlayers only"
    footer.ZIndex=101
    footer.Parent=inv

    UI.Button(page,"Inventory Viewer","OPEN",function()
        State.Combat.DummyInventoryVisible=not State.Combat.DummyInventoryVisible
        inv.Visible=State.Combat.DummyInventoryVisible
    end)

    local function dummyList()
        local list={}
        for m in pairs(Registry.Bots) do if Registry.IsBot(m) then table.insert(list,m) end end
        table.sort(list,function(a,b) return a.Name<b.Name end)
        return list
    end

    local inventoryOverride=nil
    nextButton.MouseButton1Click:Connect(function()
        local list=dummyList()
        if #list==0 then inventoryOverride=nil return end
        local idx=table.find(list,inventoryOverride) or table.find(list,State.Combat.SelectedBot) or 0
        inventoryOverride=list[idx%#list+1]
    end)

    local function inventoryTarget()
        if inventoryOverride and Registry.IsBot(inventoryOverride) then return inventoryOverride end
        if State.Combat.SelectedBot and Registry.IsBot(State.Combat.SelectedBot) then return State.Combat.SelectedBot end
        return dummyList()[1]
    end

    local function refreshInventory()
        local model=inventoryTarget()
        if not model then
            targetLabel.Text="Target: none"
            for i=1,4 do slotNames[i].Text="Empty" end
            return
        end
        targetLabel.Text="Target: "..model.Name
        local slots=Registry.GetDummyInventory and Registry.GetDummyInventory(model) or {"Empty","Empty","Empty","Empty"}
        for i=1,4 do slotNames[i].Text=tostring(slots[i] or "Empty") end
    end

    ------------------------------------------------------------------------
    -- Weapon stats + dummy damage.
    ------------------------------------------------------------------------
    local WeaponStats=nil
    pcall(function()
        local assets=ReplicatedStorage:FindFirstChild("WeaponSystemAssets")
        local mods=assets and assets:FindFirstChild("Modules")
        local ws=mods and mods:FindFirstChild("WeaponStats")
        if ws then WeaponStats=require(ws) end
    end)

    local function currentTool()
        local ch=LP.Character
        if not ch then return nil end
        for _,x in ipairs(ch:GetChildren()) do
            if x:IsA("Tool") and x:FindFirstChild("WeaponConfig") then return x end
        end
        return nil
    end

    local function currentStats()
        local tool=currentTool()
        if not tool or not WeaponStats or type(WeaponStats.Get)~="function" then return nil end
        local ok,stats=pcall(function() return WeaponStats.Get(tool) end)
        return ok and stats or nil
    end

    local function statNumber(stats,keys)
        if type(stats)~="table" then return nil end
        for _,k in ipairs(keys) do if typeof(stats[k])=="number" then return stats[k] end end
        if type(stats.damage)=="table" then
            for _,k in ipairs({"base","default","body","torso","nearDamage","damage"}) do
                if typeof(stats.damage[k])=="number" then return stats.damage[k] end
            end
        end
        return nil
    end

    local function practiceDamage(partName)
        local stats=currentStats()
        local tool=currentTool()
        local base=statNumber(stats,{"baseDamage","bulletDamage","damagePerShot","damage","Damage"})
        if not base and tool then
            for _,a in ipairs({"Damage","BaseDamage"}) do
                local v=tool:GetAttribute(a)
                if typeof(v)=="number" then base=v break end
            end
        end
        base=tonumber(base) or 25
        local lower=string.lower(partName or "")
        local mult=1
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

    local function partName(inst,model)
        if not inst then return "Unknown" end
        if inst.Name=="Handle" then
            local weld=inst:FindFirstChild("AccessoryWeld") or inst:FindFirstChildWhichIsA("Weld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(model) then return weld.Part1.Name end
        end
        return inst.Name
    end

    local lastHit=setmetatable({}, {__mode="k"})
    local function applyDummyHit(model,part)
        if not model or not Registry.IsBot(model) then return end
        local hum=Registry.HumanoidOf(model)
        if not hum or hum.Health<=0 then return end
        local now=os.clock()
        if lastHit[hum] and now-lastHit[hum]<.025 then return end
        lastHit[hum]=now
        local pn=partName(part,model)
        local damage=practiceDamage(pn)
        local old=hum.Health
        hum.Health=math.max(0,old-damage)
        local dealt=old-hum.Health
        notify("DUMMY HIT • "..pn,string.format("%s  -%.1f HP  (%.1f → %.1f)",model.Name,dealt,old,hum.Health))
        if shared.LvkHubPlayHitSound then shared.LvkHubPlayHitSound() end
        if hum.Health<=0 then
            task.delay(1.5,function()
                if model and model.Parent and hum and hum.Parent then hum.Health=hum.MaxHealth end
            end)
        end
    end

    local function cameraRayDummy()
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local center=cam.ViewportSize/2
        local ray=cam:ViewportPointToRay(center.X,center.Y)
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        local ex={cam}
        if LP.Character then table.insert(ex,LP.Character) end
        params.FilterDescendantsInstances=ex
        params.IgnoreWater=true
        local result=Workspace:Raycast(ray.Origin,ray.Direction*20000,params)
        if not result then return end
        local model=dummyFromInstance(result.Instance)
        if model then applyDummyHit(model,result.Instance) end
    end

    local function simulateSelectedShot()
        if not allowed() or not currentTool() then return end
        if State.Combat.MagicBullets then
            local target,part=chooseTarget(not (State.Combat.MagicThroughWalls==true))
            if target and part and Registry.IsBot(target) then applyDummyHit(target,part) end
            return
        end
        if State.Combat.SilentAim then
            local target,part=chooseTarget(State.Combat.WallCheck==true)
            if target and part and Registry.IsBot(target) then applyDummyHit(target,part) end
            return
        end
        cameraRayDummy()
    end

    ------------------------------------------------------------------------
    -- WeaponShotBuilder observer. Preserve original shot direction.
    ------------------------------------------------------------------------
    local installed=false
    local lastBuilderShot=0
    local shotContext=nil

    local function findBuilder()
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

    local function install()
        if installed then return true end
        local mod=findBuilder()
        if not mod then return false end
        local ok,builder=pcall(require,mod)
        if not ok or type(builder)~="table" or type(builder.ResolveBaseDirection)~="function" or type(builder.GetSpreadDirection)~="function" then return false end

        local originalResolve=builder.ResolveBaseDirection
        local originalSpread=builder.GetSpreadDirection
        builder.ResolveBaseDirection=function(ctx)
            local base=originalResolve(ctx)
            local origin=ctx and (ctx.shotOrigin or ctx.serverShotOrigin) or nil
            if typeof(origin)~="Vector3" then
                local cam=ctx and ctx.camera or Workspace.CurrentCamera
                origin=cam and cam.CFrame.Position or nil
            end
            local target,part=nil,nil
            if State.Combat.MagicBullets then target,part=chooseTarget(not (State.Combat.MagicThroughWalls==true))
            elseif State.Combat.SilentAim then target,part=chooseTarget(State.Combat.WallCheck==true) end
            shotContext={origin=origin,target=target,part=part,time=os.clock()}
            return base
        end
        builder.GetSpreadDirection=function(baseDirection,spreadState)
            local result=originalSpread(baseDirection,spreadState)
            lastBuilderShot=os.clock()
            local ctx=shotContext
            if ctx and os.clock()-ctx.time<.25 then
                if ctx.target and ctx.part and Registry.IsBot(ctx.target) then
                    task.defer(applyDummyHit,ctx.target,ctx.part)
                else
                    task.defer(cameraRayDummy)
                end
            end
            return result
        end
        installed=true
        shared.LvkHubWeaponSystemDummyAdapter={Module=mod,Builder=builder,Installed=true,DummyOnly=true,PreservesRealShotDirection=true,Version=3}
        return true
    end

    task.spawn(function()
        for _=1,40 do
            if install() then break end
            task.wait(.25)
        end
    end)

    -- Fallback for games/builds that cache shot-builder functions before patching.
    UIS.InputBegan:Connect(function(input,processed)
        if processed or input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if not currentTool() then return end
        local started=os.clock()
        task.delay(.07,function()
            if os.clock()-lastBuilderShot>.09 or lastBuilderShot<started then simulateSelectedShot() end
        end)
    end)

    local timer=0
    RunService.Heartbeat:Connect(function(dt)
        timer+=dt
        if timer>=.25 then
            timer=0
            refreshInventory()
            inv.Visible=State.Combat.DummyInventoryVisible==true
            if not installed then install() end
        end
    end)

    refreshInventory()
end
