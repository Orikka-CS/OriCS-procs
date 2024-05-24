Auxiliary.AdditionalSetcardsList={
	--마도
	[0x6e]={48048590},
	--마술사
	[0x98]={21051146,40737112,41175645},
	--티아라
	[0x2c4]={37164373},
}
local cisc=Card.IsSetCard
function Card.IsSetCard(c,set,...)
	if Auxiliary.AdditionalSetcardsList[set]
		and c:IsCode(table.unpack(Auxiliary.AdditionalSetcardsList[set])) then
		return true
	end
	if type(set)=="string" and data_setname[c:GetCode()] then
		for _,str in ipairs(data_setname[c:GetCode()]) do
			if set==str then
				return true
			end
		end
	end
	if type(set)=="string" then
		return false
	end
	return cisc(c,set,...)
end