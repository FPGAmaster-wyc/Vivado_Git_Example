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

