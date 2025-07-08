use std::collections::{BTreeMap, BTreeSet};

use crop::Rope;
use flutter_rust_bridge::frb;

#[frb(type_64bit_int)]
pub struct Buffer {
    text: Rope,
    pub version: usize,
    line_lengths: BTreeMap<usize, usize>,
    // (length, line_index)
    length_index_set: BTreeSet<(usize, usize)>,
}

impl Buffer {
    #[frb(sync)]
    pub fn new() -> Self {
        let mut line_lengths = BTreeMap::new();
        let mut length_index_set = BTreeSet::new();

        line_lengths.insert(0, 0);
        length_index_set.insert((0, 0));

        Self {
            text: Rope::new(),
            version: 0,
            line_lengths,
            length_index_set,
        }
    }

    #[frb(sync, type_64bit_int)]
    pub fn insert(&mut self, row: usize, column: usize, text: String) -> (usize, usize) {
        let char_idx = self.row_column_to_idx(row, column);
        self.text.insert(char_idx, &text);
        self.version += 1;

        let new_idx = char_idx + text.chars().count();
        let (new_row, new_column) = self.idx_to_row_column(new_idx);

        self.update_line_lengths(row, new_row);

        (new_row, new_column)
    }

    fn update_line_lengths(&mut self, start_row: usize, end_row: usize) {
        if start_row == end_row {
            self.update_single_line_length(start_row);
        } else {
            for i in start_row..=end_row {
                self.update_single_line_length(i);
            }
        }
    }

    fn update_single_line_length(&mut self, row: usize) {
        if let Some(&old_length) = self.line_lengths.get(&row) {
            self.length_index_set.remove(&(old_length, row));
        }

        let new_length = self.actual_line_len(row);

        self.line_lengths.insert(row, new_length);
        self.length_index_set.insert((new_length, row));
    }

    #[frb(sync, type_64bit_int)]
    pub fn remove_char(&mut self, row: usize, column: usize) -> (usize, usize) {
        let char_idx = self.row_column_to_idx(row, column);
        if char_idx == 0 {
            return (row, column);
        }

        self.text.delete(char_idx - 1..char_idx);
        self.version += 1;

        let new_idx = char_idx - 1;
        let (new_row, new_column) = self.idx_to_row_column(new_idx);

        self.update_line_lengths(row, new_row);

        (new_row, new_column)
    }

    #[frb(sync, type_64bit_int)]
    pub fn remove_range(
        &mut self,
        start_row: usize,
        start_column: usize,
        end_row: usize,
        end_column: usize,
    ) -> (usize, usize) {
        let start_idx = self.row_column_to_idx(start_row, start_column);
        let end_idx = self.row_column_to_idx(end_row, end_column);

        self.text.delete(start_idx..end_idx);
        self.version += 1;

        self.update_line_lengths(start_row, end_row);

        (start_row, start_column)
    }

    #[frb(sync, type_64bit_int)]
    pub fn text_in_range(
        &self,
        start_row: usize,
        start_column: usize,
        end_row: usize,
        end_column: usize,
    ) -> String {
        if self.line_count() == 0 {
            return "".to_string();
        }

        let start_idx = self.row_column_to_idx(start_row, start_column);
        let end_idx = self.row_column_to_idx(end_row, end_column);

        self.text.byte_slice(start_idx..end_idx).to_string()
    }

    #[frb(sync, type_64bit_int)]
    pub fn row_column_to_idx(&self, row: usize, column: usize) -> usize {
        let line_start_idx = self.text.byte_of_line(row);
        line_start_idx + column
    }

    #[frb(sync, type_64bit_int)]
    pub fn idx_to_row_column(&self, idx: usize) -> (usize, usize) {
        let row = self.text.line_of_byte(idx);
        let line_idx = self.text.byte_of_line(row);
        let column = idx - line_idx;
        (row, column)
    }

    #[frb(sync, type_64bit_int)]
    pub fn line_count(&self) -> usize {
        self.text.line_len()
    }

    #[frb(sync, type_64bit_int)]
    pub fn line_len(&self, row: usize) -> usize {
        self.line_lengths.get(&row).unwrap_or(&0).clone()
    }

    fn actual_line_len(&self, row: usize) -> usize {
        if row >= self.line_count() {
            0
        } else {
            self.text.line(row).byte_len()
        }
    }

    #[frb(sync)]
    pub fn to_string(&self) -> String {
        self.text.to_string()
    }

    #[frb(sync, type_64bit_int)]
    pub fn max_line_length(&self) -> usize {
        self.length_index_set
            .last()
            .map(|(length, _)| *length)
            .unwrap_or(0)
    }
}
