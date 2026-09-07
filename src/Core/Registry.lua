-- LvkHub.exe shared registries
--
-- ============================================================================
-- WORKSPACE.PLAYERS MIRROR TEST (LOCAL DUMMIES ONLY)
-- ============================================================================
-- Combat + Visuals consume Registry.Bots for compatibility.
-- Registry.Bots is populated ONLY from Workspace.TestPlayers.
--
-- For diagnostics, every Humanoid rig found directly under Workspace.Players is
-- CLONED locally into Workspace.TestPlayers. The original Workspace.Players model
-- is never inserted into Registry.Bots and is never modified by Combat/Visuals.
-- This lets us test the exact same rig/layout used by Workspace.Players without
-- targeting the real Player.Character itself.
--
-- HARD SAFETY INVARIANT:
-- Any Model actually owned by Roblox Players is rejected from Registry.Bots.
-- ============================================================================

local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local LocalPlayer=Players.LocalPlayer

local Registry={
    Bots=setmetatable({}, {__mode="k"}),
    Vehicles=setmetatable({}, {__mode="k"}),
    VehicleFolder=nil,
    TestPlayersFolder=nil,
    _connections={},
}

local function disconnectAll(list)
    for _,c in ipairs(list) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(list)
end

function Registry.HasOtherRealPlayer()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then return true end
    end
    return false
end

-- Test dummies are local clones, so practice can stay active with real Players present.
function Registry.PracticeAllowed()
    return true
end

-- ============================================================================
-- REAL-PLAYER EXCLUSION INVARIANT
-- ============================================================================
local function realPlayerOwned(model)
    if not model or not model:IsA("Model") then return false end

    local ok,p=pcall(function()
        return Players:GetPlayerFromCharacter(model)
    end)
    if ok and p then return true end

    for _,plr in ipairs(Players:GetPlayers()) do
        local ch=plr.Character
        if ch and (model==ch or model:IsDescendantOf(ch) or ch:IsDescendantOf(model)) then
            return true
        end
    end

    return false
end

function Registry.IsRealPlayerCharacter(model)
    return realPlayerOwned(model)
end

