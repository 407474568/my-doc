#!/bin/bash
# 解析配置文件
function load_config()
{
    conf_file=$1
    file_target=$(grep "^file_target" "$conf_file" | tail -n 1 | awk -F "=" '{print $NF}')
    file_size=$(grep -E "^file_size" "$conf_file" | tail -n 1 | awk -F "=" '{print $NF}')
    count=$(grep -E -c "^runtime" "$conf_file")
    if [ "$count" -ne 0 ];then
        runtime=$(grep "runtime" "$conf_file" | awk -F "=" '{print $NF}')
    fi
}


# fio 软件包的安装
function auto_handle_fio_install()
{
    echo "尝试自动通过yum安装缺失的软件包"
    yum -y install fio boost-iostreams boost-random boost-system boost-thread libibverbs libpmem libpmemblk librados2 \
      librbd1 librdmacm pciutils rdma-core
    # shellcheck disable=SC2181
    if [ $? -eq 0 ];then
        return 0
    else
        return 1
    fi
}


# 处理fio输出结果
function fio_result_handler()
{
    bench_item_name=$1
    fio_result=$2
    fio_result_report=$3
    fio_result_original=$4
#    value=$(grep -A 1 "Run status group 0" "${fio_result}" | tail -n 1 | awk -F "," '{print $1}' | awk '{print $NF}' | \
#          sed -e "s/[(|)]//g")
    value=$(grep -A 1 "Run status group 0" "${fio_result}" | tail -n 1 | awk -F "," '{print $1}' | awk '{print $2}' | \
          awk -F "=" '{print $2}')
    latency_time=$(grep -E "^\s+lat \(usec\):" "${fio_result}"  | tail -n 1 | sed "s/^ \+//" | awk -F ': ' '{print $2}')
    latency_time=$(echo "$latency_time" | sed -e "s/,//g" -e "s/=/:/g" | sed -e "s/min/最小值/g" -e "s/max/最大值/g")
    latency_time=$(echo "$latency_time" | sed -e "s/avg/平均值/g" -e "s/stdev/标准方差/g")
    # shellcheck disable=SC2001
    latency_time=$(echo "$latency_time" | sed "s/\(.*\)\(平均值.*\)/\2/g")
    latency_avg=$(echo "$latency_time" | awk '{print $1}' | awk -F ":" '{printf ("%.2f",$2/1000)}')
    latency_stdev=$(echo "$latency_time" | awk '{print $2}' | awk -F ":" '{printf ("%.2f",$2/1000)}')
    latency_time=$(printf "平均值: %-7s 毫秒 标准方差: %-7s 毫秒" "${latency_avg}" "${latency_stdev}")
#    echo "$latency_time"
    echo "${bench_item_name},${value},${latency_time}" >> "${fio_result_report}"
    cat "${fio_result}" >> "${fio_result_original}"
}


# fio 测试主体
function fio_benchmark()
{
    input_var=$1
    io_type=$(echo "$input_var" | awk '{print $1}')
    if [ "$io_type" == "read" ];then
        bench_item_name="顺序读"
    elif [ "$io_type" == "write" ];then
        bench_item_name="顺序写"
    elif [ "$io_type" == "randread" ];then
        bench_item_name="随机读"
    elif [ "$io_type" == "randwrite" ];then
        bench_item_name="随机写"
    elif [ "$io_type" == "randrw" ];then
        bench_item_name="混合读写"
    fi

    block_size=$(echo "$input_var" | awk '{print $2}')
    queue_depth=$(echo "$input_var" | awk '{print $3}')
    thread_num=$(echo "$input_var" | awk '{print $4}')
    mix_percentile=$(echo "$input_var" | awk '{print $5}')

    echo "当前测试项目: ${bench_item_name},${block_size},Q${queue_depth} T${thread_num}"
    start_time=$(date "+%s")

    if [ -z "${runtime}" ];then
        if [ "${io_type}" == "randrw" ];then
            fio -filename="${file_target}" -direct=1 -iodepth "${queue_depth}" -thread -rw="${io_type}" \
              -ioengine=libaio -bs="${block_size}" -size="${file_size}" -numjobs="${thread_num}" -group_reporting \
              -rwmixread="${mix_percentile}" -name=mytest >"${fio_result}" 2>> "${fio_error}"
        else
            fio -filename="${file_target}" -direct=1 -iodepth "${queue_depth}" -thread -rw="${io_type}" \
              -ioengine=libaio -bs="${block_size}" -size="${file_size}" -numjobs="${thread_num}" -group_reporting \
              -name=mytest >"${fio_result}" 2>> "${fio_error}"
        fi
    else
        if [ "${io_type}" == "randrw" ];then
            fio -filename="${file_target}" -direct=1 -iodepth "${queue_depth}" -thread -rw="${io_type}" -ioengine=libaio \
              -bs="${block_size}" -size="${file_size}" -runtime="${runtime}" -numjobs="${thread_num}" -group_reporting \
              -rwmixread="${mix_percentile}" -name=mytest >"${fio_result}" 2>> "${fio_error}"
        else
            fio -filename="${file_target}" -direct=1 -iodepth "${queue_depth}" -thread -rw="${io_type}" -ioengine=libaio \
              -bs="${block_size}" -size="${file_size}" -runtime="${runtime}" -numjobs="${thread_num}" -group_reporting \
              -name=mytest >"${fio_result}" 2>> "${fio_error}"
        fi
    fi

    end_time=$(date "+%s")
    times_elapsed=$((end_time-start_time))
    echo "本轮测试用时: $times_elapsed 秒"

    fio_result_handler "${bench_item_name},${block_size},Q${queue_depth} T${thread_num}" "${fio_result}" \
      "${fio_result_report}" "${fio_result_original}"
}


