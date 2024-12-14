if package.loaded['cmp_buffer'] then
  return
end

require('cmp').register_source('buffer', require('cmp_buffer'))
