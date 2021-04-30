class('Utilities')

require('__shared/Config')

function Utilities:__init()
	-- nothing to do
end

function Utilities:getCameraPos(p_Player, p_IsTarget)
	local returnVec = Vec3(0, 0, 0)
	local cameraVec = p_Player.input.authoritativeCameraPosition:Clone()

	if cameraVec.z ~= 0 then
		returnVec = p_Player.soldier.worldTransform.forward* cameraVec.z + p_Player.soldier.worldTransform.left * cameraVec.x + p_Player.soldier.worldTransform.up * cameraVec.y

		if p_IsTarget then
			if Config.AimForHead then
				if p_Player.soldier.pose == CharacterPoseType.CharacterPoseType_Stand then
					returnVec.y = returnVec.y - 0.1
				elseif p_Player.soldier.pose == CharacterPoseType.CharacterPoseType_Crouch then
					returnVec.y = returnVec.y - 0.05
				else
					returnVec.y = returnVec.y - 0.05
				end
			else
				if p_Player.soldier.pose == CharacterPoseType.CharacterPoseType_Stand then
					returnVec.y = returnVec.y - 0.5
				elseif p_Player.soldier.pose == CharacterPoseType.CharacterPoseType_Crouch then
					returnVec.y = returnVec.y - 0.3
				else
					returnVec.y = returnVec.y - 0.1
				end
			end
		end
	else
		returnVec = Vec3(0.03 ,self:getTargetHeight(p_Player.soldier, p_IsTarget), 0.03)
	end

	return returnVec
end

function Utilities:getTargetHeight(p_Soldier, p_IsTarget)
	local camereaHight = 0

	if not p_IsTarget then
		camereaHight = 1.6 --bot.soldier.pose == CharacterPoseType.CharacterPoseType_Stand

		if p_Soldier.pose == CharacterPoseType.CharacterPoseType_Prone then
			camereaHight = 0.3
		elseif p_Soldier.pose == CharacterPoseType.CharacterPoseType_Crouch then
			camereaHight = 1.0
		end

	elseif p_IsTarget and Config.AimForHead then
		camereaHight = 1.50 --bot.soldier.pose == CharacterPoseType.CharacterPoseType_Stand

		if p_Soldier.pose == CharacterPoseType.CharacterPoseType_Prone then
			camereaHight = 0.25
		elseif p_Soldier.pose == CharacterPoseType.CharacterPoseType_Crouch then
			camereaHight = 1
		end

	else --aim a little lower
		camereaHight = 1.1 --bot.soldier.pose == CharacterPoseType.CharacterPoseType_Stand - reduce by 0.5

		if p_Soldier.pose == CharacterPoseType.CharacterPoseType_Prone then
			camereaHight = 0.2 -- reduce by 0.1
		elseif p_Soldier.pose == CharacterPoseType.CharacterPoseType_Crouch then
			camereaHight = 0.7 -- reduce by 0.3
		end

	end

	return camereaHight
end

function Utilities:isBot(p_Player)
	if (type(p_Player) == 'string') then
		p_Player = PlayerManager:GetPlayerByName(p_Player)
	end
	if (type(p_Player) == 'number') then
		p_Player = PlayerManager:GetPlayerById(p_Player)
		if (p_Player == nil) then
			p_Player = PlayerManager:GetPlayerByOnlineId(p_Player)
		end
	end

	return p_Player ~= nil and p_Player.onlineId == 0
end

function Utilities:getEnumName(p_Enum, p_Value)
	for k,v in pairs(getmetatable(p_Enum)['__index']) do
		if (v == p_Value) then
			return k
		end
	end

	return nil
end

-- do not use on numerically indexed tables, only tables with string keys
-- this is shallow merge, does not recurse deeper than one p_Level
function Utilities:mergeKeys(p_OriginalTable, p_NewData)
	for k,v in pairs(p_NewData) do
		p_OriginalTable[k] = v
	end

	return p_OriginalTable
end


-- <object|o> | The object to dump
-- <boolean|p_Format> | If enabled, tab-spacing and newlines are used
-- <int|p_MaxLevels> | Max recursion level, defaults to -1 for infinite
-- <int|level> | Current recursion level
-- returns <string> | a string representation of the object
function Utilities:dump(o, p_Format, p_MaxLevels, p_Level)
	local tablevel = ''
	local tablevellessone = ''
	local newline = ''
	p_MaxLevels = p_MaxLevels or -1
	p_Level = p_Level or 1

	if p_Format then
		tablevel = string.rep("\t", p_Level)
		tablevellessone = string.rep("\t", math.max(p_Level-1, 0))
		newline = "\n"
	end

	if o == nil then
		return 'nil'
	end

	if type(o) == 'table' or tostring(o):starts('sol.VEXTRefArray') or tostring(o):starts('sol.VEXTArray') then
		if (p_MaxLevels == -1 or p_Level <= p_MaxLevels) then
			local s = tostring(o) .. ' -> { ' .. newline

			for k,v in pairs(o) do
				if type(k) ~= 'number' then
					k = '"'..k..'"'
				end

				s = s .. tablevel .. '['..k..'] = ' .. g_Utilities:dump(v, p_Format, p_MaxLevels, p_Level+1) .. ',' .. newline
			end

			return s .. tablevellessone .. '}'
		else
			return '{ '.. tostring(o) .. ' }'
		end
	elseif type(o) == 'userdata' and not tostring(o):starts('sol.VEXTRefArray') and not tostring(o):starts('sol.VEXTArray') and getmetatable(o) ~= nil then
		if (p_MaxLevels == -1 or p_Level <= p_MaxLevels) then
			local s = tostring(o)

			if (o.typeInfo ~= nil) then
				s = s .. ' (' .. o.typeInfo.name .. ')'
			end
			s = s .. ' -> [ ' .. newline

			for k,v in pairs(getmetatable(o)) do
				if (not k:starts('__') and k ~= 'typeInfo' and k ~= 'class_cast' and k ~= 'class_check') then
					s = s .. tablevel .. k .. ': ' .. g_Utilities:dump(o[k], p_Format, p_MaxLevels, p_Level+1) .. ',' .. newline
				end
			end
			return s .. tablevellessone .. ']'
		else
			return '[ '.. tostring(o) .. ' ]'
		end
	else
		return tostring(o)
	end
end

function table:has(p_Value)
	for i=1, #self do
		if (self[i] == p_Value) then
			return true
		end
	end
	return false
end

function string:isLower(p_Value)
	 return string:lower() == string
end

function string:isDigit(p_Value)
	 return tonumber(string) ~= nil
end

function string:split(sep)
	local sep, fields = sep or ':', {}
	local pattern = string.format("([^%s]+)", sep)

	self:gsub(pattern, function(c) fields[#fields + 1] = c end)

	return fields
end

function requireExists(module)
	local function reference(module)
		require(module)
	end

	res = pcall(reference, module)

	if not(res) then
		-- Not found.
	end
end

if g_Utilities == nil then
	g_Utilities = Utilities()
end

return g_Utilities
