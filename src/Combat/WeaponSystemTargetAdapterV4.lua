-- LvkHub.exe WeaponSystem Target Adapter V4
-- Adapter contract is TargetProvider-based, not Registry/TestPlayers-based.
-- The underlying practice implementation still preserves the game's real shot direction
-- and only simulates feedback/damage on targets already authorized by TargetProvider.

return function(State, TargetProvider, UI, LegacyPracticeAdapterFactory)
    if type(TargetProvider)~="table"
        or type(TargetProvider.IsTarget)~="function"
        or type(TargetProvider.GetTargets)~="function" then
        error("WeaponSystemTargetAdapterV4 requires TargetProvider")
    end
    if type(LegacyPracticeAdapterFactory)~="function" then
        error("WeaponSystemTargetAdapterV4 requires a practice adapter factory")
    end

    shared.LvkHubWeaponTargetProvider=TargetProvider
    shared.LvkHubWeaponSystemTargetAdapter={
        Version=4,
        ProviderBacked=true,
        TargetMode=TargetProvider.Policy and TargetProvider.Policy.Mode or "unknown",
        PreservesRealShotDirection=true,
    }

    -- Compatibility bridge: V3 already talks only through the passed target API
    -- (Bots/IsBot/RootOf/HumanoidOf/GetDummyInventory). TargetProvider exposes
    -- those names as aliases, so the implementation no longer receives raw Registry.
    return LegacyPracticeAdapterFactory(State,TargetProvider,UI)
end
