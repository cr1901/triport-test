.PHONY: all inferred explicit

all: inferred explicit

inferred:
	yosys -ql inferred.log -s yosys/inferred.ys

explicit:
	yosys -ql explicit.log -s yosys/explicit.ys

clean:
	rm triport_*_*.* *.log
