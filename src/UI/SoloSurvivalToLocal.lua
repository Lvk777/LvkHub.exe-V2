-- Moves the existing SOLO SURVIVAL UI block from Utility to Local without changing its logic.
return function(State, UI)
    local utility=UI.Pages.Utility
    local localPage=UI.Pages.Local
    if not utility or not localPage then return end

    local function maxOrder(page)
        local m=0
        for _,c in ipairs(page:GetChildren()) do
            if c:IsA("GuiObject") then m=math.max(m,c.LayoutOrder) end
        end
        return m
    end

    task.delay(.25,function()
        local move={}
        for _,c in ipairs(utility:GetChildren()) do
            if c:IsA("TextLabel") then
                if c.Text:find("SOLO SURVIVAL",1,true) then table.insert(move,c) end
            elseif c:IsA("Frame") then
                local t=c:FindFirstChildWhichIsA("TextLabel")
                if t then
                    local s=t.Text
                    if s:find("SURVIVAL GUARD",1,true) or s=="Full Hunger [SOLO]" or s=="Full Thirst [SOLO]" or s:find("Sources:",1,true) then
                        table.insert(move,c)
                    end
                end
            end
        end
        table.sort(move,function(a,b) return a.LayoutOrder<b.LayoutOrder end)
        local order=maxOrder(localPage)+1
        for _,c in ipairs(move) do
            c.Parent=localPage
            c.LayoutOrder=order
            order+=1
        end
    end)
end
