-- LvkHub.exe Visual runtime consistency fixes
-- IMPORTANT: this module does NOT own Chams colors anymore.
-- Chams final ownership belongs only to ChamsWallCheckV1.lua.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")

    local globalCrossNames={
        LvkCrossL2=true,LvkCrossR2=true,LvkCrossT2=true,LvkCrossB2=true,
        CrossL=true,CrossR=true,CrossT=true,CrossB=true,
    }
    local previewCrossNames={CrossL=true,CrossR=true,CrossT=true,CrossB=true}

    ------------------------------------------------------------------------
    -- Custom crosshair belongs to the real screen only, never the preview.
    ------------------------------------------------------------------------
    local function pointInside(frame,point)
        if not frame or not frame.Visible then return false end
        local p=frame.AbsolutePosition
        local s=frame.AbsoluteSize
        return point.X>=p.X and point.X<=p.X+s.X and point.Y>=p.Y and point.Y<=p.Y+s.Y
    end

    local function getPreview()
        return UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
            or UI.Gui:FindFirstChild("LvkHubUnifiedPreviewV4")
    end

    local function fixCrosshairPreview()
        local preview=getPreview()
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local center=cam.ViewportSize/2
        local covered=preview and pointInside(preview,center) or false

        for name in pairs(globalCrossNames) do
            local line=UI.Gui:FindFirstChild(name)
            if line and line:IsA("GuiObject") then
                line.ZIndex=60
                if covered then line.Visible=false end
            end
        end

        if preview then
            for _,obj in ipairs(preview:GetDescendants()) do
                if previewCrossNames[obj.Name] and obj:IsA("GuiObject") then
                    obj.Visible=false
                end
            end
        end
    end

    ------------------------------------------------------------------------
    -- Car ESP OFF must stay OFF for cars that spawn later too.
    ------------------------------------------------------------------------
    local function isOurCarMarker(obj)
        local n=obj.Name
        return n=="YokaiPreservedCarESP"
            or n=="YokaiPreservedCarLabel"
            or n:match("^LvkHubCarESP")~=nil
            or n:match("^LvkHubCarLabel")~=nil
    end

    local function forceCarEspOff()
        if State.Visuals.CarESP==true then return end
        local vf=Workspace:FindFirstChild("Vehicles")
        if not vf then return end
        for _,obj in ipairs(vf:GetDescendants()) do
            if isOurCarMarker(obj) then
                if obj:IsA("Highlight") or obj:IsA("BillboardGui") then
                    obj.Enabled=false
                elseif obj:IsA("GuiObject") then
                    obj.Visible=false
                end
            end
        end
    end

    local carTimer=0
    RunService.RenderStepped:Connect(function(dt)
        -- No Chams writes here. This prevents two RenderStepped callbacks from
        -- fighting over the same Highlight and causing visible flicker.
        fixCrosshairPreview()

        carTimer+=dt
        if carTimer>=.12 then
            carTimer=0
            forceCarEspOff()
        end
    end)
end
