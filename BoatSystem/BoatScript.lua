local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BoatSystemFolder = ReplicatedStorage:WaitForChild("BoatSystem")
local WaterPart = BoatSystemFolder:WaitForChild("WaterPart")

local Boat_Render_Connection
local Boat_Tilt = 0

local WaterData = {
	WaterAmplitude,
	WaterFrequency,
	WaterResolution,
	WaterSeed
}

--

local BOATMODEL = script.Parent.Parent
local BOATMODEL_SEAT = BOATMODEL:WaitForChild("Seat")
local BOATMODEL_PRIMARY = BOATMODEL.PrimaryPart

local BOATMODEL_MAXSPEED = 0.5
local BOATMODEL_MAX_TILT = 0.2
local BOATMODE_SPEEDMIN = 0.01
local BOATMODEL_LENGTH = 9
local BOATMODEL_HEIGHT = 1.6
local BOATMODEL_SPEED = 0.1
local BOATMODEL_TILT = 60

local BOAT_HEIGHTOFFSET = Vector3.yAxis * (BOATMODEL_HEIGHT/2 + WaterPart.Size.X)
local BOAT_SWAY = 25

--

local function GetPerlinNoiseValue(Number1,Number2)
	local Y = math.noise(
		(Number1 + WaterData.WaterSeed) / WaterData.WaterResolution * WaterData.WaterFrequency,
		(Number2 + WaterData.WaterSeed) / WaterData.WaterResolution * WaterData.WaterFrequency
	)

	return math.clamp(Y,-1,1) * WaterData.WaterAmplitude
end

local function IsValidOccupant(Occupant)
	if Occupant and Occupant.Parent then
		local Character = Occupant.Parent
		local Humanoid = Character:FindFirstChild("Humanoid")

		return Humanoid and Humanoid.Health > 0
	end
end

local function RenderBoat()
	local OldBoatCFrame = BOATMODEL_PRIMARY.CFrame

	local SteerInput = -BOATMODEL_SEAT.SteerFloat/50

	local ThrottleInput = BOATMODEL_SPEED + BOATMODEL_SEAT.Throttle/50

	local LookVector = OldBoatCFrame.LookVector * Vector3.new(1,0,1)


	BOATMODEL_SPEED = ThrottleInput >= 0 and ThrottleInput <= BOATMODEL_MAXSPEED and ThrottleInput or ThrottleInput >= BOATMODEL_MAXSPEED and BOATMODEL_MAXSPEED or BOATMODE_SPEEDMIN


	local NewBoatPosition = (OldBoatCFrame.Position * Vector3.new(1,0,1)) + LookVector * BOATMODEL_SPEED

	local NewBoatTipPosition = (OldBoatCFrame.Position * Vector3.new(1,0,1)) + LookVector * (BOATMODEL_LENGTH/3)


	local NewBoatPosition_Y = Vector3.yAxis * GetPerlinNoiseValue(NewBoatPosition.X,NewBoatPosition.Z)

	local NewBoatTipPosition_Y = Vector3.yAxis * GetPerlinNoiseValue(NewBoatTipPosition.X,NewBoatTipPosition.Z)


	local BoatSteerCFrame = CFrame.Angles(0,SteerInput,math.clamp(SteerInput + OldBoatCFrame.Rotation.Z/BOATMODEL_TILT,-BOATMODEL_MAX_TILT,BOATMODEL_MAX_TILT) + GetPerlinNoiseValue(0,Boat_Tilt)/(WaterData.WaterAmplitude * BOAT_SWAY))


	BOATMODEL_PRIMARY.CFrame = CFrame.new(NewBoatPosition + NewBoatPosition_Y,NewBoatTipPosition + NewBoatTipPosition_Y) * BoatSteerCFrame + BOAT_HEIGHTOFFSET

	Boat_Tilt += 0.5
end

local function OccupantChanged()
	local Occupant = BOATMODEL_SEAT.Occupant

	if not IsValidOccupant(Occupant) then return end

	local Player = Players:GetPlayerFromCharacter(Occupant.Parent)

	Boat_Render_Connection = RunService.Heartbeat:Connect(RenderBoat)

	BoatSystemFolder.SetupBoat:FireClient(Player,BOATMODEL)

	BOATMODEL_SEAT:GetPropertyChangedSignal("Occupant"):Wait()

	Boat_Render_Connection:Disconnect()

	BoatSystemFolder.SetupBoat:FireClient(Player)
end

for _,v in pairs(BoatSystemFolder:GetChildren()) do
	if v:IsA("NumberValue") then
		v.Changed:Connect(function(Value)
			WaterData[v.Name] = Value
		end)

		WaterData[v.Name] = v.Value
	end
end

BOATMODEL_SEAT:GetPropertyChangedSignal("Occupant"):Connect(OccupantChanged)

OccupantChanged()