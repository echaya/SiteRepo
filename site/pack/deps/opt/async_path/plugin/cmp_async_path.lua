if package.loaded['cmp_async_path'] then
  return
end

require('cmp').register_source('async_path', require('cmp_async_path').new())
