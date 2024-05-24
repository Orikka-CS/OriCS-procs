local USE_HOTFIX = true --by default, use these fixes
if Crowel_Config and not Crowel_Config[CC_USE_HOTFIX] then
	USE_HOTFIX = false
end
if Crowel_Config and Crowel_Config[CC_USE_HOTFIX] and type(Crowel_Config[CC_USE_HOTFIX])=="function" then
	--두 사람의 합의, 혹은 코인 토스 등의 요소로 결정할 경우 (차후 작성 예정)
	--Unsupported yet
	USE_HOTFIX = false
end


--Cheating : Enable Checking current effect and target effect (or target card)
local current_effect=nil
local current_te_or_tc=nil
local nexttg_cleanup_table={}
local nexttg_cleanup=function(e,v)
	if not e then return end
	local te_or_tc=e
	if v and not e:IsHasType(EFFECT_TYPE_ACTIONS)
		and (type(v)=="Effect" or type(v)=="Card") then te_or_tc=v end
	if current_te_or_tc~=te_or_tc then
		for _,f in pairs(nexttg_cleanup_table) do
			f(e,v)
		end
		current_te_or_tc=te_or_tc
	end
end
local EnableCurrentEffectCheck=function(...)
	for idx,str in ipairs({...}) do
		local func=Effect[str]
		if func and string.sub(str,1,3)=="Set" then
			--
			local eset=func
			Effect[str]=function(e,v,...)
				if not v then return eset(e,nil,...) end
				local args={v,...}
				for pos,f_or_v in pairs(args) do
					if type(f_or_v)=="function" then
						local f2=function(e2,v2,...)
							if e2 and type(e2)=="Effect" then
								current_effect=e2
								nexttg_cleanup(e2,v2 or nil)
							end
							local values={f_or_v(e2 or nil,v2 or nil,...)}
							current_effect=nil
							return table.unpack(values)
						end
						args[pos]=f2
					end
				end
				return eset(e,table.unpack(args))
			end
			--
		end
	end
end
EnableCurrentEffectCheck("SetCost","SetTarget","SetOperation")


--Bug hotfix : Stacking LP Cost
--Override Duel.CheckLPCost
local clpc=Duel.CheckLPCost
local lpcost={
	[0]={},
	[1]={}
}
table.insert(nexttg_cleanup_table,function(e,_)
	lpcost[0]={}
	lpcost[1]={}
end)
Duel.CheckLPCost=function(player,cost)
	--use usual return value if USE_HOTFIX is false, or the cost itself is unable to pay
	if not USE_HOTFIX or not current_effect then return clpc(player,cost) end
	if not clpc(player,cost) then return false end
	--calculate total LP cost
	local id=(Effect.GetOwner(current_effect)):GetOriginalCode()
	lpcost[player][id]=cost
	local total=0
	for k,v in pairs(lpcost[player]) do
		total=total+v
	end
	return table.unpack({clpc(player,total)})
end
