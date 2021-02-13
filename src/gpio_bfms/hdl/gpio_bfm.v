
/****************************************************************************
 * gpio_bfm.v
 * 
 ****************************************************************************/

module gpio_bfm #(
		parameter WIDTH=8
        ) (
        input                           clock,
        input                           reset,
        input[WIDTH-1:0]				gpio_in,
        output[WIDTH-1:0]				gpio_out
        );
	
	reg[WIDTH-1:0]		gpio_out_r = {WIDTH{1'b0}};
	reg[WIDTH-1:0]		gpio_in_last_r = {WIDTH{1'b0}};
	
	assign gpio_out = gpio_out_r;
        
    reg            in_reset = 0;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            in_reset <= 1;
        end else begin
            if (in_reset) begin
                _reset();
                in_reset <= 1'b0;
            end
            if (gpio_in_last_r !== gpio_in) begin
            	_set_gpio_in(gpio_in);
            	gpio_in_last_r <= gpio_in;
            end
        end
    end
    
    task _set_gpio_out(input reg[63:0] val);
    	gpio_out_r = val;
    endtask
        
    task init;
    begin
        $display("gpio_bfm: %m");
        // TODO: pass parameter values
        _set_parameters(WIDTH);
    end
    endtask
	
    // Auto-generated code to implement the BFM API
`ifdef PYBFMS_GEN
${pybfms_api_impl}
`endif

endmodule
