. /etc/profile
if [ -f /home/administrator/.bashrc ];then
    . /home/administrator/.bashrc
elif [ -f /home/tanhuang/.bashrc ];then
    . /home/tanhuang/.bashrc
fi
if [ "$(hostname)" == "tanhuang-PC" ];then
    rsync -aP --delete -e 'ssh -i /cygdrive/c/Users/Administrator/.ssh/id_ed25519 -p 22' \
    /cygdrive/D/Code/my-doc/_book/ root@www.heyday.net.cn:/docker/my-doc-book --debug=ALL
else
    rsync -aP --delete -e 'ssh -i /cygdrive/c/Users/Administrator/.ssh/id_ed25519 -p 6000' \
    /cygdrive/D/Code/my-doc/_book/ root@www.heyday.net.cn:/docker/my-doc-book --debug=ALL
fi
