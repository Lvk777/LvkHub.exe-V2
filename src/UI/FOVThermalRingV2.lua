-- Two-tone thermal-style animated border for the existing FOV circle.
-- The center stays fully transparent. Only the perimeter animates.
return function(State, UI)
    local RunService=game:GetService("RunService")
    local CoreGui=game:GetService("CoreGui")
    local parent=(gethui and gethui()) or CoreGui
    local fovGui=parent:FindFirstChild("LvkHubAimFOV")
    if not fovGui then return end

    local circle=nil
    for _,x in ipairs(fovGui:GetChildren()) do
        if x:IsA("Frame") and x.Name~="LvkHubThermalFOVRingV2" then
            circle=x
            break
        end
    end
    if not circle then return end

    -- Remove the old fill/rainbow presentation. The effect below is border-only.
    circle.BackgroundTransparency=1
    local oldGrad=circle:FindFirstChildWhichIsA("UIGradient")
    if oldGrad then pcall(function() oldGrad.Enabled=false end) end
    local oldStroke=circle:FindFirstChildWhichIsA("UIStroke")
    if oldStroke then oldStroke.Transparency=1 end

    local previous=fovGui:FindFirstChild("LvkHubThermalFOVRingV2")
    if previous then previous:Destroy() end

    local holder=Instance.new("Frame")
    holder.Name="LvkHubThermalFOVRingV2"
    holder.BackgroundTransparency=1
    holder.Size=UDim2.fromScale(1,1)
    holder.Position=UDim2.fromScale(0,0)
    holder.ZIndex=20
    holder.Parent=fovGui

    local COUNT=96
    local core={}
    local glow={}

    local function segment(parentName,z,thickness,transparency)
        local f=Instance.new("Frame")
        f.Name=parentName
        f.AnchorPoint=Vector2.new(.5,.5)
        f.BorderSizePixel=0
        f.BackgroundTransparency=transparency
        f.Size=UDim2.fromOffset(8,thickness)
        f.ZIndex=z
        f.Visible=false
        f.Parent=holder
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(1,0)
        c.Parent=f
        return f
    end

    for i=1,COUNT do
        glow[i]=segment("ThermalGlow",20,5.2,.80)
        core[i]=segment("ThermalCore",21,2.15,.02)
    end

    -- Exactly two tones at once, like the reference: violet/blue + pink.
    local violet=Color3.fromRGB(105,120,255)
    local pink=Color3.fromRGB(255,67,183)
    local phase=0

    local bindName="LvkHubThermalFOVRingV2"
    pcall(function() RunService:UnbindFromRenderStep(bindName) end)
    RunService:BindToRenderStep(bindName,Enum.RenderPriority.Last.Value+620,function(dt)
        if not circle.Parent or not holder.Parent then return end
        local show=State.Combat and State.Combat.ShowAimFOV==true and circle.Visible~=false
        holder.Visible=show
        if not show then return end

        phase=(phase+dt*1.55)%(math.pi*2)

        local ap=circle.AbsolutePosition
        local as=circle.AbsoluteSize
        local center=Vector2.new(ap.X+as.X*.5,ap.Y+as.Y*.5)
        local radius=math.max(2,math.min(as.X,as.Y)*.5)
        local circumference=2*math.pi*radius
        local segLen=math.max(3,circumference/COUNT*1.18)

        for i=1,COUNT do
            local angle=((i-1)/COUNT)*(math.pi*2)
            local p=center+Vector2.new(math.cos(angle),math.sin(angle))*radius
            local tangent=math.deg(angle)+90

            -- This wave moves around the circle. Both colors are always present,
            -- while their meeting points rotate continuously around the border.
            local mix=(math.sin(angle-phase)+1)*.5
            local color=violet:Lerp(pink,mix)
            local heat=(math.sin((angle-phase)*2)+1)*.5

            local g=glow[i]
            g.Position=UDim2.fromOffset(p.X,p.Y)
            g.Size=UDim2.fromOffset(segLen+1.5,5.2)
            g.Rotation=tangent
            g.BackgroundColor3=color
            g.BackgroundTransparency=.70+.18*(1-heat)
            g.Visible=true

            local s=core[i]
            s.Position=UDim2.fromOffset(p.X,p.Y)
            s.Size=UDim2.fromOffset(segLen,2.2)
            s.Rotation=tangent
            s.BackgroundColor3=color
            s.BackgroundTransparency=.01+.07*(1-heat)
            s.Visible=true
        end
    end)
end
