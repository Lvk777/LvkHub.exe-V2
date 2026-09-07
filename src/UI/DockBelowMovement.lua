-- Shared ••• popup placement: always opens below Movement and remains draggable.
-- No per-frame rewrites; after opening the user can move the popup freely.
return function(State, UI)
    local Workspace=game:GetService("Workspace")
    local oldOpen=UI.OpenDockedPanel
    if type(oldOpen)~="function" then return end

    local function viewport()
        local cam=Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920,1080)
    end

    local function place(panel)
        if not panel or not panel.Parent or UI.ActiveDockedPanel~=panel then return end
        local movement=UI.Windows and UI.Windows.Movement
        if not movement then return end
        local v=viewport()
        local w=math.max(panel.AbsoluteSize.X,214)
        local x=math.clamp(movement.AbsolutePosition.X,4,math.max(4,v.X-w-4))
        -- Important: never bounce the popup above Movement just to keep its full height onscreen.
        -- It opens below Movement exactly once; from there it is freely draggable.
        local y=movement.AbsolutePosition.Y+movement.AbsoluteSize.Y+12
        panel.Position=UDim2.fromOffset(x,y)
    end

    UI.OpenDockedPanel=function(panel)
        oldOpen(panel)
        task.defer(place,panel)
        task.delay(.05,place,panel)
        task.delay(.14,place,panel)
    end
end
