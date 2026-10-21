//! User preferences, stored as JSON in the `settings` table.

use rusqlite::{params, Connection, OptionalExtension};
use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DuplicatePolicy {
    /// Save silently.
    Allow,
    /// Save, but show a warning.
    Warn,
    /// Refuse to save the same number twice under one product.
    Block,
}

impl DuplicatePolicy {
    pub const ALL: [DuplicatePolicy; 3] = [Self::Allow, Self::Warn, Self::Block];

    pub fn label(self) -> &'static str {
        match self {
            Self::Allow => "Allow",
            Self::Warn => "Warn",
            Self::Block => "Block",
        }
    }
}

#[derive(Clone, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct Settings {
    pub staff_name: String,
    pub branch: String,
    pub min_digits: u8,
    pub max_digits: u8,
    pub duplicate_policy: DuplicatePolicy,
    pub ui_scale: f32,
    pub check_updates_on_start: bool,
    pub export_folder: String,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            staff_name: String::new(),
            branch: String::new(),
            min_digits: 9,
            max_digits: 12,
            duplicate_policy: DuplicatePolicy::Warn,
            ui_scale: 1.0,
            check_updates_on_start: true,
            export_folder: String::new(),
        }
    }
}

const KEY: &str = "app";

pub fn init(conn: &Connection) -> rusqlite::Result<()> {
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS settings (
             key   TEXT PRIMARY KEY,
             value TEXT NOT NULL
         );",
    )
}

pub fn load(conn: &Connection) -> Settings {
    conn.query_row("SELECT value FROM settings WHERE key = ?1", [KEY], |r| {
        r.get::<_, String>(0)
    })
    .optional()
    .ok()
    .flatten()
    .and_then(|json| serde_json::from_str(&json).ok())
    .unwrap_or_default()
}

pub fn save(conn: &Connection, s: &Settings) -> rusqlite::Result<()> {
    let json = serde_json::to_string(s).unwrap_or_default();
    conn.execute(
        "INSERT INTO settings (key, value) VALUES (?1, ?2)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value",
        params![KEY, json],
    )?;
    Ok(())
}
