@echo on
for /d /r . %%d in (plugged) do @if exist "%%d" rd /s/q "%%d"

SET MoveToDir=D:\Workspace\SiteRepo\site
SET MoveFromDir=c:\Users\echay\AppData\Local\nvim-data\site
RMDIR %MoveToDir% /S /Q
ROBOCOPY %MoveFromDir% %MoveToDir% /S

for /d /r . %%d in (.git) do if exist "%%d" if "%%~pd" NEQ "\Workspace\SiteRepo\" rd /s/q "%%d"
for /d /r . %%d in (.github) do if exist "%%d" rd /s/q "%%d"
for /d /r . %%d in (tests) do if exist "%%d" rd /s/q "%%d"
for /d /r . %%d in (test) do if exist "%%d" rd /s/q "%%d"
for /r "%MoveToDir%" %%f in (*.jpg, *.png, *.gif, *.bmp, *.tiff, *.svg) do del "%%f"

del d:\Workspace\SiteRepo\site\pack\deps\opt\nvim-treesitter\parser-info\.gitignore
del d:\Workspace\SiteRepo\site\pack\deps\opt\nvim-treesitter\parser\.gitignore
del d:\Workspace\SiteRepo\site\pack\deps\opt\telescope-fzf-native.nvim\.gitignore
del d:\Workspace\SiteRepo\site\pack\deps\opt\blink.cmp\.gitignore

lazygit
:: cmd /k
