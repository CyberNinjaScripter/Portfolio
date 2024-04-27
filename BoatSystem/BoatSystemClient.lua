local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BoatSystemFolder = ReplicatedStorage:WaitForChild("BoatSystem")
local WaterFolder = workspace:WaitForChild("Water")

local WaterPart = BoatSystemFolder:WaitForChild("WaterPart")
local WaterRenderConnection
local WaterPartSize = WaterPart.Size

local BoatModel_Primary

local WaterData = {
	WaterAmplitude,
	WaterFrequency,
	WaterResolution,
	WaterSeed
}

--

local BOATMODEL_HEIGHT = 1.5
local WATER_RADIUS = 25
local WATER_BLOCK = BoatSystemFolder:WaitForChild("WaterPart")
local WATER_PARTS = {}
local WATER_COLOR = ColorSequence.new({
	ColorSequenceKeypoint.new(0,Color3.new(0, 0.6, 1)),
	ColorSequenceKeypoint.new(1,Color3.new(0.560784, 1, 1))
})

--

local function GetWaterColor(Position)
	local ColorNumber = math.clamp((Position.Y/2),0,1) 

	return WATER_COLOR.Keypoints[1].Value:Lerp(WATER_COLOR.Keypoints[2].Value,ColorNumber)
end

local function GetPerlinNoiseValue(Number1,Number2)
	local Y = math.noise(
		(Number1 + WaterData.WaterSeed) / WaterData.WaterResolution * WaterData.WaterFrequency,
		(Number2 + WaterData.WaterSeed) / WaterData.WaterResolution * WaterData.WaterFrequency
	)

	return math.clamp(Y,-1,1) * WaterData.WaterAmplitude
end

local function RenderWater()
	local CurrentPosition = BoatModel_Primary.Position + BoatModel_Primary.CFrame.LookVector * WATER_RADIUS/3

	for _,v in pairs(WaterFolder:GetChildren()) do
		local PartPosition = v.Position

		v.Color = GetWaterColor(PartPosition)
		v.Position = ((WATER_PARTS[v] + CurrentPosition) * Vector3.new(1,0,1)) + (Vector3.yAxis * GetPerlinNoiseValue(PartPosition.X,PartPosition.Z))
	end
end

local function PlaceWaterPart(Position)
	local Part = WATER_BLOCK:Clone()

	Part.Position = Position - Vector3.new(0,BOATMODEL_HEIGHT + WaterPartSize.X,0)
	Part.Color = GetWaterColor(Position)
	Part.Size = WaterPartSize
	Part.Anchored = true

	WATER_PARTS[Part] = Part.Position - BoatModel_Primary.Position

	Part.Parent = WaterFolder
end

local function GenerateCircle(BoatPosition)
	local Start_X = BoatPosition.X - WATER_RADIUS
	local Start_Z = BoatPosition.Z - WATER_RADIUS

	local End_X = BoatPosition.X + WATER_RADIUS
	local End_Z = BoatPosition.Z + WATER_RADIUS

	for X = Start_X, End_X, WaterPartSize.X do
		for Z = Start_Z, End_Z, WaterPartSize.X do
			if math.pow(X - BoatPosition.X,2) + math.pow(Z - BoatPosition.Z,2) <= math.pow(WATER_RADIUS,2) then
				PlaceWaterPart(Vector3.new(X, BoatPosition.Y, Z))
			end
		end
	end
end

BoatSystemFolder.SetupBoat.OnClientEvent:Connect(function(Boat)
	if Boat then
		BoatModel_Primary = Boat.PrimaryPart

		GenerateCircle(BoatModel_Primary.Position)

		WaterRenderConnection = RunService.RenderStepped:Connect(RenderWater)
	else
		WaterFolder:ClearAllChildren()

		table.clear(WATER_PARTS)

		if WaterRenderConnection then
			WaterRenderConnection:Disconnect()
		end
	end
end)

for _,v in pairs(BoatSystemFolder:GetChildren()) do
	if v:IsA("NumberValue") then
		v.Changed:Connect(function(Value)
			WaterData[v.Name] = Value
		end)

		WaterData[v.Name] = v.Value
	end
end