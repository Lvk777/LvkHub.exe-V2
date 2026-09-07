return function(UI)
    task.defer(function()
        local win=UI and UI.Windows and UI.Windows.Visuals
        if not win then return end
        local preview=win:FindFirstChild("LvkHubUnifiedPreviewV3")
        local vp=preview and preview:FindFirstChildWhichIsA("ViewportFrame")
        local cam=vp and vp.CurrentCamera
        if cam then
            cam.CFrame=CFrame.lookAt(Vector3.new(0,1.35,9),Vector3.new(0,1.35,0),Vector3.yAxis)
        end
    end)
end
