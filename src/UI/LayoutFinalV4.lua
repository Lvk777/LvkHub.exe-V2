-- Final startup layout: evenly uses the available horizontal space.
-- Order: Combat / Movement / Visuals / Vehicle / World / Local / Utility / Target Info.
-- Preview is always placed below Target Info. After startup, everything remains draggable.
-- The loader keeps the GUI hidden until UI.LayoutReady becomes true.
return function(State, UI)
    local Workspace=game:GetService("Workspace")
    local RunService=game:GetService("RunService")

    local order={"Combat","Movement","Visuals","Vehicle","World","Local","Utility"}
    UI.LayoutReady=false

    local function vp()
        local cam=Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920,1080)
    end

    local function findTarget()
        return UI.Gui:FindFirstChild("LvkHubDummyTargetInfo")
    end

    local function findPreview()
        return UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
    end

    local function apply()
        local v=vp()
        local margin=14
        local reserve=260
        local targetGap=10
        local gaps=10
        local available=v.X-margin*2-reserve-targetGap-gaps*(#order-1)
        local menuW=math.clamp(math.floor(available/#order),184,220)
        local used=menuW*#order+gaps*(#order-1)
        local free=math.max(0,v.X-margin*2-reserve-targetGap-used)
        local extra=(#order>1) and free/(#order-1) or 0
        local gap=gaps+extra

        local x=margin
        for _,name in ipairs(order) do
            local w=UI.Windows and UI.Windows[name]
            if w then
                w.Position=UDim2.fromOffset(math.floor(x+.5),55)
                w.Size=UDim2.fromOffset(menuW,w.AbsoluteSize.Y)
                local header=w:FindFirstChild("Header")
                if header then header.Size=UDim2.new(1,0,0,37) end
                local page=UI.Pages and UI.Pages[name]
                if page then page.Size=UDim2.new(1,0,0,page.AbsoluteSize.Y) end
                w:SetAttribute("LvkHubFinalWidth",menuW)
                x+=menuW+gap
            end
        end

        local utility=UI.Windows and UI.Windows.Utility
        local target=findTarget()
        local preview=findPreview()
        local rightX=utility and (utility.AbsolutePosition.X+utility.AbsoluteSize.X+targetGap) or (v.X-reserve-margin)
        rightX=math.clamp(rightX,margin,math.max(margin,v.X-reserve-margin))

        if target then
            target.Position=UDim2.fromOffset(math.floor(rightX+.5),55)
        end

        if preview then
            local y=55+(target and target.AbsoluteSize.Y or 110)+10
            preview.Position=UDim2.fromOffset(math.floor(rightX+.5),math.floor(y+.5))
        end
    end

    UI.ApplyFinalLayout=apply

    -- Resolve all deferred row sizes/AutomaticCanvasSize while the loader still
    -- has the ScreenGui hidden. No late startup repositioning happens after reveal.
    task.spawn(function()
        local deadline=os.clock()+2.5
        repeat
            local ready=true
            for _,name in ipairs(order) do
                local w=UI.Windows and UI.Windows[name]
                if not w or w.AbsoluteSize.X<10 then
                    ready=false
                    break
                end
            end
            if ready and findTarget() and findPreview() then break end
            task.wait(.025)
        until os.clock()>deadline

        -- Give UIListLayout / AutomaticSize a couple of render passes to settle.
        pcall(function() RunService.RenderStepped:Wait() end)
        apply()
        pcall(function() RunService.RenderStepped:Wait() end)
        apply()
        UI.LayoutReady=true
    end)

    local function bindCamera(cam)
        if not cam then return end
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            task.delay(.12,function()
                apply()
            end)
        end)
    end

    bindCamera(Workspace.CurrentCamera)
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        bindCamera(Workspace.CurrentCamera)
        task.delay(.12,apply)
    end)
end
