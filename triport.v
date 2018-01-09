`define DATA_WIDTH_RANGE 3:0
`define REG_WIDTH 5
`define REG_WIDTH_RANGE (`REG_WIDTH - 1):0

module triport(input clk, input rst, input [`REG_WIDTH_RANGE] rd_addr1,
`ifdef TRIPORT
    input [`REG_WIDTH_RANGE] rd_addr2,
`endif
    input [`REG_WIDTH_RANGE] wr_addr, output [`DATA_WIDTH_RANGE] rd_data1,
`ifdef TRIPORT
    output [`DATA_WIDTH_RANGE] rd_data2,
`endif
    input [`DATA_WIDTH_RANGE] wr_data, input wen, input stall);

    wire [`REG_WIDTH_RANGE] rd_addr1;
    `ifdef TRIPORT
        wire [`REG_WIDTH_RANGE] rd_addr2;
    `endif
    wire [`REG_WIDTH_RANGE] reg_rd_addr1;
    `ifdef TRIPORT
        wire [`REG_WIDTH_RANGE] reg_rd_addr2;
    `endif
    wire [`REG_WIDTH_RANGE] wr_addr;

    `ifdef WRITE_FIRST
        wire [`DATA_WIDTH_RANGE] rd_data1;

        `ifdef TRIPORT
            wire [`DATA_WIDTH_RANGE] rd_data2;
        `endif
    `else
        `ifdef READ_FIRST
            reg [`DATA_WIDTH_RANGE] rd_data1;

            `ifdef TRIPORT
                reg [`DATA_WIDTH_RANGE] rd_data2;
            `endif
        `endif
    `endif

    wire [`DATA_WIDTH_RANGE] wr_data;

    reg [`DATA_WIDTH_RANGE] registers [(1 << `REG_WIDTH) - 1:0];

    always @(posedge clk) begin
        `ifdef READ_FIRST
            rd_data1 <= registers[rd_addr1];

            `ifdef TRIPORT
                rd_data2 <= registers[rd_addr2];
            `endif
        `endif

        if (wen) begin
            registers[wr_addr] <= wr_data;
        end

        // Required so yosys knows reads are synchronous. yosys will
        // refuse to infer a block RAM otherwise b/c it can't prove
        // that reads are synchronous from this module alone without these
        // statements.
        `ifdef WRITE_FIRST
            if(!stall) begin
                reg_rd_addr1 <= rd_addr1;

                `ifdef TRIPORT
                    reg_rd_addr2 <= rd_addr2;
                `endif
            end
        `endif
    end

`ifdef WRITE_FIRST
    assign rd_data1 = registers[reg_rd_addr1];

    `ifdef TRIPORT
        assign rd_data2 = registers[reg_rd_addr2];
    `endif
`endif

endmodule
