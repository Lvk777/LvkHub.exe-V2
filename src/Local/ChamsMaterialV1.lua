-- Local-only material layer for SelfChams and GunChams.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local A=State.Local._Appearance or {}
    A.SelfMaterial=A.SelfMaterial or "ForceField"
    A.GunMaterial=A.GunMaterial or "ForceField"
    State.Local._Appearance=A

    local mats={ForceField=Enum.Material.ForceField,Neon=Enum.Material.Neon,SmoothPlastic=Enum.Material.SmoothPlastic,Glass=Enum.Material.Glass,Foil=Enum.Material.Foil,Metal=Enum.Material.Metal,Plastic=Enum.Material.Plastic}
    local selfSnap=setmetatable({}, {__mode="k"})
    local gunSnap=setmetatable({}, {__mode="k"})
    local texSnap=setmetatable({}, {__mode="k"})

    local function snapPart(map,p)
        if not map[p] then map[p]={Material=p.Material,Color=p.Color,TextureID=p:IsA("MeshPart") and p.TextureID or nil} end
    end
    local function restoreMap(map)
        for p,s in pairs(map) do
            if p and p.Parent then pcall(function() p.Material=s.Material;p.Color=s.Color;if p:IsA("MeshPart") and s.TextureID~=nil then p.TextureID=s.TextureID end end) end
            map[p]=nil
        end
    end
    local function restoreTextures()
        for d,v in pairs(texSnap) do if d and d.Parent then pcall(function() d.Transparency=v end) end;texSnap[d]=nil end
    end
    local function applySelf()
        if not State.Local.SelfChams then restoreMap(selfSnap);return end
        local ch=LP.Character;if not ch then return end
        local mat=mats[A.SelfMaterial] or Enum.Material.ForceField
        for _,o in ipairs(ch:GetDescendants()) do
            if o:IsA("BasePart") and o.Name~="HumanoidRootPart" and not o:FindFirstAncestorWhichIsA("Tool") then
                snapPart(selfSnap,o);o.Material=mat;o.Color=A.SelfColor or Color3.fromRGB(119,120,255)
                if o:IsA("MeshPart") then o.TextureID="" end
            end
        end
    end
    local function gunRoots()
        local out={};local ch=LP.Character;local tool=nil
        if ch then for _,x in ipairs(ch:GetChildren()) do if x:IsA("Tool") then tool=x;table.insert(out,x);break end end end
        local cam=Workspace.CurrentCamera
        if cam then
            local tn=tool and tool.Name:lower() or ""
            for _,m in ipairs(cam:GetDescendants()) do
                if m:IsA("Model") then
                    local n=m.Name:lower();local grip=m:FindFirstChild("Grip",true);local muzzle=grip and grip:FindFirstChild("Muzzle",true)
                    if (tn~="" and (n==tn or n:find(tn,1,true))) or (grip and muzzle) then table.insert(out,m) end
                end
            end
        end
        return out
    end
    local function applyGun()
        if not State.Local.GunChams then restoreMap(gunSnap);restoreTextures();return end
        local mat=mats[A.GunMaterial] or Enum.Material.ForceField
        local live={}
        for _,root in ipairs(gunRoots()) do
            for _,o in ipairs(root:GetDescendants()) do
                if o:IsA("BasePart") then
                    live[o]=true;snapPart(gunSnap,o);o.Material=mat;o.Color=A.GunColor or Color3.fromRGB(119,120,255)
                    if o:IsA("MeshPart") then o.TextureID="" end
                elseif o:IsA("Decal") or o:IsA("Texture") then
                    if texSnap[o]==nil then texSnap[o]=o.Transparency end;o.Transparency=1
                end
            end
        end
        for p,s in pairs(gunSnap) do
            if not live[p] then
                if p and p.Parent then pcall(function() p.Material=s.Material;p.Color=s.Color;if p:IsA("MeshPart") and s.TextureID~=nil then p.TextureID=s.TextureID end end) end
                gunSnap[p]=nil
            end
        end
    end

    local t=0
    RunService.RenderStepped:Connect(function(dt)
        t+=dt;if t<.08 then return end;t=0
        applySelf();applyGun()
    end)
    LP.CharacterAdded:Connect(function() restoreMap(selfSnap);restoreMap(gunSnap);restoreTextures() end)
end
