-- Yokai-style Trail glow layer.
-- MainV4 owns the base Trail; this module owns only the optional glow copy/Bloom.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Lighting=game:GetService("Lighting")
    local Workspace=game:GetService("Workspace")
    local page=UI.Pages.Local

    UI.Toggle(page,"Glow",function() return State.Local.TrailGlow end,function(v) State.Local.TrailGlow=v end)

    local glowCopy=nil
    local sourceTrail=nil
    local bloom=nil

    local function findTrail()
        local cam=Workspace.CurrentCamera
        if cam then
            local t=cam:FindFirstChild("LvkHubTrailLocal",true)
            if t and t:IsA("Trail") then return t end
        end
        local t=Workspace:FindFirstChild("LvkHubTrailLocal",true)
        if t and t:IsA("Trail") then return t end
        return nil
    end

    local function ensureBloom()
        if bloom and bloom.Parent then return end
        bloom=Lighting:FindFirstChild("LvkHubTrailBloom")
        if not bloom then
            bloom=Instance.new("BloomEffect")
            bloom.Name="LvkHubTrailBloom"
            bloom.Intensity=.55
            bloom.Size=18
            bloom.Threshold=.92
            bloom.Parent=Lighting
        end
    end

    local function clearGlow()
        if glowCopy then pcall(function() glowCopy:Destroy() end) end
        glowCopy=nil
        sourceTrail=nil
        if bloom then pcall(function() bloom:Destroy() end) end
        bloom=nil
    end

    local function syncGlow()
        if not State.Local.TrailGlow or not State.Local.Trail then
            clearGlow()
            return
        end

        local original=findTrail()
        if not original or not original.Parent then
            if glowCopy then pcall(function() glowCopy:Destroy() end) end
            glowCopy=nil
            sourceTrail=nil
            return
        end

        ensureBloom()
        if sourceTrail~=original or not glowCopy or not glowCopy.Parent then
            if glowCopy then pcall(function() glowCopy:Destroy() end) end
            glowCopy=original:Clone()
            glowCopy.Name="LvkHubTrailGlow"
            glowCopy.Parent=original.Parent
            sourceTrail=original
        end

        glowCopy.Enabled=original.Enabled
        glowCopy.Attachment0=original.Attachment0
        glowCopy.Attachment1=original.Attachment1
        glowCopy.Color=original.Color
        glowCopy.Lifetime=original.Lifetime
        glowCopy.FaceCamera=original.FaceCamera
        glowCopy.LightEmission=1
        glowCopy.LightInfluence=0
        glowCopy.Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,.58),
            NumberSequenceKeypoint.new(1,.92),
        })
        pcall(function() glowCopy.WidthScale=NumberSequence.new(1.7) end)
    end

    local tick=0
    RunService.Heartbeat:Connect(function(dt)
        tick+=dt
        if tick<.12 then return end
        tick=0
        syncGlow()
    end)
end
