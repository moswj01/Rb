-- Preview — โชว์ไอเท็มแบบ 3D หมุนได้ใน UI (ViewportFrame) ใช้โมเดลเดียวกับที่ใส่จริงในเกม
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CB = require(Shared.CosmeticBuilders)

local Preview = {}

local spinning = {} -- [ViewportFrame] = record

local function frameCamera(record)
	local angle = record.Angle
	local dir = CFrame.Angles(0, angle, 0):VectorToWorldSpace(record.Dir)
	record.Camera.CFrame = CFrame.lookAt(record.Center + dir * record.Distance, record.Center)
end

-- สร้าง ViewportFrame ของไอเท็ม  options: { Spin = bool, Zoom = number }
function Preview.Create(item, parent, size, position, options)
	options = options or {}
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Size = size or UDim2.fromScale(1, 1)
	viewport.Position = position or UDim2.new()
	viewport.Ambient = Color3.fromRGB(200, 190, 210)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-0.4, -1, -0.7)
	viewport.Parent = parent

	local ok, model, view = pcall(CB.BuildPreview, item)
	if not ok or not model then
		return viewport
	end
	model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.FieldOfView = 32
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local cf, extents = model:GetBoundingBox()
	local radius = extents.Magnitude / 2
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * (options.Zoom or 1.0)
	local dir = view == "Back" and Vector3.new(0.55, 0.3, 1).Unit or Vector3.new(0.45, 0.25, -1).Unit

	local record = { Camera = camera, Center = cf.Position, Distance = distance, Dir = dir, Angle = 0, Speed = options.Speed or 0.8 }
	frameCamera(record)
	if options.Spin then
		spinning[viewport] = record
		viewport.Destroying:Connect(function()
			spinning[viewport] = nil
		end)
	end
	return viewport
end

RunService.RenderStepped:Connect(function(dt)
	for viewport, record in spinning do
		if viewport.Parent then
			record.Angle += dt * record.Speed
			frameCamera(record)
		else
			spinning[viewport] = nil
		end
	end
end)

return Preview
