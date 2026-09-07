-- Opens every ••• panel BELOW the complete Movement window/page.
-- Repositions for a short settling window after open, then leaves it draggable.
return function(State, UI)
    local Workspace=game:GetService("Workspace")
    local oldOpen=UI.OpenDockedPanel
    if type(oldOpen)~="function" then return end

    local openSerial=0

    local function viewport()
        local cam=Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920,1080)
    end

    local function movementBottom()
        local win=UI.Windows and UI.Windows.Movement
        local page=UI.Pages and UI.Pages.Movement
        if not win then return nil,nil end
        local bottom=win.AbsolutePosition.Y+win.AbsoluteSize.Y
        if page and page.Visible then
            bottom=math.max(bottom,page.AbsolutePosition.Y+page.AbsoluteSize.Y)
        end
        return win.AbsolutePosition.X,bottom
    end

    local function place(panel)
        if not panel or not panel.Parent or UI.ActiveDockedPanel~=panel then return end
        local x,bottom=movementBottom()
        if not x then return end
        local vp=viewport()
        local wantedY=bottom+24
        local maxY=math.max(4,vp.Y-panel.AbsoluteSize.Y-6)
        -- Normal case: strictly below Movement. Only clamp upward if the panel
        -- physically cannot fit on screen.
        local y=math.min(wantedY,maxY)
        local px=math.clamp(x,4,math.max(4,vp.X-panel.AbsoluteSize.X-4))
        panel.Position=UDim2.fromOffset(px,y)
    end

    UI.OpenDockedPanel=function(panel)
        oldOpen(panel)
        openSerial+=1
        local serial=openSerial
        task.spawn(function()
            local deadline=os.clock()+1.0
            repeat
                if serial~=openSerial or UI.ActiveDockedPanel~=panel then return end
                place(panel)
                task.wait(.05)
            until os.clock()>=deadline
        end)
    end
end
