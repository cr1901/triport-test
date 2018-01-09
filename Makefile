inferred:
	yosys -ql inferred.log -s yosys/inferred.ys

clean:
	rm triport_*_*.* *.log
