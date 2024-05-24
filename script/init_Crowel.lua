--constants
EFFECT_LINK_MAT_RESTRICTION     =73941492+TYPE_LINK     --141050356 =0x86841F4
EFFECT_CUSTOM_MAT_RESTRICTION   =73941492+TYPE_SPSUMMON --107495924 =0x66841F4
EFFECT_LEVEL_RANK_R             =EFFECT_FORBIDDEN+EFFECT_LEVEL_RANK
EFFECT_ACTIVATABLE_RANGE        =701


--new functions for convenience
--    유틸리티에서는 빠른 처리 및 제작자 본인의 편의를 위해 사용하고 있지만,
--    개별 카드에서는 호환성 문제를 감안해서 사용하지 않을 예정입니다.
--    마찬가지로, 다른 분들이 사용하실 경우에도, 유틸리티에서만 사용하시는 것을 추천합니다.
function table.Filter(t,f,ex,...)
	local ft={}
	for i,v in ipairs(t) do
		if v~=ex and f(v,...) then table.insert(ft,v) end
	end
	return ft
end
function table.FilterCount(t,f,ex,...)
	return #(table.Filter(t,f,ex,...))
end
function table.IsExists(t,f,ct,ex,...)
	if not ct then ct=1 end
	return table.FilterCount(t,f,ex,...)>=ct
end
function Effect.IsCode(e,...)
	local arg={...}
	local code=e:GetCode()
	for _,v in ipairs(arg) do
		if code==v then return true end
	end
	return false
end


--Bug fix
Duel.LoadScript("Crowel_config.lua")
Duel.LoadScript("Crowel_hotfix.lua")


--EFFECT_LINK_MAT_RESTRICTION
local lap=Link.AddProcedure
Link.AddProcedure=function(c,f,min,max,specialchk,desc)
	local materialchk=function(g,lc,sumtype,tp)
		if #g<=1 then return true end
		local gc=g:GetFirst()
		while gc do
			if gc:IsHasEffect(EFFECT_LINK_MAT_RESTRICTION) then
				local effs={gc:GetCardEffect(EFFECT_LINK_MAT_RESTRICTION)}
				for _,eff in ipairs(effs) do
					local fValue=eff:GetValue()
					local fFilter=function(tc,te) return not fValue(te,tc) end
					if g:IsExists(fFilter,1,gc,eff) then return false end
				end
			end
			gc=g:GetNext()
		end
		return true
	end
	if not specialchk then
		lap(c,f,min,max,materialchk,desc)
	else
		lap(c,f,min,max,aux.AND(specialchk,materialchk),desc)
	end
end


--EFFECT_CUSTOM_MAT_RESTRICTION
--차후 작업


--EFFECT_LEVEL_RANK_R
--Replace Level with Rank
Card.HasDataLevel = Card.HasLevel
Card.HasLevel = function(c)
	if c:IsMonster() then
		return c:GetType()&TYPE_LINK~=TYPE_LINK
			and (c:GetType()&TYPE_XYZ~=TYPE_XYZ
				or c:IsHasEffect(EFFECT_RANK_LEVEL) or c:IsHasEffect(EFFECT_RANK_LEVEL_S))
			and not (c:IsHasEffect(EFFECT_LEVEL_RANK)
				and c:IsHasEffect(EFFECT_ALLOW_NEGATIVE) and c:GetLevel()==0
				and (not EFFECT_LEVEL_RANK_R or c:IsHasEffect(EFFECT_LEVEL_RANK_R)))
			and not c:IsStatus(STATUS_NO_LEVEL)
	elseif c:IsOriginalType(TYPE_MONSTER) then
		return not (c:IsOriginalType(TYPE_XYZ+TYPE_LINK) or c:IsStatus(STATUS_NO_LEVEL))
			and not (c:IsHasEffect(EFFECT_LEVEL_RANK) and c:IsHasEffect(EFFECT_LEVEL_RANK_R))
	end
	return false
end
Card.GetOriginalDataLevel=Card.GetOriginalLevel
Card.GetOriginalDataRank=Card.GetOriginalRank
Card.GetOriginalLevel=function(c)
	local data_level=c:GetOriginalDataLevel()
	local data_rank=c:GetOriginalDataRank()
	local effs=table.Filter({c:GetCardEffect()},(function(e)
		return e:GetProperty()&(EFFECT_FLAG_INITIAL|EFFECT_FLAG_SINGLE_RANGE|EFFECT_FLAG_CANNOT_DISABLE|EFFECT_FLAG_UNCOPYABLE)==(EFFECT_FLAG_INITIAL|EFFECT_FLAG_CANNOT_DISABLE|EFFECT_FLAG_UNCOPYABLE)
			and e:GetType()==EFFECT_TYPE_SINGLE
	end))
	if data_level~=0 and not table.IsExists(effs,Effect.IsCode,1,nil,EFFECT_LEVEL_RANK_R) then data_rank=0 end
	if data_rank~=0 then
		for _,eff in ipairs(effs) do
			if eff:IsCode(EFFECT_RANK_LEVEL_S) then
				data_level=data_rank
				break
			end
		end
		if data_level==0 then
			for _,eff in ipairs(effs) do
				if eff:IsCode(EFFECT_RANK_LEVEL) then
					for _,e in ipairs(effs) do
						if e:IsCode(EFFECT_CHANGE_LEVEL,EFFECT_CHANGE_LEVEL_FINAL) then
							local v=e:GetValue()
							if type(v)=='function' then v=v(e,c) end
							if v~=0 then
								data_level=v
								break
							end
						end
					end
					break
				end
			end
		end
	end
	return data_level
