-- Applies the requested local hit sound asset to LvkHub's existing sound object.
return function(State, UI)
    local RunService=game:GetService("RunService")
    local wanted="rbxassetid://91546829095879"
    local timer=0
    RunService.Heartbeat:Connect(function(dt)
        timer+=dt
        if timer<.25 then return end
        timer=0
        local cam=workspace.CurrentCamera
        if not cam then return end
        local s=cam:FindFirstChild("LvkHubHitSoundV3") or cam:FindFirstChild("LvkHubHitSoundV2")
        if s and s:IsA("Sound") and s.SoundId~=wanted then s.SoundId=wanted end
    end)
end
