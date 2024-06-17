-- ping from adam.pinter@apox.hu
-- Usage: Plugin ping "127.0.0.1"
-- Can also run from plugin pool, it will ask for input
-- Has been tested on windows, mac and desks.

-- Function to run a command asynchronously.
-- The function will return an object with several functions to get result lines, get the state, or free the object. It is currently not implemented to stop a running executable.
-- Warning: if the plugin is interrupted before the object is freed it will leave temporary files behind.
function cmdAsync(cmd)
    local tmpfile = GetPath(Enums.PathType.Temp)-- os.tmpname() returns empty string on console !
    tmpfile = tmpfile .. "/LCA" .. tostring(os.clock()):gsub('%.', '')
    Echo("cmdAsync File folder : " .. tmpfile)

    os.execute('mkdir -p "' .. tmpfile .. '"')

    if HostOS() == 'Windows' then
        local f = io.open(tmpfile .. '/x.bat', 'w')
        f:write("@" .. cmd .. "\n@echo %ERRORLEVEL% > return_value.txt\n@exit")
        f:close()
        os.execute('cd /d ' .. tmpfile .. ' && start /B x.bat > output.txt')
    else
        local f = io.open(tmpfile .. '/x.sh', 'w')
        f:write("#!/bin/bash\n" .. cmd .. "\necho $? > return_value.txt\nexit")
        f:close()
        os.execute('cd ' .. tmpfile .. ' && chmod +x x.sh && ./x.sh > output.txt 2>&1 &')
    end

    local outFile = io.open(tmpfile .. '/output.txt', "r")
    local finished = false

    return {
        isRunning = function(self)
            return self:getResult() == true
        end,
        getResult = function(self)
            -- this returns the process result. If nil, the process is still running!
            local file = io.open(tmpfile .. '/return_value.txt', "r")
            if not file then
                return true
            end
            local result = file:read("*a")
            file:close()
            return result
        end,
        getLine = function(self)
            if finished then
                return nil
            end
            if not outFile then
                -- file did not open yet, try again...
                outFile = io.open(tmpfile .. '/output.txt', "r")
            end

            if not outFile then
                return false
            end

            local lastPosition = outFile:seek() or 0
            local newEndPosition = outFile:seek("end") or 0
            outFile:seek("set", lastPosition)
            local bytesToRead = newEndPosition - lastPosition

            if bytesToRead == 0 then
                return false
            end
            local content, err = outFile:read(bytesToRead)

            if not self:isRunning() then
                finished = true;
                io.close(outFile);
                outFile = nil
            end

            return content, err
        end,
        free = function()
            if outFile then
                io.close(outFile)
                outFile = nil
            end
            if HostOS() == 'Windows' then
                os.execute('rmdir /s /q "' .. tmpfile .. '"')
            else
                os.execute('rm -rf "' .. tmpfile .. '"')
            end
        end
    }
end

return function(display, host)
    host = host or TextInput("Enter IP:")
    if host == nil or host == "" then
        return
    end
    Printf("Pinging " .. host .. "...")
    local command = (HostOS() == 'Windows') and 'ping -n 4 ' or 'ping -c 4 '
    local cmdObj = cmdAsync(command .. host)
    local result

    -- UI preparation for displaying ping result
    Timer(function()
        -- put MessageBox in Timer so it won't block
        MessageBox({
            title = "Pinging " .. host,
            message = " "
        })
    end, 0, 1)

    coroutine.yield(0.1)
    local texts = {}

    for i = 1, #GetDisplayCollect() do
        local _display = GetDisplayCollect()[i]
        if _display ~= nil then
            local msgBox = _display:FindRecursive('MsgBox')

            if msgBox ~= nil then
                local text = msgBox:FindRecursive("Text")
                if IsObjectValid(text) then
                    text.TextAlignmentH = "Left"
                    table.insert(texts, text)
                end
            end
        end
    end

    -- wait for lines from ping
    repeat
        result = cmdObj:getLine()
        if result then
            for line in result:gmatch("[^\n]+") do
                Printf(line)
            end
            for _, text in ipairs(texts) do
                if (IsObjectValid(text)) then
                    text.Text = text.Text .. result
                end
            end
        end
        coroutine.yield(0.1)
    until result == nil

    cmdObj:free()
end
