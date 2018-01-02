ice40:
	yosys -ql ice40.log -s yosys/ice40.ys

xilinx:
	yosys -ql xilinx.log -s yosys/xilinx.ys

clean:
	rm triport_*_*.* *.log abc.history
