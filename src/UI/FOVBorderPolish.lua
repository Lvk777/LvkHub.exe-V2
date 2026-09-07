-- Two-tone animated border for the EXISTING LvkHub FOV ring.
-- No second FOV circle/holder is created.
return function(State, UI)
    local RunService=game:GetService("RunService")
    local CoreGui=game:GetService("CoreGui")

    local parent=(gethui and gethui()) or CoreGui
    local fovGui=parent:FindFirstChild("LvkHubAimFOV")
    if not fovGui then return end

    local circle=nil
    for _,x in ipairs(fovGui:GetChildren()) do
        if x:IsA("Frame") and x.Name~="LvkHubFOVBorderBeam" then
            circle=x
            break
        end
    end
    if not circle then return end

    -- Remove the old segmented second ring if a previous build created it.
    local duplicate=fovGui:FindFirstChild("LvkHubFOVBorderBeam")
    if duplicate then duplicate:Destroy() end

    -- Keep the center completely transparent; only the original border is styled.
    circle.BackgroundTransparency=1
    local bodyGradient=circle:FindFirstChildWhichIsA("UIGradient")
    if bodyGradient then bodyGradient.Enabled=false end

    local stroke=circle:FindFirstChildWhichIsA("UIStroke")
    if not stroke then
        stroke=Instance.new("UIStroke")
        stroke.Parent=circle
    end
    stroke.Thickness=1.65
    stroke.Transparency=.025
    stroke.Color=Color3.new(1,1,1)

    local oldGradient=stroke:FindFirstChild("LvkHubFOVStrokeGradient")
    if oldGradient then oldGradient:Destroy() end

    local gradient=Instance.new("UIGradient")
    gradient.Name="LvkHubFOVStrokeGradient"
    gradient.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0.00,Color3.fromRGB(248,105,218)),
        ColorSequenceKeypoint.new(0.28,Color3.fromRGB(194,118,255)),
        ColorSequenceKeypoint.new(0.52,Color3.fromRGB(118,126,255)),
        ColorSequenceKeypoint.new(0.76,Color3.fromRGB(95,205,255)),
        ColorSequenceKeypoint.new(1.00,Color3.fromRGB(235,118,230)),
    })
    gradient.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,.02),
        NumberSequenceKeypoint.new(.5,.10),
        NumberSequenceKeypoint.new(1,.02),
    })
    gradient.Rotation=28
    gradient.Parent=stroke

    local rotation=28
    RunService.RenderStepped:Connect(function(dt)
        if not circle.Parent or not stroke.Parent or not gradient.Parent then return end
        local show=State.Combat and State.Combat.ShowAimFOV==true
        stroke.Enabled=show
        if not show then return end

        -- Slow thermal-like movement around the same border: opposite sides keep
        -- visibly different pink/purple and blue/cyan tones.
        rotation=(rotation+dt*7.5)%360
        gradient.Rotation=rotation
    end)
end
