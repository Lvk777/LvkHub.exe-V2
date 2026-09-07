-- Reorders the existing Combat rows without changing dummy-only targeting logic.
return function(State, UI)
    local page=UI.Pages.Combat
    if not page then return end

    local function row(label)
        for _,c in ipairs(page:GetChildren()) do
            if c:IsA("Frame") then
                local t=c:FindFirstChildWhichIsA("TextLabel")
                if t and t.Text==label then return c end
            end
        end
    end

    task.delay(.15,function()
        local magic=row("Magic Bullets")
        local through=row("Magic Through Walls")
        if magic and through then
            local wanted=magic.LayoutOrder+1
            for _,c in ipairs(page:GetChildren()) do
                if c~=through and c.LayoutOrder>=wanted then c.LayoutOrder+=1 end
            end
            through.LayoutOrder=wanted
        end
    end)
end
