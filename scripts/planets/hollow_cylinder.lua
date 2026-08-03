-- Do not touch to this 2 variables
local perlin = PerlinNoise()
local chunksize = 32

local function GetBlockIndices(chunkIndices, blockIndices)
    local x = chunkIndices.x * chunksize + blockIndices.x - chunksize * 0.5
    local y = chunkIndices.y * chunksize + blockIndices.z - chunksize * 0.5
    local z = chunkIndices.z * chunksize + blockIndices.y - chunksize * 0.5
    return Vec3(x, y, z)
end

return {
    PlanetType = "round_cube_planet", -- TODO: Change this to "hollow_cylinder_planet"
    Generator = function (chunk, chunkDims, properties)
        local seed = assert(properties.Seed, "missing Seed property")

        perlin:reseed(seed)

        local blockSize = chunk:GetBlockSize()

        local blockLibrary = chunk:GetBlockLibrary()
        local blockCount = chunk:GetBlockCount()

        local emptyBlock = blockLibrary:GetBlockIndex("empty")
        local debugBlock = blockLibrary:GetBlockIndex("debug")
        local dirtBlock = blockLibrary:GetBlockIndex("dirt")
        local grassBlock = blockLibrary:GetBlockIndex("grass")
        local hullBlock = blockLibrary:GetBlockIndex("hull")
        local snowBlock = blockLibrary:GetBlockIndex("snow")
        local stoneBlock = blockLibrary:GetBlockIndex("stone")
        local stoneMossyBlock = blockLibrary:GetBlockIndex("stone_mossy")
        local forcefieldBlock = blockLibrary:GetBlockIndex("forcefield")
        local planksBlock = blockLibrary:GetBlockIndex("planks")
        local stoneBricksBlock = blockLibrary:GetBlockIndex("stone_bricks")
        local goldBlock = blockLibrary:GetBlockIndex("gold")
        local glassBlock = blockLibrary:GetBlockIndex("glass")
        local waterBlock = blockLibrary:GetBlockIndex("water")
        local rockBlock = blockLibrary:GetBlockIndex("rock")
        local barkBlock = blockLibrary:GetBlockIndex("bark")
        local cliffRock = blockLibrary:GetBlockIndex("cliff_rocks")

        local planet = chunk:GetContainer()
        local chunkIndices = chunk:GetIndices()

        local baseThickness = 20 * blockSize -- Base thickness of the hollow cylinder
        local bigRadius = ((chunksize * chunkDims.y)/2 - 1) * blockSize -- Assume the planet is a cylinder along the X axis and that chunkDims.y == chunkDims.z
        local baseSmallRadius = bigRadius - baseThickness -- Base inner radius of the hollow cylinder

        local terrainVariation1Scale = 0.06 * baseSmallRadius
        local terrainVariation2Scale = 0.16 * baseSmallRadius
        local moutainScale = 0.025 * baseSmallRadius
        local stoneScale = 0.35 * baseSmallRadius

        local content = table.new(chunksize * chunksize * chunksize, 0)

        for z = 0, chunksize - 1 do
            for y = 0, chunksize - 1 do
                for x = 0, chunksize - 1 do
                    local blockPos = GetBlockIndices(chunkIndices, Vec3(x, y, z))
                    local blockPosScaled = blockPos * blockSize

                    local distToCenterAxis = Vec2(blockPosScaled.y, blockPosScaled.z):GetLength()

                    -- Boundary conditions for the hollow cylinder
                    if distToCenterAxis > bigRadius or math.abs(blockPosScaled.x) >= ((chunksize * chunkDims.x)/2 - 1) * blockSize or distToCenterAxis == 0 then
                        table.insert(content, emptyBlock)
                        goto continue
                    end

                    local blockSurfaceSamplingPos = Vec3(blockPosScaled.x/baseSmallRadius, blockPosScaled.y/distToCenterAxis, blockPosScaled.z/distToCenterAxis)
                    
                    local baseMountainous = perlin:normalizedOctave3D_01((blockSurfaceSamplingPos.x * moutainScale)+10, blockSurfaceSamplingPos.y * moutainScale, blockSurfaceSamplingPos.z * moutainScale, 4, 0.1)
                    local mountainous
                    if baseMountainous < 0.6 then 
                        mountainous = 0
                    elseif baseMountainous < 0.8 then 
                        mountainous = 5*baseMountainous-3
                    else
                        mountainous = 1
                    end

                    local heightVariation1 = 10 * perlin:normalizedOctave3D_01(blockSurfaceSamplingPos.x * terrainVariation1Scale, blockSurfaceSamplingPos.y * terrainVariation1Scale, blockSurfaceSamplingPos.z * terrainVariation1Scale, 4, 0.1)
                    local heightVariation2 = 30 * mountainous * perlin:normalizedOctave3D_01((blockSurfaceSamplingPos.x * terrainVariation2Scale)+20, blockSurfaceSamplingPos.y * terrainVariation2Scale, blockSurfaceSamplingPos.z * terrainVariation2Scale, 4, 0.1)

                    local height = heightVariation1 + heightVariation2

                    
                    if distToCenterAxis <= baseSmallRadius - height then
                        table.insert(content, emptyBlock)
                        goto continue
                    end

                    local blockType = emptyBlock
                    if distToCenterAxis > baseSmallRadius then
                        blockType = stoneBlock
                    else
                        if mountainous > 0.1 then
                            blockType = cliffRock
                        elseif baseMountainous < 0.6 then
                            local stoneNoise = perlin:normalizedOctave3D((blockSurfaceSamplingPos.x * stoneScale)+10, blockSurfaceSamplingPos.y * stoneScale, blockSurfaceSamplingPos.z * stoneScale, 4, 0.1)
                            blockType = stoneNoise >= 0.4 and dirtBlock or grassBlock
                        else
                            blockType = rockBlock
                        end
                    end
                    table.insert(content, blockType)

                    ::continue::
                end
            end
        end

        return content
    end
}