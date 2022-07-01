@echo off
set /p title=输入本次上传的说明标题: 
if defined title (
    echo 变量 title 的值为%title%
) else set title=该用户不屑于输入备注

:build
REM 在Windows中执行gitbook命令后, 发生了退出操作, 无法获取%errorlevel%来进行后续操作, 用以下这种奇葩方式解决
cmd /k "gitbook build . && exit"
if %errorlevel% == 0 (goto upload) else (goto build)

:upload
echo 开始上传markdown文档
del /q _book\自动发布book.cmd
del /q _book\自动发布gitbook_upload.sh
git add .
git commit -m %title%
git push git master
git push gitee master
git push local master


echo 开始上传静态网站
cd _book
if %computername% == TANHUANG-PC (set fastcopy_command="C:\Program Files\FastCopy\FastCopy.exe")
if %computername% == TANHUANG-NOTE (set fastcopy_command="C:\Program Files\FastCopy\FastCopy.exe")
REM fastcopy同步一次图片文件夹, 避免因每次的文件时间不同, 导致重复上传浪费时间
%fastcopy_command% /cmd=sync /force_close /estimate /bufsize=256 /acl /log=FALSE /balloon=FALSE D:\Code\my-doc\images\ /to=D:\Code\my-doc\_book\images

REM 弃用
REM git init
REM git remote add git git@github.com:407474568/my-doc.git
REM REM git config credential.helper store
REM git add .
REM git commit -m %title%
REM git push -f git master:gh-pages

"C:\cygwin64\bin\mintty.exe" -l bash D:\Code\my-doc\自动发布gitbook_upload.sh
