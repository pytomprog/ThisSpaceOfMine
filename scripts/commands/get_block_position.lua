local EmptyBlock = 0

local function GetBlockPosition(physWorld, controller)
	local eyePos = controller:GetEyePosition()
	local cameraRot = controller:GetCameraRotation()

	local result = physWorld:RaycastQueryFirst(eyePos, eyePos + cameraRot * Vec3(0, 0, -1000), { IgnorePlayers = true })
	if not result or not result.hitEntity or not result.hitChunk then
		return
	end

	local chunkNode = result.hitEntity:GetComponent("node")
	local chunkRigidbody = result.hitEntity:GetComponent("rigidbody3d")

	local localPos = chunkNode:ToLocalPosition(result.hitPosition)
	local localRot = chunkNode:ToLocalDirection(result.hitNormal)

	local hitBlock = result.hitChunk:ComputeHitCoordinates(localPos, localRot, chunkRigidbody:GetCollider(), result.subShapeID)
	if not hitBlock then
		return
	end

	local chunkContainer = result.hitChunk:GetContainer()

	local globalHitBlockIndices = chunkContainer:GetBlockIndices(result.hitChunk:GetIndices(), hitBlock.blockIndices)
    return globalHitBlockIndices
end

return function (opt)
    opt = opt or {}

	local env = CurrentPlayer:GetEntity():GetEnvironment()
	local physWorld = env:GetPhysWorld()
	local controller = CurrentPlayer:GetController()
	
    return GetBlockPosition(physWorld, controller)
end