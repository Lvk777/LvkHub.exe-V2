-- BringCar for local practice sessions.
-- Vehicle discovery is direct from Workspace.Vehicles and has no distance filter.
return function(Registry, UI)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local LP = Players.LocalPlayer
    local page = UI.Pages.Vehicle or UI.Pages.Local

    UI.Section(page, "BringCar")
    local _, status = UI.Row(page, "BringCar: scanning Workspace.Vehicles...")
    status.TextColor3 = Color3.fromRGB(160, 190, 255)

    local selected = nil
    local selectedIndex = 0

    local function vehicleFolder()
        return Workspace:FindFirstChild("Vehicles")
    end

    local function vehicleList()
        local folder = vehicleFolder()
        local list = {}
        if not folder then return list end
        for _, m in ipairs(folder:GetChildren()) do
            if m:IsA("Model") then table.insert(list, m) end
        end
        table.sort(list, function(a, b)
            local an, bn = string.lower(a.Name), string.lower(b.Name)
            if an == bn then return tostring(a:GetDebugId()) < tostring(b:GetDebugId()) end
            return an < bn
        end)
        return list
    end

    local function refreshStatus()
        local list = vehicleList()
        if #list == 0 then
            selected = nil
            selectedIndex = 0
            status.Text = "BringCar: 0 vehicles in Workspace.Vehicles"
            return list
        end
        if selected and selected.Parent then
            local found = table.find(list, selected)
            if found then selectedIndex = found else selected = nil; selectedIndex = 0 end
        else
            selected = nil
            selectedIndex = 0
        end
        status.Text = selected
            and string.format("Vehicle %d/%d: %s", selectedIndex, #list, selected.Name)
            or string.format("BringCar: %d vehicles found", #list)
        return list
    end

    local function driverScore(seat)
        if not seat or not (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then return -1 end
        local n = string.lower(seat.Name)
        local score = seat:IsA("VehicleSeat") and 100 or 10
        if n:find("driver", 1, true) or n:find("drive", 1, true) then score += 50 end
        if n == "seat1" or n == "vehicle seat" or n == "vehicleseat" then score += 15 end
        local p = seat.Parent
        if p and string.lower(p.Name):find("seat", 1, true) then score += 5 end
        return score
    end

    local function scanDriverSeat(vehicle)
        if not vehicle then return nil end
        local best, bestScore = nil, -1

        local functional = vehicle:FindFirstChild("Functional")
        local seatsFolder = functional and functional:FindFirstChild("Seats")
        if seatsFolder then
            for _, obj in ipairs(seatsFolder:GetDescendants()) do
                local score = driverScore(obj)
                if score > bestScore then best, bestScore = obj, score end
            end
            if best then return best end
        end

        for _, obj in ipairs(vehicle:GetDescendants()) do
            local score = driverScore(obj)
            if score > bestScore then best, bestScore = obj, score end
        end
        return best
    end

    local function findDriverSeat(vehicle, retrySeconds)
        local seat = scanDriverSeat(vehicle)
        if seat or not vehicle or (retrySeconds or 0) <= 0 then return seat end

        local deadline = os.clock() + retrySeconds
        repeat
            task.wait(.10)
            if not vehicle.Parent then return nil end
            seat = scanDriverSeat(vehicle)
        until seat or os.clock() >= deadline
        return seat
    end

    local function playerInSeat(seat)
        local occupant = seat and seat.Occupant
        if not occupant then return nil end
        local char = occupant.Parent
        return char and Players:GetPlayerFromCharacter(char) or nil
    end

    UI.Button(page, "Select vehicle", "NEXT", function()
        local list = refreshStatus()
        if #list == 0 then return end
        selectedIndex = (selectedIndex % #list) + 1
        selected = list[selectedIndex]
        local seat = findDriverSeat(selected, .6)
        if seat then
            local occupiedBy = playerInSeat(seat)
            status.Text = occupiedBy
                and string.format("Vehicle %d/%d: %s • occupied by %s", selectedIndex, #list, selected.Name, occupiedBy.Name)
                or string.format("Vehicle %d/%d: %s • driver: %s", selectedIndex, #list, selected.Name, seat.Name)
        else
            status.Text = string.format("Vehicle %d/%d: %s • seat not streamed/found", selectedIndex, #list, selected.Name)
        end
    end)

    UI.Button(page, "Refresh vehicles", "REFRESH", function(b)
        refreshStatus()
        b.Text = "DONE"
        task.wait(.35)
        b.Text = "REFRESH"
    end)

    UI.Button(page, "Bring selected car", "BRING", function(b)
        local list = refreshStatus()
        if #list == 0 then return end
        if not selected or not selected.Parent then
            selectedIndex = 1
            selected = list[1]
        end

        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        if not ch or not hum or not root then
            status.Text = "BringCar: local character not ready"
            return
        end

        status.Text = "BringCar: waiting for driver seat..."
        local seat = findDriverSeat(selected, 2.0)
        if not seat or not seat:IsA("BasePart") then
            status.Text = "BringCar: seat not streamed/found in " .. selected.Name
            return
        end

        local occupiedBy = playerInSeat(seat)
        if occupiedBy and occupiedBy ~= LP then
            status.Text = "BringCar: driver seat occupied by " .. occupiedBy.Name
            return
        end

        local vehicleRoot = selected.PrimaryPart or seat or selected:FindFirstChildWhichIsA("BasePart", true)
        if not vehicleRoot then
            status.Text = "BringCar: vehicle root not found"
            return
        end

        local oldPlayer = root.CFrame
        local destination = oldPlayer * CFrame.new(0, 0, -8)
        local moved = false

        if selected.PrimaryPart then
            moved = pcall(function() selected:PivotTo(destination) end)
        else
            moved = pcall(function() vehicleRoot.CFrame = destination end)
        end

        if not moved then
            status.Text = "BringCar: local vehicle move failed"
            return
        end

        task.wait(.15)
        local afterMove = selected:GetPivot().Position
        local expected = destination.Position
        if (afterMove - expected).Magnitude > 14 then
            status.Text = "BringCar: vehicle position is server-controlled"
            return
        end

        pcall(function() root.CFrame = seat.CFrame * CFrame.new(0, 2, 0) end)
        task.wait(.12)
        pcall(function() seat:Sit(hum) end)
        task.wait(.30)

        if root.Parent then pcall(function() root.CFrame = oldPlayer end) end

        task.wait(.15)
        local finalPos = selected:GetPivot().Position
        if (finalPos - expected).Magnitude > 18 then
            status.Text = "BringCar: server restored vehicle position"
        else
            status.Text = string.format("Vehicle %d/%d: %s • driver: %s", selectedIndex, #list, selected.Name, seat.Name)
        end

        b.Text = "DONE"
        task.wait(.5)
        b.Text = "BRING"
    end)

    local function bindFolder(folder)
        if not folder then return end
        folder.ChildAdded:Connect(function() task.defer(refreshStatus) end)
        folder.ChildRemoved:Connect(function() task.defer(refreshStatus) end)
    end

    bindFolder(vehicleFolder())
    Workspace.ChildAdded:Connect(function(c)
        if c.Name == "Vehicles" then
            bindFolder(c)
            task.defer(refreshStatus)
        end
    end)

    task.defer(refreshStatus)
end
