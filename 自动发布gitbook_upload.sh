. /etc/profile
if [ -f /home/administrator/.bashrc ];then
    . /home/administrator/.bashrc
elif [ -f /home/tanhuang/.bashrc ];then
    . /home/tanhuang/.bashrc
fi
if [ "$(hostname)" == "tanhuang-PC" ];then
#   rsync -aP --delete -e 'ssh -i /cygdrive/c/Users/Administrator/.ssh/id_ed25519 -p 22' \
#    rsync -aP --delete -e 'ssh -i ~/.ssh/id_ed25519 -p 6000' \
#    /cygdrive/D/Code/my-doc/_book/ root@code.heyday.net.cn:/docker/my-doc-book --debug=ALL
# 再次修改, 注意要把 密钥文件放到 mintty 的家目录下, 否则权限映射转换问题难得折腾
    rsync -aP --delete -e 'ssh -p 6000' /cygdrive/D/Code/my-doc/_book/ root@code.heyday.net.cn:/docker/my-doc-book --debug=ALL
elif [ "$(hostname)" == "tanhuang-note" ];then
#    rsync -aP --delete -e 'ssh -i /cygdrive/c/Users/Administrator/.ssh/id_ed25519 -p 6000' \
    rsync -aP --delete -e 'ssh -i /cygdrive/c/Users/Administrator/.ssh/id_ed25519 -p 6000' \
    /cygdrive/D/Code/my-doc/_book/ root@code.heyday.net.cn:/docker/my-doc-book --debug=ALL
fi

