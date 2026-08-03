local EmptyBlock = 0

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

local function SaveStructure(chunkContainer, blockPos1, blockPos2, filename, controller)
    local centerPos = Vec3((blockPos1.x + blockPos2.x) / 2, (blockPos1.y + blockPos2.y) / 2, (blockPos1.z + blockPos2.z) / 2)
	local cameraRot = controller:GetCameraRotation()
    local upVector = GetUpVector(centerPos)
    local frontVector = GetFrontVectorFromPlayer(upVector, cameraRot)
    local rightVector = frontVector:CrossProduct(upVector)

	local minX = math.min(blockPos1.x, blockPos2.x)
	local maxX = math.max(blockPos1.x, blockPos2.x)
	local minY = math.min(blockPos1.y, blockPos2.y)
	local maxY = math.max(blockPos1.y, blockPos2.y)
	local minZ = math.min(blockPos1.z, blockPos2.z)
	local maxZ = math.max(blockPos1.z, blockPos2.z)

    local rotatedFrameBlockPos1 = Vec3(rightVector:DotProduct(blockPos1), frontVector:DotProduct(blockPos1), upVector:DotProduct(blockPos1))
    local rotatedFrameBlockPos2 = Vec3(rightVector:DotProduct(blockPos2), frontVector:DotProduct(blockPos2), upVector:DotProduct(blockPos2))
    local minI = math.min(rotatedFrameBlockPos1.x, rotatedFrameBlockPos2.x)
    local maxI = math.max(rotatedFrameBlockPos1.x, rotatedFrameBlockPos2.x)
    local minJ = math.min(rotatedFrameBlockPos1.y, rotatedFrameBlockPos2.y)
    local maxJ = math.max(rotatedFrameBlockPos1.y, rotatedFrameBlockPos2.y)
    local minK = math.min(rotatedFrameBlockPos1.z, rotatedFrameBlockPos2.z)
    local maxK = math.max(rotatedFrameBlockPos1.z, rotatedFrameBlockPos2.z)

    -- First, fill the structureContent table with EmptyBlock values
    local structureContent = {}
    for i = 1, maxI - minI + 1 do
        structureContent[i] = {}
        for j = 1, maxJ - minJ + 1 do
            structureContent[i][j] = {}
            for k = 1, maxK - minK + 1 do
                structureContent[i][j][k] = EmptyBlock
            end
        end
    end
	
    for x = minX, maxX do
        table.insert(structureContent, {})
		for y = minY, maxY do
            table.insert(structureContent[x - minX + 1], {})
            for z = minZ, maxZ do                
				local globalBlockIndices = Vec3(x, y, z)
                local savingBlockIndices = Vec3(rightVector:DotProduct(globalBlockIndices), frontVector:DotProduct(globalBlockIndices), upVector:DotProduct(globalBlockIndices)) - Vec3(minI - 1, minJ - 1, minK - 1)
                
                local chunkIndices, innerCoordinates = chunkContainer:GetChunkIndicesByBlockIndices(globalBlockIndices)
                local targetChunk = chunkContainer:GetChunk(chunkIndices)
                if targetChunk then
                    local block = targetChunk:GetBlockContent(innerCoordinates)
                    structureContent[savingBlockIndices.x][savingBlockIndices.y][savingBlockIndices.z] = block
                else
                    structureContent[savingBlockIndices.x][savingBlockIndices.y][savingBlockIndices.z] = EmptyBlock
                end 
            end
        end
    end
    
    local filePath = "structures/" .. filename
    local file = io.open(filePath, "w")
    if not file then
        error("Could not open file for writing: " .. filePath)
    end
    local dkjson = require("dkjson")
    file:write(dkjson.encode(structureContent))
    file:close()
    print("Saved structure content to file: " .. filePath)

    return structureContent
end

return function (opt)
    local blockPos1 = opt[1]
    local blockPos2 = opt[2]
    local filename = opt[3]

    local env = CurrentPlayer:GetEntity():GetEnvironment()
	if env:GetType() == EnvironmentType.Planet then
        local chunkContainer = env:GetChunkContainer()
        local controller = CurrentPlayer:GetController()

		return SaveStructure(chunkContainer, blockPos1, blockPos2, filename, controller)
    else
        print("Error: Current environment is not a planet.")
    end

    return {}
end