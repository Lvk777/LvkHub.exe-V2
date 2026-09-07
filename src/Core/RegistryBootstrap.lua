-- Lightweight startup prime for local TestPlayers registry.
-- Fixes the race where the clones exist before Registry.Bots has been rebuilt.

return function(Registry)
    if not Registry or type(Registry.RefreshTargets)~="function" then return end

    pcall(Registry.RefreshTargets)

    task.spawn(function()
        -- Short bootstrap window only; no permanent Workspace scan loop.
        for _,delay in ipairs({0.10,0.25,0.50,0.85,1.25,1.75,2.50}) do
            task.wait(delay)
            pcall(Registry.RefreshTargets)
        end
    end)
end