conf_file=fio_auto_bench_and_report.ini
load_config "$conf_file"

if ! fallocate "${file_target}" -l "${file_size}";
then
    echo "尝试预分配文件大小失败, 请人工核实"
    exit 1
fi


# 检查fio软件包安装情况
echo "检查软件包安装情况"
fio_package_list="fio boost-iostreams boost-random boost-system boost-thread libibverbs libpmem libpmemblk librados2 librbd1 librdmacm pciutils rdma-core"
missing_package_list=""
for package in ${fio_package_list}
do
    count=$(rpm -qa "${package}" | wc -l)
    if [ "${count}" -eq 0 ];then
        missing_package_list="${missing_package_list} ${package}"
    fi
done
if [ "${missing_package_list}" != "" ];then
    auto_handle_fio_install
    # shellcheck disable=SC2181
    if [ $? -ne 0 ];then
        # shellcheck disable=SC2001
        missing_package_list=$(echo "${missing_package_list}" | sed "s/^ //")
        printf "以下软件包缺失, 且已尝试通过yum安装, 测试无法进行:\nThe following package is missing:\n%s\nInstall first.\n" \
          "${missing_package_list}"
        exit 1
    fi
fi


fio_result=/tmp/fio_result.tmp
printf "" > ${fio_result}
fio_result_original=/tmp/fio_result.raw
printf "" > ${fio_result_original}
fio_result_report=/tmp/fio_result_report.txt
printf "" > ${fio_result_report}
fio_error=/tmp/fio_error.log
printf "" > ${fio_error}

echo "fio 测试开始"

grep -E "^test_object=" "$conf_file" | while read -r line
do
    parm=$(echo "$line" | awk -F "=" '{print $NF}' | awk -v FS="," -v OFS=" " '{print $1,$2,$3,$4,$5}')
    fio_benchmark "$parm"
done


# 测试结果格式化输出
echo " ------------------------------------------------------------------------------------------------------------ "
if [ -z "${runtime}" ];then
    printf "|     测试文件大小    |       %-9s |     持续时间     |                      无限制                     |\n" "$file_size"
else
    printf "|     测试文件大小    |       %-9s |     持续时间     |                     %-10s                   |\n" "$file_size" "${runtime} 秒"
fi
echo " ------------------------------------------------------------------------------------------------------------ "
printf "|  测试项目  | 块大小 | 队列深度 线程数 |       带宽       |                     IO 延迟                     |\n"
echo " ------------------------------------------------------------------------------------------------------------ "
while read -r line
do
    type=$(echo "${line}" | awk -F ',' '{print $1}')
    block_size=$(echo "${line}" | awk -F ',' '{print $2}')
    queue_depth_thread_num=$(echo "${line}" | awk -F ',' '{print $3}')
#    value=$(echo "${line}" | awk -F ',' '{print $4}' | sed "s@\([0-9]\+\)\(.*\)@\1 \2@g")
    value=$(echo "${line}" | awk -F ',' '{print $4}')
#    num=$(echo "${value}" | sed "s/\(.*[0-9]\)\([TGMk]\{0,\}B\/s\)/\1/g")
    num=$(echo "${value}" | sed "s/\(.*[0-9]\)\([a-Z]\+B\/s\)/\1/g")
#    unit=$(echo "${value}" | sed "s/.*[0-9]\([TGMk]\{0,\}B\/s\)/\1/g")
    unit=$(echo "${value}" | sed "s/\(.*[0-9]\)\([a-Z]\+B\/s\)/\2/g")
#    if [ "$unit" == "kB/s" ];then
#        num=$(echo "${num}" | awk '{printf ("%.2f\n",$1/1024)}')
#        unit="MB/s"
#    fi
    value=$(printf "%-6s %-4s" "${num}" "${unit}")
    latency_time=$(echo "${line}" | awk -F "," '{print $NF}')
    if [ "$type" == "混合读写" ];then
        printf "|  %-13s |  %-4s  | " "${type}" "${block_size}"
    else
        printf "|  %-12s |  %-4s  | " "${type}" "${block_size}"
    fi
    echo -n "     ${queue_depth_thread_num}    " | sed "s/\(Q[0-9]\{1\}\) \(T[0-9]\{1\}\)/\1  \2/g"
    printf " |   %-12s   |" "${value}"
    printf "   %-12s   |\n" "${latency_time}"
done < "$fio_result_report"
echo " ------------------------------------------------------------------------------------------------------------ "
