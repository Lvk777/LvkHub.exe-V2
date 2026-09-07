# LvkHub target architecture

Targeting is now split into three independent layers.

## 1. Policy — authorization only

`src/Restrictions/Policy.lua` decides whether a candidate is allowed.

- `Targets.IsRealPlayerCharacter(model)` rejects Roblox `Player.Character` models.
- `Targets.CanCloneSource(model)` controls which source rigs may be copied into local practice candidates.
- `Targets.IsAllowedTarget(model)` authorizes only managed local practice targets.
- Session gates such as solo weapon/survival/vehicle rules remain in the same policy module.

Policy no longer enumerates Workspace targets.

## 2. RegistryV3 — discovery/cache only

`src/Core/RegistryV3.lua` owns raw discovery and lifecycle:

- creates/synchronizes local practice clones;
- caches them in `Registry.Candidates`;
- stores four-slot local inventory snapshots;
- tracks vehicles;
- emits target-change notifications.

Registry does not decide which candidate Combat/Visuals may use.

## 3. TargetProvider — consumer-facing target API

`src/Core/TargetProvider.lua` combines Registry candidates with Policy authorization.

Combat, Visuals, target UI and practice hit feedback receive `TargetProvider`, not the raw Registry.

The provider exposes the current API through:

- `GetTargets()` / `Targets`;
- `IsTarget(model)`;
- `CountTargets()`;
- `RootOf(model)`;
- `HumanoidOf(model)`;
- `GetDummyInventory(model)`.

Compatibility aliases (`Bots`, `IsBot`, `CountBots`) remain temporarily so older modules can be migrated without changing their rendering/selection code all at once.

## WeaponSystem adapter

`src/Combat/WeaponSystemTargetAdapterV4.lua` is the adapter boundary. It receives TargetProvider rather than raw Registry. The current practice implementation preserves the game's real shot direction and only simulates hit feedback on targets already authorized by TargetProvider.

## Data flow

```text
Workspace/source rigs
        ↓
RegistryV3.Candidates
        ↓
Policy.Targets.IsAllowedTarget
        ↓
TargetProvider.Targets
        ↓
Combat / Visuals / Target Info / practice WeaponSystem adapter
```

Changing candidate discovery should be done in Registry/source logic; changing authorization should be done in Policy; target consumers should not need to know where candidates came from.
