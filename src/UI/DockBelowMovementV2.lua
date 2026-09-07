-- Final ••• popup dock. Loaded last so it wins over earlier placement helpers.
-- Every options panel opens directly BELOW Movement and can then be dragged freely.
return function(State, UI)
    local Workspace=game:GetService("Workspace")
    local oldOpen=UI.OpenDockedPanel
    if type(oldOpen)~="function" then return end

    local function place(panel)
        if not panel or not panel.Parent or UI.ActiveDockedPanel~=panel then return end
        local movement=UI.Windows and UI.Windows.Movement
        if not movement then return end
        local cam=Workspace.CurrentCamera
        local v=cam and cam.ViewportSize or Vector2.new(1920,1080)
        local w=math.max(panel.AbsoluteSize.X,214)
        local x=math.clamp(movement.AbsolutePosition.X,4,math.max(4,v.X-w-4))
        local y=movement.AbsolutePosition.Y+movement.AbsoluteSize.Y+12
        panel.Position=UDim2.fromOffset(x,y)
    end

    UI.OpenDockedPanel=function(panel)
        oldOpen(panel)
        task.defer(place,panel)
        task.delay(.06,place,panel)
        task.delay(.18,place,panel)
        task.delay(.30,place,panel)
    end
end
