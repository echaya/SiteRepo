
(image 
  [
    (link_destination) @image
    (image_description (shortcut_link (link_text) @image))
    (#gsub! @image "|.*" "") ; remove wikilink image options
    (#gsub! @image "^<" "") ; remove bracket link
    (#gsub! @image "^>" "")
  ]) @anchor
