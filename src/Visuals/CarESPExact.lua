-- Exact-style Car ESP port from Yokai PreservedLocalExtrasV15.
-- Differences requested for LvkHub.exe:
--   * reads Workspace.Vehicles directly instead of Registry.Vehicles
--   * no min/max distance gate
--   * uses the existing State.Visuals.CarESP toggle

return function(State)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")

    local carColor=Color3.fromRGB(60,220,180)
    local cars=setmetatable({}, {__mode="k"})
    local vehicles=nil
    local vehicleChildAdded=nil
    local vehicleChildRemoved=nil
    local loopToken=0

    local function isVehicle(m)
        if not m or not m:IsA("Model") then return false end
        if m:FindFirstChildWhichIsA("VehicleSeat",true) then return true end
        if m:FindFirstChild("Seat1",true) then return true end
        local n=m.Name:lower()
        return n:find("car",1,true)
            or n:find("truck",1,true)
            or n:find("sedan",1,true)
            or n:find("vehicle",1,true)
            or n:find("pickup",1,true)
    end

    local function anchor(m)
        return m:FindFirstChildWhichIsA("VehicleSeat",true)
            or m:FindFirstChild("Seat1",true)
            or m.PrimaryPart
            or m:FindFirstChildWhichIsA("BasePart",true)
    end

    local function cleanupModel(m)
        local s=cars[m]
        if s then
            if s.h then pcall(function() s.h:Destroy() end) end
            if s.bb then pcall(function() s.bb:Destroy() end) end
            cars[m]=nil
        end
    end

    local function removeLegacyDuplicates(m)
        for _,d in ipairs(m:GetDescendants()) do
            if d:IsA("Highlight") and (d.Name=="YokaiPreservedCarESP" or d.Name=="LvkHubCarESP" or d.Name=="GunTestingLiteCarESP") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("BillboardGui") and (d.Name=="YokaiPreservedCarLabel" or d.Name=="LvkHubCarESPLabel" or d.Name=="GunTestingLiteCarESPLabel") then
                pcall(function() d:Destroy() end)
            end
        end
    end

    local function addCar(m)
        if cars[m] or not isVehicle(m) then return end
        local a=anchor(m)
        if not a then return end

        removeLegacyDuplicates(m)

        local h=Instance.new("Highlight")
        h.Name="YokaiPreservedCarESP"
        h.Adornee=m
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency=.86
        h.OutlineTransparency=.08
        h.FillColor=carColor
        h.OutlineColor=carColor
        h.Enabled=false
        h.Parent=m

        local bb=Instance.new("BillboardGui")
        bb.Name="YokaiPreservedCarLabel"
        bb.Adornee=a
        bb.AlwaysOnTop=true
        bb.MaxDistance=0
        bb.Size=UDim2.fromOffset(180,28)
        bb.StudsOffsetWorldSpace=Vector3.new(0,3,0)
        bb.Enabled=false
        bb.Parent=a

        local t=Instance.new("TextLabel")
        t.BackgroundTransparency=1
        t.Size=UDim2.fromScale(1,1)
        t.Font=Enum.Font.GothamSemibold
        t.TextSize=12
        t.TextStrokeTransparency=.45
        t.TextColor3=carColor
        t.Parent=bb

        cars[m]={h=h,bb=bb,t=t,a=a}
    end

    local function scanFolder(folder)
        if not folder then return end
        for _,m in ipairs(folder:GetChildren()) do
            addCar(m)
        end
    end

    local function attachVehiclesFolder(folder)
        if vehicles==folder then
            scanFolder(folder)
            return
        end
        if vehicleChildAdded then vehicleChildAdded:Disconnect(); vehicleChildAdded=nil end
        if vehicleChildRemoved then vehicleChildRemoved:Disconnect(); vehicleChildRemoved=nil end
        vehicles=folder
        if vehicles then
            scanFolder(vehicles)
            vehicleChildAdded=vehicles.ChildAdded:Connect(function(m) task.defer(addCar,m) end)
            vehicleChildRemoved=vehicles.ChildRemoved:Connect(function(m) cleanupModel(m) end)
        end
    end

    local function updateCarsOnce()
        local cam=Workspace.CurrentCamera
        for m,s in pairs(cars) do
            if not m or not m.Parent or not s.a or not s.a.Parent then
                cleanupModel(m)
            else
                local show=State.Visuals.CarESP==true
                s.h.Enabled=show
                s.bb.Enabled=show
                if show then
                    s.h.FillColor=carColor
                    s.h.OutlineColor=carColor
                    s.t.TextColor3=carColor
                    local dist=cam and (s.a.Position-cam.CFrame.Position).Magnitude or 0
                    s.t.Text=string.format("%s  •  %d studs",m.Name:gsub("_"," "),math.floor(dist+.5))
                end
            end
        end
    end

    attachVehiclesFolder(Workspace:FindFirstChild("Vehicles"))
    Workspace.ChildAdded:Connect(function(c)
        if c.Name=="Vehicles" then attachVehiclesFolder(c) end
    end)
    Workspace.ChildRemoved:Connect(function(c)
        if c==vehicles then attachVehiclesFolder(nil) end
    end)

    -- Same 5 Hz update cadence used by the working Yokai version. No distance filter.
    task.spawn(function()
        local last=false
        while true do
            local enabled=State.Visuals.CarESP==true
            if not vehicles then attachVehiclesFolder(Workspace:FindFirstChild("Vehicles")) end
            if enabled or last then
                scanFolder(vehicles)
                updateCarsOnce()
            end
            last=enabled
            task.wait(.20)
        end
    end)
end