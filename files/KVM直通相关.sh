#查看NVIDIA显卡设备
[root@localhost ~]# lspci -nnk | grep -i nvidia

#根据上面显示的显卡设备编号，查看显卡驱动
lspci -vv -s 86:00.0 | grep driver
lspci -vv -s 86:00.1 | grep driver
lspci -vv -s 86:00.2 | grep driver
lspci -vv -s 86:00.3 | grep driver
#显示有3个驱动nouveau，snd_hda_intel，xhci_hcd

在服务器主机上禁用显卡设备
vi /etc/modprobe.d/blacklist.conf
添加
blacklist nouveau
blacklist snd_hda_intel


# 取出iommu组
for id in `lspci | grep -i nvidia | awk '{print $1}'`
do
    dmesg | grep iommu | grep $id
done

# PCI总线上的设备的id
for id in `lspci | grep -i nvidia | awk '{print $1}' | awk -F '.' '{print $1}'`
do
    lspci -nn | grep $id | awk '{print $(NF-2)}'
done

# 根据设备ID,添加到/etc/default/grub.cfg, 再生成启动内核
grub2-mkconfig -o /boot/grub2/grub.cfg


# 重启后, 确认已在stub-pci状态
for id in `lspci | grep -i nvidia | awk '{print $1}' | awk -F '.' '{print $1}'`
do
    lspci -nnv | grep -E "(^\S|Kernel driver in use)" | grep $id -A 1
done




for i in `virsh nodedev-list --cap pci`
do
    count=`virsh nodedev-dumpxml $i | grep -c -i nvidia`
    if [ $count != 0 ];then
        virsh nodedev-dumpxml $i
    fi
done

