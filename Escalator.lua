Escalator = {}
Escalator.__index = Escalator

local ms_modelInfoPtrs = {
	ESC_STEP = {
		m_iModelId = 1656,
		m_fRadius = 0.720858,
		m_fLength = 0.41 - 0.06,
		m_fWidth = 1.36,
		m_fHeight = 0.24,
		m_boundBox = {
			m_vecMin = Vector3(-0.66719055175781, -0.19547456502914, -0.11506843566895),
			m_vecMax = Vector3(0.69209289550781, 0.21811932325363, 0.12915229797363)
		}
	},
	ESC_STEP_8 = {
		m_iModelId = 1698,
		m_fRadius = 1.7927,
		m_fLength = 3.31,
		m_fWidth = 1.36,
		m_fHeight = 0.24,
		m_boundBox = {
			m_vecMin = Vector3(-0.66719055175781, -1.5557241439819, -0.11506843566895),
			m_vecMax = Vector3(0.69209289550781, 1.7530131340027, 0.12915229797363)
		}
	},
}

engineSetModelLODDistance(ms_modelInfoPtrs.ESC_STEP.m_iModelId, 50)
engineSetModelLODDistance(ms_modelInfoPtrs.ESC_STEP_8.m_iModelId, 50)

function Escalator.AddThisOne(vecStart, vecBottom, vecTop, vecEnd, bMoveDown)
	local self = setmetatable({}, Escalator)

	self.m_bIsActive = false
	self.m_bIsMoving = true
	self.m_fSpeed = 1 / 500.0

	self.m_vecStart = vecStart
	self.m_vecBottom = vecBottom
	self.m_vecTop = vecTop
	self.m_vecEnd = vecEnd
	self.m_bIsMoveDown = not not bMoveDown

	local fStepHeight = ms_modelInfoPtrs.ESC_STEP.m_boundBox.m_vecMax.z

	self.m_vecStart.z = self.m_vecStart.z - fStepHeight
	self.m_vecBottom.z = self.m_vecBottom.z - fStepHeight
	self.m_vecTop.z = self.m_vecTop.z - fStepHeight
	self.m_vecEnd.z = self.m_vecEnd.z - fStepHeight

	local vecBottomMagnitude = (self.m_vecStart - self.m_vecBottom):getLength()
	local vecIntermediateMagnitude = (self.m_vecBottom - self.m_vecTop):getLength()
	local vecTopMagnitude = (self.m_vecTop - self.m_vecEnd):getLength()

	self.m_nIntermediatePlanes = math.ceil(vecIntermediateMagnitude / ms_modelInfoPtrs.ESC_STEP.m_fLength) + 1.0
	self.m_nBottomPlanes = math.ceil(vecBottomMagnitude / ms_modelInfoPtrs.ESC_STEP_8.m_fLength)
	self.m_nTopPlanes = math.ceil(vecTopMagnitude / ms_modelInfoPtrs.ESC_STEP_8.m_fLength)

	self.m_vecIntermediateDir = (self.m_vecTop - self.m_vecBottom):getNormalized()
	self.m_vecBottomDir = (self.m_vecBottom - self.m_vecStart):getNormalized()
	self.m_vecTopDir = (self.m_vecEnd - self.m_vecTop):getNormalized()

	local vecDirection = Vector3(self.m_vecStart.x - self.m_vecBottom.x, self.m_vecStart.y - self.m_vecBottom.y, 0.0)
	vecDirection:normalize()

	self.m_matrix = {}
	self.m_matrix[1] = {vecDirection.y, -vecDirection.x, 0, 0}
	self.m_matrix[2] = {vecDirection.x, vecDirection.y, 0, 0}
	self.m_matrix[3] = {0, 0, 1, 0}
	self.m_matrix[4] = {0, 0, 0, 1}

	self.m_vecMidPoint = (self.m_vecStart + self.m_vecEnd) / 2.0
	self.m_fRadius = (self.m_vecStart - self.m_vecMidPoint):getLength()

	self.m_fCurrentPosition = 0.0
	self.m_pSteps = {}

	return self
end

function Escalator:GetPosition()
	return self.m_vecMidPoint
end

function Escalator:GetIsActive()
	return not not self.m_bIsActive
end

function Escalator:GetIsMoving()
	return not not self.m_bIsMoving
end

function Escalator:SetIsMoving(bIsMoving)
	self.m_bIsMoving = not not bIsMoving
end

function Escalator:SetSpeed(fSpeed)
	self.m_fSpeed = math.abs(fSpeed)
end

function Escalator:GetDirection()
	return not not self.m_bIsMoveDown
end

function Escalator:SetDirection(bMoveDown)
	self.m_bIsMoveDown = not not bMoveDown
end

function Escalator:Visualize()
	dxDrawLine3D(self.m_vecStart, self.m_vecBottom, 0xAAFF0000, 5)
	dxDrawLine3D(self.m_vecBottom, self.m_vecTop, 0xAA00FF00, 5)
	dxDrawLine3D(self.m_vecTop, self.m_vecEnd, 0xAA0000FF, 5)
end

local function setElementPositionEx(pEntity, vecPosition)
	if isElementStreamedIn(pEntity) then
		local aEntityMatrix = getElementMatrix(pEntity)

		aEntityMatrix[4][1] = vecPosition.x
		aEntityMatrix[4][2] = vecPosition.y
		aEntityMatrix[4][3] = vecPosition.z

		setElementMatrix(pEntity, aEntityMatrix)
	else
		setElementPosition(pEntity, vecPosition)
	end
end

