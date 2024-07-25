local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local BoatSystemFolder = ReplicatedStorage:WaitForChild("BoatSystem")
local BoatModel = BoatSystemFolder:WaitForChild("Boat")
local Baseplate = workspace:WaitForChild("Baseplate")

local SpawnModel = BoatSystemFolder:WaitForChild("Spawn")
local WaterPart = BoatSystemFolder:WaitForChild("WaterPart")
local SpawnBoat = SpawnModel.SpawnBoat

local Water_Conditions = true
local Water_Resolution
local Water_Frequency
local Water_Amplitude
local SeedSpeed = 0.1
local Seed = 1

local DefaultCondition = {
	CONDITION_NAME = "Normal",
	WATER_RESOLUTION = 150,
	WATER_FREQUENCY = 5,
	WATER_AMPLITUDE = 4
}

local Conditions = {
	{
		CONDITION_NAME = "High waves",
		WATER_AMPLITUDE = 6
	},

	{
		CONDITION_NAME = "Storm",
		WATER_AMPLITUDE = 7
	},

	{
		CONDITION_NAME = "Calm",
		WATER_AMPLITUDE = 2,
	},

	{
		CONDITION_NAME = "Still",
		WATER_AMPLITUDE = 1,
	},

	DefaultCondition
}

local MetaTables = {
	__index = function(_,Index)
		return DefaultCondition[Index]
	end
}

--

local WATER_PARTSIZE = Vector3.new(0.7,1,0.7)
local CONDITION_CHANGETIME = 60
local CONDITION_TWEENTIME = 25

--

local function GetPerlinNoiseValue(Number1,Number2)
	local Y = math.noise(
		(Number1 + Seed) / Water_Resolution * Water_Frequency,
		(Number2 + Seed) / Water_Resolution * Water_Amplitude
	)

	return math.clamp(Y,-1,1) * Water_Amplitude
end

local function GetRandomPointOnWater()
	local Position = Vector3.new(math.random(-Baseplate.Size.X/2, Baseplate.Size.X/2),0,math.random(-Baseplate.Size.Y/2, Baseplate.Size.Y/2))
	return Position + Vector3.yAxis * GetPerlinNoiseValue(Position.X,Position.Z)
end

local function SetCondition(Condition)
	print("New water condition!",Condition.CONDITION_NAME)

	Water_Resolution = Condition.WATER_RESOLUTION
	Water_Frequency = Condition.WATER_FREQUENCY
	Water_Amplitude = Condition.WATER_AMPLITUDE

	TweenService:Create(BoatSystemFolder.WaterResolution,TweenInfo.new(CONDITION_TWEENTIME),{Value = Water_Resolution}):Play()
	TweenService:Create(BoatSystemFolder.WaterFrequency,TweenInfo.new(CONDITION_TWEENTIME),{Value = Water_Frequency}):Play()
	TweenService:Create(BoatSystemFolder.WaterAmplitude,TweenInfo.new(CONDITION_TWEENTIME),{Value = Water_Amplitude}):Play()
end

local WaterConditionCoroutine = coroutine.create(function()
	while Water_Conditions do
		task.wait(CONDITION_CHANGETIME)

		local SelectedCondition = Conditions[math.random(1,#Conditions)]

		SetCondition(SelectedCondition)
	end
end)

local function SetupBoatSystem()
	SetCondition(DefaultCondition)

	for _,v in pairs(Conditions) do
		setmetatable(v,MetaTables)
	end

	local BoatFolder = Instance.new("Folder")
	local WaterFolder = Instance.new("Folder")

	BoatFolder.Name = "Boats"
	WaterFolder.Name = "Water"

	BoatSystemFolder.WaterResolution.Value = Water_Resolution
	BoatSystemFolder.WaterFrequency.Value = Water_Frequency
	BoatSystemFolder.WaterAmplitude.Value = Water_Amplitude

	SpawnModel.Parent = workspace
	BoatFolder.Parent = workspace
	WaterFolder.Parent = workspace

	WaterPart.Size = WATER_PARTSIZE

	for _,v in pairs(Players:GetPlayers()) do
		local Chracter = v.Character

		if not Chracter then continue end

		local HumanoidRootPart = Chracter:FindFirstChild("HumanoidRootPart")

		if not HumanoidRootPart then continue end

		HumanoidRootPart.Position = SpawnModel.SpawnLocation.Position + Vector3.yAxis * 5
	end
	
	coroutine.resume(WaterConditionCoroutine)
end

RunService.Heartbeat:Connect(function()
	Seed += SeedSpeed
	BoatSystemFolder.WaterSeed.Value = Seed
end)

SpawnBoat.ProximityPrompt.Triggered:Connect(function(Player)
	local BoatClone = BoatModel:Clone()
	BoatClone.Name = Player.Name

	BoatClone.PrimaryPart.Position = GetRandomPointOnWater()
	BoatClone.Parent = workspace:WaitForChild("Boats")

	BoatClone.Seat:Sit(Player.Character.Humanoid)
end)

SetupBoatSystem()
