-- BulletTracer V4: local cosmetic beam that starts at the actual equipped/viewmodel muzzle.
-- No remotes are sent and no weapon/server state is modified.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local UIS=game:GetService("UserInputService")
    local RunService=game:GetService("RunService")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local

    State.Local.BulletTracer=State.Local.BulletTracer==true
    local C=State.Local._BulletTracerV4 or State.Local._BulletTracerV3 or {
        Color=Color3.fromRGB(119,120,255),Transparency=5,Lifetime=.18,Thickness=.08,Glow=true,Distance=20000,
    }
    State.Local._BulletTracerV4=C

    local function rounded(o,r)
        local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 4);c.Parent=o
    end

    local rainbow=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
    })

    local function openOptions()
        local p=Instance.new("Frame")
        p.Name="LvkBulletTracerOptionsV4";p.Size=UDim2.fromOffset(236,252);p.BackgroundColor3=Color3.fromRGB(17,18,22);p.BorderSizePixel=0;p.ZIndex=130;rounded(p,7)
        local ps=Instance.new("UIStroke");ps.Color=Color3.fromRGB(65,67,80);ps.Transparency=.12;ps.Parent=p
        local title=Instance.new("TextLabel");title.BackgroundTransparency=1;title.Position=UDim2.fromOffset(10,5);title.Size=UDim2.new(1,-42,0,28);title.Font=Enum.Font.SourceSansSemibold;title.TextSize=14;title.TextColor3=Color3.fromRGB(238,238,242);title.TextXAlignment=Enum.TextXAlignment.Left;title.Text="BulletTracer";title.ZIndex=131;title.Parent=p
        local close=Instance.new("TextButton");close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-7,0,6);close.Size=UDim2.fromOffset(25,22);close.BackgroundColor3=Color3.fromRGB(34,35,42);close.BorderSizePixel=0;close.Text="×";close.TextColor3=Color3.fromRGB(215,215,222);close.ZIndex=132;close.Parent=p;rounded(close,4)
        close.MouseButton1Click:Connect(function() if UI.CloseDockedPanel then UI.CloseDockedPanel(p) elseif p.Parent then p:Destroy() end end)

        local cr=Instance.new("Frame");cr.Position=UDim2.fromOffset(7,39);cr.Size=UDim2.new(1,-14,0,38);cr.BackgroundColor3=Color3.fromRGB(27,28,34);cr.BorderSizePixel=0;cr.ZIndex=131;cr.Parent=p;rounded(cr,4)
        local cl=Instance.new("TextLabel");cl.BackgroundTransparency=1;cl.Position=UDim2.fromOffset(8,0);cl.Size=UDim2.fromOffset(74,38);cl.Font=Enum.Font.SourceSans;cl.TextSize=12;cl.TextColor3=Color3.fromRGB(222,222,228);cl.TextXAlignment=Enum.TextXAlignment.Left;cl.Text="Color";cl.ZIndex=132;cl.Parent=cr
        local cb=Instance.new("Frame");cb.Position=UDim2.fromOffset(80,11);cb.Size=UDim2.new(1,-90,0,16);cb.BackgroundColor3=Color3.new(1,1,1);cb.BorderSizePixel=0;cb.Active=true;cb.ZIndex=133;cb.Parent=cr;rounded(cb,4)
        local grad=Instance.new("UIGradient");grad.Color=rainbow;grad.Parent=cb
        local ck=Instance.new("Frame");ck.AnchorPoint=Vector2.new(.5,.5);ck.Size=UDim2.fromOffset(4,22);ck.BackgroundColor3=Color3.fromRGB(248,248,250);ck.BorderSizePixel=0;ck.ZIndex=134;ck.Parent=cb
        local cd=false
        local function colorX(x)
            local h=math.clamp((x-cb.AbsolutePosition.X)/math.max(1,cb.AbsoluteSize.X),0,1)
            C.Color=Color3.fromHSV(h,1,1);ck.Position=UDim2.new(h,0,.5,0)
        end
        cb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then cd=true;colorX(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i) if cd and i.UserInputType==Enum.UserInputType.MouseMovement then colorX(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then cd=false end end)
        ck.Position=UDim2.new(select(1,C.Color:ToHSV()),0,.5,0)

        local function slider(label,get,set,min,max,step,y)
            local r=Instance.new("Frame");r.Position=UDim2.fromOffset(7,y);r.Size=UDim2.new(1,-14,0,38);r.BackgroundColor3=Color3.fromRGB(27,28,34);r.BorderSizePixel=0;r.ZIndex=131;r.Parent=p;rounded(r,4)
            local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(8,0);l.Size=UDim2.fromOffset(76,38);l.Font=Enum.Font.SourceSans;l.TextSize=12;l.TextColor3=Color3.fromRGB(222,222,228);l.TextXAlignment=Enum.TextXAlignment.Left;l.Text=label;l.ZIndex=132;l.Parent=r
            local bar=Instance.new("Frame");bar.Position=UDim2.fromOffset(82,16);bar.Size=UDim2.new(1,-137,0,6);bar.BackgroundColor3=Color3.fromRGB(43,44,51);bar.BorderSizePixel=0;bar.Active=true;bar.ZIndex=133;bar.Parent=r;rounded(bar,3)
            local fill=Instance.new("Frame");fill.BackgroundColor3=UI.Accent;fill.BorderSizePixel=0;fill.ZIndex=134;fill.Parent=bar;rounded(fill,3)
            local k=Instance.new("Frame");k.AnchorPoint=Vector2.new(.5,.5);k.Size=UDim2.fromOffset(10,16);k.BackgroundColor3=Color3.fromRGB(242,242,245);k.BorderSizePixel=0;k.ZIndex=135;k.Parent=bar;rounded(k,5)
            local val=Instance.new("TextLabel");val.AnchorPoint=Vector2.new(1,.5);val.Position=UDim2.new(1,-7,.5,0);val.Size=UDim2.fromOffset(44,20);val.BackgroundColor3=Color3.fromRGB(35,36,43);val.BorderSizePixel=0;val.Font=Enum.Font.Code;val.TextSize=9;val.TextColor3=Color3.fromRGB(220,220,228);val.ZIndex=134;val.Parent=r;rounded(val,3)
            local dragging=false
            local function paint()
                local n=math.clamp(tonumber(get()) or min,min,max);local a=(n-min)/(max-min)
                fill.Size=UDim2.new(a,0,1,0);k.Position=UDim2.new(a,0,.5,0);val.Text=step<1 and string.format("%.2f",n) or tostring(math.floor(n+.5))
            end
            local function fromX(x)
                local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
                local n=min+(max-min)*a;n=math.floor(n/step+.5)*step;set(math.clamp(n,min,max));paint()
            end
            bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;fromX(i.Position.X) end end)
            k.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;fromX(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then fromX(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            paint()
        end
        slider("Transp.",function() return C.Transparency end,function(v) C.Transparency=v end,0,100,1,82)
        slider("Lifetime",function() return C.Lifetime end,function(v) C.Lifetime=v end,.05,1.5,.05,125)
        slider("Thickness",function() return C.Thickness end,function(v) C.Thickness=v end,.02,.35,.01,168)
        local gr=Instance.new("Frame");gr.Position=UDim2.fromOffset(7,211);gr.Size=UDim2.new(1,-14,0,31);gr.BackgroundColor3=Color3.fromRGB(27,28,34);gr.BorderSizePixel=0;gr.ZIndex=131;gr.Parent=p;rounded(gr,4)
        local gl=Instance.new("TextLabel");gl.BackgroundTransparency=1;gl.Position=UDim2.fromOffset(8,0);gl.Size=UDim2.new(1,-50,1,0);gl.Font=Enum.Font.SourceSans;gl.TextSize=12;gl.TextColor3=Color3.fromRGB(222,222,228);gl.TextXAlignment=Enum.TextXAlignment.Left;gl.Text="Glow";gl.ZIndex=132;gl.Parent=gr
        local gb=Instance.new("TextButton");gb.AnchorPoint=Vector2.new(1,.5);gb.Position=UDim2.new(1,-7,.5,0);gb.Size=UDim2.fromOffset(34,18);gb.Text="";gb.BorderSizePixel=0;gb.ZIndex=133;gb.Parent=gr;rounded(gb,3)
        local function gp() gb.BackgroundColor3=C.Glow and UI.Accent or Color3.fromRGB(48,49,57) end
        gb.MouseButton1Click:Connect(function() C.Glow=not C.Glow;gp() end);gp()
        if UI.OpenDockedPanel then UI.OpenDockedPanel(p) else p.Parent=UI.Gui end
    end

    local row,text=UI.Row(page,"BulletTracer")
    text.Size=UDim2.new(1,-78,1,0);text.Active=true
    local dots=Instance.new("TextButton");dots.AnchorPoint=Vector2.new(1,.5);dots.Position=UDim2.new(1,-44,.5,0);dots.Size=UDim2.fromOffset(26,20);dots.BackgroundColor3=Color3.fromRGB(34,34,40);dots.BorderSizePixel=0;dots.Font=Enum.Font.SourceSansBold;dots.TextSize=15;dots.TextColor3=Color3.fromRGB(195,195,205);dots.Text="•••";dots.Parent=row;rounded(dots,4)
    local tog=Instance.new("TextButton");tog.AnchorPoint=Vector2.new(1,.5);tog.Position=UDim2.new(1,-7,.5,0);tog.Size=UDim2.fromOffset(28,18);tog.Text="";tog.BorderSizePixel=0;tog.Parent=row;rounded(tog,3)
    local mark=Instance.new("Frame");mark.AnchorPoint=Vector2.new(.5,.5);mark.Position=UDim2.fromScale(.5,.5);mark.Size=UDim2.fromOffset(18,10);mark.BorderSizePixel=0;mark.Parent=tog;rounded(mark,2)
    local function paint() local on=State.Local.BulletTracer;tog.BackgroundColor3=on and UI.Accent or Color3.fromRGB(45,45,45);mark.BackgroundColor3=on and Color3.fromRGB(238,238,240) or Color3.fromRGB(86,86,86) end
    local function flip() State.Local.BulletTracer=not State.Local.BulletTracer;paint() end
    tog.MouseButton1Click:Connect(flip);text.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then flip() end end);dots.MouseButton1Click:Connect(openOptions);paint()

    for _,name in ipairs({"LvkHubBulletTracersV2","LvkHubBulletTracersV3","LvkHubBulletTracersV4"}) do
        local old=Workspace:FindFirstChild(name);if old then old:Destroy() end
    end
    local folder=Instance.new("Folder");folder.Name="LvkHubBulletTracersV4";folder.Parent=Workspace

    local function currentWeapon()
        local ch=LP.Character
        if not ch then return nil end
        for _,o in ipairs(ch:GetChildren()) do
            if o:IsA("Tool") and (o:FindFirstChild("WeaponConfig") or o:FindFirstChild("Ammo")) then return o end
        end
    end

    local muzzleNames={muzzle=true,muzzlepoint=true,muzzleattachment=true,barrelend=true,firepoint=true,tip=true}
    local function worldPosition(obj)
        if not obj then return nil end
        if obj:IsA("Attachment") then return obj.WorldPosition end
        if obj:IsA("BasePart") then return obj.Position end
    end
    local function findMuzzle(root)
        if not root then return nil end
        for _,d in ipairs(root:GetDescendants()) do
            local n=d.Name:lower():gsub("[%s_%-]","")
            if muzzleNames[n] and (d:IsA("Attachment") or d:IsA("BasePart")) then return d end
        end
        local grip=root:FindFirstChild("Grip",true)
        if grip then
            local a=grip:FindFirstChildWhichIsA("Attachment",true)
            if a and a.Name:lower():find("muzzle",1,true) then return a end
        end
    end
    local function muzzlePosition(tool)
        -- Third-person/equipped weapon first.
        local obj=findMuzzle(tool)
        local p=worldPosition(obj)
        if p then return p end

        -- First-person viewmodel second.
        local cam=Workspace.CurrentCamera
        if cam then
            local toolName=tool and tool.Name:lower() or ""
            local best=nil
            for _,m in ipairs(cam:GetDescendants()) do
                if m:IsA("Model") then
                    local n=m.Name:lower()
                    if toolName=="" or n==toolName or n:find(toolName,1,true) or m:FindFirstChild("Grip",true) then
                        best=findMuzzle(m)
                        if best then break end
                    end
                end
            end
            p=worldPosition(best)
            if p then return p end
        end

        -- Handle front is a better cosmetic fallback than the camera center.
        local handle=tool and (tool:FindFirstChild("Handle",true) or tool:FindFirstChild("Grip",true))
        if handle and handle:IsA("BasePart") then
            return handle.Position+handle.CFrame.LookVector*(math.max(handle.Size.X,handle.Size.Y,handle.Size.Z)*.5)
        end
        if cam then return cam.CFrame.Position+cam.CFrame.LookVector*.6 end
    end

    local function endpoint()
        local cam=Workspace.CurrentCamera
        if not cam then return nil end
        local center=cam.ViewportSize/2
        local ray=cam:ViewportPointToRay(center.X,center.Y)
        local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude
        local ex={folder,cam};if LP.Character then table.insert(ex,LP.Character) end
        rp.FilterDescendantsInstances=ex;rp.IgnoreWater=true
        local distance=C.Distance or 20000
        local hit=Workspace:Raycast(ray.Origin,ray.Direction*distance,rp)
        return hit and hit.Position or (ray.Origin+ray.Direction*distance)
    end

    local function point(v)
        local p=Instance.new("Part");p.Size=Vector3.new(.03,.03,.03);p.Transparency=1;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CFrame=CFrame.new(v);p.Parent=folder
        local a=Instance.new("Attachment");a.Parent=p
        return p,a
    end

    local lastSpawn=0
    local function spawn(tool)
        if not State.Local.BulletTracer or not tool or tool.Parent~=LP.Character then return end
        local now=os.clock();if now-lastSpawn<.045 then return end;lastSpawn=now
        local a=muzzlePosition(tool);local b=endpoint();if not a or not b then return end
        local p0,a0=point(a);local p1,a1=point(b)
        local beam=Instance.new("Beam")
        beam.Attachment0=a0;beam.Attachment1=a1;beam.FaceCamera=true;beam.Color=ColorSequence.new(C.Color)
        beam.Transparency=NumberSequence.new(math.clamp((C.Transparency or 0)/100,0,1));beam.Width0=C.Thickness or .08;beam.Width1=C.Thickness or .08
        beam.LightEmission=C.Glow and 1 or .2;beam.LightInfluence=0;beam.Parent=p0
        if C.Glow then
            local g=beam:Clone();g.Name="Glow";g.Width0=(C.Thickness or .08)*2.8;g.Width1=g.Width0
            g.Transparency=NumberSequence.new(math.clamp((C.Transparency or 0)/100+.45,0,1));g.Parent=p0
        end
        task.delay(math.max(.05,C.Lifetime or .18),function() if p0 then p0:Destroy() end;if p1 then p1:Destroy() end end)
    end

    local watched=setmetatable({}, {__mode="k"})
    local function watchTool(tool)
        if not tool or not tool:IsA("Tool") or watched[tool] or not (tool:FindFirstChild("WeaponConfig") or tool:FindFirstChild("Ammo")) then return end
        watched[tool]=true
        tool.Activated:Connect(function() task.defer(spawn,tool) end)
        local ammo=tool:FindFirstChild("Ammo")
        local mag=ammo and ammo:FindFirstChild("MagAmmo")
        local last=mag and tonumber(mag.Value)
        if mag and mag:IsA("ValueBase") then
            mag:GetPropertyChangedSignal("Value"):Connect(function()
                local n=tonumber(mag.Value)
                if n and last and n<last then spawn(tool) end
                last=n
            end)
        end
    end

    local function scanCharacter()
        local ch=LP.Character
        if not ch then return end
        for _,o in ipairs(ch:GetChildren()) do if o:IsA("Tool") then watchTool(o) end end
    end
    if LP.Character then
        scanCharacter()
        LP.Character.ChildAdded:Connect(function(o) if o:IsA("Tool") then task.defer(watchTool,o) end end)
    end
    LP.CharacterAdded:Connect(function(ch)
        ch.ChildAdded:Connect(function(o) if o:IsA("Tool") then task.defer(watchTool,o) end end)
        task.delay(.25,scanCharacter)
    end)

    UIS.InputBegan:Connect(function(i,processed)
        if processed and UIS:GetFocusedTextBox() then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            local tool=currentWeapon()
            if tool then task.delay(.015,spawn,tool) end
        end
    end)

    local timer=0
    RunService.Heartbeat:Connect(function(dt)
        timer+=dt
        if timer>.5 then timer=0;scanCharacter() end
    end)
end
