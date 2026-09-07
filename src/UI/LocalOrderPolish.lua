-- Reorders Local rows without changing their behavior.
return function(State, UI)
    local page=UI.Pages.Local
    if not page then return end

    local function rowByLabel(label)
        for _,child in ipairs(page:GetChildren()) do
            if child:IsA("Frame") then
                local text=child:FindFirstChildWhichIsA("TextLabel")
                if text and text.Text==label then return child end
            end
        end
        return nil
    end

    task.defer(function()
        task.wait(.05)
        local mute=rowByLabel("Mute Gunshots")
        local tracer=rowByLabel("BulletTracer")
        if not mute and not tracer then return end

        -- Preserve the LOCAL section header as the first item, then put these
        -- two local-only controls immediately below it.
        for _,child in ipairs(page:GetChildren()) do
            if child:IsA("Frame") and child~=mute and child~=tracer and child.LayoutOrder>=2 then
                child.LayoutOrder+=2
            end
        end
        if mute then mute.LayoutOrder=2 end
        if tracer then tracer.LayoutOrder=3 end
    end)
end
