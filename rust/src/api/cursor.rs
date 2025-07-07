use flutter_rust_bridge::frb;

#[frb(type_64bit_int)]
pub struct Cursor {
    pub row: usize,
    pub column: usize,
    pub sticky_column: usize,
}

impl Default for Cursor {
    #[frb(sync)]
    fn default() -> Self {
        Self {
            row: 0,
            column: 0,
            sticky_column: 0,
        }
    }
}

impl Cursor {
    #[frb(sync, type_64bit_int)]
    pub fn new(row: usize, column: usize, sticky_column: usize) -> Self {
        Self {
            row,
            column,
            sticky_column,
        }
    }
}
