-- LvkHub.exe vehicle occupancy badge.
-- Adds Empty/InUse status to the currently selected Workspace.Vehicles entry.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local page=UI.Pages.Vehicle
    if not page then return end

    local GREEN=Color3.fromRGB(80,225,125)
    local RED=Color3.fromRGB(245,80,80)
    local MUTED=Color3.fromRGB(145,150,170)

    local statusRow,statusLabel,badge=nil,nil,nil

    local function trim(s)
        return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$",""))
    end

    local function findStatusRow()
        if statusRow and statusRow.Parent and statusLabel and statusLabel.Parent then return true end
        for _,row in ipairs(page:GetChildren()) do
            if row:IsA("Frame") then
                local label=row:FindFirstChildWhichIsA("TextLabel")
                local text=label and label.Text or ""
                if text:match("^BringCar:") or text:match("^Vehicle%s+%d+/%d+:") then
                    statusRow=row
                    statusLabel=label
                    statusLabel.Size=UDim2.new(1,-68,1,0)
                    badge=row:FindFirstChild("LvkVehicleOccupancyBadge")
                    if not badge then
                        badge=Instance.new("TextLabel")
                        badge.Name="LvkVehicleOccupancyBadge"
                        badge.AnchorPoint=Vector2.new(1,.5)
                        badge.Position=UDim2.new(1,-7,.5,0)
                        badge.Size=UDim2.fromOffset(54,20)
                        badge.BackgroundColor3=Color3.fromRGB(31,32,38)
                        badge.BackgroundTransparency=.12
                        badge.BorderSizePixel=0
                        badge.Font=Enum.Font.SourceSansSemibold
                        badge.TextSize=11
                        badge.Text=""
                        badge.Visible=false
                        badge.Parent=row
                        local c=Instance.new("UICorner")
                        c.CornerRadius=UDim.new(0,4)
                        c.Parent=badge
                    end
                    return true
                end
            end
        end
        return false
    end

    local function findDriverSeat(vehicle)
        if not vehicle then return nil end
        local functional=vehicle:FindFirstChild("Functional")
        local seatsFolder=functional and functional:FindFirstChild("Seats")
        if seatsFolder then
            for _,obj in ipairs(seatsFolder:GetDescendants()) do
                if obj:IsA("VehicleSeat") then
                    local n=obj.Name:lower()
                    if n:find("driver",1,true) or n:find("drive",1,true) then return obj end
                end
            end
            local seat=seatsFolder:FindFirstChildWhichIsA("VehicleSeat",true)
            if seat then return seat end
        end
        for _,obj in ipairs(vehicle:GetDescendants()) do
            if obj:IsA("VehicleSeat") then
                local n=obj.Name:lower()
                if n:find("driver",1,true) or n:find("drive",1,true) then return obj end
            end
        end
        return vehicle:FindFirstChildWhichIsA("VehicleSeat",true)
            or vehicle:FindFirstChild("Seat1",true)
            or vehicle:FindFirstChildWhichIsA("Seat",true)
    end

    local function selectedVehicleFromText(text)
        local prefix,name=text:match("^(Vehicle%s+%d+/%d+:)%s*(.-)%s*•")
        if not prefix then prefix,name=text:match("^(Vehicle%s+%d+/%d+:)%s*(.+)$") end
        if not prefix or not name then return nil,nil end
        name=trim(name)
        local vf=Workspace:FindFirstChild("Vehicles")
        local vehicle=vf and vf:FindFirstChild(name)
        return vehicle,prefix
    end

    local timer=0
    RunService.Heartbeat:Connect(function(dt)
        timer+=dt
        if timer<.20 then return end
        timer=0
        if not findStatusRow() then return end

        local vehicle,prefix=selectedVehicleFromText(statusLabel.Text)
        if not vehicle then
            badge.Visible=false
            return
        end

        -- Remove the older driver suffix so the occupancy state sits cleanly at right.
        local wantedText=prefix.." "..vehicle.Name
        if statusLabel.Text~=wantedText then statusLabel.Text=wantedText end

        local seat=findDriverSeat(vehicle)
        if not seat or not seat:IsA("Seat") and not seat:IsA("VehicleSeat") then
            badge.Text="NoSeat"
            badge.TextColor3=MUTED
            badge.Visible=true
            return
        end

        local inUse=seat.Occupant~=nil
        badge.Text=inUse and "InUse" or "Empty"
        badge.TextColor3=inUse and RED or GREEN
        badge.Visible=true
    end)
end
