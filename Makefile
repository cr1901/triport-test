.PHONY: induct inferred explicit

induct:
	yosys -ql induct.log -s yosys/induct.ys

inferred:
	yosys -ql inferred.log -s yosys/inferred.ys

explicit:
	yosys -ql explicit.log -s yosys/explicit.ys

clean:
	rm triport_*_*.* *.log
