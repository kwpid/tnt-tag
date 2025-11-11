--[[
	Logger.lua
	Centralized logging utility with context and severity levels
]]

local Logger = {}
Logger.__index = Logger

local LogLevel = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
}

Logger.LogLevel = LogLevel

function Logger.new(context)
	local self = setmetatable({}, Logger)
	self.context = context or "Unknown"
	self.minLevel = LogLevel.INFO
	return self
end

function Logger:setMinLevel(level)
	self.minLevel = level
end

function Logger:debug(message, data)
	if self.minLevel <= LogLevel.DEBUG then
		self:_log("DEBUG", message, data)
	end
end

function Logger:info(message, data)
	if self.minLevel <= LogLevel.INFO then
		self:_log("INFO", message, data)
	end
end

function Logger:warn(message, data)
	if self.minLevel <= LogLevel.WARN then
		self:_log("WARN", message, data)
	end
end

function Logger:error(message, data)
	if self.minLevel <= LogLevel.ERROR then
		self:_log("ERROR", message, data)
	end
end

function Logger:_log(level, message, data)
	local prefix = string.format("[%s][%s]", self.context, level)
	local output = prefix .. " " .. message
	
	if data then
		output = output .. " | Data: " .. tostring(data)
	end
	
	if level == "ERROR" then
		warn(output)
	else
		print(output)
	end
end

-- Utility: wrap async operations with pcall and logging
function Logger:wrapAsync(operation, operationName, onError)
	local success, result = pcall(operation)
	
	if not success then
		self:error(operationName .. " failed", result)
		if onError then
			onError(result)
		end
		return nil, result
	end
	
	return result, nil
end

return Logger
