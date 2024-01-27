
GHDL = docker run -it --rm --mount type=bind,source=$(shell pwd),target=/src -w=/src ghdl/vunit:llvm ghdl
SRC = \
	  src/packet_check.vhd \

OBJ = $(SRC:vhd=o)

GHDL_OPT = -v --std=93

build: $(SRC)
	$(GHDL) -a $(GHDL_OPT) $(SRC)

clean:
	rm -f *.o work-*.cf

