use rand::Rng;
use std::f32::consts::PI;

static mut ROTATION: f32 = 0.0;
static mut SPEED: f32 = 0.0;
static mut SPINNING: bool = false;
static mut SECTORS: Vec<String> = Vec::new();

#[no_mangle]
pub extern "C" fn add_sector(ptr: *const u8, len: usize) {
    let slice = unsafe { std::slice::from_raw_parts(ptr, len) };
    let name = String::from_utf8_lossy(slice).to_string();

    unsafe {
        if SECTORS.len() < 8 && !name.is_empty() {
            SECTORS.push(name);
        }
    }
}

#[no_mangle]
pub extern "C" fn start_spin() {
    unsafe {
        if !SECTORS.is_empty() {
            SPINNING = true;
            SPEED = 8.0 + rand::thread_rng().gen_range(0.0..2.0);
        }
    }
}

#[no_mangle]
pub extern "C" fn update() -> f32 {
    unsafe {
        if SPINNING {
            ROTATION -= SPEED;
            SPEED *= 0.99;

            if SPEED.abs() < 0.005 {
                SPINNING = false;
            }
        }

        ROTATION
    }
}

#[no_mangle]
pub extern "C" fn get_winner() -> i32 {
    unsafe {
        if SPINNING || SECTORS.is_empty() {
            return -1;
        }

        let two_pi = 2.0 * PI;
        let angle = (ROTATION % two_pi + two_pi) % two_pi;
        let index = (angle / (two_pi / SECTORS.len() as f32)) as i32;

        index
    }
}
