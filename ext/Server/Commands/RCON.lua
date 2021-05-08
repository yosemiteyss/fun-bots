class('RCONCommands')

require('__shared/Config')

local m_BotManager = require('BotManager')
local m_BotSpawner = require('BotSpawner')


function RCONCommands:__init()
	if Config.DisableRCONCommands then
		return
	end

	self.commands = {
		-- Get Config
		GET_CONFIG = {
			Name = 'funbots.config',
			Callback = (function(p_Command, p_Args)
				if Debug.Server.RCON then
					print('[RCON] call funbots.config')
					print(json.encode(p_Args))
				end

				return {
					'OK',
					json.encode({
						MAX_NUMBER_OF_BOTS = MAX_NUMBER_OF_BOTS,
						USE_REAL_DAMAGE = USE_REAL_DAMAGE,
						Config = Config,
						StaticConfig = StaticConfig
					})
				}
			end)
		},

		-- Set Config
		SET_CONFIG = {
			Name = 'funbots.set.config',
			Parameters = { 'Name', 'Value' },
			Callback = (function(p_Command, p_Args)
				if Debug.Server.RCON then
					print('[RCON] call funbots.set.config')
					print(json.encode(p_Args))
				end

				local old = {
					Name = nil,
					Value = nil
				}

				local new = {
					Name = nil,
					Value = nil
				}

				local name = p_Args[1]
				local value = p_Args[2]

				if name == nil then
					return {'ERROR', 'Needing <Name>.'}
				end

				if value == nil then
					return {'ERROR', 'Needing <Value>.'}
				end

				-- Constants
				if name == 'MAX_NUMBER_OF_BOTS' then
					old.Name = name
					old.Value = MAX_NUMBER_OF_BOTS
					MAX_NUMBER_OF_BOTS = tonumber(value)
					new.Name = name
					new.Value = MAX_NUMBER_OF_BOTS

				elseif name == 'USE_REAL_DAMAGE' then
					local new_value = false

					if value == true or value == '1' or value == 'true' or value == 'True' or value == 'TRUE' then
						new_value = true
					end

					old.Name = name
					old.Value = USE_REAL_DAMAGE
					USE_REAL_DAMAGE = new_value
					new.Name = name
					new.Value = USE_REAL_DAMAGE
				else
					-- Config
					if Config[name] ~= nil then
						local test = tostring(Config[name])
						local type = 'nil'

						-- Boolean
						if (test == 'true' or test == 'false') then
							type = 'boolean'

						-- String
						elseif (test == Config[name]) then
							type = 'string'

						-- Number
						elseif (tonumber(test) == Config[name]) then
							type = 'number'
						end


						old.Name = 'Config.' .. name
						old.Value = Config[name]

						if type == 'boolean' then
							local new_value = false

							if value == true or value == '1' or value == 'true' or value == 'True' or value == 'TRUE' then
								new_value = true
							end

							Config[name] = new_value
							new.Name = 'Config.' .. name
							new.Value = Config[name]

						elseif type == 'string' then
							Config[name] = tostring(value)
							new.Name = 'Config.' .. name
							new.Value = Config[name]

						elseif type == 'number' then
							Config[name] = tonumber(value)
							new.Name = 'Config.' .. name
							new.Value = Config[name]

						else
							print('Unknown Config property-Type: ' .. name .. ' -> ' .. type)
						end
					elseif StaticConfig[name] ~= nil then
						local test = tostring(StaticConfig[name])
						local type = 'nil'

						old.Name = 'StaticConfig.' .. name
						old.Value = StaticConfig[name]

						-- Boolean
						if (test == 'true' or test == 'false') then
							type = 'boolean'

						-- String
						elseif (test == StaticConfig[name]) then
							type = 'string'

						-- Number
						elseif (tonumber(test) == StaticConfig[name]) then
							type = 'number'
						end

						if type == 'boolean' then
							local new_value = false

							if value == true or value == '1' or value == 'true' or value == 'True' or value == 'TRUE' then
								new_value = true
							end

							StaticConfig[name] = new_value
							new.Name = 'StaticConfig.' .. name
							new.Value = StaticConfig[name]

						elseif type == 'string' then
							StaticConfig[name] = tostring(value)
							new.Name = 'StaticConfig.' .. name
							new.Value = StaticConfig[name]

						elseif type == 'number' then
							StaticConfig[name] = tonumber(value)
							new.Name = 'StaticConfig.' .. name
							new.Value = StaticConfig[name]

						else
							print('Unknown Config property-Type: ' .. name .. ' -> ' .. type)
						end
					else
						print('Unknown Config property: ' .. name)
					end
				end

				-- Update some things
				local updateBotTeamAndNumber = false
				local updateWeaponSets = false
				local updateWeapons = false
				local calcYawPerFrame = false

				if name == 'botAimWorsening' then
					updateWeapons = true
				end

				if name == 'botSniperAimWorsening' then
					updateWeapons = true
				end

				if name == 'spawnMode' then
					updateBotTeamAndNumber = true
				end

				if name == 'spawnInBothTeams' then
					updateBotTeamAndNumber = true
				end

				if name == 'initNumberOfBots' then
					updateBotTeamAndNumber = true
				end

				if name == 'newBotsPerNewPlayer' then
					updateBotTeamAndNumber = true
				end

				if name == 'keepOneSlotForPlayers' then
					updateBotTeamAndNumber = true
				end

				if name == 'assaultWeaponSet' then
					updateWeaponSets = true
				end

				if name == 'engineerWeaponSet' then
					updateWeaponSets = true
				end

				if name == 'supportWeaponSet' then
					updateWeaponSets = true
				end

				if name == 'reconWeaponSet' then
					updateWeaponSets = true
				end

				if updateWeapons then
					if Debug.Server.RCON then
						print('[RCON] call WeaponModification:ModifyAllWeapons()')
					end

					WeaponModification:ModifyAllWeapons(Config.BotAimWorsening, Config.BotSniperAimWorsening)
				end

				NetEvents:BroadcastLocal('WriteClientSettings', Config, updateWeaponSets)

				if updateWeaponSets then
					if Debug.Server.RCON then
						print('[RCON] call WeaponList:updateWeaponList()')
					end

					WeaponList:updateWeaponList()
				end

				if calcYawPerFrame then
					if Debug.Server.RCON then
						print('[RCON] call m_BotManager:calcYawPerFrame()')
					end

					Globals.YawPerFrame = m_BotManager:calcYawPerFrame()
				end

				if updateBotTeamAndNumber then
					if Debug.Server.RCON then
						print('[RCON] call m_BotSpawner:UpdateBotAmountAndTeam()')
					end

					Globals.SpawnMode = Config.SpawnMode
					m_BotSpawner:UpdateBotAmountAndTeam()
				end

				if Debug.Server.RCON then
					print('[RCON] Config Result')
					print('[RCON] ' .. old.Name .. ' = ' .. tostring(old.Value))
					print('[RCON] ' .. new.Name .. ' = ' .. tostring(new.Value))
				end

				return { 'OK', old.Name .. ' = ' .. tostring(old.Value), new.Name .. ' = ' .. tostring(new.Value) }
			end)
		},

		-- Clear/Reset Botnames
		CLEAR_BOTNAMES = {
			Name = 'funbots.clear.BotNames',
			Callback = (function(p_Command, p_Args)
				BotNames = {}

				return { 'OK' }
			end)
		},

		-- Add BotName
		ADD_BOTNAMES = {
			Name = 'funbots.add.BotNames',
			Parameters = { 'String' },
			Callback = (function(p_Command, p_Args)
				local value = p_Args[1]

				if value == nil then
					return {'ERROR', 'Needing <String>.'}
				end

				table.insert(BotNames, value)

				return { 'OK' }
			end)
		},

		-- Replace BotName
		REPLACE_BOTNAMES = {
			Name = 'funbots.replace.BotNames',
			Parameters = { 'JSONArray' },
			Callback = (function(p_Command, p_Args)
				local value = p_Args[1]

				if value == nil then
					return {'ERROR', 'Needing <JSONArray>.'}
				end

				local result = json.decode(value)

				if result == nil then
					return {'ERROR', 'Needing <JSONArray>.'}
				end

				BotNames = result

				return { 'OK' }
			end)
		},

		-- Kick All
		KICKALLL = {
			Name = 'funbots.kickAll',
			Callback = (function(p_Command, p_Args)
				m_BotManager:destroyAll()

				return { 'OK' }
			end)
		},

		-- Kick Bot
		KICKBOT = {
			Name = 'funbots.kickBot',
			Parameters = { 'Name' },
			Callback = (function(p_Command, p_Args)
				local name = p_Args[1]
				if name == nil then
					return {'ERROR', 'Name needed.'}
				end
				m_BotManager:destroyBot(name)

				return { 'OK' }
			end)
		},

		-- Kill All
		KILLALL = {
			Name = 'funbots.killAll',
			Callback = (function(p_Command, p_Args)
				m_BotManager:killAll()

				return { 'OK' }
			end)
		},

		-- Spawn <Amount> <Team>
		SPAWN = {
			Name = 'funbots.spawn',
			Parameters = { 'Amount', 'Team' },
			Callback = (function(p_Command, p_Args)
				local value	= p_Args[1]
				local team	= p_Args[2]

				if value == nil then
					return {'ERROR', 'Needing Spawn amount.'}
				end

				if team == nil then
					return {'ERROR', 'Needing Team.'}
				end

				if tonumber(value) == nil then
					return {'ERROR', 'Needing Spawn amount.'}
				end

				local amount = tonumber(value)
				
				if TeamId[team] == nil then
					return {'ERROR', 'Unknown Team: TeamId.' .. team }
				end
				
				m_BotSpawner:SpawnWayBots(nil, amount, true, nil, nil, TeamId[team])

				return {'OK'}
			end)
		},

		-- Permissions <Player> <PermissionName>
		PERMISSIONS = {
			Name		= 'funbots.Permissions',
			Parameters	= { 'PlayerName', 'PermissionName' },
			Callback	= (function(command, args)
				local name			= args[1]
				local permission	= args[2]

				-- Revoke ALL Permissions
				if permission ~= nil then
					if permission == '!' then
						local permissions	= PermissionManager:GetPermissions(name)
						local result		= {'OK', 'REVOKED'}

						if permissions ~= nil and #permissions >= 1 then
							for key, value in pairs(permissions) do
								table.insert(result, PermissionManager:GetCorrectName(value))
							end
						end

						if PermissionManager:RevokeAll(name) then
							return result
						else
							return {'ERROR', 'Can\'r revoke all Permissions from "' .. name .. '".'}
						end

					-- Revoke SPECIFIC Permission
					elseif permission:sub(1, 1) == '!' then
						permission = permission:sub(2)

						if PermissionManager:Exists(permission) == false then
							return {'ERROR', 'Unknown Permission:', permission}
						end

						if PermissionManager:Revoke(name, permission) then
							return {'OK', 'REVOKED'}
						else
							return {'ERROR', 'Can\'r revoke the Permission "' .. PermissionManager:GetCorrectName(permission) .. '" for "' .. name .. '".'}
						end
					end
				end

				if name == nil then
					local all = PermissionManager:GetAll()

					if all ~= nil and #all >= 1 then
						local result = {'OK', 'LIST'}

						for key, value in pairs(all) do
							table.insert(result, PermissionManager:GetCorrectName(value))
						end

						return result
					end

					return {'ERROR', 'Needing PlayerName.'}
				end

				local player = PlayerManager:GetPlayerByName(name)

				if player == nil then
					player = PlayerManager:GetPlayerByGuid(Guid(name))

					if player == nil then
						return {'ERROR', 'Unknown PlayerName "' .. name .. '".'}
					end
				end

				if permission == nil then
					local result		= { 'LIST', player.name, tostring(player.guid) }
					local permissions	= PermissionManager:GetPermissions(name)

					if permissions ~= nil then
						for name, value in pairs(permissions) do
							table.insert(result, PermissionManager:GetCorrectName(value))
						end
					end

					return result
				end

				if PermissionManager:Exists(permission) == false then
					return {'ERROR', 'Unknown Permission:', permission}
				end
				
				PermissionManager:AddPermission(player.name, permission)
				
				return {'OK'}
			end)
		}
	}

	self:createCommand('funbots', (function(p_Command, p_Args)
		local result = {}

		table.insert(result, 'OK')

		for index, command in pairs(self.commands) do
			local the_command = command.Name

			if command.Parameters ~= nil then
				for _, parameter in pairs(command.Parameters) do
					the_command = the_command .. ' <' .. parameter .. '>'
				end
			end

			table.insert(result, the_command)
		end

		return result
	end))

	self:create()
end

function RCONCommands:create()
	for index, command in pairs(self.commands) do
		self:createCommand(command.Name, command.Callback)
	end
end

function RCONCommands:createCommand(p_Name, p_Callback)
	RCON:RegisterCommand(p_Name, RemoteCommandFlag.RequiresLogin, function(p_Command, p_Args, p_LoggedIn)
		return p_Callback(p_Command, p_Args)
	end)
end

if g_RCONCommands == nil then
	g_RCONCommands = RCONCommands()
end

return g_RCONCommands
