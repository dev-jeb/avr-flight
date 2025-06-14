/// Simple busy-wait delay function
/// This is a very basic delay that wastes CPU cycles
pub fn delay(cycles: u32) {
    let mut i = 0;
    while i < cycles {
        i += 1;
    }
}
