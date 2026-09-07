return function(State, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")

    local old=UI.Gui:FindFirstChild("LvkHubWatermark")
    if old then old:Destroy() end

    local frame=Instance.new("Frame")
    frame.Name="LvkHubWatermark"
    frame.AnchorPoint=Vector2.new(.5,0)
    frame.Position=UDim2.new(.5,0,0,8)
    frame.Size=UDim2.fromOffset(382,28)
    frame.BackgroundColor3=Color3.fromRGB(16,17,21)
    frame.BackgroundTransparency=.12
    frame.BorderSizePixel=0
    frame.ZIndex=300
    frame.ClipsDescendants=false
    frame.Parent=UI.Gui
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,7);corner.Parent=frame
    local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(68,72,92);stroke.Transparency=.20;stroke.Thickness=1;stroke.Parent=frame

    local dot=Instance.new("Frame")
    dot.Position=UDim2.fromOffset(9,10);dot.Size=UDim2.fromOffset(7,7);dot.BackgroundColor3=UI.Accent;dot.BorderSizePixel=0;dot.ZIndex=303;dot.Parent=frame
    local dc=Instance.new("UICorner");dc.CornerRadius=UDim.new(1,0);dc.Parent=dot

    local text=Instance.new("TextLabel")
    text.BackgroundTransparency=1;text.Position=UDim2.fromOffset(23,0);text.Size=UDim2.new(1,-30,1,0)
    text.Font=Enum.Font.SourceSansSemibold;text.TextSize=12;text.TextColor3=Color3.fromRGB(226,228,236)
    text.TextXAlignment=Enum.TextXAlignment.Left;text.ZIndex=303;text.Parent=frame

    local function spaced(word)
        local out={}
        for i=1,#word do out[#out+1]=word:sub(i,i) end
        return table.concat(out," ")
    end
    local brand=spaced("LvkHub")
    local by=spaced("by").." "..spaced("Lvk")

    local glow=Instance.new("Frame")
    glow.AnchorPoint=Vector2.new(.5,.5);glow.Size=UDim2.fromOffset(24,6);glow.BackgroundColor3=UI.Accent;glow.BackgroundTransparency=.72;glow.BorderSizePixel=0;glow.ZIndex=301;glow.Parent=frame
    local gc=Instance.new("UICorner");gc.CornerRadius=UDim.new(1,0);gc.Parent=glow
    local beam=Instance.new("Frame")
    beam.AnchorPoint=Vector2.new(.5,.5);beam.Size=UDim2.fromOffset(18,2);beam.BackgroundColor3=Color3.fromRGB(185,190,255);beam.BorderSizePixel=0;beam.ZIndex=302;beam.Parent=frame
    local bc=Instance.new("UICorner");bc.CornerRadius=UDim.new(1,0);bc.Parent=beam
    local bg=Instance.new("UIGradient")
    bg.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(70,110,255)),
        ColorSequenceKeypoint.new(.5,Color3.fromRGB(220,225,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(125,80,255)),
    })
    bg.Parent=beam

    local frames=0
    local elapsed=0
    local fps=60
    local travel=0

    local function setText()
        text.Text=string.format("%s   •   %s   •   %d FPS   •   %d Players",brand,by,fps,#Players:GetPlayers())
    end

    RunService.RenderStepped:Connect(function(dt)
        frames+=1;elapsed+=dt
        if elapsed>=.5 then
            fps=math.floor(frames/math.max(elapsed,.001)+.5)
            frames=0;elapsed=0
            setText()
        end

        local w=math.max(40,frame.AbsoluteSize.X-10)
        local h=math.max(12,frame.AbsoluteSize.Y-10)
        local per=2*(w+h)
        travel=(travel+dt*92)%per
        local x,y,rot
        if travel<w then
            x=5+travel;y=4;rot=0
        elseif travel<w+h then
            x=5+w;y=4+(travel-w);rot=90
        elseif travel<2*w+h then
            x=5+w-(travel-(w+h));y=4+h;rot=0
        else
            x=5;y=4+h-(travel-(2*w+h));rot=90
        end
        beam.Position=UDim2.fromOffset(x,y);beam.Rotation=rot
        glow.Position=beam.Position;glow.Rotation=rot
    end)

    setText()
end
