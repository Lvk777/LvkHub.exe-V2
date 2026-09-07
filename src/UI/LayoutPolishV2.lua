-- Responsive aligned window placement.
-- Category windows are positioned once; option-panel positioning is owned only
-- by UI/Enhancements.lua so draggable ••• panels never fight another loop.
return function(State, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")

    local function vp()
        local cam=Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920,1080)
    end

    local ordered={"Combat","Movement","Visuals","Utility","World","Local","Vehicle"}
    local placed=false
    local timer=0

    local function alignWindows()
        local v=vp()
        local list={}
        for _,name in ipairs(ordered) do
            local w=UI.Windows[name]
            if w then table.insert(list,w) end
        end
        if #list==0 then return end

        local margin=12
        local total=0
        for _,w in ipairs(list) do total+=math.max(1,w.AbsoluteSize.X) end
        local maxGap=10
        local gap=#list>1 and math.floor((v.X-margin*2-total)/(#list-1)) or 0
        gap=math.clamp(gap,4,maxGap)
        local x=margin
        local y=55
        for _,w in ipairs(list) do
            w.Position=UDim2.fromOffset(x,y)
            x+=w.AbsoluteSize.X+gap
        end

        local vehicle=UI.Windows.Vehicle
        local target=UI.Gui:FindFirstChild("LvkHubDummyTargetInfo")
        local preview=UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
        if vehicle then
            local right=vehicle.AbsolutePosition.X+vehicle.AbsoluteSize.X+8
            if target then
                if right+target.AbsoluteSize.X<=v.X-4 then
                    target.Position=UDim2.fromOffset(right,vehicle.AbsolutePosition.Y)
                else
                    target.Position=UDim2.fromOffset(math.max(4,v.X-target.AbsoluteSize.X-4),vehicle.AbsolutePosition.Y+vehicle.AbsoluteSize.Y+8)
                end
            end
            if preview then
                local px=target and target.AbsolutePosition.X or math.max(4,v.X-preview.AbsoluteSize.X-4)
                local py=target and (target.AbsolutePosition.Y+target.AbsoluteSize.Y+8) or (vehicle.AbsolutePosition.Y+vehicle.AbsoluteSize.Y+8)
                preview.Position=UDim2.fromOffset(
                    math.max(4,math.min(px,v.X-preview.AbsoluteSize.X-4)),
                    math.max(4,math.min(py,v.Y-preview.AbsoluteSize.Y-4))
                )
            end
        end
    end

    RunService.RenderStepped:Connect(function(dt)
        timer+=dt
        if timer<.06 then return end
        timer=0

        if not placed then
            local ready=true
            for _,name in ipairs(ordered) do
                if name~="Vehicle" and not UI.Windows[name] then
                    ready=false
                    break
                end
            end
            if ready then
                alignWindows()
                placed=true
            end
        end

        -- Do NOT move UI.ActiveDockedPanel here. Enhancements places it once below
        -- Combat and then leaves Position entirely under the user's drag control.

        local preview=UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
        if preview and State.Visuals.Preview==true and UI.Main.Visible==false then
            preview.Visible=false
        end
    end)
end
