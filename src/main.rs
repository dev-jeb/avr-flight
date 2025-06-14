#![no_std]
#![no_main]

use avr_flight::delay;
use avr_flight::port;

#[panic_handler]
pub fn panic(_panic: &core::panic::PanicInfo) -> ! {
    loop {}
}

#[unsafe(no_mangle)]
pub extern "C" fn main() -> ! {
    let mut port = port::portb::init();
    port.set_pin_mode(5, true);
    port.set_pin_state(5, true);
    loop {
        port.set_pin_state(5, !port.read_pin(5));
        delay::delay(100000);
    }
}
