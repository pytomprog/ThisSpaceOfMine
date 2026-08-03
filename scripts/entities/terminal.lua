local classData = EntityRegistry.ClassBuilder()

classData:AddProperty("state", { type = "Integer", default = 1, isNetworked = true })

texts = {"Hi", "You can spawn a ship with the command /spawnship", "You can now explore the universe !"}

if CLIENT then
	function updateText(self, newState)
		local newText = texts[newState]
		self:SetInteractibleText(string.format("[%d/%d] %s", newState, #texts, newText))
	end
end

classData:On("init", function (self)
	local physSettings = {
		kind = "static",
		mass = 0.0,
		collider = CapsuleCollider3D.new(1.25, 0.3),
		objectLayer = Constants.ObjectLayerStatic
	}
	
	self:AddComponent("rigidbody3d", physSettings)
	
	self:SetInteractible(true)

	if CLIENT then
		updateText(self, self:GetProperty("state"))
		
		local model = AssetLibrary.GetModel("terminal")

		local gfx = self:AddComponent("graphics")
		gfx:AttachRenderable(model, Constants.RenderMask3D)
	end
end)

if SERVER then
	classData:On("interact", function (self, player)
		local newState = self:GetProperty("state") + 1
		if newState > #texts then
			newState = 1
		end

		--if newState == 2:


		self:UpdateProperty("state", newState)
	end)
else
	local function onStateUpdate(self, newState)
		updateText(self, newState)
	end

	classData:OnPropertyUpdate("state", onStateUpdate)
end

EntityRegistry.RegisterClass("terminal", classData)
