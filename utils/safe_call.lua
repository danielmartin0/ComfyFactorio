local function safe_call(func, ...)
	local success, result = pcall(func, ...)
	if not success then
		local info = debug.getinfo(func, 'n')
		local func_name = info and info.name or 'unknown function'
		log('Error in ' .. func_name .. ': ' .. tostring(result))
	end
	return success, result
end

return safe_call
