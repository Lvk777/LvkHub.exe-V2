-- Final ••• popup dock. Every options panel opens below Vehicle.
-- Placement is only applied during opening; after that the panel stays freely draggable.
return function(State, UI)
    local Workspace=game:GetService("Workspace")
    local oldOpen=UI.OpenDockedPanel
    if type(oldOpen)~="function" then return end

    local function place(panel)
        if not panel or not panel.Parent or UI.ActiveDockedPanel~=panel then return end
        local vehicle=UI.Windows and UI.Windows.Vehicle
        if not vehicle then return end
        local cam=Workspace.CurrentCamera
        local v=cam and cam.ViewportSize or Vector2.new(1920,1080)
        local w=math.max(panel.AbsoluteSize.X,214)
        local x=math.clamp(vehicle.AbsolutePosition.X,4,math.max(4,v.X-w-4))
        local y=vehicle.AbsolutePosition.Y+vehicle.AbsoluteSize.Y+12
        if y+panel.AbsoluteSize.Y>v.Y-4 then
            y=math.max(4,v.Y-panel.AbsoluteSize.Y-4)
        end
        panel.Position=UDim2.fromOffset(x,y)
    end

    UI.OpenDockedPanel=function(panel)
        oldOpen(panel)
        task.defer(place,panel)
        task.delay(.06,place,panel)
        task.delay(.16,place,panel)
    end
end
