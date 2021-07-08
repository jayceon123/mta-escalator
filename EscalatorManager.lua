EscalatorManager = {}
EscalatorManager.m_aEscalators = {}

function EscalatorManager.Init()
	local self = setmetatable(EscalatorManager, EscalatorManager)

	self:Shutdown()

	return self
end

function EscalatorManager:AddOne(...)
	local oEscalator = Escalator.AddThisOne(...)
	self.m_aEscalators[#self.m_aEscalators + 1] = oEscalator
	return oEscalator
end

function EscalatorManager:Add(vecStart, fHeading, fHeight, fBottomLength, fIntermediateLength, fTopLength, bMoveDown)
	fHeading = math.rad(fHeading)

	local vecBottom = Vector3(
		vecStart.x + fBottomLength * math.cos(fHeading),
		vecStart.y + fBottomLength * math.sin(fHeading),
		vecStart.z
	)

	local vecTop = Vector3(
		vecBottom.x + fIntermediateLength * math.cos(fHeading),
		vecBottom.y + fIntermediateLength * math.sin(fHeading),
		vecBottom.z + fHeight
	)

	local vecEnd = Vector3(
		vecTop.x + fTopLength * math.cos(fHeading),
		vecTop.y + fTopLength * math.sin(fHeading),
		vecTop.z
	)

	return self:AddOne(vecStart, vecBottom, vecTop, vecEnd, bMoveDown)
end

function EscalatorManager:Update(fTimeDelta)
	if fTimeDelta > 60 then
		fTimeDelta = 60
	end

	for i = 1, #self.m_aEscalators do
		if self.m_aEscalators[i] then
			self.m_aEscalators[i]:Update(fTimeDelta)
		end
	end
end

function EscalatorManager:Render()
	for i = 1, #self.m_aEscalators do
		if self.m_aEscalators[i] then
			self.m_aEscalators[i]:Visualize()
		end
	end
end

function EscalatorManager:Shutdown()
	for i = 1, #self.m_aEscalators do
		if self.m_aEscalators[i] then
			self.m_aEscalators[i]:SwitchOff()
		end
	end
end
