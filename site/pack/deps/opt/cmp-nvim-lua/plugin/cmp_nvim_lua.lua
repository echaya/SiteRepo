if package.loaded['cmp_nvim_lua'] then
	return
end

require('cmp').register_source('nvim_lua', require('cmp_nvim_lua').new())
