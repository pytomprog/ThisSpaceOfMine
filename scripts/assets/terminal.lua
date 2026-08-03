local params = {
	mesh = {
		center = false,
		--texCoordScale = Vec2(-1.0, 1.0),
		vertexOffset = Vec3(0, 0, 0),
		vertexRotation = EulerAngles(0, -26, 0),
		vertexScale = Vec3(1.0)
	},
	loadMaterials = false
}

local terminal = Model.Load("CookedAssets/Models/Terminal/Terminal.obj", params)

local mat = MaterialInstance.Instantiate(MaterialType.PhysicallyBased)
mat:SetTextureProperty("BaseColorMap", Texture.Load("CookedAssets/Models/Terminal/textureMap.dds"))
--mat:SetTextureProperty("MetalnessSmoothnessMap", Texture.Load("CookedAssets/Models/Terminal/metalnessMap.dds"))
mat:SetTextureProperty("NormalMap", Texture.Load("CookedAssets/Models/Terminal/normalMap.dds"))
mat:SetTextureProperty("EmissiveMap", Texture.Load("CookedAssets/Models/Terminal/emissiveMap.dds"))

terminal:SetMaterial(0, mat)

AssetLibrary.RegisterModel("terminal", terminal)
