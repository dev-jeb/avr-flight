// src/port.rs

use core::ptr::{read_volatile, write_volatile};

/// Represents a port on the AVR microcontroller
pub struct Port {
    ddr: *mut u8,   // Data Direction Register
    port: *mut u8,  // Port Register
    pin: *const u8, // Pin Register, const because it's read only
}

impl Port {
    /// Creates a new Port instance
    ///
    /// # Safety
    /// The caller must ensure the register addresses are valid for the target microcontroller
    pub unsafe fn new(ddr_addr: u16, port_addr: u16, pin_addr: u16) -> Self {
        Port {
            ddr: ddr_addr as *mut u8,
            port: port_addr as *mut u8,
            pin: pin_addr as *const u8,
        }
    }

    /// Sets the direction of a pin (input or output)
    pub fn set_pin_mode(&mut self, pin: u8, is_output: bool) {
        unsafe {
            let current = read_volatile(self.ddr);
            let new = if is_output {
                current | (1 << pin)
            } else {
                current & !(1 << pin)
            };
            write_volatile(self.ddr, new);
        }
    }

    /// Sets the output state of a pin (high or low)
    pub fn set_pin_state(&mut self, pin: u8, is_high: bool) {
        unsafe {
            let current = read_volatile(self.port);
            let new = if is_high {
                current | (1 << pin)
            } else {
                current & !(1 << pin)
            };
            write_volatile(self.port, new);
        }
    }

    /// Reads the input state of a pin
    pub fn read_pin(&self, pin: u8) -> bool {
        unsafe {
            let value = read_volatile(self.pin);
            (value & (1 << pin)) != 0
        }
    }
}

// Example usage for Port B
pub mod portb {
    use super::Port;

    // These addresses are for ATmega328p
    const DDRB: u16 = 0x24;
    const PORTB: u16 = 0x25;
    const PINB: u16 = 0x23;

    pub fn init() -> Port {
        unsafe { Port::new(DDRB, PORTB, PINB) }
    }
}
