(declaration
  (call_expression
    (function_name) @fn (#eq? @fn "url")
    (arguments  [
      (plain_value) @image
      (string_value) @image
      ; Remove quotes from the image URL
      (#gsub! @image "^['\"]" "")
      (#gsub! @image "['\"]$" "")
    ]))
) @anchor
