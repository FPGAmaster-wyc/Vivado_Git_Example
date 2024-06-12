# Product Version: Vivado v2019.2 (64-bit)
# 工程名称
set projName Aurora_xdma_ddr	
# 工程芯片选型		
set part xc7z100ffg900-2	
# 顶层文件			
set top top	
# 顶层仿真文件
set tb_top tb_ddr_data_sim

proc run_create {} {
    global projName
    global part
    global top
    global tb_top

    set outputDir ./$projName			

    file mkdir $outputDir

    # 创建一个新的vivado工程
    create_project $projName $outputDir -part $part -force		

    # 将当前项目的目录路径存储在 projDir 变量中
    set projDir [get_property directory [current_project]]

    # 添加 src 代码
    add_files -fileset [current_fileset] -force -norecurse {
        ../src/aurora_64b66b_0_cdc_sync_exdes.v
        ../src/aurora_64b66b_0_example_axi_to_ll.v
        ../src/aurora_64b66b_0_example_ll_to_axi.v
        ../src/aurora_64b66b_0_exdes.v
        ../src/aurora_64b66b_0_frame_check.v
        ../src/aurora_64b66b_0_frame_gen.v
        ../src/frame_count.v
        ../src/pma_init_rst.v
        ../src/top.v
        ../src/wr_rd_ddr.v
    }

    # 添加 ip （xci和xcix文件都可以）
    add_files -fileset [current_fileset] -force -norecurse {
        ../ip/vio_7series/vio_7series.xci
        ../ip/aurora_64b66b_0.xci
        ../ip/aurora_64b66b_0_reg_slice_0.xci
		../ip/aurora_64b66b_0_reg_slice_2.xci
		../ip/clk_wiz_0.xci
		../ip/ila_0.xci
		../ip/ila_7series.xci
    }

    # 添加 仿真文件
    add_files -fileset [get_filesets sim_1] -force -norecurse {
        ../src/tb_ddr_data_sim.v
    }

    # 添加 约束文件
    add_files -fileset [current_fileset -constrset] -force -norecurse {
        ../src/top.xdc
    }
	
	#添加自定义ip库 
	set_property ip_repo_paths "../ip/axi_lite_4reg_1.0" [current_project]
	update_ip_catalog

    # 加载 block design 设计
    source {../bd/bd.tcl}

    # 设置仿真顶层
    set_property top $tb_top [get_filesets sim_1]
    set_property top_lib xil_defaultlib [get_filesets sim_1]
    update_compile_order -fileset sim_1

    # 设置工程顶层
    set_property top $top [current_fileset]
    set_property generic DEBUG=TRUE [current_fileset]

    set_property AUTO_INCREMENTAL_CHECKPOINT 1 [current_run -implementation]

    # 更新编译
    update_compile_order
}

# 自动化执行 Vivado 设计流程中的综合和实现
proc run_build {} {         
    upgrade_ip [get_ips]

    # Synthesis
    launch_runs -jobs 12 [current_run -synthesis]
    wait_on_run [current_run -synthesis]

    # Implementation
    launch_runs -jobs 12 [current_run -implementation] -to_step write_bitstream
    wait_on_run [current_run -implementation]
}

# 导出 xsa 文件  
proc run_dist {} {
    global projName
    global top

    # Copy binary files
    set prefix [get_property DIRECTORY [current_run -implementation]]
    #set bit_fn [format "%s/%s.bit" $prefix $top]
    #set dbg_fn [format "%s/debug_nets.ltx" $prefix]
    #file copy -force $bit_fn {./}
    #file copy -force $dbg_fn {./}

    # Export hardware
    # Before 2019.2
    #set sdk_path [format "%s/%s.sdk" $projName $projName]
    #set hdf_fn [format "%s/%s.hdf" $sdk_path $top]
    # Export with bitstream
    #set sysdef_fn [format "%s/%s.sysdef" $prefix $top]
    #file copy -force $sysdef_fn $hdf_fn
    # Export without bitstream
    #file mkdir $sdk_path
    #write_hwdef -force -file $hdf_fn
    # Post 2019.2
    set xsa_fn [format "%s.xsa" $projName]
    write_hw_platform -fixed -force -file $xsa_fn

    # Archieve project
    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    archive_project -force [format "%s_%s.xpr" [current_project] $timestamp]
}

