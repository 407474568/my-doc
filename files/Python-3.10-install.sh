#!/bin/bash
function get_os_vendor
{
    flag=`cat /proc/version | grep "Red Hat" | wc -l`
    if [ ${flag} -eq 1 ];then
        echo "redhat"
    fi
    flag=`cat /proc/version | grep "SUSE" | wc -l`
    if [ ${flag} -eq 1 ];then
        echo "suse"
    fi
}

work_dir=`pwd`



# Python解释器
python_version=`find ./ -type f | grep -E "^\./Python-.*.tar.xz$" | sed "s@\./\(Python-[0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\)\.tar.xz@\1@g"`
python_version_main=`echo "${python_version}" | sed -e "s/-//g" -e "s/\(.*\)\.[0-9]\{1,\}/\1/g"`
python_version_main_num=`echo "${python_version_main}" | sed "s/Python//g"`

# 前置条件检查, 如果低于gcc 7, 安装必然不成功, 给出提示
gcc_main_version=$(gcc --version | head -n 1 | awk '{print $3}' | awk -F '.' '{print $1}')
if [ $gcc_main_version -lt 8 ];then
    printf "由于当前环境的gcc版本低于8, Python版本 %-s 的编译安装必然不会成功\n" "$python_version_main_num"
    printf "Because of current gcc version is low than 8, Python version %-s compile install will be definitely fail.\n\n" "$python_version_main_num"
    printf "gcc 版本可以在不影响系统当前版本的前提下进行临时的版本替换, 如需更多信息:\n"
    printf "请参阅: https://doc.heyday.net.cn:1000/Linux_gcc_upgrade.html\n"
    printf "gcc version could upgrade temporary without compromise current version, if you need more information, see link above.\n"
    exit
fi


os_vendor=`get_os_vendor`
if [ "${os_vendor}" == "redhat" ];then
    yum -y install make autoconf libtool zlib zlib-devel libffi-devel
elif [ "${os_vendor}" == "suse" ];then
    zypper -n install make autoconf libtool zlib zlib-devel libffi-devel
fi
rm -rf /tmp/${python_version}
tar -xvf ${python_version}.tar.xz -C /tmp
# 关于python要启用ssl模块,以下方法随源码包版本变化可能失效
# sed -i "s@#SSL=/usr/local/ssl@SSL=/usr/local/openssl@g" /tmp/${python_version}/Modules/Setup.dist
# sed -i "212,214s/#//" /tmp/${python_version}/Modules/Setup.dist
sed -i "s@#_socket socketmodule.c@_socket socketmodule.c@g" /tmp/${python_version}/Modules/Setup
sed -i "s@#zlib zlibmodule.c@zlib zlibmodule.c@g" /tmp/${python_version}/Modules/Setup
# 213-214行也是启用openssl的代码行, 需要检查行数是否有效
sed -i "s@# OPENSSL=.*@OPENSSL=/usr/local/openssl@g" /tmp/${python_version}/Modules/Setup
sed -i "212,214s/# //" /tmp/${python_version}/Modules/Setup
# 开始编译
cd /tmp/${python_version}
./configure --prefix=/usr/local/${python_version_main} --with-openssl=/usr/local/openssl --enable-optimizations --enable-shared
# make -j 4 && make install -j 4
make -j 4 && make altinstall -j 4
# make clean
# make distclean
ln -sf /usr/local/${python_version_main}/bin/python${python_version_main_num} /usr/bin/python3
ln -sf /usr/local/${python_version_main}/bin/pip${python_version_main_num} /usr/bin/pip3
python3 -V
# # pip
# cd ${work_dir}
# pip_version=`find ./ -type f | grep -E "\./pip-.*.tar.gz" | sed "s@\./\(pip-[0-9]\{1,\}\.[0-9]\{1,\}\)\.tar.gz@\1@g"`
# tar -xvf ${pip_version}.tar.gz -C /tmp
# cd /tmp/${pip_version}
# python3 setup.py install
# pip3 --version
# # 各种库
# cd ${work_dir}/Python_packages_for_Linux
# # pip3 install --no-index --find-links=./ -r requirements.txt
# cat requirements.txt | while read line
# do
    # pip3 install --no-index --find-links=./ ${line}
# done
ln -s /usr/local/${python_version_main}/lib/libpython${python_version_main_num}.so.1.0 /usr/lib64/libpython${python_version_main_num}.so.1.0
echo "/usr/local/${python_version_main}/lib" >/etc/ld.so.conf.d/python3.conf
ldconfig
ldd /usr/bin/python3
pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
