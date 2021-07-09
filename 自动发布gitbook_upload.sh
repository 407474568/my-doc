. /etc/profile
. /home/administrator/.bashrc
rsync -a --delete -e 'ssh -p 20022' /cygdrive/D/Code/my-doc/_book/ root@www.heyday.net.cn:/docker/my-doc-book --debug=ALL
