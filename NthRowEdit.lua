-- Every-N Cell Edit
-- Written by adam.pinter@apox.hu

--[[
    This plugin let's you edit every n-th cell in a Sequence Editor.
    Just select a cell and run the plugin. It will select every n-th cell below the selected one.
]]

local pressEnterAtEnd = true    -- press enter or not?
local nth = 2                   -- every nth row will be selected
local skipCueOff = true         -- to avoid grabbing off-cue

return function()
    -- find open sequence editor
    local editor = nil
    for _, display in ipairs(GetDisplayCollect()) do
        local e = display:FindRecursive("GenericSettingsEditor")
        if e and e.EditTarget:GetClass() == "Sequence" then
            editor = e; break
        end
    end

    if editor == nil then Printf("Sequence Editor not found"); return end

    -- find sequence grid
    local grid = editor:FindRecursive("SequenceGrid")
    local grSel = grid:GridGetSelection()
    local selectedItems = grSel.SelectedItems
    local dims = grid:GridGetDimensions() -- returns {r=44,c=44}

    if #selectedItems < 1 then Printf("No cell selected"); return end

    -- lookups for column ids
    local col_ids = {} -- key is 0 based index, value is column id
    local rev_col_ids = {} -- key is column id, value is 0 based index
    local name_col -- this is for later use
    for c = 0, dims.c - 1 do
        local d = grid:GridGetCellData({r = 0, c = c});
        col_ids[c]=d.column_id
        rev_col_ids[d.column_id]=c 
        if d.column_id == selectedItems[1].column then name_col = c end
    end

    -- lookups for row ids
    local row_ids = {} -- key is 0 based index, value is row object id
    local rev_row_ids = {} -- key is row object id, value is 0 based index
    for r = 0, dims.r - 1 do
        local d = grid:GridGetCellData({r = r, c = name_col});
        row_ids[r]=d.row_id
        rev_row_ids[d.row_id]=r 
    end

    -- turn selectedItems into selectedCells
    local selectedCells = {}
    for _, item in ipairs(selectedItems) do
        if rev_row_ids[item.row] == nil then
            -- this happens when we use a different column for lookups than selected (for example when cue part is selected and Name is the row lookup column id)
            Echo("Can not find row index from object id! Row index is "..item.row)
            Echo("Class = "..IntToHandle(item.row):GetClass())
            Echo("Parent Class = "..IntToHandle(item.row):Parent():GetClass())
            local parentId = HandleToInt(IntToHandle(item.row):Parent())
            table.insert(selectedCells, {r=rev_row_ids[parentId], c=rev_col_ids[item.column]})
        else
            table.insert(selectedCells, {r=rev_row_ids[item.row], c=rev_col_ids[item.column]})
        end
    end

    if selectedCells[1].r == nil or selectedCells[1].c == nil then Printf("Can not interpret selected cell for some reason :(") return end

    -- run the keyboard / mouse emulation (user input has to be disabled)
    SetBlockInput(true)
    Keyboard(grid:GetDisplayIndex(), 'press', 'LeftCtrl', false, false, false)
    local target_row
    for target_row = selectedCells[1].r + nth, dims.r - (skipCueOff and 2 or 1), nth do
        local cell = {r=target_row, c=selectedCells[1].c}
        grid:GridScrollCellIntoView(cell)
        local rect = grid:GridGetCellDimensions(cell)
        local displayIndex = grid:GetDisplayIndex()
        Mouse(displayIndex, "move", rect.x + rect.w / 2, rect.y + rect.h / 2)
        Mouse(displayIndex, "press", "Left")
        Mouse(displayIndex, "release", "Left")
    end
    Keyboard(grid:GetDisplayIndex(), 'release', 'LeftCtrl', false, false, false)

    if pressEnterAtEnd then
        Keyboard(grid:GetDisplayIndex(), 'press', 'Enter', false, false, false)
        Keyboard(grid:GetDisplayIndex(), 'release', 'Enter', false, false, false)
    end

    SetBlockInput(false)
end, function() SetBlockInput(false) end