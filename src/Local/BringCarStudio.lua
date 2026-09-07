-- BringCar for local practice sessions.
-- Vehicle discovery is direct from Workspace.Vehicles and has no distance filter.
return function(Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local Restrictions=shared.LvkHubRestrictions
    local page=UI.Pages.Vehicle or UI.Pages.Local

    UI.Section(page,"BringCar")
    local _,status=UI.Row(page,"BringCar: scanning Workspace.Vehicles...")
    status.TextColor3=Color3.fromRGB(160,190,255)

    local selected=nil
    local selectedIndex=0

    local function vehicleFolder()
        return Workspace:FindFirstChild("Vehicles")
    end

    local function vehicleList()
        local folder=vehicleFolder()
        local list={}
        if not folder then return list end
        for _,m in ipairs(folder:GetChildren()) do if m:IsA("Model") then table.insert(list,m) end end
        table.sort(list,function(a,b)
            local an,bn=string.lower(a.Name),string.lower(b.Name)
            if an==bn then return tostring(a:GetDebugId())<tostring(b:GetDebugId()) end
            return an<bn
        end)
        return list
    end

    local function refreshStatus()
        local list=vehicleList()
        if #list==0 then
            selected=nil; selectedIndex=0; status.Text="BringCar: 0 vehicles in Workspace.Vehicles"; return list
        end
        if selected and selected.Parent then
            local found=table.find(list,selected)
            if found then selectedIndex=found else selected=nil; selectedIndex=0 end
        else selected=nil; selectedIndex=0 end
        status.Text=selected and string.format("Vehicle %d/%d: %s",selectedIndex,#list,selected.Name) or string.format("BringCar: %d vehicles found",#list)
        return list
    end

    local function findDriverSeat(vehicle)
        if not vehicle then return nil end
        local functional=vehicle:FindFirstChild("Functional")
        local seatsFolder=functional and functional:FindFirstChild("Seats")
        if seatsFolder then
            for _,obj in ipairs(seatsFolder:GetDescendants()) do
                if obj:IsA("VehicleSeat") then
                    local n=string.lower(obj.Name)
                    if n:find("driver",1,true) or n:find("drive",1,true) then return obj end
                end
            end
            local vehicleSeat=seatsFolder:FindFirstChildWhichIsA("VehicleSeat",true)
            if vehicleSeat then return vehicleSeat end
        end
        for _,obj in ipairs(vehicle:GetDescendants()) do
            if obj:IsA("VehicleSeat") then
                local n=string.lower(obj.Name)
                if n:find("driver",1,true) or n:find("drive",1,true) then return obj end
            end
        end
        local vehicleSeat=vehicle:FindFirstChildWhichIsA("VehicleSeat",true)
        if vehicleSeat then return vehicleSeat end
        local seat1=vehicle:FindFirstChild("Seat1",true)
        if seat1 and seat1:IsA("Seat") then return seat1 end
        return vehicle:FindFirstChildWhichIsA("Seat",true)
    end

    local function realPlayerInSeat(seat)
        if type(Restrictions)=="table" and type(Restrictions.RealPlayerInSeat)=="function" then
            return Restrictions.RealPlayerInSeat(seat)
        end
        return true -- fail closed when restrictions are unavailable
    end

    UI.Button(page,"Select vehicle","NEXT",function()
        local list=refreshStatus(); if #list==0 then return end
        selectedIndex=(selectedIndex%#list)+1
        selected=list[selectedIndex]
        local seat=findDriverSeat(selected)
        if seat then
            local occupiedBy=realPlayerInSeat(seat)
            status.Text=occupiedBy and string.format("Vehicle %d/%d: %s • driver occupied",selectedIndex,#list,selected.Name)
                or string.format("Vehicle %d/%d: %s • driver: %s",selectedIndex,#list,selected.Name,seat.Name)
        else
            status.Text=string.format("Vehicle %d/%d: %s • driver not found",selectedIndex,#list,selected.Name)
        end
    end)

    UI.Button(page,"Refresh vehicles","REFRESH",function(b)
        refreshStatus(); b.Text="DONE"; task.wait(.35); b.Text="REFRESH"
    end)

    UI.Button(page,"Bring selected car","BRING",function(b)
        local permitted=type(Restrictions)=="table" and type(Restrictions.VehicleBringAllowed)=="function" and Restrictions.VehicleBringAllowed()==true
        if not permitted then status.Text="BringCar: restricted by centralized session policy"; return end

        local list=refreshStatus(); if #list==0 then return end
        if not selected or not selected.Parent then selectedIndex=1; selected=list[1] end

        local ch=LP.Character
        local hum=ch and ch:FindFirstChildOfClass("Humanoid")
        local root=ch and ch:FindFirstChild("HumanoidRootPart")
        if not ch or not hum or not root then status.Text="BringCar: local character not ready"; return end

        local seat=findDriverSeat(selected)
        if not seat or not seat:IsA("BasePart") then status.Text="BringCar: driver VehicleSeat not found in "..selected.Name; return end
        if realPlayerInSeat(seat) then status.Text="BringCar: driver seat occupied by a real Player"; return end

        local vehicleRoot=selected.PrimaryPart or seat or selected:FindFirstChildWhichIsA("BasePart",true)
        if not vehicleRoot then status.Text="BringCar: vehicle root not found"; return end

        local old=root.CFrame
        local destination=old*CFrame.new(0,0,-8)
        if selected.PrimaryPart then pcall(function() selected:PivotTo(destination) end)
        else pcall(function() vehicleRoot.CFrame=destination end) end

        task.wait(.15)
        pcall(function() root.CFrame=seat.CFrame*CFrame.new(0,2,0) end)
        task.wait(.15)
        pcall(function() seat:Sit(hum) end)
        task.wait(.35)
        if root.Parent then pcall(function() root.CFrame=old end) end

        status.Text=string.format("Vehicle %d/%d: %s • driver: %s",selectedIndex,#list,selected.Name,seat.Name)
        b.Text="DONE"; task.wait(.5); b.Text="BRING"
    end)

    local folder=vehicleFolder()
    if folder then
        folder.ChildAdded:Connect(function() task.defer(refreshStatus) end)
        folder.ChildRemoved:Connect(function() task.defer(refreshStatus) end)
    end
    Workspace.ChildAdded:Connect(function(c)
        if c.Name=="Vehicles" then
            c.ChildAdded:Connect(function() task.defer(refreshStatus) end)
            c.ChildRemoved:Connect(function() task.defer(refreshStatus) end)
            task.defer(refreshStatus)
        end
    end)
    task.defer(refreshStatus)
end
