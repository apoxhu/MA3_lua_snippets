-- quick and dirty ping from adam.pinter@apox.hu
-- Usage: Plugin ping "127.0.0.1"
-- Note: This code has not yet been tested on Mac OS or Linux (console)!
-- Please be cautious and don't run it untested in show situations!

-- function to run a command asynchronously.
-- The function will return an object with several functions to get result lines, get the state, or free the object. It is currently not implemented to stop a running executable.
-- Warning: if the plugin is interrupted before the object is freed it will leave temporary files behind.
function cmdAsync(cmd)
	local tmpfile = os.tmpname()
	
	os.execute('mkdir '..tmpfile)
	
	if HostOS() == 'Windows' then
		local f = io.open(tmpfile..'/x.bat','w')
		f:write("@"..cmd.."\n@echo %ERRORLEVEL% > return_value.txt\n@exit")
		f:close()
		os.execute('cd /d '..tmpfile..' && start /B x.bat > output.txt')
	else
		local f = io.open(tmpfile..'/x.sh','w')
		f:write("#!/bin/bash\n"..cmd.."\necho $? > return_value.txt\nexit")
		f:close()
		os.execute('cd '..tmpfile..' && ./x.sh > output.txt')
	end
	
	local outFile = io.open(tmpfile..'/output.txt', "r")
    local finished = false
	
	return {
		isRunning = function(self)
			return self:getResult() == true
		end,
		getResult = function(self) -- this returns the process result. If nil, the process is still running!
		    local file = io.open(tmpfile..'/return_value.txt', "r")
		    if not file then
                return true 
            end
		    local result = file:read("*a")
		    file:close()
		    return result
		end,
		getLine = function(self)
            if finished then return nil end
			if not outFile then -- file did not open yet, try again...
				outFile = io.open(tmpfile..'/output.txt', "r")
			end
			
			if not outFile then return false end

            local lastPosition = outFile:seek() or 0
            local newEndPosition = outFile:seek("end") or 0
            outFile:seek("set", lastPosition)
            local bytesToRead = newEndPosition - lastPosition

            if bytesToRead == 0 then return false end

            local content, err = outFile:read(bytesToRead)

            if not self:isRunning() then finished = true; io.close(outFile); outFile = nil end

            return content, err
		end,
        free = function()
            if outFile then io.close(outFile) outFile = nil end
            if HostOS() == 'Windows' then
                os.execute('rmdir /s /q '..tmpfile)
            else
                os.execute('rm -r '..tmpfile)
            end
        end
	}
end

return function(display, host)
    local host = host
    Echo("Pinging "..host.."...")
	local cmdObj = cmdAsync('ping -n 4 '..host)
    local result
    repeat
        result = cmdObj:getLine()
        if result then 
            for line in result:gmatch("[^\n]+") do
                Printf(line)
            end
        end
        coroutine.yield(0.1)
    until result == nil

    cmdObj:free()
end