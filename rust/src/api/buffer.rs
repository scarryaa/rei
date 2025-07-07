use flutter_rust_bridge::frb;
use ropey::Rope;

#[frb(type_64bit_int)]
pub struct Buffer {
    text: Rope,
    pub version: usize,
}

impl Buffer {
    #[frb(sync)]
    pub fn new() -> Self {
        Self {
            text: Rope::new(),
            version: 0,
        }
    }

    #[frb(sync, type_64bit_int)]
    pub fn insert(&mut self, row: usize, column: usize, text: String) -> (usize, usize) {
        let char_idx = self.row_column_to_idx(row, column);
        self.text.insert(char_idx, &text);
        self.version += 1;

        let new_idx = char_idx + text.chars().count();
        let (new_row, new_column) = self.idx_to_row_column(new_idx);
        (new_row, new_column)
    }

    #[frb(sync, type_64bit_int)]
    pub fn row_column_to_idx(&self, row: usize, column: usize) -> usize {
        let line_start_idx = self.text.line_to_char(row);
        line_start_idx + column
    }

    #[frb(sync, type_64bit_int)]
    pub fn idx_to_row_column(&self, idx: usize) -> (usize, usize) {
        let row = self.text.char_to_line(idx);
        let column = idx - row;
        (row, column)
    }

    #[frb(sync)]
    pub fn to_string(&self) -> String {
        self.text.to_string()
    }
}