function Registry.RootOf(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart")
end

function Registry.HumanoidOf(model)
    return model and model:FindFirstChildOfClass("Humanoid") or nil
end

local function excludedContainer(model)
    local cur=model
    while cur and cur~=Workspace do
        local n=string.lower(cur.Name)
        if n:find("corpse",1,true) or n=="playercorpses" or n=="grounditems" then
            return true
        end
        if Registry.VehicleFolder and (cur==Registry.VehicleFolder or cur:IsDescendantOf(Registry.VehicleFolder)) then
            return true
        end
        cur=cur.Parent
    end
    return false
end

local function rigShapeValid(model)
    if not model or not model:IsA("Model") then return false end
    local hum=model:FindFirstChildOfClass("Humanoid")
    local root=Registry.RootOf(model)
    return hum~=nil and root~=nil
end

local function validTestTarget(model)
    if not model or not model:IsA("Model") or not model:IsDescendantOf(Workspace) then return false end
    if realPlayerOwned(model) or excludedContainer(model) then return false end
    local hum=Registry.HumanoidOf(model)
    local root=Registry.RootOf(model)
    return hum~=nil and root~=nil and hum.Health>0
end

function Registry.IsBot(model)
    return validTestTarget(model) and Registry.Bots[model]==true
end

local function ensureTestPlayersFolder()
    local folder=Workspace:FindFirstChild("TestPlayers")
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="TestPlayers"
        folder:SetAttribute("LvkHubManagedFolder",true)
        folder.Parent=Workspace
    end
    Registry.TestPlayersFolder=folder
    return folder
end

local function sourcePlayerFolder()
    local f=Workspace:FindFirstChild("Players")
    if f and (f:IsA("Folder") or f:IsA("Model")) then return f end
    return nil
end

function Registry.CountWorkspacePlayerRigs()
    local source=sourcePlayerFolder()
    if not source then return 0 end
    local n=0
    for _,m in ipairs(source:GetChildren()) do
        if rigShapeValid(m) then n+=1 end
    end
    return n
end

local mirrorBusy=false

local function stripClone(clone)
    for _,d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
            d:Destroy()
        elseif d:IsA("Tool") then
            d:Destroy()
        elseif d:IsA("BasePart") then
            d.Anchored=true
            d.CanCollide=false
            d.CanTouch=false
            d.Massless=true
        end
    end
end

local function testPlacement(index)
    local ch=LocalPlayer.Character
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    if root then
        local col=(index-1)%4
        local row=math.floor((index-1)/4)
        return root.CFrame*CFrame.new((col-1.5)*6,0,-18-row*7)
    end
    return CFrame.new(index*6,10,0)
end

local function cloneSourceRig(sourceModel,index)
    local oldArchivable=sourceModel.Archivable
    sourceModel.Archivable=true
    local ok,clone=pcall(function() return sourceModel:Clone() end)
    sourceModel.Archivable=oldArchivable
    if not ok or not clone then return nil end

    clone.Name="TEST_"..sourceModel.Name
    clone:SetAttribute("LvkHubManagedDummy",true)
    clone:SetAttribute("LvkHubSourceName",sourceModel.Name)

    local ref=Instance.new("ObjectValue")
    ref.Name="SourceCharacter"
    ref.Value=sourceModel
    ref:SetAttribute("LvkHubManagedReference",true)
    ref.Parent=clone

    stripClone(clone)
    clone.Parent=ensureTestPlayersFolder()
    pcall(function() clone:PivotTo(testPlacement(index)) end)
    return clone
end

local function sourceFromClone(clone)
    if not clone or not clone:IsA("Model") then return nil end
    local ref=clone:FindFirstChild("SourceCharacter")
    if ref and ref:IsA("ObjectValue") then return ref.Value end
    return nil
end

local function syncManagedClones()
    if mirrorBusy then return end
    mirrorBusy=true

    local testFolder=ensureTestPlayersFolder()
    local source=sourcePlayerFolder()
    local wanted=setmetatable({}, {__mode="k"})
    local ordered={}

    if source then
        for _,m in ipairs(source:GetChildren()) do
            if rigShapeValid(m) then
                wanted[m]=true
                table.insert(ordered,m)
            end
        end
    end

    table.sort(ordered,function(a,b) return string.lower(a.Name)<string.lower(b.Name) end)

    local existing=setmetatable({}, {__mode="k"})
    for _,entry in ipairs(testFolder:GetChildren()) do
        if entry:IsA("Model") and entry:GetAttribute("LvkHubManagedDummy")==true then
            local src=sourceFromClone(entry)
            if src and wanted[src] and src.Parent then
                existing[src]=entry
            else
                entry:Destroy()
            end
        end
    end

    for index,src in ipairs(ordered) do
        local clone=existing[src]
        if not clone or not clone.Parent then
            clone=cloneSourceRig(src,index)
            existing[src]=clone
        end
    end

    mirrorBusy=false
end

local function resolveTestEntry(entry)
    if not entry then return nil end
    if entry:IsA("Model") then
        return validTestTarget(entry) and entry or nil
    end
    if entry:IsA("ObjectValue") then
        local model=entry.Value
        return validTestTarget(model) and model or nil
    end
    return nil
end

local function rebuildTargets()
    table.clear(Registry.Bots)
    local folder=ensureTestPlayersFolder()
    for _,entry in ipairs(folder:GetChildren()) do
        local model=resolveTestEntry(entry)
        if model then Registry.Bots[model]=true end
    end
end

function Registry.RefreshTargets()
    syncManagedClones()
    rebuildTargets()
end

local function rescanVehicles()
    table.clear(Registry.Vehicles)
    local folder=Registry.VehicleFolder
    if not folder then return end
    for _,child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then Registry.Vehicles[child]=true end
    end
end

local function attachVehicles(folder)
    Registry.VehicleFolder=folder
    rescanVehicles()
end

local function attachPlayerCharacterRefresh(player)
    table.insert(Registry._connections,player.CharacterAdded:Connect(function()
        task.defer(Registry.RefreshTargets)
    end))
    table.insert(Registry._connections,player.CharacterRemoving:Connect(function()
        task.defer(Registry.RefreshTargets)
    end))
end

function Registry.Refresh()
    disconnectAll(Registry._connections)

    attachVehicles(Workspace:FindFirstChild("Vehicles"))
    Registry.RefreshTargets()

    local testFolder=ensureTestPlayersFolder()
    table.insert(Registry._connections,testFolder.ChildAdded:Connect(function()
        if not mirrorBusy then task.defer(rebuildTargets) end
    end))
    table.insert(Registry._connections,testFolder.ChildRemoved:Connect(function()
        if not mirrorBusy then task.defer(rebuildTargets) end
    end))

    local source=sourcePlayerFolder()
    if source then
        table.insert(Registry._connections,source.ChildAdded:Connect(function() task.defer(Registry.RefreshTargets) end))
        table.insert(Registry._connections,source.ChildRemoved:Connect(function() task.defer(Registry.RefreshTargets) end))
    end

    table.insert(Registry._connections,Workspace.ChildAdded:Connect(function(child)
        if child.Name=="Vehicles" then
            attachVehicles(child)
        elseif child.Name=="Players" or child.Name=="TestPlayers" then
            task.defer(Registry.Refresh)
        end
    end))

    table.insert(Registry._connections,Workspace.ChildRemoved:Connect(function(child)
        if child==Registry.VehicleFolder then
            Registry.VehicleFolder=nil
            table.clear(Registry.Vehicles)
        end
        if child==Registry.TestPlayersFolder or child.Name=="Players" then
            task.defer(Registry.Refresh)
        end
    end))

    table.insert(Registry._connections,Workspace.DescendantAdded:Connect(function(obj)
        local sourceNow=sourcePlayerFolder()
        if sourceNow and obj:IsDescendantOf(sourceNow) and (obj:IsA("Humanoid") or obj.Name=="HumanoidRootPart" or obj.Name=="Head") then
            task.defer(Registry.RefreshTargets)
        end
        if obj and obj.Parent==Registry.VehicleFolder and obj:IsA("Model") then
            Registry.Vehicles[obj]=true
        end
    end))

    table.insert(Registry._connections,Workspace.DescendantRemoving:Connect(function(obj)
        Registry.Bots[obj]=nil
        Registry.Vehicles[obj]=nil
    end))

    table.insert(Registry._connections,Players.PlayerAdded:Connect(function(p)
        attachPlayerCharacterRefresh(p)
        task.defer(Registry.RefreshTargets)
    end))
    table.insert(Registry._connections,Players.PlayerRemoving:Connect(function()
        task.defer(Registry.RefreshTargets)
    end))
    for _,p in ipairs(Players:GetPlayers()) do attachPlayerCharacterRefresh(p) end
end

function Registry.CountBots()
    local n=0
    for model in pairs(Registry.Bots) do
        if not validTestTarget(model) then
            Registry.Bots[model]=nil
        else
            n+=1
        end
    end
    return n
end

function Registry.CountVehicles()
    local n=0
    for model in pairs(Registry.Vehicles) do
        if model and model.Parent then
            n+=1
        else
            Registry.Vehicles[model]=nil
        end
    end
    return n
end

Registry.Refresh()
return Registry
