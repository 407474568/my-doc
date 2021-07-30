. /etc/profile
if [ -f /home/administrator/.bashrc ];then
    . /home/administrator/.bashrc
elif [ -f /home/tanhuang/.bashrc ];then
    . /home/tanhuang/.bashrc
fi
rsync -a --delete -e 'ssh -p 20022' /cygdrive/D/Code/my-doc/_book/ root@www.heyday.net.cn:/docker/my-doc-book --debug=ALL
