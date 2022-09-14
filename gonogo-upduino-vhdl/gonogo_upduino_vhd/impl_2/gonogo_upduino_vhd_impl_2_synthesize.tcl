if {[catch {

# define run engine funtion
source [file join {C:/lscc/radiant/3.2} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) 1
set para(prj_dir) "C:/Users/duodi/Documents/Personnel/electronique/fpga-cpld/lattice/gonogo-upduino-vhdl/gonogo_upduino_vhd"
# synthesize IPs
# synthesize VMs
# synthesize top design
file delete -force -- gonogo_upduino_vhd_impl_2.vm gonogo_upduino_vhd_impl_2.ldc
run_engine_newmsg synthesis -f "gonogo_upduino_vhd_impl_2_lattice.synproj"
run_postsyn [list -a iCE40UP -p iCE40UP5K -t SG48 -sp High-Performance_1.2V -oc Industrial -top -w -o gonogo_upduino_vhd_impl_2_syn.udb gonogo_upduino_vhd_impl_2.vm] "C:/Users/duodi/Documents/Personnel/electronique/fpga-cpld/lattice/gonogo-upduino-vhdl/gonogo_upduino_vhd/impl_2/gonogo_upduino_vhd_impl_2.ldc"

} out]} {
   runtime_log $out
   exit 1
}
