@echo off
set /p title=���뱾���ϴ���˵������: 
if defined title (
    echo ���� title ��ֵΪ%title%
) else set title=���û���м�����뱸ע

:build
REM ��Windows��ִ��gitbook�����, �������˳�����, �޷���ȡ%errorlevel%�����к�������, �������������ⷽʽ���
cmd /k "gitbook build . && exit"
if %errorlevel% == 0 (goto upload) else (goto build)

:upload
echo ��ʼ�ϴ�markdown�ĵ�
del /q _book\�Զ�����book.cmd
del /q _book\�Զ�����gitbook_upload.sh
git add .
git commit -m %title%
git push git master
git push gitee master
git push local master


echo ��ʼ�ϴ���̬��վ
cd _book
if %computername% == TANHUANG-PC (set fastcopy_command="C:\Program Files\FastCopy\FastCopy.exe")
if %computername% == TANHUANG-NOTE (set fastcopy_command="C:\Program Files\FastCopy\FastCopy.exe")
REM fastcopyͬ��һ��ͼƬ�ļ���, ������ÿ�ε��ļ�ʱ�䲻ͬ, �����ظ��ϴ��˷�ʱ��
%fastcopy_command% /cmd=sync /force_close /estimate /bufsize=256 /acl /log=FALSE /balloon=FALSE D:\Code\my-doc\images\ /to=D:\Code\my-doc\_book\images

REM ����
REM git init
REM git remote add git git@github.com:407474568/my-doc.git
REM REM git config credential.helper store
REM git add .
REM git commit -m %title%
REM git push -f git master:gh-pages

"C:\cygwin64\bin\mintty.exe" -l bash D:\Code\my-doc\�Զ�����gitbook_upload.sh
