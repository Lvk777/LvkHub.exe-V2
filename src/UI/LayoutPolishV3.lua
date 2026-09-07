-- Startup-only placement for main windows and detached panels.
-- Utility and Vehicle swap their original positions.
-- Target Info aligns to the Vehicle row height; Preview sits strictly below Target Info.
-- No continuous position writes: everything remains draggable after startup.
return function(State, UI)
    local Workspace=game:GetService("Workspace")

    local function viewport()
        local cam=Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920,1080)
    end

    local function readyFrame(name)
        local f=UI.Gui:FindFirstChild(name)
        if f and f.AbsoluteSize.X>10 and f.AbsoluteSize.Y>10 then return f end
        return nil
    end

    task.spawn(function()
        local deadline=os.clock()+5
        local utility,vehicle,target,preview
        repeat
            utility=UI.Windows and UI.Windows.Utility
            vehicle=UI.Windows and UI.Windows.Vehicle
            target=readyFrame("LvkHubDummyTargetInfo")
            preview=readyFrame("LvkHubVisualsDummyPreview")
            if utility and vehicle and utility.AbsoluteSize.X>10 and vehicle.AbsoluteSize.X>10 and target and preview then break end
            task.wait(.05)
        until os.clock()>deadline
        if not utility or not vehicle then return end

        task.wait(.12)

        -- Exact startup swap: each window takes the other's original slot.
        local utilityPos=utility.Position
        local vehiclePos=vehicle.Position
        utility.Position=vehiclePos
        vehicle.Position=utilityPos

        -- Let AbsolutePosition settle after the swap and after preview AutoSize.
        task.wait(.12)
        target=target or readyFrame("LvkHubDummyTargetInfo")
        preview=preview or readyFrame("LvkHubVisualsDummyPreview")
        if not target or not preview then return end

        local v=viewport()
        -- Put the detached cards after the rightmost of Utility/Vehicle, but keep
        -- the same top line as Vehicle so Target Info visually aligns with it.
        local anchor=utility.AbsolutePosition.X>vehicle.AbsolutePosition.X and utility or vehicle
        local widest=math.max(target.AbsoluteSize.X,preview.AbsoluteSize.X)
        local desiredX=anchor.AbsolutePosition.X+anchor.AbsoluteSize.X+8
        local x=math.clamp(desiredX,4,math.max(4,v.X-widest-4))
        local y=math.max(4,vehicle.AbsolutePosition.Y)
        target.Position=UDim2.fromOffset(x,y)

        task.wait(.08)
        -- Never overlap Preview with Target Info. Do not bounce it upward.
        preview.Position=UDim2.fromOffset(x,target.AbsolutePosition.Y+target.AbsoluteSize.Y+8)
    end)
end
