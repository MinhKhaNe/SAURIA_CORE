VSIM = vsim
VLOG = vlog
VLIB = vlib
VMAP = vmap

WORK = work
TOP  = tb_processing_element

RTL_F = rtl.f
TB_SRC = $(TOP).sv

run: compile simulate

$(WORK):
	$(VLIB) $(WORK)
	$(VMAP) $(WORK) $(WORK)

compile: $(WORK)
	$(VLOG) -sv -f $(RTL_F) $(TB_SRC)

simulate:
	$(VSIM) -c $(TOP) -do "run -all; quit"

gui:
	$(VSIM) $(TOP)

clean:
	rm -rf $(WORK) transcript vsim.wlf *.log *.vcd

wave:
	$(VSIM) -voptargs=+acc $(TOP) -do "add wave -r sim:/tb_processing_element/*; run -all"
