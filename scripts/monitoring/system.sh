#!/bin/bash
# Fake System Info für Honeypot

# Fake uname - gibt High-End AMD EPYC Server vor
uname() {
    case "$1" in
        -a)
            echo "Linux webapp-prod-01 5.15.0-91-generic #101-Ubuntu SMP Tue Nov 14 13:30:08 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux"
            ;;
        -r)
            echo "5.15.0-91-generic"
            ;;
        -m|--machine)
            echo "x86_64"
            ;;
        -s|--kernel-name)
            echo "Linux"
            ;;
        -n|--nodename)
            echo "webapp-prod-01"
            ;;
        -v|--kernel-version)
            echo "#101-Ubuntu SMP Tue Nov 14 13:30:08 UTC 2023"
            ;;
        -p|--processor)
            echo "x86_64"
            ;;
        -i|--hardware-platform)
            echo "x86_64"
            ;;
        -o|--operating-system)
            echo "GNU/Linux"
            ;;
        *)
            echo "Linux"
            ;;
    esac
}

# Fake lscpu - AMD EPYC mit 128 Cores
lscpu() {
    cat << 'EOF'
Architecture:                       x86_64
CPU op-mode(s):                     32-bit, 64-bit
Address sizes:                      48 bits physical, 48 bits virtual
Byte Order:                         Little Endian
CPU(s):                             128
On-line CPU(s) list:                0-127
Vendor ID:                          AuthenticAMD
Model name:                         AMD EPYC 7763 64-Core Processor
CPU family:                         25
Model:                              1
Thread(s) per core:                 2
Core(s) per socket:                 64
Socket(s):                          1
Stepping:                           1
Frequency boost:                    enabled
CPU max MHz:                        3500.0000
CPU min MHz:                        1500.0000
BogoMIPS:                           4890.86
Flags:                              fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 invpcid_single hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd amd_ppin brs arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
Virtualization features:            
  Virtualization:                   AMD-V
Caches (sum of all):                
  L1d:                              2 MiB (64 instances)
  L1i:                              2 MiB (64 instances)
  L2:                               32 MiB (64 instances)
  L3:                               256 MiB (8 instances)
NUMA:                               
  NUMA node(s):                     1
  NUMA node0 CPU(s):                0-127
Vulnerabilities:                    
  Gather data sampling:             Not affected
  Itlb multihit:                    Not affected
  L1tf:                             Not affected
  Mds:                              Not affected
  Meltdown:                         Not affected
  Mmio stale data:                  Not affected
  Retbleed:                         Not affected
  Spec rstack overflow:             Mitigation; safe RET
  Spec store bypass:                Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:                       Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:                       Mitigation; Retpolines, IBPB conditional, IBRS_FW, STIBP always-on, RSB filling, PBRSB-eIBRS Not affected
  Srbds:                            Not affected
  Tsx async abort:                  Not affected
EOF
}

# Fake free - 128GB RAM
free() {
    local ARGS="$*"
    
    # Human readable output
    if [[ "$ARGS" == *"-h"* ]] || [[ "$ARGS" == *"--human"* ]]; then
        cat << 'EOF'
               total        used        free      shared  buff/cache   available
Mem:           127Gi       8.2Gi       112Gi       145Mi       7.1Gi       118Gi
Swap:          8.0Gi          0B       8.0Gi
EOF
    else
        # Standard output in KB
        cat << 'EOF'
               total        used        free      shared  buff/cache   available
Mem:       134217728    8601600   117440512      148480     7372800   124518400
Swap:        8388608          0     8388608
EOF
    fi
}

# Fake nproc - Anzahl CPUs
nproc() {
    echo "128"
}

# Fake /proc/cpuinfo cat
# Wird aufgerufen wenn jemand "cat /proc/cpuinfo" macht
alias cat_cpuinfo='cat << "EOF"
processor	: 0
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 1
model name	: AMD EPYC 7763 64-Core Processor
stepping	: 1
microcode	: 0xa0011d1
cpu MHz		: 2445.406
cache size	: 512 KB
physical id	: 0
siblings	: 128
core id		: 0
cpu cores	: 64
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 invpcid_single hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd amd_ppin brs arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 4890.86
TLB size	: 3584 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

[... repeated for cores 1-127 ...]
EOF'

# Fake hostname
hostname() {
    echo "webapp-prod-01"
}

# Export functions
export -f uname lscpu free nproc hostname