function Escalator:Update(fTimeDelta)
	local vecCameraPosition = Vector3(getElementPosition(getCamera()))
	local fCameraMagnitude = (vecCameraPosition - self.m_vecMidPoint):getLength()

	if not self.m_bIsActive then
		if self.m_fRadius + 20.0 > fCameraMagnitude then
			self.m_bIsActive = true
			self.m_fCurrentPosition = 0.0

			if self.m_nIntermediatePlanes > 0 then
				for i = 1, self.m_nIntermediatePlanes do
					self.m_pSteps[i] = createObject(ms_modelInfoPtrs.ESC_STEP.m_iModelId, self.m_vecBottom)

					if isElement(self.m_pSteps[i]) then
						setElementMatrix(self.m_pSteps[i], self.m_matrix)
					end
				end
			end

			for i = 1, self.m_nBottomPlanes + self.m_nTopPlanes do
				self.m_pSteps[self.m_nIntermediatePlanes + i] = createObject(ms_modelInfoPtrs.ESC_STEP_8.m_iModelId, self.m_vecBottom)

				if isElement(self.m_pSteps[self.m_nIntermediatePlanes + i]) then
					setElementMatrix(self.m_pSteps[self.m_nIntermediatePlanes + i], self.m_matrix)
				end
			end
		end
	else
		local pContactEntity = getPedContactElement(localPlayer)
		local fTimeStep = fTimeDelta * self.m_fSpeed

		if self.m_bIsMoving then
			local fPosition = 0

			if self.m_bIsMoveDown then
				fPosition = self.m_fCurrentPosition - fTimeStep + 1.0
			else
				fPosition = self.m_fCurrentPosition + fTimeStep
			end

			self.m_fCurrentPosition = fPosition - math.floor(fPosition)
		end

		if self.m_nIntermediatePlanes > 0 then
			for i = 1, self.m_nIntermediatePlanes do
				local pStepObject = self.m_pSteps[i]

				if isElement(pStepObject) then
					local fStepOffset = ms_modelInfoPtrs.ESC_STEP.m_fLength
					local vecStepOffset = self.m_vecIntermediateDir * (i - self.m_fCurrentPosition) * fStepOffset
					local vecStepPosition = self.m_vecTop - vecStepOffset

					if self.m_bIsMoving then
						if pContactEntity == pStepObject then
							local vecPlayerPosition = Vector3(getElementPosition(localPlayer))
							local vecPlayerVelocity = self.m_vecIntermediateDir * fStepOffset * fTimeStep

							if self.m_bIsMoveDown then
								vecPlayerVelocity = -vecPlayerVelocity
							end

							setElementPosition(localPlayer, vecPlayerPosition + vecPlayerVelocity, false)
							setElementVelocity(localPlayer, vecPlayerVelocity)
						end
					end

					setElementPositionEx(pStepObject, vecStepPosition)
				end
			end
		end

		if self.m_nBottomPlanes > 0 then
			local t = 4

			for i = 1, self.m_nBottomPlanes do
				local pStepObject = self.m_pSteps[self.m_nIntermediatePlanes + i]

				if isElement(pStepObject) then
					local fStepOffset = 0.4125
					local vecStepOffset = self.m_vecBottomDir * (t + self.m_fCurrentPosition) * fStepOffset
					local vecStepPosition = self.m_vecStart + vecStepOffset

					if self.m_bIsMoving then
						if pContactEntity == pStepObject then
							local vecPlayerPosition = Vector3(getElementPosition(localPlayer))
							local vecPlayerVelocity = self.m_vecBottomDir * fStepOffset * fTimeStep

							if self.m_bIsMoveDown then
								vecPlayerVelocity = -vecPlayerVelocity
							end

							setElementPosition(localPlayer, vecPlayerPosition + vecPlayerVelocity, false)
							setElementVelocity(localPlayer, vecPlayerVelocity)
						end
					end

					setElementPositionEx(pStepObject, vecStepPosition)
				end

				t = t + 8
			end
		end

		if self.m_nTopPlanes > 0 then
			local t = 3.5

			for i = 1, self.m_nTopPlanes do
				local pStepObject = self.m_pSteps[self.m_nBottomPlanes + self.m_nIntermediatePlanes + i]

				if isElement(pStepObject) then
					local fStepOffset = 0.4125
					local vecStepOffset = self.m_vecTopDir * (t + self.m_fCurrentPosition) * fStepOffset
					local vecStepPosition = self.m_vecTop + vecStepOffset

					if self.m_bIsMoving then
						if pContactEntity == pStepObject then
							local vecPlayerPosition = Vector3(getElementPosition(localPlayer))
							local vecPlayerVelocity = self.m_vecTopDir * fStepOffset * fTimeStep

							if self.m_bIsMoveDown then
								vecPlayerVelocity = -vecPlayerVelocity
							end

							setElementPosition(localPlayer, vecPlayerPosition + vecPlayerVelocity, false)
							setElementVelocity(localPlayer, vecPlayerVelocity)
						end
					end

					setElementPositionEx(pStepObject, vecStepPosition)
				end

				t = t + 8
			end
		end

		if self.m_fRadius + 23.0 < fCameraMagnitude then
			self:SwitchOff()
		end
	end
end

function Escalator:SwitchOff()
	if self.m_bIsActive then
		for i = 1, self.m_nBottomPlanes + self.m_nIntermediatePlanes + self.m_nTopPlanes do
			if self.m_pSteps[i] then
				if isElement(self.m_pSteps[i]) then
					destroyElement(self.m_pSteps[i])
				end

				self.m_pSteps[i] = nil
			end
		end

		self.m_bIsActive = false
	end
end
