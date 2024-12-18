-- Flip selection's DMXInvertTilt
-- Written by adam.pinter@apox.hu

return function()
    local fixtureIndex, gridX, gridY, gridZ = SelectionFirst()
    if fixtureIndex == nil then return end
    while fixtureIndex do
        local subf = GetSubfixture(fixtureIndex)
        subf.dmxInvertTilt = subf.dmxInvertTilt == true and '' or true
        fixtureIndex, gridX, gridY, gridZ = SelectionNext(fixtureIndex)
    end
end