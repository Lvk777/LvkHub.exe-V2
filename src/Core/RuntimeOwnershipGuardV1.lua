-- LvkHub.exe Runtime Ownership Guard V1
-- Removes only stale/obsolete LvkHub-owned runtime instances.
-- It never touches game-owned objects or Player.Character objects.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")

    local obsoleteUI={
        LvkHubUnifiedVisualsV3=true,
        LvkHubUnifiedVisualsV4=true,
        LvkHubUnifiedPreviewV3=true,
        LvkHubUnifiedPreviewV4=true,
        LvkHubUnifiedPreviewV5=true,
        LvkHubVisualPreview=true,
        LvkHubPracticeSnapline=true,
        CrossL=true,CrossR=true,CrossT=true,CrossB=true,
    }

    local obsoleteDummyHighlights={
        LvkHubUnifiedV3Chams=true,
        LvkHubUnifiedV4Chams=true,
        LvkHubTestChams=true,
        LvkHubPracticeTargetBlue=true,
    }

    local obsoleteVehicleMarkers={
        YokaiPreservedCarESP=true,
        YokaiPreservedCarLabel=true,
        LvkHubCarESPV3=true,
        LvkHubCarLabelV3=true,
        LvkHubCarESPV4=true,
        LvkHubCarLabelV4=true,
    }

    local function cleanupUI()
        -- UI.Gui contains the main shell/overlay helper frames.
        for _,obj in ipairs(UI.Gui:GetChildren()) do
            if obsoleteUI[obj.Name] then
                pcall(function() obj:Destroy() end)
            end
        end

        -- Unified visual ScreenGuis are siblings of the main LvkHub GUI.
        local parent=UI.Gui.Parent
        if parent then
            for _,obj in ipairs(parent:GetChildren()) do
                if obsoleteUI[obj.Name] then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end

    local function cleanupDummies()
        local tf=Workspace:FindFirstChild("TestPlayers")
        if not tf then return end
        for _,model in ipairs(tf:GetChildren()) do
            if model:IsA("Model") and model:GetAttribute("LvkHubManagedDummy")==true then
                local currentSeen=false
                for _,obj in ipairs(model:GetChildren()) do
                    if obj:IsA("Highlight") then
                        if obsoleteDummyHighlights[obj.Name] then
                            pcall(function() obj:Destroy() end)
                        elseif obj.Name=="LvkHubUnifiedV5Chams" then
                            -- Exactly one current world Chams Highlight per dummy.
                            if currentSeen then
                                pcall(function() obj:Destroy() end)
                            else
                                currentSeen=true
                            end
                        end
                    end
                end
            end
        end
    end

    local function cleanupVehicles()
        local vf=Workspace:FindFirstChild("Vehicles")
        if not vf then return end
        for _,obj in ipairs(vf:GetDescendants()) do
            if obsoleteVehicleMarkers[obj.Name] then
                pcall(function() obj:Destroy() end)
            end
        end
    end

    local function cleanup()
        cleanupUI()
        cleanupDummies()
        cleanupVehicles()
    end

    cleanup()

    local timer=0
    RunService.Heartbeat:Connect(function(dt)
        timer+=dt
        if timer<1 then return end
        timer=0
        cleanup()
    end)
end
