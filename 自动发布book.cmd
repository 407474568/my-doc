@echo off
set /p title=���뱾���ϴ���˵������: 

:build
REM ��Windows��ִ��gitbook�����, �������˳�����, �޷���ȡ%errorlevel%�����к�������, �������������ⷽʽ���
cmd /k "gitbook build . && exit"
if %errorlevel% == 0 (goto upload) else (goto build)

:upload
echo ��ʼ�ϴ�markdown�ĵ�
del /q _book\�Զ�����book.cmd
git add .
git commit -m %title%
git push git master


echo ��ʼ�ϴ���̬��վ
cd _book
git init
git remote add git https://github.com/407474568/my-doc.git
git config credential.helper store
git add .
git commit -m %title%
git push -f git master:gh-pages
