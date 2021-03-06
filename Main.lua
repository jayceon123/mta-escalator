local oEscalatorManager = EscalatorManager.Init()
local oAudioManager = AudioManager.Init(oEscalatorManager)

addEventHandler("onClientResourceStart", resourceRoot,
	function()
		oEscalatorManager:Add(Vector3(1139.2392578125, -1508.7066650391, 15.0), 90.0, 8.7, 2.0, 9.0, 6.0, true)
	end
)

addEventHandler("onClientPreRender", root,
	function(fTimeDelta)
		oEscalatorManager:Update(fTimeDelta)
		oAudioManager:Update(fTimeDelta)
	end
)

addEventHandler("onClientRender", root,
	function()
		oAudioManager:ProcessEscalators()
	end
)
