非常正确 👍，要做个“操作留痕”文档，方便以后系统重装或 BIOS 被恢复默认时，能快速复原到你现在排查过的状态。

我帮你整理一份 **截至今天你在 5950X 主机上做过的 BIOS & 内核 cmdline 改动清单**（只含你提过的实际操作过的部分）：

---

## 📌 AMD Ryzen 9 5950X 主机（ROG STRIX X570-E GAMING WIFI II）调整记录

### 1. BIOS 调整过的项目

**Advanced → AMD CBS**

* `Global C-state Control` → **Disabled**（关闭 C-States，避免深度节能状态导致不稳定）

**AI Tweaker → CPU Core/Performance**

* `Precision Boost Overdrive (PBO)` → **Enabled**（提升性能）

> ⚠️ 菜单中未找到或未改动的：
>
> * `Extreme Performance`（你的 BIOS 没这个选项）
> * `AMD Cool’n’Quiet`（未找到，可能被新版 BIOS 合并或移除）
> * `NBIO Common Options → PCIe ASPM`（未出现，只有 ACS / ARI 等项，未更改）

**BIOS 版本**

* 已确认是 **最新稳定版**（非测试版）。

---

### 2. 内核启动参数（cmdline）改动

原始值（示例）：

```bash
BOOT_IMAGE=(hd0,gpt2)/vmlinuz-6.1.102 root=UUID=70028d44-394f-4156-a4b6-2fcb28dd89aa ro crashkernel=0M-2G:0M,2G-8G:256M,8G-:512M rd.md.uuid=ae22fa72:d9f8ae2a:809c4919:2fb859c5 rhgb quiet amd_iommu=on iommu=pt
```

新增准备加入的参数：

```
idle=nomwait processor.max_cstate=1
```

> ✅ 意义：进一步限制 CPU 进入深度 C-state，以避免 ACPI/电源管理导致的系统重启。
> 目前你已写好计划，但尚未 `grubby --update-kernel` 应用。

---

### 3. 尚未改动，但提到过的选项

* `NBIO Common Options → PCIe ASPM → Disabled` （未找到）
* `AI Tweaker → Extreme Performance`（菜单中无）
* `AMD Cool’n’Quiet`（未找到，未修改）

---

这样你以后重装系统或 BIOS 恢复默认时，就可以按这个 checklist 来快速恢复环境。

要不要我帮你写一个 **脚本 + 文档**，重装系统后只需执行脚本，就能自动把 grub cmdline 改回？（比如一键 `grubby --update-kernel` 写入 `idle=nomwait processor.max_cstate=1`）。
