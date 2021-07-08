AudioManager = {}

function AudioManager.Init(oEscalatorManager)
	local self = setmetatable(AudioManager, AudioManager)

	self.m_pCamera = getCamera()
	self.m_vecCameraPos = Vector3(0, 0, 0)
	self.m_oEscalatorManager = oEscalatorManager

	return self
end

function AudioManager:Update(fTimeDelta)
	self.m_vecCameraPos = Vector3(getElementPosition(self.m_pCamera))
end

local function SQR(x)
	return x * x
end

function AudioManager:GetDistanceSquared(vecPos)
	return SQR(vecPos.x - self.m_vecCameraPos.x) + SQR(vecPos.y - self.m_vecCameraPos.y) + SQR((vecPos.z - self.m_vecCameraPos.z) * 0.2)
end

function AudioManager:ComputeVolume(iEmittingVolume, fSoundIntensity, fDistance)
	local fNewSoundIntensity

	if fSoundIntensity <= 0.0 then
		return 0
	end

	fNewSoundIntensity = fSoundIntensity / 5.0

	if fNewSoundIntensity <= fDistance then
		iEmittingVolume = SQR((fSoundIntensity - fNewSoundIntensity - (fDistance - fNewSoundIntensity)) / (fSoundIntensity - fNewSoundIntensity)) * iEmittingVolume
	end

	return iEmittingVolume
end

function AudioManager:ProcessEscalators()
	local SOUND_INTENSITY = 30.0
	local EMITTING_VOLUME = 26

	for i = 1, #self.m_oEscalatorManager.m_aEscalators do
		local oEscalator = self.m_oEscalatorManager.m_aEscalators[i]

		if oEscalator then
			local bSoundPlaying = false

			if oEscalator:GetIsActive() and oEscalator:GetIsMoving() then
				local vecPos = oEscalator:GetPosition()
				local fDistance = self:GetDistanceSquared(vecPos)

				if fDistance < SQR(SOUND_INTENSITY) then
					oEscalator.m_fDistanceFromCamera = math.sqrt(fDistance)
					oEscalator.m_iVolume = self:ComputeVolume(EMITTING_VOLUME, SOUND_INTENSITY, oEscalator.m_fDistanceFromCamera)

					if oEscalator.m_iVolume ~= 0 then
						if not oEscalator.m_pSoundFx then
							oEscalator.m_pSoundFx = playSound3D("sfx.wav", vecPos, true)

							if isElement(oEscalator.m_pSoundFx) then
								setSoundProperties(oEscalator.m_pSoundFx, 0.0, i * 50 % 250 + 3973, 0.0)
								setSoundSpeed(oEscalator.m_pSoundFx, 3.0)
								setSoundEffectEnabled(oEscalator.m_pSoundFx, "reverb", true)
								setSoundMinDistance(oEscalator.m_pSoundFx, EMITTING_VOLUME)
								setSoundMaxDistance(oEscalator.m_pSoundFx, SOUND_INTENSITY)
							end
						elseif isElement(oEscalator.m_pSoundFx) then
							setSoundVolume(oEscalator.m_pSoundFx, oEscalator.m_iVolume / 127.0)
						end

						bSoundPlaying = true
					end
				end
			end

			if not bSoundPlaying then
				if oEscalator.m_pSoundFx then
					if isElement(oEscalator.m_pSoundFx) then
						destroyElement(oEscalator.m_pSoundFx)
					end

					oEscalator.m_pSoundFx = nil
				end
			end
		end
	end
end
