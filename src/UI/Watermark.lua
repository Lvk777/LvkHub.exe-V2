return function(State, UI)
    local old=UI.Gui:FindFirstChild("LvkHubWatermark")
    if old then old:Destroy() end

    local frame=Instance.new("Frame")
    frame.Name="LvkHubWatermark"
    frame.AnchorPoint=Vector2.new(.5,0)
    frame.Position=UDim2.new(.5,0,0,8)
    frame.Size=UDim2.fromOffset(174,26)
    frame.BackgroundColor3=Color3.fromRGB(16,17,21)
    frame.BackgroundTransparency=.18
    frame.BorderSizePixel=0
    frame.ZIndex=300
    frame.Parent=UI.Gui

    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,6)
    corner.Parent=frame

    local stroke=Instance.new("UIStroke")
    stroke.Color=Color3.fromRGB(68,72,92)
    stroke.Transparency=.28
    stroke.Parent=frame

    local dot=Instance.new("Frame")
    dot.Position=UDim2.fromOffset(8,9)
    dot.Size=UDim2.fromOffset(7,7)
    dot.BackgroundColor3=UI.Accent
    dot.BorderSizePixel=0
    dot.ZIndex=301
    dot.Parent=frame
    local dc=Instance.new("UICorner")
    dc.CornerRadius=UDim.new(1,0)
    dc.Parent=dot

    local text=Instance.new("TextLabel")
    text.BackgroundTransparency=1
    text.Position=UDim2.fromOffset(21,0)
    text.Size=UDim2.new(1,-27,1,0)
    text.Font=Enum.Font.SourceSansSemibold
    text.TextSize=12
    text.TextColor3=Color3.fromRGB(224,226,234)
    text.TextXAlignment=Enum.TextXAlignment.Left
    text.Text="LVKHUB  •  TEST MODE"
    text.ZIndex=301
    text.Parent=frame
end
