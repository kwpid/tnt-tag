--[[
	ServiceRegistry.lua
	Centralized service registry for sharing service instances across scripts
]]

local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

local services = {}

function ServiceRegistry:register(serviceName, serviceInstance)
	services[serviceName] = serviceInstance
end

function ServiceRegistry:get(serviceName)
	return services[serviceName]
end

function ServiceRegistry:getAll()
	return services
end

return ServiceRegistry
