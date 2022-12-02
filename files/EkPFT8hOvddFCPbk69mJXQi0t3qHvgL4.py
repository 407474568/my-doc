import time
import random
import psutil
from pathlib import Path
from SMWinservice import SMWinservice

class PythonCornerExample(SMWinservice):
    _svc_name_ = "My_Watchdog_for_Windows"
    _svc_display_name_ = "My_Watchdog_for_Windows"
    _svc_description_ = "That's a great winservice! :)"

    def start(self):
        self.isrunning = True

    def stop(self):
        self.isrunning = False

    def watch_process(process_name, exe_path):
        flag = 0
        for i in psutil.pids():
            if psutil.Process(i).name() == process_name:
                return flag
        if not flag:
            log_writer("检测到进程: " + process_name + " 不存在,启动该进程", ident=True)
            subprocess.Popen(exe_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    def check_self_if_alive():
        process_name = "python"
        command_prefix = "wmic process where \"caption like '%"
        command_suffix = "%'\" get /Format:csv"
        command = command_prefix + process_name + command_suffix
        is_alive = False
        count = 0
        output = os.popen(command)
        for line in output.readlines():
            if line.startswith('\n') or line.startswith('Node'):
                continue
            line_content = line.strip('\n')
            line_content_list = line_content.split(',')
            command_line = line_content_list[2]
            pid = line_content_list[28]
            if re.search(r"python  .*my_watchdog_for_windows_pc.py", command_line):
                print("发现运行中的Python程序: " + command_line + " PID为: " + pid)
                count += 1
        if count >= 2:
            is_alive = True
        return is_alive
        
    def main(self):
        # 开机时间5分钟以内, 先行等待, MACtype 加载完后才能渲染XYplorer
        while True:
            startup_duration = time.time() - psutil.boot_time()
            if startup_duration > 300:
                break
            else:
                time.sleep(1)
        if self.check_self_if_alive():
            print("已有一个 my_watchdog_for_windows_pc 在运行")
            return
        watch_process_list = list()
        watch_process_list.append(("XYplorer.exe", r'Z:\XYplorer\XYplorer.exe'))
        watch_process_list.append(("Foxmail.exe", r'"D:\Program Files\Foxmail\Foxmail.exe" /min'))
        while self.isrunning:
            for process_name, exe_path in watch_process_list:
                self.watch_process(process_name, exe_path)
            time.sleep(10)

if __name__ == '__main__':
    PythonCornerExample.parse_command_line()
