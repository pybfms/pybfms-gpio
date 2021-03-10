
import pybfms

@pybfms.bfm(hdl={
    pybfms.BfmType.Verilog : pybfms.bfm_hdl_path(__file__, "hdl/gpio_bfm.v"),
    pybfms.BfmType.SystemVerilog : pybfms.bfm_hdl_path(__file__, "hdl/gpio_bfm.v"),
    }, has_init=True)
class GpioBfm():

    def __init__(self):
        self.busy = pybfms.lock()
        self.is_reset = False
        self.reset_ev = pybfms.event()
        self.n_pins = 0
        self.n_banks = 0
        self._gpio_in = 0
        self._gpio_out = 0
        
        self.ev = pybfms.event()
        pass
        
    @pybfms.export_task(pybfms.uint32_t, pybfms.uint32_t)
    def _set_parameters(self, n_pins, n_banks):
        self.n_pins = n_pins
        self.n_banks = n_banks
        pass
    
    async def propagate(self):
        await self.busy.acquire()
        self._propagate_req()
        await self.ev.wait()
        self.ev.clear()
        self.busy.release()
    
    def set_gpio_out_bit(self, idx, v):
        if (v):
            self._gpio_out |= (1 << idx)
        else:
            self._gpio_out &= ~(1 << idx)
        self._set_gpio_out(self._gpio_out)
    
    @pybfms.export_task(pybfms.uint64_t)
    def _set_gpio_in(self, gpio_in):
        self._gpio_in = gpio_in
        
    @pybfms.import_task(pybfms.uint64_t)
    def _set_gpio_out(self, gpio_out):
        pass
   
    @pybfms.import_task()
    def _propagate_req(self):
        pass
    
    @pybfms.export_task()
    def _propagate_ack(self):
        self.ev.set()
        
        
    @pybfms.export_task()
    def _reset(self):
        self.is_reset = True
        self.reset_ev.set()
        
        
