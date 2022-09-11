



local Aimbot = {

Library.flags["Aimbot Active"] = false

 }


local CIELUVInterpolator = LoadFile("utilities/cieluv_interpolator.lua")

local HealthbarLerp = CIELUVInterpolator:Lerp(Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0))
Library.flags["Aimbot Active"] = false

local DrawingProperties = {
    Line = {
        Thickness = 1.5,
        Color = Color3.fromRGB(255, 255, 255),
        Visible = false
    },
    Text = {
        Size = 16,
        Center = true,
        Outline = true,
        Color = Color3.fromRGB(255, 255, 255),
        Visible = false
    },
    Circle = {
        Thickness = 1.5,
        NumSides = 100,
        Radius = 0,
        Filled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Visible = false
    },
    Square = {
        Thickness = 1.5,
        Filled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Visible = false
    },
    Image = {
        Rounding = 0,
        Visible = false
    }
}

local Visuals = {Players = {}} do
    function Visuals:Round(Number, Bracket)
        Bracket = (Bracket or 1)

        if typeof(Number) == "Vector2" then
            return Vector2.new(Visuals:Round(Number.X), Visuals:Round(Number.Y))
        else
            return (Number - Number % (Bracket or 1))
        end
    end

    function Visuals:GetScreenPosition(Position)
        local Position, Visible = Workspace.CurrentCamera:WorldToViewportPoint(Position)
        local FullPosition = Position
        Position = Vector2.new(Position.X, Position.Y)

        return Position, Visible, FullPosition
    end

    function Visuals:CreateDrawing(Type, Custom)
        local Drawing = Drawing.new(Type)

        for Property, Value in pairs(DrawingProperties[Type]) do
            Drawing[Property] = Value
        end

        if Custom then
            for Property, Value in pairs(Custom) do
                Drawing[Property] = Value
            end
        end

        return Drawing
    end

    function Visuals.AddPlayer(Player)
        if not Visuals.Players[Player] then
            Visuals.Players[Player] = {
                Box = {
                    Outline = Visuals:CreateDrawing("Square", {Color = Color3.fromRGB(0, 0, 0)}),
                    Main = Visuals:CreateDrawing("Square")
                    --// Main = Visuals:CreateDrawing("Image", {Data = game:HttpGet("https://coasts.cool/uploads/48ny7FCjZ9iCmbAwirI.png")})

                },
                Healthbar = {
                    Outline = Visuals:CreateDrawing("Square", {Filled = true, Color = Color3.fromRGB(0, 0, 0)}),
                    Main = Visuals:CreateDrawing("Square", {Filled = true, Color = Color3.fromRGB(0, 255, 0)})
                },
                Info = {
                    Main = Visuals:CreateDrawing("Text"),
                    Extra = Visuals:CreateDrawing("Text")
                }
            }
        end
    end

    function Visuals.RemovePlayer(Player)
        if Visuals.Players[Player] then
            for Index, Table in pairs(Visuals.Players[Player]) do
                for Index2, Drawing in pairs(Table) do
                    if Drawing.Remove then
                        Drawing:Remove()
                    end
                end
            end

            Visuals.Players[Player] = nil
        end
    end
end

