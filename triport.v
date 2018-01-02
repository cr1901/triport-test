`define DATA_WIDTH_RANGE 7:0
`define REG_WIDTH 5
`define REG_WIDTH_RANGE (`REG_WIDTH - 1):0

module triport(input clk, input rst, input [`REG_WIDTH_RANGE] rd_addr1,
    input [`REG_WIDTH_RANGE] rd_addr2, input [`REG_WIDTH_RANGE] wr_addr,
    output [`DATA_WIDTH_RANGE] rd_data1, output [`DATA_WIDTH_RANGE] rd_data2,
    input [`DATA_WIDTH_RANGE] wr_data, input wen);

    wire [`REG_WIDTH_RANGE] rd_addr1;
    wire [`REG_WIDTH_RANGE] rd_addr2;
    wire [`REG_WIDTH_RANGE] reg_rd_addr1;
    wire [`REG_WIDTH_RANGE] reg_rd_addr2;
    wire [`REG_WIDTH_RANGE] wr_addr;

    `ifdef WRITE_FIRST
        wire [`DATA_WIDTH_RANGE] rd_data1;
        wire [`DATA_WIDTH_RANGE] rd_data2;
    `else
        `ifdef READ_FIRST
            reg [`DATA_WIDTH_RANGE] rd_data1;
            reg [`DATA_WIDTH_RANGE] rd_data2;
        `endif
    `endif

    wire [`DATA_WIDTH_RANGE] wr_data;

    reg [`DATA_WIDTH_RANGE] registers [(1 << `REG_WIDTH) - 1:0];

    always @(posedge clk) begin
        `ifdef READ_FIRST
            rd_data1 <= registers[rd_addr1];
            rd_data2 <= registers[rd_addr2];
        `endif

        if (wen) begin
            registers[wr_addr] <= wr_data;
        end

        // Required so yosys knows reads are synchronous. yosys will
        // refuse to infer a block RAM otherwise b/c it can't prove
        // that reads are synchronous from this module alone without these
        // statements.
        `ifdef WRITE_FIRST
            reg_rd_addr1 <= rd_addr1;
            reg_rd_addr2 <= rd_addr2;
        `endif
    end

`ifdef WRITE_FIRST
    assign rd_data1 = registers[reg_rd_addr1];
    assign rd_data2 = registers[reg_rd_addr2];
`endif

endmodule
