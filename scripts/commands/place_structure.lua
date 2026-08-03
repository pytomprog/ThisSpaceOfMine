local function GetUpVector(globalBlockIndices)
    local upVector = Vec3(1, 0, 0)
    local maxValue = math.max(math.abs(globalBlockIndices.x), math.abs(globalBlockIndices.y), math.abs(globalBlockIndices.z))
    if maxValue == globalBlockIndices.x then
        upVector = Vec3(1, 0, 0)
    elseif maxValue == -globalBlockIndices.x then
        upVector = Vec3(-1, 0, 0)
    elseif maxValue == globalBlockIndices.y then
        upVector = Vec3(0, 1, 0)
    elseif maxValue == -globalBlockIndices.y then
        upVector = Vec3(0, -1, 0)
    elseif maxValue == globalBlockIndices.z then
        upVector = Vec3(0, 0, 1)
    elseif maxValue == -globalBlockIndices.z then
        upVector = Vec3(0, 0, -1)
    end
    return upVector
end

local function QuaternionToDirection(quaternion)
    local x = quaternion.x
    local y = quaternion.y
    local z = quaternion.z
    local w = quaternion.w

    local directionX = 2 * (x * z + w * y)
    local directionY = 2 * (y * z - w * x)
    local directionZ = 1 - 2 * (x * x + y * y)
    local direction = Vec3(directionX, directionY, directionZ):GetNormal()

    return direction
end

local function GetFrontVectorFromPlayer(upVector, cameraRot)
    local cameraDirection = QuaternionToDirection(cameraRot)
    if math.abs(upVector.x) == 1 then
        if math.abs(cameraDirection.y) > math.abs(cameraDirection.z) then
            return Vec3(0, cameraDirection.y < 0 and 1 or -1, 0)
        else
            return Vec3(0, 0, cameraDirection.z < 0 and 1 or -1)
        end
    elseif math.abs(upVector.y) == 1 then
        if math.abs(cameraDirection.x) > math.abs(cameraDirection.z) then
            return Vec3(cameraDirection.x < 0 and 1 or -1, 0, 0)
        else
            return Vec3(0, 0, cameraDirection.z < 0 and 1 or -1)
        end
    else
        assert(math.abs(upVector.z) == 1, "Up vector must be aligned with one of the axes.")
        if math.abs(cameraDirection.x) > math.abs(cameraDirection.y) then
            return Vec3(cameraDirection.x < 0 and 1 or -1, 0, 0)
        else
            return Vec3(0, cameraDirection.y < 0 and 1 or -1, 0)
        end
    end
end

local function GetRandomFrontVector(upVector)
    local frontVector
    local r = math.random()
    if r < 0.25 then
        frontVector = Vec3(upVector.z, upVector.x, upVector.y)
    elseif r < 0.5 then
        frontVector = Vec3(-upVector.z, -upVector.x, -upVector.y)
    elseif r < 0.75 then
        frontVector = Vec3(upVector.y, upVector.z, upVector.x)
    else
        frontVector = Vec3(-upVector.y, -upVector.z, -upVector.x)
    end
    return frontVector
end


local function GenerateStructure(physWorld, controller, filename)
	local eyePos = controller:GetEyePosition()
	local cameraRot = controller:GetCameraRotation()

	local result = physWorld:RaycastQueryFirst(eyePos, eyePos + cameraRot * Vec3(0, 0, -1000), { IgnorePlayers = true })
	if not result or not result.hitEntity or not result.hitChunk then
		return
	end

    local blockLibrary = result.hitChunk:GetBlockLibrary()
    local emptyBlock = blockLibrary:GetBlockIndex("empty")
    local debugBlock = blockLibrary:GetBlockIndex("debug")
    local floorTilesBlock = blockLibrary:GetBlockIndex("floor_tiles")

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
    local upVector = GetUpVector(globalHitBlockIndices)
    local frontVector = GetFrontVectorFromPlayer(upVector, cameraRot) --result.hitPosition, eyePos) --GetRandomFrontVector(upVector)
    local rightVector = frontVector:CrossProduct(upVector)

    local filePath = "structures/" .. filename
    local file = io.open(filePath, "r")
    if not file then
        error("Could not open file for reading: " .. filePath)
    end
    local structureContentStr = file:read("*a")
    file:close()
    
    local dkjson = require("dkjson")
    local structureContent = dkjson.decode(structureContentStr)

    for x = 1, #structureContent do
        for y = 1, #structureContent[x] do
            for z = 1, #structureContent[x][y] do
                local block = structureContent[x][y][z]
                local chunkIndices, innerCoordinates = chunkContainer:GetChunkIndicesByBlockIndices(globalHitBlockIndices + rightVector*(x - 1) + frontVector*(y - 1) + upVector*z)
                local targetChunk = chunkContainer:GetChunk(chunkIndices)
                if targetChunk then
                    targetChunk:UpdateBlock(innerCoordinates, block)
                end 
            end
        end
    end

    print("Generated structure from file: " .. filePath)
end

return function (opt)
    local filename = opt[1]

	local env = CurrentPlayer:GetEntity():GetEnvironment()
	local physWorld = env:GetPhysWorld()
	local controller = CurrentPlayer:GetController()

    GenerateStructure(physWorld, controller, filename)
end