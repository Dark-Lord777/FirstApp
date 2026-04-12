use std::ffi::c_char;
use std::ffi::{CString, CStr};
use std::os::raw::c_float;
//structure of wheell
static mut ROTATION: f32 = 0.0;
static mut SPEED: f32 = 0.0;
static mut SPINNING: bool = false;
//wheel 
#[no_mangle]
pub extern "C" fn wheel_reset() {
    unsafe {
        ROTATION = 0.0;
        SPEED = 0.0;
        SPINNING = false;
    }
}
//start a whelling? (вращение )
#[no_mangle]
pub extern "C" fn wheel_spin() {
    unsafe {
        if !SPINNING {
            SPINNING = true;
            SPEED = 8.0;
        }
    }
}
//this function should look like as loop in maxroquad bibliotecs(blja kak picat na angl.. mda)
//#[no_mangle]
pub extern "C" fn wheel_update() {
    unsafe {
        if SPINNING {
            ROTATION -= SPEED;
            SPEED *= 0.99;

            if SPEED < 0.005 {
                SPINNING = false;
            }
        }
    }
}//look and and karoche aaa give a angl
#[no_mangle]
pub extern "C" fn wheel_get_rotation() -> c_float {
    unsafe { ROTATION }
}
//spining
#[no_mangle]
pub extern "C" fn wheel_is_spinning() -> bool {
    unsafe { SPINNING }
}

