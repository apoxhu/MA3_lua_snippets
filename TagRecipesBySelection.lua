--[[
This script assigns tags to recipes based on their targets.
Each configuration entry specifies a target list and the corresponding tag to assign.
Written by adam.pinter@apox.hu 2026
]]

local config = {
    {targetList = "Group 1 Thru 100", tag = "GROUP1"},
    {targetList = "Group 101 Thru 200", tag = "GROUP2"},
    {targetList = "Group 201 Thru 300", tag = "GROUP3"},
}


function CreateTagIfNotExists(name)
    local tags = nil
    for _, mt in ipairs(ShowData():Children()) do
        if mt.Name == "Tags" then
            tags = mt
            break
        end
    end
    if not tags then return end
    if not IsObjectValid(tags[name]) then
    	local t = tags:Acquire()
    	t.Name = name
    end
end

return function()
    -- Prepare (create tags and list objects)
    for _, entry in ipairs(config) do
        CreateTagIfNotExists(entry.tag)
        entry.targets = ObjectList(entry.targetList)
    end

    
    for iSequ, sequ in pairs(DataPool().Sequences:Children()) do
        for iCue, cue in ipairs(sequ:Children()) do
            for iPart, part in ipairs(cue:Children()) do
                Printf("Sequ %s %s Cue %s %s Part %s %s: ", tostring(sequ:Get('INDEX')), sequ.Name, tostring(cue:Get('INDEX')), cue.Name, tostring(part:Get('INDEX')), part.Name)

                -- add tags
                for iRecipe, recipe in ipairs(part:Children()) do
                    local target = recipe.Selection

                    for _, entry in ipairs(config) do
                        for _, obj in ipairs(entry.targets) do
                            if obj == target then
                                Printf("Assigning tag %s to target %s", entry.tag, target.Name)
                                recipe.Tags = recipe.Tags .. ',' ..entry.tag .. ':0'
                            end
                        end
                    end
                end
            end
        end
    end
end