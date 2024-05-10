sysbench_package=sysbench-1.0.20.tar.gz

yum -y install make automake libtool pkgconfig libaio-devel
# For MySQL support, replace with mysql-devel on RHEL/CentOS 5
yum -y install mariadb-devel openssl-devel
# For PostgreSQL support
yum -y install postgresql-devel

tar -xvzf "$sysbench_package"
dir=$(echo "$sysbench_package" | sed "s/.tar.gz//g")
cd $dir
./autogen.sh
# Add --with-pgsql to build with PostgreSQL support
./configure
make -j
make install
