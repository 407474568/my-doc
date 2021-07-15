@echo off
set /p title=输入本次上传的说明标题: 

:build
REM 在Windows中执行gitbook命令后, 发生了退出操作, 无法获取%errorlevel%来进行后续操作, 用以下这种奇葩方式解决
cmd /k "gitbook build . && exit"
if %errorlevel% == 0 (goto upload) else (goto build)

:upload
echo 开始上传markdown文档
del /q _book\自动发布book.cmd
git add .
git commit -m %title%
git push git master
git push gitee master
git push local master


echo 开始上传静态网站
cd _book
if %computername% == TANHUANG-PC (set fastcopy_command=C:\Users\Administrator\FastCopy\FastCopy.exe)
if %computername% == TANHUANG-NOTE (set fastcopy_command="C:\Program Files\FastCopy\FastCopy.exe")
%fastcopy_command% /cmd=sync /force_close /estimate /bufsize=256 /acl /log=FALSE /balloon=FALSE D:\Code\my-doc\images\ /to=D:\Code\my-doc\_book\images
git init
git remote add git git@github.com:407474568/my-doc.git
REM git config credential.helper store
git add .
git commit -m %title%
git push -f git master:gh-pages


REM 上传本地网站
REM convmv -f gbk -t utf-8 -r --notest /docker/my-doc-book/