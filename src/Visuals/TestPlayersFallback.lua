-- Robust fallback renderer for Workspace.TestPlayers local dummies only.
-- Uses bounding-box projection instead of the legacy root-size formula so Visuals
-- still work on unusual R6/R15 player-shaped test rigs.

return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local parent=UI.Gui.Parent
    local BLUE=Color3.fromRGB(119,120,255)

    local old=parent:FindFirstChild("LvkHubTestPlayersVisualFallback")
    if old then old:Destroy() end

    local gui=Instance.new("ScreenGui")
    gui.Name="LvkHubTestPlayersVisualFallback"
    gui.IgnoreGuiInset=true
    gui.ResetOnSpawn=false
    gui.DisplayOrder=999
    gui.Parent=parent

    local stores=setmetatable({}, {__mode="k"})

    local function line()
        local f=Instance.new("Frame")
        f.AnchorPoint=Vector2.new(.5,.5)
        f.BorderSizePixel=0
        f.BackgroundColor3=Color3.new(1,1,1)
        f.Visible=false
        f.Parent=gui
        return f
    end

    local function setLine(f,a,b,thickness,color)
        if not f or not a or not b then if f then f.Visible=false end return end
        local d=b-a
        if d.Magnitude<.01 then f.Visible=false return end
        f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
        f.Size=UDim2.fromOffset(d.Magnitude,thickness or 1)
        f.Rotation=math.deg(math.atan2(d.Y,d.X))
        f.BackgroundColor3=color or Color3.new(1,1,1)
        f.Visible=true
    end

    local function label(size)
        local t=Instance.new("TextLabel")
        t.AnchorPoint=Vector2.new(.5,.5)
        t.BackgroundTransparency=1
        t.Size=UDim2.fromOffset(size or 180,18)
        t.Font=Enum.Font.Code
        t.TextSize=11
        t.TextColor3=Color3.new(1,1,1)
        t.TextStrokeTransparency=0
        t.Visible=false
        t.Parent=gui
        return t
    end

    local function newStore(model)
        local s={model=model}
        s.h=Instance.new("Highlight")
        s.h.Name="LvkHubTestPlayersFallbackChams"
        s.h.Adornee=model
        s.h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        s.h.FillColor=BLUE
        s.h.OutlineColor=BLUE
        s.h.FillTransparency=.82
        s.h.OutlineTransparency=.05
        s.h.Enabled=false
        s.h.Parent=model

        s.corner={}; for i=1,8 do s.corner[i]=line() end
        s.box3d={}; for i=1,12 do s.box3d[i]=line() end
        s.skeleton={}; for i=1,15 do s.skeleton[i]=line() end
        s.tracer=line()
        s.name=label(220)
        s.distance=label(180)

        s.healthBack=Instance.new("Frame")
        s.healthBack.BorderSizePixel=0
        s.healthBack.BackgroundColor3=Color3.fromRGB(0,0,0)
        s.healthBack.Visible=false
        s.healthBack.Parent=gui
        s.health=Instance.new("Frame")
        s.health.BorderSizePixel=0
        s.health.BackgroundColor3=BLUE
        s.health.Visible=false
        s.health.Parent=gui

        stores[model]=s
        return s
    end

    local function hideLines(t)
        for _,x in ipairs(t) do x.Visible=false end
    end

    local function hide(s)
        s.h.Enabled=false
        hideLines(s.corner); hideLines(s.box3d); hideLines(s.skeleton)
        s.tracer.Visible=false; s.name.Visible=false; s.distance.Visible=false
        s.healthBack.Visible=false; s.health.Visible=false
    end

    local function destroy(model)
        local s=stores[model]
        if not s then return end
        for _,v in pairs(s) do
            if typeof(v)=="Instance" then pcall(function() v:Destroy() end)
            elseif type(v)=="table" then for _,x in ipairs(v) do pcall(function() x:Destroy() end) end end
        end
        stores[model]=nil
    end

    local function projectedBounds(model,cam)
        local ok,cf,size=pcall(function()
            local c,s=model:GetBoundingBox()
            return c,s
        end)
        if not ok or not cf or not size then return nil end
        local hs=size/2
        local minX,minY=math.huge,math.huge
        local maxX,maxY=-math.huge,-math.huge
        local any=false
        local points={}
        for x=-1,1,2 do
            for y=-1,1,2 do
                for z=-1,1,2 do
                    local wp=(cf*CFrame.new(hs.X*x,hs.Y*y,hs.Z*z)).Position
                    local p,on=cam:WorldToViewportPoint(wp)
                    table.insert(points,{screen=Vector2.new(p.X,p.Y),visible=on and p.Z>0})
                    if on and p.Z>0 then
                        any=true
                        minX=math.min(minX,p.X); maxX=math.max(maxX,p.X)
                        minY=math.min(minY,p.Y); maxY=math.max(maxY,p.Y)
                    end
                end
            end
        end
        if not any then return nil end
        return Vector2.new((minX+maxX)/2,(minY+maxY)/2),math.max(8,maxX-minX),math.max(12,maxY-minY),points
    end

    local function corners(lines,pos,w,h,color)
        local l,r=pos.X-w/2,pos.X+w/2
        local t,b=pos.Y-h/2,pos.Y+h/2
        local cw,ch=w*.22,h*.22
        local p={
            {Vector2.new(l,t),Vector2.new(l+cw,t)},{Vector2.new(l,t),Vector2.new(l,t+ch)},
            {Vector2.new(r,t),Vector2.new(r-cw,t)},{Vector2.new(r,t),Vector2.new(r,t+ch)},
            {Vector2.new(l,b),Vector2.new(l+cw,b)},{Vector2.new(l,b),Vector2.new(l,b-ch)},
            {Vector2.new(r,b),Vector2.new(r-cw,b)},{Vector2.new(r,b),Vector2.new(r,b-ch)},
        }
        for i,v in ipairs(p) do setLine(lines[i],v[1],v[2],1,color) end
    end

    local edges={{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}
    local function box3d(lines,points,color)
        if not points then hideLines(lines); return end
        for i,e in ipairs(edges) do
            local a,b=points[e[1]],points[e[2]]
            if a and b and a.visible and b.visible then setLine(lines[i],a.screen,b.screen,1,color) else lines[i].Visible=false end
        end
    end

    local bonesR15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
    local bonesR6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
    local function skeleton(lines,model,cam)
        hideLines(lines)
        local bones=model:FindFirstChild("UpperTorso") and bonesR15 or bonesR6
        for i,b in ipairs(bones) do
            local a=model:FindFirstChild(b[1]); local c=model:FindFirstChild(b[2])
            if a and c and a:IsA("BasePart") and c:IsA("BasePart") and lines[i] then
                local pa,va=cam:WorldToViewportPoint(a.Position)
                local pc,vc=cam:WorldToViewportPoint(c.Position)
                if va and vc and pa.Z>0 and pc.Z>0 then
                    setLine(lines[i],Vector2.new(pa.X,pa.Y),Vector2.new(pc.X,pc.Y),1,Color3.new(1,1,1))
                end
            end
        end
    end

    local function valid(model)
        if not model or not model.Parent then return false end
        local folder=Workspace:FindFirstChild("TestPlayers")
        if not folder or not model:IsDescendantOf(folder) then return false end
        if Registry.IsRealPlayerCharacter and Registry.IsRealPlayerCharacter(model) then return false end
        local hum=Registry.HumanoidOf(model); local root=Registry.RootOf(model)
        return hum~=nil and root~=nil and hum.Health>0
    end

    RunService.RenderStepped:Connect(function()
        local cam=Workspace.CurrentCamera
        if not cam then return end

        local folder=Workspace:FindFirstChild("TestPlayers")
        local current=setmetatable({}, {__mode="k"})
        if folder then
            for _,model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") and valid(model) then current[model]=true end
            end
        end

        for model in pairs(stores) do if not current[model] then destroy(model) end end

        local any=State.Visuals.ESP or State.Visuals.Chams or State.Visuals.CornerBox or State.Visuals.Box3D or State.Visuals.HealthBar or State.Visuals.NameDistance or State.Visuals.Tracers or State.Visuals.Skeleton or State.Visuals.ThermalCorner
        for model in pairs(current) do
            local s=stores[model] or newStore(model)
            if not any then hide(s) continue end

            local hum=Registry.HumanoidOf(model)
            local root=Registry.RootOf(model)
            local pos,w,h,points=projectedBounds(model,cam)

            local chamsOn=State.Visuals.Chams or State.Visuals.ESP
            s.h.Enabled=chamsOn
            s.h.FillColor=State.Visuals.ThermalCorner and Color3.fromRGB(255,120,40) or BLUE
            s.h.OutlineColor=BLUE

            if not pos then
                hideLines(s.corner); hideLines(s.box3d); hideLines(s.skeleton)
                s.tracer.Visible=false; s.name.Visible=false; s.distance.Visible=false
                s.healthBack.Visible=false; s.health.Visible=false
                continue
            end

            if State.Visuals.CornerBox or State.Visuals.ESP or State.Visuals.ThermalCorner then
                corners(s.corner,pos,w,h,State.Visuals.ThermalCorner and Color3.fromRGB(255,145,60) or BLUE)
            else hideLines(s.corner) end

            if State.Visuals.Box3D then box3d(s.box3d,points,BLUE) else hideLines(s.box3d) end
            if State.Visuals.Skeleton then skeleton(s.skeleton,model,cam) else hideLines(s.skeleton) end

            if State.Visuals.Tracers then
                setLine(s.tracer,Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y),pos,1,BLUE)
            else s.tracer.Visible=false end

            if State.Visuals.NameDistance or State.Visuals.ESP then
                s.name.Position=UDim2.fromOffset(pos.X,pos.Y-h/2-12)
                s.name.Text=model.Name
                s.name.Visible=true
                local dist=root and (root.Position-cam.CFrame.Position).Magnitude or 0
                s.distance.Position=UDim2.fromOffset(pos.X,pos.Y+h/2+9)
                s.distance.Text=string.format("%d studs",math.floor(dist+.5))
                s.distance.Visible=true
            else
                s.name.Visible=false; s.distance.Visible=false
            end

            if (State.Visuals.HealthBar or State.Visuals.ESP) and hum then
                local ratio=math.clamp(hum.Health/math.max(1,hum.MaxHealth),0,1)
                s.healthBack.Position=UDim2.fromOffset(pos.X-w/2-6,pos.Y-h/2)
                s.healthBack.Size=UDim2.fromOffset(3,h)
                s.healthBack.Visible=true
                s.health.Position=UDim2.fromOffset(pos.X-w/2-6,pos.Y-h/2+h*(1-ratio))
                s.health.Size=UDim2.fromOffset(3,h*ratio)
                s.health.Visible=true
            else
                s.healthBack.Visible=false; s.health.Visible=false
            end
        end
    end)
end
