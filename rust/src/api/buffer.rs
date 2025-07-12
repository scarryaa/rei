use crop::Rope;
use flutter_rust_bridge::frb;
use rand::Rng;
use std::collections::{BTreeMap, BTreeSet};

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

        let version: u32 = rand::rng().random();

        Self {
            text: Rope::new(),
            version: version as usize,
            line_lengths,
            length_index_set,
        }
    }

    #[frb(sync)]
    pub fn from(text: String) -> Self {
        let mut line_lengths = BTreeMap::new();
        let mut length_index_set = BTreeSet::new();

        for (i, line) in text.lines().enumerate() {
            let line_length = line.len();

            line_lengths.insert(i, line_length);
            length_index_set.insert((line_length, i));
        }

        let version: u32 = rand::rng().random();

        Self {
            text: Rope::from(text),
            version: version as usize,
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

        self.update_line_lengths_range(row, new_row);

        (new_row, new_column)
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

        self.update_line_lengths_range(new_row.min(row), new_row.max(row));

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
        let mut end_idx = self.row_column_to_idx(end_row, end_column);
        let should_clear =
            self.line_count() == 0 || self.line_count() - 1 == end_row && start_row == 0;

        if should_clear {
            end_idx = self.text.byte_len();
        }

        self.text.delete(start_idx..end_idx);
        self.version += 1;

        if should_clear {
            self.line_lengths.clear();
            self.length_index_set.clear();

            if self.text.byte_len() == 0 {
                self.line_lengths.insert(0, 0);
                self.length_index_set.insert((0, 0));
            }
        } else {
            self.rebuild_line_lengths_from(start_row);
        }

        (start_row, start_column)
    }

    fn update_line_lengths_range(&mut self, start_row: usize, end_row: usize) {
        for row in start_row..=end_row {
            self.update_single_line_length(row);
        }
    }

    fn update_single_line_length(&mut self, row: usize) {
        let new_length = self.actual_line_len(row);

        if let Some(&old_length) = self.line_lengths.get(&row) {
            if old_length != new_length {
                self.length_index_set.remove(&(old_length, row));
                self.length_index_set.insert((new_length, row));
            }
        } else {
            self.length_index_set.insert((new_length, row));
        }

        self.line_lengths.insert(row, new_length);
    }

    fn rebuild_line_lengths_from(&mut self, start_row: usize) {
        let keys_to_remove: Vec<usize> = self
            .line_lengths
            .range(start_row..)
            .map(|(&row, &length)| {
                self.length_index_set.remove(&(length, row));
                row
            })
            .collect();

        for row in keys_to_remove {
            self.line_lengths.remove(&row);
        }

        let line_count = self.line_count();
        for row in start_row..line_count {
            self.update_single_line_length(row);
        }
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
    pub fn text_in_range_char_offset(
        &self,
        start_row: usize,
        end_row: usize,
        start_char_offset: usize,
        end_char_offset: usize,
    ) -> String {
        if self.line_count() == 0 || start_row >= end_row {
            return String::new();
        }

        if end_row - start_row == 1 {
            let line = self.text.line(start_row);
            let line_len = line.byte_len();

            if start_char_offset >= line_len {
                return String::new();
            }

            let slice_end = end_char_offset.min(line_len);
            if start_char_offset < slice_end {
                return line.byte_slice(start_char_offset..slice_end).to_string();
            }
            return String::new();
        }

        let mut parts = Vec::with_capacity(end_row - start_row);

        for row in start_row..end_row {
            let line = self.text.line(row);
            let line_len = line.byte_len();

            if start_char_offset >= line_len {
                parts.push("".to_string());
                continue;
            }

            let slice_end = end_char_offset.min(line_len);
            if start_char_offset < slice_end {
                parts.push(line.byte_slice(start_char_offset..slice_end).to_string());
            } else {
                parts.push("".to_string());
            }
        }

        parts.join("\n")
    }

    #[frb(sync, type_64bit_int)]
    pub fn row_column_to_idx(&self, row: usize, column: usize) -> usize {
        if self.line_count() == 0 {
            return 0;
        }

        let line_start_idx = self.text.byte_of_line(row);
        line_start_idx + column
    }

    #[frb(sync, type_64bit_int)]
    pub fn byte_of_line(&self, row: usize) -> usize {
        if self.line_count() == 0 {
            return 0;
        }

        self.text.byte_of_line(row)
    }

    #[frb(sync, type_64bit_int)]
    pub fn idx_to_row_column(&self, idx: usize) -> (usize, usize) {
        if self.line_count() == 0 {
            return (0, 0);
        }

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
    pub fn line_count_with_trailing_newline(&self) -> usize {
        let extra_newline =
            if self.text.byte_len() != 0 && self.text.byte(self.text.byte_len() - 1) == b'\n' {
                1
            } else {
                0
            };
        self.text.line_len() + extra_newline
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
