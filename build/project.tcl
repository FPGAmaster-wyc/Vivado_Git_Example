# Product Version: Vivado v2019.2 (64-bit)
# 使用教程：在对应的vivado下面，Tcl console界面，cd进入build.Tcl目录，然后table，然后source ./build.tcl即可
set projName Aurora_xdma_ddr	
set part xc7z100ffg900-2	
set top top	
set tb_top tb_ddr_data_sim

proc run_create {} {
    global projName
    global part
    global top
    global tb_top

    set outputDir ./$projName			

    file mkdir $outputDir

    create_project $projName $outputDir -part $part -force		

    set projDir [get_property directory [current_project]]

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
	
    add_files -fileset [current_fileset] -force -norecurse {
        ../ip/vio_7series/vio_7series.xci
        ../ip/aurora_64b66b_0.xcix
        ../ip/aurora_64b66b_0_reg_slice_0.xcix
		../ip/aurora_64b66b_0_reg_slice_2.xcix
		../ip/clk_wiz_0.xcix
		../ip/ila_0.xcix
		../ip/ila_7series.xcix
    }

    add_files -fileset [get_filesets sim_1] -force -norecurse {
        ../src/tb_ddr_data_sim.v
    }

    add_files -fileset [current_fileset -constrset] -force -norecurse {
        ../src/top.xdc
    }
	
	set_property ip_repo_paths "../ip/axi_lite_4reg_1.0" [current_project]
	update_ip_catalog

    source {../bd/bd.tcl}

    set_property top $tb_top [get_filesets sim_1]
    set_property top_lib xil_defaultlib [get_filesets sim_1]
    update_compile_order -fileset sim_1

    set_property top $top [current_fileset]
    set_property generic DEBUG=TRUE [current_fileset]

    set_property AUTO_INCREMENTAL_CHECKPOINT 1 [current_run -implementation]

    update_compile_order
}

proc run_build {} {         
    upgrade_ip [get_ips]

    # Synthesis
    launch_runs -jobs 12 [current_run -synthesis]
    wait_on_run [current_run -synthesis]

    # Implementation
    launch_runs -jobs 12 [current_run -implementation] -to_step write_bitstream
    wait_on_run [current_run -implementation]
}


