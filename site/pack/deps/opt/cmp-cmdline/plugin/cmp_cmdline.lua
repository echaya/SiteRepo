if package.loaded['cmp_cmdline'] then
  return
end

require('cmp').register_source('cmdline', require('cmp_cmdline').new())
