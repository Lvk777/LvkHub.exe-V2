local State = {
    UI = {Visible = true, Minimized = false, ActiveTab = "Visuals"},
    Visuals = {
        ESP = false, Chams = false, CornerBox = false, Box3D = false,
        HealthBar = false, NameDistance = false, ThermalCorner = false,
        Tracers = false, Skeleton = false, Preview = false, CarESP = false,
        Snapline = false, CustomCrosshair = false,
        TargetInfo = false, TargetInfoPinned = false,
        FOV = 70, PreviewHealth = 100,
    },
    World = {
        FullBrightness = false, NoFog = false, Vegetation = false,
        NoShadows = false, FPSBoost = false, Sky = "Default",
    },
    Movement = {
        Fly = false, CarFly = false, Noclip = false, Speed = false,
        SpeedValue = 32, FlySpeed = 65, CarFlySpeed = 90, MouseTP = false,
    },
    Combat = {
        Aimbot = false, HitBoxes = false, SilentAim = false, MagicBullets = false,
        AntiAim = false, AimPart = "Head", HitboxSize = 6,
        AimFOV = 180, ShowAimFOV = false,
        WallCheck = false,
        MagicThroughWalls = false,
        AimbotSmoothness = 0.32,
        DummyHitNotifications = false,
        DummyInventoryVisible = false,
        NoRecoil = false,
        InfiniteAmmo = false,
        FastReload = false,
        FastReloadMultiplier = 4,
    },
    Utility = {
        AntiAFK = false, NoMenuFog = false,
        FullHunger = false, FullThirst = false,
        MenuKeyName = "RightShift",
    },
    Local = {
        HitSound = false, MuteGunshots = false,
        GunChams = false, SelfChams = false,
        Trail = false, TrailGlow = false,
        BulletTracer = false,
    },
}

return State