local PlayerUtilities = {} do
    function PlayerUtilities:IsPlayerAlive(Player)
        local Character = Player.Character
        local Humanoid = (Character and Character:FindFirstChildWhichIsA("Humanoid"))

        if Character and Humanoid then
            if Humanoid.Health > 0 then
                return true
            end
        end

        return false
    end

    function PlayerUtilities:GetHealth(Player)
        local Character = Player.Character
        local Humanoid = (Character and Character:FindFirstChildWhichIsA("Humanoid"))

        if Character and Humanoid then
            return {
                CurrentHealth = Humanoid.Health,
                MaxHealth = Humanoid.MaxHealth
            }
        end
    end

    function PlayerUtilities:GetBodyParts(Player)
        local Character = Player.Character
        local Head = (Character and Character:FindFirstChild("Head"))
        local Root = (Character and Character:FindFirstChild("HumanoidRootPart"))
        local Torso = Character and (Character:FindFirstChild("LowerTorso") or Character:FindFirstChild("Torso"))
        local LeftArm = Character and (Character:FindFirstChild("LeftLowerArm") or Character:FindFirstChild("Left Arm"))
        local RightArm = Character and (Character:FindFirstChild("RightLowerArm") or Character:FindFirstChild("Right Arm"))
        local LeftLeg = Character and (Character:FindFirstChild("LeftLowerLeg") or Character:FindFirstChild("Left Leg"))
        local RightLeg = Character and (Character:FindFirstChild("RightLowerLeg") or Character:FindFirstChild("Right Leg"))

        if Character and (Head and Root and Torso and LeftArm and RightArm and LeftLeg and RightLeg) then
            return {
                Character = Character,
                Head = Head,
                Root = Root,
                Torso = Torso,
                LeftArm = LeftArm,
                RightArm = RightArm,
                LeftLeg = LeftLeg,
                RightLeg = RightLeg
            }
        end
    end

    function PlayerUtilities:GetTeamColor(Player)
        return Player.TeamColor.Color
    end

    function PlayerUtilities:IsOnClientTeam(Player)
        if LocalPlayer.Team == Player.Team then
            return true
        end

        return false
    end

    function PlayerUtilities:GetDistanceFromClient(Position)
        return LocalPlayer:DistanceFromCharacter(Position)
    end

    function PlayerUtilities:GetClosestPlayer()
        local ClosestPlayer = nil
        local FarthestDistance = math.huge

        for Index, Player in pairs(Players:GetPlayers()) do
            if Player == LocalPlayer then continue end
        
            local PassedTeamCheck = true
            local IsPlayerAlive = PlayerUtilities:IsPlayerAlive(Player)
            local Health = PlayerUtilities:GetHealth(Player)
            local BodyParts = PlayerUtilities:GetBodyParts(Player)
            local IsOnClientTeam = PlayerUtilities:IsOnClientTeam(Player)
        
            if Library.flags["Aimbot Team Check"] and IsOnClientTeam then
                PassedTeamCheck = false
            end
        
            if IsPlayerAlive and Health and BodyParts and PassedTeamCheck then
                local ScreenPosition, OnScreen = Visuals:GetScreenPosition(BodyParts.Root.Position)

                if ScreenPosition and OnScreen then
                    local MouseDistance = (ScreenPosition - UserInputService:GetMouseLocation()).Magnitude

                    if MouseDistance < FarthestDistance then
                        if Library.flags["Aimbot Use FOV"] then
                            if MouseDistance <= Library.flags["Aimbot FOV Radius"] then
                                FarthestDistance = MouseDistance
                                ClosestPlayer = {
                                    Player = Player,
                                    BodyParts = BodyParts
                                }
                            end
                        else
                            FarthestDistance = MouseDistance
                            ClosestPlayer = {
                                Player = Player,
                                BodyParts = BodyParts
                            }
                        end
                    end
                end
            end
        end

        return ClosestPlayer
    end

    function PlayerUtilities:AimAt(Position, Smoothing)
        local MouseLocation = UserInputService:GetMouseLocation()
        MoveMouse(((Position.X - MouseLocation.X) / Smoothing), ((Position.Y - MouseLocation.Y) / Smoothing))
    end
end

if Games[game.GameId] then
    local CustomGameFunctions = LoadFile(Games[game.GameId])

    if CustomGameFunctions then
        for Index, Value in pairs(CustomGameFunctions) do
            PlayerUtilities[Index] = Value
        end
    else
        shared:Kick("Failed to replace normal functions with custom ones on file: " .. Games[game.GameId])
    end

end

local FOVCircle = Visuals:CreateDrawing("Circle")
for Index, Player in pairs(Players:GetPlayers()) do
    if Player == LocalPlayer then continue end
    Visuals.AddPlayer(Player)
end

