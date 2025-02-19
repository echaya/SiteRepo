(
  (expr) @image.src
  (#match? @image.src "^\\[\\[(file:)?.*(png|jpg)\\]\\]$")
  (#offset! @image.src 0 2 0 -2)
)
