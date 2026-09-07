-- Final presentation pass: keep visible feature names aligned with the requested Yokai set.

return function(UI)
    local rename={
        ["ESP Pack"]="ESP",
        ["Aimbot (hold Mouse2)"]="Aimbot",
        ["Silent Aim (bot adapter)"]="Silent Aim",
        ["AntiAim (local pose)"]="AntiAim",
        ["Mouse TP (Alt + click)"]="Mouse TP",
        ["No Leaves (all leaves)"]="No Leaves",
        ["Rejoin current server"]="Rejoin",
        ["HitSound"]="Hitsound",
        ["GunChams"]="GunChams",
        ["SelfChams"]="SelfChams",
        ["CarFly"]="CarFly",
        ["FullBrightness"]="FullBrightness",
        ["NoMenuFog"]="NoMenuFog",
        ["AntiAFK"]="AntiAFK",
    }

    for _,page in pairs(UI.Pages) do
        for _,d in ipairs(page:GetDescendants()) do
            if d:IsA("TextLabel") and rename[d.Text] then d.Text=rename[d.Text] end
        end
    end

    -- Remove development/diagnostic rows that are not features.
    for _,page in pairs(UI.Pages) do
        for _,child in ipairs(page:GetChildren()) do
            if child:IsA("Frame") then
                local label=child:FindFirstChildOfClass("TextLabel")
                local txt=label and tostring(label.Text) or ""
                if txt:match("^Bots:%s*%d+") or txt:match("^Fly:%s") then
                    child.Visible=false
                    child.Size=UDim2.new(1,0,0,0)
                end
            end
        end
    end
end