local PlayerAddedEvent = Players.PlayerAdded:Connect(Visuals.AddPlayer)
local PlayerRemovingEvent = Players.PlayerRemoving:Connect(Visuals.RemovePlayer)
local LoopId = HttpService:GenerateGUID(false)
RunService:BindToRenderStep(LoopId, 1, function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Color = Library.flags["Aimbot FOV Color"]
    FOVCircle.Visible = ((Library.flags["Aimbot Enabled"] and Library.flags["Aimbot Use FOV"]) and true) or false
    
    if Library.flags["Aimbot FOV Type"] == "Static" then
        FOVCircle.Radius = Library.flags["Aimbot FOV Radius"]
    elseif Library.flags["Aimbot FOV Type"] == "Dynamic" then
        FOVCircle.Radius = (Library.flags["Aimbot FOV Radius"] + workspace.CurrentCamera.FieldOfView)
    elseif Library.flags["Aimbot FOV Type"] == "Dynamic Reversed" then
        FOVCircle.Radius = (Library.flags["Aimbot FOV Radius"] - workspace.CurrentCamera.FieldOfView)
    end

    if Library.flags["Aimbot Enabled"] and Library.flags["Aimbot Active"] then
        local ClosestPlayer = PlayerUtilities:GetClosestPlayer()

        if ClosestPlayer and (ClosestPlayer.Player and ClosestPlayer.BodyParts) then
            local ScreenPosition, OnScreen = Visuals:GetScreenPosition(ClosestPlayer.BodyParts.Head.Position)

            if ScreenPosition and OnScreen then
                PlayerUtilities:AimAt(ScreenPosition, Library.flags["Aimbot Smoothing"])
            end
        end
    end

    for Index, Player in pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end

        local Objects = Visuals.Players[Player]
        if not Objects then continue end

        local OnScreen, PassedTeamCheck = false, true
        local IsPlayerAlive = PlayerUtilities:IsPlayerAlive(Player)
        local Health = PlayerUtilities:GetHealth(Player)
        local BodyParts = PlayerUtilities:GetBodyParts(Player)
        local PlayerColor = (PlayerUtilities:IsOnClientTeam(Player) and Library.flags["Visuals Ally Color"]) or Library.flags["Visuals Enemy Color"]
        local IsOnClientTeam = PlayerUtilities:IsOnClientTeam(Player)

        if Library.flags["Visuals Use Team Color"] then
            PlayerColor = PlayerUtilities:GetTeamColor(Player)
        end

        if Library.flags["Visuals Team Check"] and IsOnClientTeam then
            PassedTeamCheck = false
        end

        if IsPlayerAlive and Health and BodyParts and PlayerColor and PassedTeamCheck then
            local HealthPercent = (Health.CurrentHealth / Health.MaxHealth)
            local Distance = PlayerUtilities:GetDistanceFromClient(BodyParts.Root.Position)
            ScreenPosition, OnScreen = Visuals:GetScreenPosition(BodyParts.Root.Position)

            local Orientation, Size = BodyParts.Character:GetBoundingBox()
            local Height = (Workspace.CurrentCamera.CFrame - Workspace.CurrentCamera.CFrame.Position) * Vector3.new(0, (math.clamp(Size.Y, 1, 10) + 0.5) / 2, 0)
            Height = math.abs(Workspace.CurrentCamera:WorldToScreenPoint(Orientation.Position + Height).Y - Workspace.CurrentCamera:WorldToScreenPoint(Orientation.Position - Height).Y)
            Size = Visuals:Round(Vector2.new((Height / 2), Height))

            local NameString = string.format("%s", Player.Name)

            if Player.DisplayName ~= Player.Name then
                NameString = string.format("%s | @%s", Player.Name, Player.DisplayName)
            end

            Objects.Box.Main.Color = PlayerColor
            Objects.Box.Main.Size = Size
            Objects.Box.Main.Position = Visuals:Round(Vector2.new(ScreenPosition.X, ScreenPosition.Y) - (Size / 2))

            Objects.Box.Outline.Thickness = (Objects.Box.Main.Thickness * 2)
            Objects.Box.Outline.Size = Objects.Box.Main.Size
            Objects.Box.Outline.Position = Objects.Box.Main.Position

            Objects.Healthbar.Main.Color = HealthbarLerp(HealthPercent)
            Objects.Healthbar.Main.Size = Vector2.new(2, (-Objects.Box.Main.Size.Y * HealthPercent))
            Objects.Healthbar.Main.Position = Vector2.new((Objects.Box.Main.Position.X - (Objects.Box.Outline.Thickness + 1)), (Objects.Box.Main.Position.Y + Objects.Box.Main.Size.Y))

            Objects.Healthbar.Outline.Size = Vector2.new(4, (Objects.Box.Main.Size.Y + 2))
            Objects.Healthbar.Outline.Position = Vector2.new((Objects.Box.Main.Position.X - (Objects.Box.Outline.Thickness + 2)), (Objects.Box.Main.Position.Y - 1))
            
            Objects.Info.Main.Font = Drawing.Fonts[Library.flags["Visuals Info Font"]]
            Objects.Info.Main.Text = NameString
            Objects.Info.Main.Size = Library.flags["Visuals Info Font Size"]
            Objects.Info.Main.Position = Vector2.new(((Objects.Box.Main.Size.X / 2) + Objects.Box.Main.Position.X), ((ScreenPosition.Y - Objects.Box.Main.Size.Y / 2) - 18))

            Objects.Info.Extra.Font = Drawing.Fonts[Library.flags["Visuals Info Font"]]
            Objects.Info.Extra.Text = string.format("(%dft) (%d/%d)", Distance, Health.CurrentHealth, Health.MaxHealth)
            Objects.Info.Extra.Size = Library.flags["Visuals Info Font Size"]
            Objects.Info.Extra.Position = Vector2.new(((Objects.Box.Main.Size.X / 2) + Objects.Box.Main.Position.X), (Objects.Box.Main.Size.Y + Objects.Box.Main.Position.Y))
        end

        Objects.Box.Main.Visible = (OnScreen and Library.flags["Visuals Show Boxes"]) or false
        Objects.Box.Outline.Visible = Objects.Box.Main.Visible

        Objects.Healthbar.Main.Visible = (OnScreen and Library.flags["Visuals Show Healthbar"]) or false
        Objects.Healthbar.Outline.Visible = Objects.Healthbar.Main.Visible

        Objects.Info.Main.Visible = (OnScreen and Library.flags["Visuals Show Info"]) or false
        Objects.Info.Extra.Visible = (OnScreen and Library.flags["Visuals Show Extra Info"]) or false
    end

return Aimbot;
