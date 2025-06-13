#![no_std]
#![no_main]

mod port;

#[panic_handler]
fn panic(_panic: &core::panic::PanicInfo) -> ! {
    loop {}
}

fn delay(cycles: u32) {
    let mut i = 0;
    while i < cycles {
        i += 1;
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn main() -> ! {
    let mut port = port::portb::init();
    port.set_pin_mode(5, true);
    port.set_pin_state(5, true);
    loop {
        port.set_pin_state(5, !port.read_pin(5));
        delay(100000);
    }
}
