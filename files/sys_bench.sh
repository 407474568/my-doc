function analyse_result_file_cpu() {
    prime_number_limit=$(\grep "^Prime numbers limit:" "$file" | awk -F ": " '{print $2}')
    threads_num=$(\grep "^Number of threads" "$file" | awk -F ": " '{print $2}')
    duration=$(\grep -E "^\s+total time" "$file" | awk -F ": +" '{print $2}' | awk -F "." '{print $1}')
    total_finished_round=$(\grep -E "^\s+total number of events" "$file" | awk -F ": +" '{print $2}')
    avg_each_round_duration=$(\grep -E "^\s+avg:" "$file" | awk -F ": +" '{print $2}')
    printf "| %-8s | %-6s | %-6s秒 | %-8s | %-8s毫秒 |\n" "$prime_number_limit" "$threads_num" "$duration" \
        "$total_finished_round" "$avg_each_round_duration"
}

function analyse_result_file_mem() {
    access_mode=$1
    block_size=$(\grep -E "^\s+block size" "$file" | awk -F ": " '{print $2}')
    total_size=$(\grep -E "^\s+total size" "$file" | awk -F ": " '{print $2}')
    total_size_num=${total_size//MiB/}
    speed=$(\grep -E ".*MiB transferred" "$file" | sed  "s@.*(\(.*\))@\1@g")
    speed_num=$(echo "$speed" | awk '{print $1}')
    speed_unit=$(echo "$speed" | awk '{print $2}')
    opera_type=$(\grep -E "^\s+operation" "$file" | awk -F ": +" '{print $2}')
    printf "| %-6s | %-8s MiB | %10s %-s | %-8s | %-10s |\n" "$block_size" "$total_size_num" "$speed_num" \
        "$speed_unit" "$opera_type" "$access_mode"
}

function cpu_bench() {
    # 获取主机的逻辑线程总数
    cpu_threads_num_total=$(\grep 'processor' /proc/cpuinfo | sort -u | wc -l)
    cpu_threads_num_half=$(echo "$cpu_threads_num_total" | awk '{print ($1/2)}')
    # 根据逻辑线程是否为2的指数倍生成不同的测试线程数队列
    # 低于等于4个线程
    if [ "$cpu_threads_num_total" -le 4 ];then
        num_queue="1 $cpu_threads_num_half $cpu_threads_num_total"
    # 低于等于8个线程
    elif [ "$cpu_threads_num_total" -le 8 ];then
        num_queue="1 2 $cpu_threads_num_half $cpu_threads_num_total"
    # 低于等于16个线程
    elif [ "$cpu_threads_num_total" -le 16 ];then
        num_queue="1 2 4 $cpu_threads_num_half $cpu_threads_num_total"
    # 低于等于32个线程
    elif [ "$cpu_threads_num_total" -le 32 ];then
        num_queue="1 2 4 8 $cpu_threads_num_half $cpu_threads_num_total"
    # 32个线程以上
    else
        num_queue="1 2 4 8 16 $cpu_threads_num_half $cpu_threads_num_total"
    fi


    # 素数上限2万，默认20秒
    cpu_max_prime=20000
    duration=60
    
    echo " -------------------------------------------------------- "
    printf "| 素数上限 | 线程数 | 持续时间 | 完成轮数 | 平均每轮用时 |\n"
    echo " -------------------------------------------------------- "
    
    # shellcheck disable=SC2116
    for threads_num in $num_queue
    do
        sysbench cpu --cpu-max-prime="$cpu_max_prime" --time="$duration" --threads="$threads_num"  run > "$file"
        analyse_result_file_cpu
    done
    
    echo " -------------------------------------------------------- "
}

function mem_bench() {
    echo " ------------------------------------------------------------------ "
    printf "| 块大小 |    总大小    |        速度        | 操作类型 | 访问类型 |\n"
    echo " ------------------------------------------------------------------ "
    
    # shellcheck disable=SC2116
    for block_size in $(echo "1 4 8 16 32 64 128")
    do
        sysbench memory --memory-block-size="${block_size}kb" --memory-total-size=50G --memory-oper=read  --memory-access-mode=seq run > "$file"
        analyse_result_file_mem "顺序"
        sysbench memory --memory-block-size="${block_size}kb" --memory-total-size=50G --memory-oper=read  --memory-access-mode=rnd run > "$file"
        analyse_result_file_mem "随机"
        sysbench memory --memory-block-size="${block_size}kb" --memory-total-size=50G --memory-oper=write --memory-access-mode=seq run > "$file"
        analyse_result_file_mem "顺序"
        sysbench memory --memory-block-size="${block_size}kb" --memory-total-size=50G --memory-oper=write --memory-access-mode=rnd run > "$file"
        analyse_result_file_mem "随机"
    done
    
    echo " ------------------------------------------------------------------ "
}


file=/tmp/sysbench_result_tmp.txt
cpu_bench
mem_bench
