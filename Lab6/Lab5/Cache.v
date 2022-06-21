`include "DataMemory.v"
`include "opcodes.v"


module Cache #(parameter LINE_SIZE = 16,
               parameter NUM_SETS = 16,
               parameter NUM_WAYS = 1) (
    input reset,
    input clk,

    input is_input_valid,
    input [31:0] addr,
    input mem_read,
    input mem_write,
    input [31:0] din,

    output is_ready,
    output reg is_output_valid,
    output reg [31:0] dout,
    output reg is_hit);

  // Wire declarations
  wire [1:0]bit_offset;
  wire [1:0]block_offset;
  wire [3:0]index;
  wire [23:0]tag;
  wire [LINE_SIZE * 8 -1: 0] dmem_dout;
  wire tag_hit;
  wire is_valid;
  wire is_dirty;

  // wire for dmem
  //wire dmem_input_valid;
  wire is_data_mem_ready;
  wire dmem_output_valid;

  // Reg declarations
  reg [LINE_SIZE * 8 -1: 0] Cache_line[0: LINE_SIZE-1];
  reg valid_bit[0: LINE_SIZE-1];
  reg dirty_bit[0: LINE_SIZE-1];
  reg [23:0]tag_bit[0: LINE_SIZE-1];

  // You might need registers to keep the status.
  // 00 is for IDLE, 01 is for evicting data
  // 10 is for reading data from DMEM, 11 is for errored state
  reg [1:0]state;
  reg miss;
  reg dmem_input_valid;
  reg dmem_read;
  reg dmem_write;
  reg [31:0]dmem_addr; // tag(24) + index(4) = total 28 bit 
  reg [LINE_SIZE * 8 -1 : 0] dmem_din;

  integer i;

  // Assignments
  assign bit_offset = addr[1:0];
  assign block_offset = addr[3:2];
  assign index = addr[7:4];
  assign tag = addr[31:8];

  assign tag_hit = tag_bit[index] == tag;
  assign is_valid = valid_bit[index];
  assign is_dirty = dirty_bit[index];

  assign is_ready = is_data_mem_ready;

  always@(*) begin
    // read hit or write hit
    if(is_input_valid && is_valid && tag_hit && !miss) begin
        case (block_offset)
          0 : dout = Cache_line[index][31:0];
          1 : dout = Cache_line[index][63:32];
          2 : dout = Cache_line[index][95:64];
          3 : dout = Cache_line[index][127:96];
        endcase
        is_hit = 1;
        is_output_valid = 1;
        dmem_input_valid = 0;
        dmem_read = 0;
        dmem_write = 0;
    end

    // read miss, write miss
    else if(is_input_valid && (!is_valid || !tag_hit || miss) ) begin
      is_output_valid = 0;
      is_hit = 0;
    end

    else if(!is_input_valid) begin
      is_hit = 1;
      is_output_valid = 1;
    end


  end


  always@(posedge clk) begin
    if(reset) begin //reset
        miss <= 0;
        state <= `Idle;
        dmem_input_valid <= 0;
        for(i = 0 ; i < LINE_SIZE ; i = i + 1) begin
          Cache_line[i] <= 0;
          valid_bit[i] <= 0;
          dirty_bit[i] <= 0;
          tag_bit[i] <= 0;
        end
    end

    else if(is_input_valid)begin //state transition
      if(state == `Idle) begin
        //dirty -> evict
        if(is_input_valid && is_dirty && is_valid && !tag_hit ) begin
          state <= `Fetch;
          miss <= 1;
          dmem_input_valid <= 1;
          dmem_write <= 1;
          dmem_read <= 0;
          dmem_addr <= {4'd0, tag_bit[index], index};
          dmem_din <= Cache_line[index];
          dirty_bit[index] <= 0;
          valid_bit[index] <= 0;
        end

        //clean or read miss
        else if(is_input_valid && (!is_valid || (!is_dirty && !tag_hit) )) begin
          state <= `Read_dmem;
          dmem_input_valid <= 1;
          dmem_read <= 1;
          miss <= 1;
          dmem_addr <= {4'd0, tag, index};
        end

        else if(mem_write && is_valid && tag_hit) begin
          case (block_offset)
            0: Cache_line[index][31:0] <= din;
            1: Cache_line[index][63:32] <= din;
            2: Cache_line[index][95:64] <= din;
            3: Cache_line[index][127:96] <= din;
          endcase
          dirty_bit[index] <= 1;
        end

        else begin
          state <= `Idle;
        end
      end

      else if(state == `Evict) begin // evict state
        dmem_input_valid <= 0;
        dmem_write <= 0;
        dmem_read <= 0;
        if(is_data_mem_ready) begin
          state <= `Read_dmem;
          dmem_input_valid <= 1;
          dmem_read <= 1;
          dmem_addr <= {4'd0, tag, index};
        end
        else begin
          state <= `Evict;
        end
      end

      else if(state == `Read_dmem) begin // read state
        dmem_input_valid <= 0;
        dmem_write <= 0;
        dmem_read <= 0;
        if(dmem_output_valid && is_data_mem_ready) begin
          state <= `Idle;
          Cache_line[index] <= dmem_dout;
          valid_bit[index] <= 1;
          tag_bit[index] <= tag;
          dirty_bit[index] <= 0;
          miss <= 0;
      end
        else begin
          state <= `Read_dmem;
        end
    end


      else if(state == `Fetch) begin
        state <= `Evict;
      end


      else
        state<= state;
    end
end




  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),
    // send inputs to the data memory.
    .is_input_valid(dmem_input_valid),
    .addr(dmem_addr),        // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read(dmem_read), 
    .mem_write(dmem_write),
    .din(dmem_din), // din has to have 16Byte Size
    .is_output_valid(dmem_output_valid),
    .dout(dmem_dout),
    // is data memory ready to accept request?
    .mem_ready(is_data_mem_ready)
  );
endmodule
