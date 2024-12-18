-- Flip selection's DMXInvertPan
-- Written by adam.pinter@apox.hu

return function()
    local fixtureIndex, gridX, gridY, gridZ = SelectionFirst()
    if fixtureIndex == nil then return end
    while fixtureIndex do
        local subf = GetSubfixture(fixtureIndex)
        subf.dmxInvertPan = subf.dmxInvertPan == true and '' or true
        fixtureIndex, gridX, gridY, gridZ = SelectionNext(fixtureIndex)
    end
end