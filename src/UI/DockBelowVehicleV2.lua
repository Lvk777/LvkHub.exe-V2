-- Opens every ••• options panel clearly below Vehicle with extra spacing.
return function(State, UI)
    local Workspace=game:GetService("Workspace")
    local oldOpen=UI.OpenDockedPanel
    if type(oldOpen)~="function" then return end

    local function place(panel)
        if not panel or not panel.Parent or UI.ActiveDockedPanel~=panel then return end
        local vehicle=UI.Windows and UI.Windows.Vehicle
        if not vehicle then return end
        local cam=Workspace.CurrentCamera
        local vp=cam and cam.ViewportSize or Vector2.new(1920,1080)
        local w=math.max(panel.AbsoluteSize.X,214)
        local x=math.clamp(vehicle.AbsolutePosition.X,4,math.max(4,vp.X-w-4))
        local wantedY=vehicle.AbsolutePosition.Y+vehicle.AbsoluteSize.Y+28
        local maxY=math.max(4,vp.Y-panel.AbsoluteSize.Y-4)
        panel.Position=UDim2.fromOffset(x,math.min(wantedY,maxY))
    end

    UI.OpenDockedPanel=function(panel)
        oldOpen(panel)
        task.defer(place,panel)
        task.delay(.05,place,panel)
        task.delay(.14,place,panel)
    end
end
