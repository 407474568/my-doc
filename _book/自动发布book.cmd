:A
gitbook build .
if %errorlevel% == 0 (goto B) else (goto A)

:B
cd _book
git add -A
git commit -m '添加gcc升级操作的文档'
git push -f origin master:gh-pages

