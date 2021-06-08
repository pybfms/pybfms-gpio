/****************************************************************************
 * gpio_bfm.v
 * 
 * Provides support for interacting with signals from the testbench, as 
 * well as controlling pin muxing for BFMs to/from the design
 ****************************************************************************/

module gpio_bfm #(
		// Total number of bins
		parameter N_PINS=8,
		// Candidates that can be multiplexed
		parameter N_BANKS=1
        ) (
        input                           clock,
        input                           reset,
        
        input[N_PINS-1:0]				pin_i,
        output[N_PINS-1:0]              pin_o,
        output[N_PINS-1:0]              pin_oe,
        
        output[N_PINS*N_BANKS-1:0]		banks_i,
        input[N_PINS*N_BANKS-1:0]		banks_o,
        input[N_PINS*N_BANKS-1:0]		banks_oe
        );

	reg[N_PINS-1:0]			gpio_out       = {N_PINS{1'b0}};
	reg[N_PINS-1:0]			gpio_out_r     = {N_PINS{1'b0}};
	reg[N_PINS-1:0]			gpio_oe        = {N_PINS{1'b0}};
	reg[N_PINS-1:0]			gpio_oe_r      = {N_PINS{1'b0}};
	wire[N_PINS-1:0]		gpio_in        = pin_i;
	
	reg[N_PINS-1:0]			gpio_in_last_r = {N_PINS{1'b0}};
	reg[N_PINS-1:0]			banksel_en     = {N_PINS{1'b0}};
	reg[N_PINS-1:0]			banksel_en_r   = {N_PINS{1'b0}};
	
	reg[1:0]                propagate_req_r = {2{1'b0}};
	reg						propagate_req = 0;
	
    reg            			in_reset = 0;
    
    reg[3:0]				banksel[N_PINS-1:0];
    reg[3:0]				banksel_r[N_PINS-1:0];
    
	localparam BANKSEL_WIDTH = 4; // TODO:
	
	generate
		genvar banksel_ii;
		for (banksel_ii=0; banksel_ii<N_PINS; banksel_ii=banksel_ii+1) begin
			always @(posedge clock or posedge reset) begin
				if (reset) begin
					banksel[banksel_ii] <= 0;
					banksel_r[banksel_ii] = 0;
				end else begin
					banksel[banksel_ii] <= banksel_r[banksel_ii];
				end
			end
		end
	endgenerate
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            in_reset <= 1;
            propagate_req <= 0;
            propagate_req_r = {2{1'b0}};
        end else begin
            if (in_reset) begin
                _reset();
                in_reset <= 1'b0;
            end
            gpio_out <= gpio_out_r;
            gpio_oe <= gpio_oe_r;
            banksel_en <= banksel_en_r;
            propagate_req <= propagate_req_r;
            
            if (propagate_req) begin
            	_propagate_ack();
            	propagate_req_r = propagate_req_r - 1;
            end
            
            if (gpio_in_last_r !== gpio_in) begin
            	_set_gpio_in(gpio_in);
            	gpio_in_last_r <= gpio_in;
            end
        end
    end
    
    generate
    	genvar pin_ii, bank_ii;
    	for (pin_ii=0; pin_ii<N_PINS; pin_ii=pin_ii+1) begin
    		always @(posedge clock) begin
    			if (reset) begin
    				banksel[pin_ii] <= {BANKSEL_WIDTH{1'b0}};
    				banksel_en[pin_ii] <= 1'b0;     // Default is to connect GPIO
    				gpio_out[pin_ii] <= 1'b0;
    				gpio_oe[pin_ii] <= 1'b0;  // Default is for pin in input mode
    			end else begin
//    				if (rt_we && !rt_adr[0] && rt_adr[RT_ADR_WIDTH-1:1] == pin_ii) begin
//    					banksel[pin_ii] <= rt_dat_w[BANKSEL_WIDTH-1:0];
//    					banksel_en[pin_ii] <= rt_dat_w[8];
//    					gpio_out[pin_ii] <= rt_dat_w[9];
//    					gpio_oe[pin_ii] <= rt_dat_w[10];
//    				end
    			end
    		end

    		assign pin_o[pin_ii]  = (banksel_en[pin_ii])?banks_o[banksel[pin_ii]]:gpio_out[pin_ii];
    		assign pin_oe[pin_ii] = (banksel_en[pin_ii])?banks_oe[banksel[pin_ii]]:gpio_oe[pin_ii];
    		always @* begin
    			if (banksel_en[pin_ii]) begin
    			end else begin
    			end
    		end
    		for (bank_ii=0; bank_ii<N_BANKS; bank_ii=bank_ii+1) begin
    			// Connect inputs back
    			assign banks_i[N_PINS*bank_ii+pin_ii] = 
    				(banksel_en[pin_ii] && banksel[pin_ii]==bank_ii)?pin_i[N_PINS*bank_ii+pin_ii]:1'b0;
    		end
    	end
    endgenerate
    
    task _propagate_req;
    	propagate_req_r = 1;
    endtask
    
    task _set_banksel_en(input reg[63:0] val);
    	banksel_en_r = val;
   	endtask
   	
   	task _set_banksel(input reg[31:0] idx, input reg[7:0] sel);
   		banksel_r[idx] = sel;
   	endtask
   	
    task _set_gpio_out(input reg[63:0] val);
    	gpio_out_r = val;
    endtask
    
    task _set_gpio_oe(input reg[63:0] val);
    	gpio_oe_r = val;
    endtask
        
    task init;
    begin
        $display("%0t: gpio_bfm: %m", $time);
        // TODO: pass parameter values
        _set_parameters(N_PINS, N_BANKS);
      	_set_gpio_in(gpio_in);
    end
    endtask
	
    // Auto-generated code to implement the BFM API
`ifdef PYBFMS_GEN
${pybfms_api_impl}
`endif

endmodule
