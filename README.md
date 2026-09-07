# LvkHub.exe

Trimmed Yokai-style ClickGui build containing only the requested categories and feature set.

## Menu

The UI uses independent draggable/collapsible Yokai-style windows rather than a single sidebar frame.

Visible categories:
- Combat
- Movement
- Visuals
- Utility
- World
- Local

There is no Render window and no Settings window.

## Features

### Visuals
3D Box, Chams, Corner Box, ESP, FOV Changer, HealthBar, Name + Distance, Preview, Thermal Corner, Tracers, Skeleton, Car ESP.

### World
ChangeSkyDome, FullBrightness, No Fog, No Leaves, No Shadows, FPS Boost.

### Movement
CarFly, Fly, Noclip, Speed, Mouse TP.

### Combat
HitBoxes, AntiAim, Aimbot and Silent Aim are scoped to the shared non-player practice-bot registry under `Workspace > Players`.

### Utility
AntiAFK, NoMenuFog, Rejoin, ServerHop.

### Local
Hitsound, GunChams, SelfChams, Trail, plus the Studio/test-only BringCar helper.

## Runtime architecture

- One shared registry for non-player bot rigs under `Workspace > Players`.
- One shared registry for vehicles under `Workspace > Vehicles`.
- No duplicate full-workspace polling loops per feature.
- Persistent World overrides use property-change listeners plus a slow watchdog to avoid visible flicker.

`ClientKickDisable`, anti-cheat bypass, anti-detection and kick suppression are not included.