end
Card.GetOriginalRank=function(c)
	local data_rank=c:GetOriginalDataRank()
	local data_level=c:GetOriginalDataLevel()
	local effs=table.Filter({c:GetCardEffect()},(function(e)
		return e:GetProperty()&(EFFECT_FLAG_INITIAL|EFFECT_FLAG_SINGLE_RANGE|EFFECT_FLAG_CANNOT_DISABLE|EFFECT_FLAG_UNCOPYABLE)==(EFFECT_FLAG_INITIAL|EFFECT_FLAG_CANNOT_DISABLE|EFFECT_FLAG_UNCOPYABLE)
			and e:GetType()==EFFECT_TYPE_SINGLE
	end))
	if data_rank~=0 or table.IsExists(effs,Effect.IsCode,1,nil,EFFECT_LEVEL_RANK_R) then data_level=0 end
	if data_level~=0 then
		for _,eff in ipairs(effs) do
			if eff:IsCode(EFFECT_LEVEL_RANK_S) then
				data_rank=data_level
				break
			end
		end
		if data_rank==0 then
			for _,eff in ipairs(effs) do
				if eff:IsCode(EFFECT_LEVEL_RANK) then
					for _,e in ipairs(effs) do
						if e:IsCode(EFFECT_CHANGE_RANK,EFFECT_CHANGE_RANK_FINAL) then
							local v=e:GetValue()
							if type(v)=='function' then v=v(e,c) end
							if v~=0 then
								data_rank=v
								break
							end
						end
					end
					break
				end
			end
		end
	end
	return data_rank
end
function Auxiliary.ReplaceLevelWithRank(c,rc,reset)
	if not c then
		Debug.PrintStacktrace()
		Debug.Message("Error: Auxiliary.ReplaceLevelWithRank should be used with Card parameter")
		Debug.Message("(카드 변수와 함께 사용되어야 합니다)")
		return
	end
	if not reset then reset=0 end
	if reset==0 and not c:IsStatus(STATUS_INITIALIZING) then
		Debug.PrintStacktrace()
		Debug.Message("Error: Auxiliary.ReplaceLevelWithRank should be used on initializing or with RESET")
		Debug.Message("(카드 초기화 단계에서 사용되거나, RESET과 함께 사용되어야 합니다)")
		return
	end
	local f=Effect.CreateEffect
	if not rc then f=Effect.GlobalEffect end
	local ex5=f(rc)
	local ex1=f(rc)
	ex1:SetType(EFFECT_TYPE_SINGLE)
	ex1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	ex1:SetCode(EFFECT_LEVEL_RANK)
	ex1:SetLabelObject(ex5)
	ex1:SetReset(reset)
	c:RegisterEffect(ex1)
	local ex2=f(rc)
	ex2:SetType(EFFECT_TYPE_SINGLE)
	ex2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	ex2:SetCode(EFFECT_CHANGE_RANK_FINAL)
	ex2:SetValue(c:GetOriginalDataLevel())
	ex2:SetReset(reset)
	c:RegisterEffect(ex2)
	local ex3=f(rc)
	ex3:SetType(EFFECT_TYPE_SINGLE)
	ex3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	ex3:SetCode(EFFECT_ALLOW_NEGATIVE)
	ex3:SetReset(reset)
	c:RegisterEffect(ex3)
	local ex4=f(rc)
	ex4:SetType(EFFECT_TYPE_SINGLE)
	ex4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	ex4:SetCode(EFFECT_CHANGE_LEVEL_FINAL)
	ex4:SetValue(0)
	ex4:SetLabelObject(ex5)
	ex4:SetReset(reset)
	c:RegisterEffect(ex4)
	--local ex5=f(rc)
	ex5:SetType(EFFECT_TYPE_SINGLE)
	ex5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	ex5:SetCode(EFFECT_IMMUNE_EFFECT)
	ex5:SetCondition(function(e)
		local c=e:GetHandler()
		return not c:IsHasEffect(EFFECT_RANK_LEVEL) and not c:IsHasEffect(EFFECT_RANK_LEVEL_S)
	end)
	ex5:SetValue(function(e,re)
		if re:GetLabelObject()==e then return false end
		return re:IsCode(EFFECT_UPDATE_LEVEL,EFFECT_CHANGE_LEVEL,EFFECT_CHANGE_LEVEL_FINAL,
			EFFECT_LEVEL_RANK,EFFECT_LEVEL_RANK_S,EFFECT_LEVEL_RANK_R)
	end)
	ex5:SetReset(reset)
	c:RegisterEffect(ex5)
	local ex6=f(rc)
	ex6:SetType(EFFECT_TYPE_SINGLE)
	ex6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	ex6:SetCode(EFFECT_LEVEL_RANK_R)
	ex6:SetLabelObject(ex5)
	ex6:SetReset(reset)
	c:RegisterEffect(ex6)
end
--Functions to automate some Fusion cards using Spell/Traps as Fusion Material
local ExtraFusion={}
function Auxiliary.EnableExtraFusion(f)
	if not f or type(f)~='function' then return false end
	if table.IsExists(ExtraFusion,function(_f) return f==_f end) then return false end
	local ge1=Effect.GlobalEffect()
	ge1:SetType(EFFECT_TYPE_SINGLE)
	ge1:SetCode(EFFECT_EXTRA_FUSION_MATERIAL)
	ge1:SetValue(aux.FALSE)
	local ge2=Effect.GlobalEffect()
	ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	ge2:SetTarget(aux.TargetBoolFunction(f))
	ge2:SetTargetRange(LOCATION_ALL,LOCATION_ALL)
	ge2:SetLabelObject(ge1)
	Duel.RegisterEffect(ge2,0)
	table.insert(ExtraFusion,f)
	return true
end


--EFFECT_ST_ACT_IN_LOCATION
--Make Spell/Trap activatable from other than hand/field
--차후 작업


