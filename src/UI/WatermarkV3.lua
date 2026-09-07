return function(State, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")

    local old=UI.Gui:FindFirstChild("LvkHubWatermark")
    if old then old:Destroy() end

    local frame=Instance.new("Frame")
    frame.Name="LvkHubWatermark"
    frame.AnchorPoint=Vector2.new(.5,0)
    frame.Position=UDim2.new(.5,0,0,8)
    frame.Size=UDim2.fromOffset(430,28)
    frame.BackgroundColor3=Color3.fromRGB(16,17,21)
    frame.BackgroundTransparency=.10
    frame.BorderSizePixel=0
    frame.ZIndex=300
    frame.ClipsDescendants=false
    frame.Parent=UI.Gui
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,7)
    corner.Parent=frame

    local stroke=Instance.new("UIStroke")
    stroke.Name="LvkHubWatermarkBorderBeam"
    stroke.Color=Color3.new(1,1,1)
    stroke.Transparency=.02
    stroke.Thickness=1.35
    stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    stroke.Parent=frame

    local grad=Instance.new("UIGradient")
    grad.Name="BorderBeamGradient"
    grad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0.00,Color3.fromRGB(62,72,98)),
        ColorSequenceKeypoint.new(0.23,Color3.fromRGB(82,100,175)),
        ColorSequenceKeypoint.new(0.43,Color3.fromRGB(119,120,255)),
        ColorSequenceKeypoint.new(0.50,Color3.fromRGB(228,230,255)),
        ColorSequenceKeypoint.new(0.57,Color3.fromRGB(119,120,255)),
        ColorSequenceKeypoint.new(0.77,Color3.fromRGB(86,92,170)),
        ColorSequenceKeypoint.new(1.00,Color3.fromRGB(62,72,98)),
    })
    grad.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,.50),
        NumberSequenceKeypoint.new(.32,.30),
        NumberSequenceKeypoint.new(.48,.00),
        NumberSequenceKeypoint.new(.52,.00),
        NumberSequenceKeypoint.new(.68,.30),
        NumberSequenceKeypoint.new(1,.50),
    })
    grad.Parent=stroke

    local text=Instance.new("TextLabel")
    text.BackgroundTransparency=1
    text.Position=UDim2.fromOffset(10,0)
    text.Size=UDim2.new(1,-20,1,0)
    text.Font=Enum.Font.SourceSansSemibold
    text.TextSize=12
    text.TextColor3=Color3.fromRGB(226,228,236)
    text.TextXAlignment=Enum.TextXAlignment.Center
    text.TextYAlignment=Enum.TextYAlignment.Center
    text.RichText=true
    text.ZIndex=303
    text.Parent=frame

    local blue="#7778FF"
    local frames,elapsed,fps=0,0,60
    local rotation=0
    local function setText()
        text.Text=string.format(
            '<font color="%s">LvkHub</font>   /   by <font color="%s">Lvk</font>   /   %d FPS   /   %d Players',
            blue,blue,fps,#Players:GetPlayers()
        )
    end

    RunService.RenderStepped:Connect(function(dt)
        frames+=1
        elapsed+=dt
        rotation=(rotation+dt*24)%360
        if grad.Parent then grad.Rotation=rotation end
        if elapsed>=.5 then
            fps=math.floor(frames/math.max(elapsed,.001)+.5)
            frames=0
            elapsed=0
            setText()
        end
    end)

    setText()
end
