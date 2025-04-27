local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local CoreGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Load the BulletFactory module
local Bullet = require(ReplicatedStorage.Components.BulletFactory)
local u5 = game:GetService("ReplicatedStorage")
local u10 = require(u5.Shared.Raycast2) -- Raycast2 module for raycasting
local u2 = Bullet -- Reference to u2, as BulletFactory returns setmetatable(u2, v1)
local u3 = require(game.ReplicatedStorage.World) -- Needed for u2.CalcArc

function GetClosestToMouse()
    local MouseLocation = UserInputService:GetMouseLocation()
    local ClosestPlayer = nil
    local ClosestCharacter = nil
    local ClosestDistance = math.huge

    for _, Player in next, Players:GetPlayers() do
        if (Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild('HumanoidRootPart')) then
            local Character = Player.Character
            local RootPart = Character.HumanoidRootPart
        
            local ScreenPosition, OnScreen = Camera:WorldToScreenPoint(RootPart.Position)
            if (OnScreen) then
                local Distance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - MouseLocation).Magnitude
                if (Distance < ClosestDistance) then
                    ClosestDistance = Distance
                    ClosestPlayer = Player
                    ClosestCharacter = Character
                end
            end
        end
    end

    return ClosestPlayer, ClosestCharacter
end

local OldFire
OldFire = hookfunction(u2.Fire, function(BulletId, Origin, BulletPos, ...)
    local Player, Character = GetClosestToMouse()
    if (Player and Character) then
        -- Try to target Head, fallback to HumanoidRootPart
        local Target = Character:FindFirstChild('Head') or Character:FindFirstChild('HumanoidRootPart')
        if Target then
            -- Hardcode bullet velocity
            local BulletVelocity = 500 -- Hardcoded value (studs per second)

            -- Calculate distance and travel time
            local Distance = (Target.Position - Origin).Magnitude
            local TravelTime = Distance / BulletVelocity

            -- Predict target's future position based on velocity
            local TargetVelocity = Target.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
            local PredictedPosition = Target.Position + TargetVelocity * TravelTime

            -- Always redirect the bullet toward the predicted head position
            local Direction = (PredictedPosition - Origin).Unit
            local TimeStep = RunService.Stepped:Wait() -- Dynamic frame time
            local AdjustedPosition = u2.CalcArc(BulletId, Origin, Direction, TravelTime)

            BulletPos = (AdjustedPosition - Origin).Unit * math.min(Distance, BulletVelocity * 3) -- Cap at 3 seconds of travel

            local RaycastResult = u10.Raycast(Origin, PredictedPosition - Origin, nil, u2.CanBulletPassThrough)
            if RaycastResult and RaycastResult.Instance and not RaycastResult.Instance:IsDescendantOf(Character) then
            end
        end
    end

    return OldFire(BulletId, Origin, BulletPos, ...)
end)

CoreGui:SetCore("SendNotification", {
    Title = "Headshot Aimbot Loaded",
    Text = "All Hit Shots Redirect to Head",
    Duration = 5
})
