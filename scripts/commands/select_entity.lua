local EmptyBlock = 0

local function SelectEntity(physWorld, controller)
	local eyePos = controller:GetEyePosition()
	local cameraRot = controller:GetCameraRotation()

	local result = physWorld:RaycastQueryFirst(eyePos, eyePos + cameraRot * Vec3(0, 0, -1000), { IgnorePlayers = true })
	
    return result.hitEntity
end

return function (opt)
    opt = opt or {}

	local env = CurrentPlayer:GetEntity():GetEnvironment()
	local physWorld = env:GetPhysWorld()
	local controller = CurrentPlayer:GetController()
	
    return SelectEntity(physWorld, controller)
end