:A
gitbook build .
if %errorlevel% == 0 (goto B) else (goto A)

:B
cd _book
git add -A
git commit -m '���gcc�����������ĵ�'
git push -f origin master:gh-pages

