// qsys_sdram_a2.v

// Generated using ACDS version 12.0 178 at 2012.10.29.15:53:30

`define IDLE  2'b00
`define READ  2'b01
`define WRITE 2'b10

`timescale 1 ps / 1 ps
module sdram_a2 
  (
   // Interface from controller to SDRAM Chip
   output wire [ 12: 0] 	       zs_addr,
   output wire [ 1: 0] 		       zs_ba,
   output wire 			       zs_cas_n,
   output wire 			       zs_cke,
   output wire 			       zs_cs_n,
   inout wire [ 31: 0] 		       zs_dq,
   output wire [ 3: 0] 		       zs_dqm,
   output wire 			       zs_ras_n,
   output wire 			       zs_we_n,
		
		`ifdef SYNTH
   output wire 			       altpll_0_c0_clk,
		`else
   output reg 			       altpll_0_c0_clk,
		`endif

		// Interface from caches
   input wire 			       read, write,
   input wire [24:0] 		       addr_in,
   input wire [31:0] 		       data_in,
   output wire [31:0] 		       za_data,
   input wire [$clog2(`maxTrans)-1: 0] size, 
   output wire 			       readValid, 

		// temp write error flag
   output wire 			       write_error,
		
   input wire 			       reset_reset_n, // reset.reset_n
   input wire 			       clk_clk        //   clk.clk
   );
		


   wire 		     btn0, btn1;
   wire 		     btn0_n, btn1_n;
   assign btn0_n = ~btn0;
   assign btn1_n = ~btn1;
   
   /*
    negedge_detector btn0_ned(.ed(btn0), .in(btns[0]), .clk(clk_clk), .rst_b(reset_reset_n));
    negedge_detector btn1_ned(.ed(btn1), .in(btns[1]), .clk(clk_clk), .rst_b(reset_reset_n));
    */
   
   //wire [31:0] za_data;
   wire 		     za_valid;
   wire 		     za_waitrequest;
   
   //	always @(posedge clk_clk) assert(!(write & za_waitrequest)); // TODO: uncomment this later
   assign readValid = za_valid;
   
   wire [7:0] 		     reg_data, reg_data_next;
   //assign LEDs = reg_data;
   
   assign readValid = za_valid;
   assign reg_data_next = (za_valid) ? za_data[7:0] : reg_data;
   ff_ar #(8,8'b0) za_data_reg(.q(reg_data), .d(reg_data_next), .clk(clk_clk), .rst(~reset_reset_n));
   
   //wire    altpll_0_c0_clk;                    // altpll_0:c0 -> [rst_controller:clk, sdram_0:clk]
   wire 		     rst_controller_reset_out_reset;     // rst_controller:reset_out -> sdram_0:reset_n
   wire 		     rst_controller_001_reset_out_reset; // rst_controller_001:reset_out -> altpll_0:reset
   
   reg 			     re_n, we_n;
   reg [24:0] 		     addr, nextAddr;
   reg [31:0] 		     data, nextData;
   reg [$clog2(`maxTrans)-1:0] count, nextCount;
   reg [ 1:0] 		       state, nextState;
   //reg writeValid, readValid;	
   
   assign write_error = ~we_n && (data != addr);
   
   // TODO: test arbitrary length reads and writes
   // TODO: figure out if burst length configurable and implement
   // TODO: write arbiter for SDRAM ctrl
   // TODO: figure out if latency changes based on consecutive address
   //	 reading and writing
   always @* begin
      nextCount = count; re_n = 1; we_n = 1;
      //		readValid = za_valid; 	
      nextAddr = 0; nextData = 0; nextCount = 0;
      case(state)
	`IDLE:begin
	   if(read) begin
	      nextCount = count + 1'b1;
	      nextAddr = addr_in;
	      nextState = `READ;
	   end
	   else if(write) begin
	      nextCount = count + 1'b1;
	      nextAddr = addr_in;
	      nextData = data_in;
	      nextState = `WRITE;
	   end
	   else nextState = `IDLE;
	end
	`READ:begin
	   re_n = 0;
	   if(za_waitrequest) begin
	      nextCount = count;
	      nextAddr = addr;
	      re_n = 1;
	      nextState = `READ;
	   end
	   else if(count == size) begin	
	      nextCount = 0;
	      nextAddr = 0;
	      nextState = `IDLE;
	   end
	   else if(count < size) begin
	      nextCount = count + 1'b1;
	      nextAddr = addr + 1'b1;
	      nextState = `READ;
	   end
	   else begin
	      re_n = 1;
	      nextCount = 0;
	      nextAddr = 0;
	      nextState = `IDLE;
	   end
	end
	`WRITE:begin
	   we_n = 0;
	   if(za_waitrequest) begin
	      nextCount = count;
	      nextAddr = addr;
	      nextData = data;
	      we_n = 1;
	      nextState = `WRITE;
	   end
	   // Only support 1 word writes as of now
	   else if(count == 1) begin	
	      nextCount = 0;
	      nextAddr = 0;
	      nextData = 0;
	      nextState = `IDLE;
	   end
	   else if(count < size) begin
	      nextCount = count + 1'b1;
	      nextAddr = addr + 1'b1;
	      nextData = data_in;
	      nextState = `WRITE;
	   end
	   else begin
	      we_n = 1;
	      nextCount = 0;
	      nextAddr = 0;
	      nextData = 0;
	      nextState = `IDLE;
	   end
	end
	default: begin 
	   nextCount = 0;
	   nextState = `IDLE;
	end
      endcase
   end
   
   
   always @(posedge clk_clk, negedge reset_reset_n) begin
      if(~reset_reset_n) begin
	 addr <= 'h0;
	 data <= 'h0;
	 count <= 'h0;
	 state <= `IDLE;
      end
      else begin
	 addr <= nextAddr;
	 data <= nextData;
	 count <= nextCount;
	 state <= nextState;
      end
   end
   
   qsys_sdram_a2_sdram_0 sdram_0 
     (
      .clk            (clk_clk),                         //   clk.clk
      .reset_n        (~rst_controller_reset_out_reset), // reset.reset_n
      .az_addr        (addr),                            //    s1.address
      .az_be_n        (4'b0000),                         //      .byteenable_n
      .az_cs          (1'b1),                            //      .chipselect
      .az_data        (data),                            //      .writedata
      .az_rd_n        (re_n),                            //      .read_n
      .az_wr_n        (we_n),                            //      .write_n
      .za_data        (za_data),                         //      .readdata
      .za_valid       (za_valid),                        //      .readdatavalid
      .za_waitrequest (za_waitrequest),                  //      .waitrequest
      .zs_addr        (zs_addr),                         //  wire.export
      .zs_ba          (zs_ba),                           //      .export
      .zs_cas_n       (zs_cas_n),                        //      .export
      .zs_cke         (zs_cke),                          //      .export
      .zs_cs_n        (zs_cs_n),                         //      .export
      .zs_dq          (zs_dq),                           //      .export
      .zs_dqm         (zs_dqm),                          //      .export
      .zs_ras_n       (zs_ras_n),                        //      .export
      .zs_we_n        (zs_we_n)                          //      .export
      );
   
		`ifdef SYNTH
   qsys_sdram_a2_altpll_0 altpll_0 
     (
      .clk       (clk_clk),                   //   inclk_interface.clk
      .reset     (rst_controller_001_reset_out_reset), // inclk_interface_reset
      .read      (),                          //         pll_slave.read
      .write     (),                          //                  .write
      .address   (),                          //                  .address
      .readdata  (),                          //                  .readdata
      .writedata (),                          //                  .writedata
      .c0        (altpll_0_c0_clk),           //                c0.clk
      .areset    (),                          //    areset_conduit.export
      .locked    (),                          //    locked_conduit.export
      .phasedone ()                           // phasedone_conduit.export     
      );
		`else
   // SKETCHY AS FUCK
   // #delay is totally hacked to make za_valid coincide with za_data
   always @(clk_clk) begin // used to be posedge or negedge
      altpll_0_c0_clk <= #0 clk_clk;
   end
		`endif
   
   altera_reset_controller 
     #(
       .NUM_RESET_INPUTS        (1),
       .OUTPUT_RESET_SYNC_EDGES ("deassert"),
       .SYNC_DEPTH              (2)
       ) 
   rst_controller 
     (
      .reset_in0  (~reset_reset_n),                 // reset_in0.reset
      .clk        (altpll_0_c0_clk),                //       clk.clk
      .reset_out  (rst_controller_reset_out_reset), // reset_out.reset
      .reset_in1  (1'b0),                           // (terminated)
      .reset_in2  (1'b0),                           // (terminated)
      .reset_in3  (1'b0),                           // (terminated)
      .reset_in4  (1'b0),                           // (terminated)
      .reset_in5  (1'b0),                           // (terminated)
      .reset_in6  (1'b0),                           // (terminated)
      .reset_in7  (1'b0),                           // (terminated)
      .reset_in8  (1'b0),                           // (terminated)
      .reset_in9  (1'b0),                           // (terminated)
      .reset_in10 (1'b0),                           // (terminated)
      .reset_in11 (1'b0),                           // (terminated)
      .reset_in12 (1'b0),                           // (terminated)
      .reset_in13 (1'b0),                           // (terminated)
      .reset_in14 (1'b0),                           // (terminated)
      .reset_in15 (1'b0)                            // (terminated)
      );
   
   altera_reset_controller 
     #(
       .NUM_RESET_INPUTS        (1),
       .OUTPUT_RESET_SYNC_EDGES ("deassert"),
       .SYNC_DEPTH              (2)
       ) 
   rst_controller_001 
     (
      .reset_in0  (~reset_reset_n),                     // reset_in0.reset
      .clk        (clk_clk),                            //       clk.clk
      .reset_out  (rst_controller_001_reset_out_reset), // reset_out.reset
      .reset_in1  (1'b0),                               // (terminated)
      .reset_in2  (1'b0),                               // (terminated)
      .reset_in3  (1'b0),                               // (terminated)
      .reset_in4  (1'b0),                               // (terminated)
      .reset_in5  (1'b0),                               // (terminated)
      .reset_in6  (1'b0),                               // (terminated)
      .reset_in7  (1'b0),                               // (terminated)
      .reset_in8  (1'b0),                               // (terminated)
      .reset_in9  (1'b0),                               // (terminated)
      .reset_in10 (1'b0),                               // (terminated)
      .reset_in11 (1'b0),                               // (terminated)
      .reset_in12 (1'b0),                               // (terminated)
      .reset_in13 (1'b0),                               // (terminated)
      .reset_in14 (1'b0),                               // (terminated)
      .reset_in15 (1'b0)                                // (terminated)
      );
   
endmodule
