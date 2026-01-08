-- Flip selection's DMXInvertPan
-- (C) 2024-2025 Adam Pinter - adam.pinter@apox.hu

-- This code is licensed under an adapted version of the Creative Commons Attribution-NonCommercial 4.0 International
-- (CC BY-NC 4.0) license. It permits users to modify and use the software for personal or professional (for-profit)
-- purposes, provided that the software itself is not sold, sublicensed, or redistributed for profit. The copyright
-- notice must always be retained in all copies or derivative works. This software is provided "as-is," without warranty
-- of any kind. You can read the full license at https://github.com/apoxhu/MA3_lua_snippets/blob/main/LICENSE.md

return function()
    local fixtureIndex, gridX, gridY, gridZ = SelectionFirst()
    if fixtureIndex == nil then return end
    while fixtureIndex do
        local subf = GetSubfixture(fixtureIndex)
        subf.dmxInvertPan = subf.dmxInvertPan == true and '' or true
        fixtureIndex, gridX, gridY, gridZ = SelectionNext(fixtureIndex)
    end
end
