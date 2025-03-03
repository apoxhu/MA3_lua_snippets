local config = {
	timecodeSlot = "TimecodeSlot 1"
}

return (function (config, pluginName, componentName, signalTable, pluginComponent)
	local tcSlot = nil
	
	function tcChange()
		if tcSlot == nil then return end
		
		local isRunning = not (tcSlot.sourceIP == "")

        Printf("Incoming timecode is "..(isRunning and "running" or "stopped"))
	end

	return function()
		tcSlot = GetObject(config.timecodeSlot)
		HookObjectChange(tcChange, tcSlot, pluginComponent:Parent())
		tcChange()
	end
end)(config, ...)