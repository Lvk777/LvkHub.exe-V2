return function(UI)
    local RunService=game:GetService("RunService")
    local timer=0
    RunService.Heartbeat:Connect(function(dt)
        timer+=dt
        if timer<.35 then return end
        timer=0
        local preview=UI.Gui:FindFirstChild("LvkHubUnifiedPreviewV4")
        if not preview then return end
        local vp=preview:FindFirstChildWhichIsA("ViewportFrame",true)
        if not vp then return end
        local cam=vp.CurrentCamera or vp:FindFirstChildWhichIsA("Camera")
        if not cam then return end
        cam.CFrame=CFrame.lookAt(Vector3.new(0,1.35,8),Vector3.new(0,1.35,0))
    end)
end
