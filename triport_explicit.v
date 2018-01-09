`define CFG_RESET_SENSITIVITY
`define TRUE    1'b1
`define FALSE   1'b0

`define DATA_WIDTH 4
`define DATA_WIDTH_RANGE (`DATA_WIDTH - 1):0
`define REG_WIDTH 5
`define REG_WIDTH_RANGE (`REG_WIDTH - 1):0

module triport_explicit(
    input clk,
    input rst,
    input [`REG_WIDTH_RANGE] rd_addr1,
`ifdef TRIPORT
    input [`REG_WIDTH_RANGE] rd_addr2,
`endif
    input [`REG_WIDTH_RANGE] wr_addr,
    output [`DATA_WIDTH_RANGE] rd_data1,
`ifdef TRIPORT
    output [`DATA_WIDTH_RANGE] rd_data2,
`endif
    input [`DATA_WIDTH_RANGE] wr_data,
    input wen,
    input stall);

    wire [`REG_WIDTH_RANGE] rd_addr1;
    wire [`REG_WIDTH_RANGE] rd_addr2;
    wire [`REG_WIDTH_RANGE] wr_addr;

    wire [`DATA_WIDTH_RANGE] rd_data1;
    wire [`DATA_WIDTH_RANGE] rd_data2;

    wire [`DATA_WIDTH_RANGE] wr_data;


    reg [`DATA_WIDTH_RANGE] reg_data_live_0;
    reg [`DATA_WIDTH_RANGE] reg_data_buf_0;
    reg use_buf;                                    // Whether to use reg_data_live or reg_data_buf

    `ifdef TRIPORT
        reg [`DATA_WIDTH_RANGE] reg_data_live_1;
        reg [`DATA_WIDTH_RANGE] reg_data_buf_1;
    `endif

    wire [`DATA_WIDTH_RANGE] regfile_data_0;
    reg  regfile_raw_0, regfile_raw_0_nxt;

    reg [`DATA_WIDTH_RANGE]  w_result_d;

    `ifdef TRIPORT
        wire [`DATA_WIDTH_RANGE] regfile_data_1;
        reg regfile_raw_1, regfile_raw_1_nxt;
    `endif

    /*----------------------------------------------------------------------
     Check if read and write is being performed to same register in current
     cycle? This is done by comparing the read and write IDXs.
     ----------------------------------------------------------------------*/
    always @(wen or wr_addr or rd_addr2 or rd_addr1)
      begin
         if (wen
             && (wr_addr == rd_addr1))
           regfile_raw_0_nxt = 1'b1;
         else
           regfile_raw_0_nxt = 1'b0;

         `ifdef TRIPORT
             if (wen
                 && (wr_addr == rd_addr2))
               regfile_raw_1_nxt = 1'b1;
             else
               regfile_raw_1_nxt = 1'b0;
         `endif
      end

    /*----------------------------------------------------------------------
     Select latched (delayed) write value or data from register file. If
     read in previous cycle was performed to register written to in same
     cycle, then latched (delayed) write value is selected.
     ----------------------------------------------------------------------*/
    always @(regfile_raw_0 or wr_data or regfile_data_0)
      if (regfile_raw_0)
        reg_data_live_0 = w_result_d;
      else
        reg_data_live_0 = regfile_data_0;

    /*----------------------------------------------------------------------
     Select latched (delayed) write value or data from register file. If
     read in previous cycle was performed to register written to in same
     cycle, then latched (delayed) write value is selected.
     ----------------------------------------------------------------------*/
     `ifdef TRIPORT
         always @(regfile_raw_1 or w_result_d or regfile_data_1)
          if (regfile_raw_1)
            reg_data_live_1 = w_result_d;
          else
            reg_data_live_1 = regfile_data_1;
    `endif

    /*----------------------------------------------------------------------
     Latch value written to register file
     ----------------------------------------------------------------------*/
    always @(posedge clk)
        /* if (rst == `TRUE)
          begin
             regfile_raw_0 <= 1'b0;
             `ifdef TRIPORT
                regfile_raw_1 <= 1'b0;
             `endif
             w_result_d <= 32'b0;
          end
        else */
            begin
               regfile_raw_0 <= regfile_raw_0_nxt;
               `ifdef TRIPORT
                    regfile_raw_1 <= regfile_raw_1_nxt;
                `endif
               w_result_d <= wr_addr;
            end

    /*----------------------------------------------------------------------
     Register file instantiation as Pseudo-Dual Port EBRs.
     ----------------------------------------------------------------------*/
    // Modified by GSI: removed non-portable RAM instantiation
    lm32_ram
      #(
        // ----- Parameters -----
        .data_width(`DATA_WIDTH),
        .address_width(`REG_WIDTH)
        )
    reg_0
      (
       // ----- Inputs -----
       .read_clk      (clk),
       .write_clk     (clk),
       .reset         (rst),
       .enable_read   (`TRUE),
       .read_address  (rd_addr1),
       .enable_write  (`TRUE),
       .write_address (wr_addr),
       .write_data    (wr_data),
       .write_enable  (wen),
       // ----- Outputs -----
       .read_data     (regfile_data_0)
       );

    `ifdef TRIPORT
        lm32_ram
          #(
            .data_width(`DATA_WIDTH),
            .address_width(`REG_WIDTH)
            )
        reg_1
          (
           // ----- Inputs -----
           .read_clk      (clk),
           .write_clk     (clk),
           .reset         (rst),
           .enable_read   (`TRUE),
           .read_address  (rd_addr2),
           .enable_write  (`TRUE),
           .write_address (wr_addr),
           .write_data    (wr_data),
           .write_enable  (wen),
           // ----- Outputs -----
           .read_data     (regfile_data_1)
           );
    `endif

    assign rd_data1 = use_buf ? reg_data_buf_0 : reg_data_live_0;
    `ifdef TRIPORT
        assign rd_data2 = use_buf ? reg_data_buf_1 : reg_data_live_1;
    `endif


    always @(posedge clk)
    begin
        /* if (rst == `TRUE)
        begin
            use_buf <= `FALSE;
            reg_data_buf_0 <= {`DATA_WIDTH{1'b0}};
            //reg_data_buf_1 <= {`DATA_WIDTH{1'b0}};
        end
        else */
        begin
            if (stall == `FALSE)
                use_buf <= `FALSE;
            else if (use_buf == `FALSE)
            begin
                reg_data_buf_0 <= reg_data_live_0;
                `ifdef TRIPORT
                    reg_data_buf_1 <= reg_data_live_1;
                `endif
                use_buf <= `TRUE;
            end
            if (wen == `TRUE)
            begin
                if (wr_addr == rd_addr1)
                    reg_data_buf_0 <= wr_data;
                `ifdef TRIPORT
                    if (wr_addr == rd_addr2)
                        reg_data_buf_1 <= wr_data;
                `endif
            end
        end
    end
endmodule


module lm32_ram (
    // ----- Inputs -------
    read_clk,
    write_clk,
    reset,
    enable_read,
    read_address,
    enable_write,
    write_address,
    write_data,
    write_enable,
    // ----- Outputs -------
    read_data
    );

/*----------------------------------------------------------------------
 Parameters
 ----------------------------------------------------------------------*/
parameter data_width = 1;               // Width of the data ports
parameter address_width = 1;            // Width of the address ports
parameter init_file = "NONE";           // Initialization file

/*----------------------------------------------------------------------
 Inputs
 ----------------------------------------------------------------------*/
input read_clk;                         // Read clock
input write_clk;                        // Write clock
input reset;                            // Reset

input enable_read;                      // Access enable
input [address_width-1:0] read_address; // Read/write address
input enable_write;                     // Access enable
input [address_width-1:0] write_address;// Read/write address
input [data_width-1:0] write_data;      // Data to write to specified address
input write_enable;                     // Write enable

/*----------------------------------------------------------------------
 Outputs
 ----------------------------------------------------------------------*/
output [data_width-1:0] read_data;      // Data read from specified addess
wire   [data_width-1:0] read_data;

/*----------------------------------------------------------------------
 Internal nets and registers
 ----------------------------------------------------------------------*/
reg [data_width-1:0]    mem[0:(1<<address_width)-1]; // The RAM
reg [address_width-1:0] ra; // Registered read address

/*----------------------------------------------------------------------
 Combinational Logic
 ----------------------------------------------------------------------*/
// Read port
assign read_data = mem[ra];

/*----------------------------------------------------------------------
 Sequential Logic
 ----------------------------------------------------------------------*/
// Write port
always @(posedge write_clk)
    if ((write_enable == `TRUE) && (enable_write == `TRUE))
        mem[write_address] <= write_data;

// Register read address for use on next cycle
always @(posedge read_clk)
    if (enable_read)
        ra <= read_address;

endmodule
