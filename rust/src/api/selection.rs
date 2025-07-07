use flutter_rust_bridge::frb;

use super::cursor::Cursor;

#[frb(dart_metadata=("freezed", "immutable" import "package:meta/meta.dart" as meta), type_64bit_int)]
#[derive(Clone, Copy)]
pub struct Selection {
    pub start: Cursor,
    pub end: Cursor,
}

impl Default for Selection {
    #[frb(sync)]
    fn default() -> Self {
        Self {
            start: Cursor::default(),
            end: Cursor::default(),
        }
    }
}

impl Selection {
    #[frb(sync)]
    pub fn new(start: Cursor, end: Cursor) -> Self {
        Self { start, end }
    }

    #[frb(sync)]
    pub fn normalized(&self) -> Self {
        if self.start.row == self.end.row && self.start.column > self.end.column
            || self.start.row > self.end.row
        {
            Self {
                start: self.end,
                end: self.start,
            }
        } else {
            *self
        }
    }

    #[frb(sync)]
    pub fn is_empty(&self) -> bool {
        self.start == self.end
    }
}
