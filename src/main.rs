#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use eframe::egui::{self, Color32, RichText, Stroke};
use egui_phosphor::regular as icon;
use rusqlite::{params, Connection};
use std::path::PathBuf;

mod settings;
mod updater;

use settings::{DuplicatePolicy, Settings};

// ---------- Design tokens (Swiss / minimal, dark slate + HNB amber) ----------
mod theme {
    use eframe::egui::Color32;
    // Colours taken from hnb.lk
    pub const BG: Color32 = Color32::from_rgb(0xF0, 0xF4, 0xF7);
    pub const PANEL: Color32 = Color32::from_rgb(0xFF, 0xFF, 0xFF);
    pub const CARD: Color32 = Color32::from_rgb(0xFF, 0xFF, 0xFF);
    pub const MUTED: Color32 = Color32::from_rgb(0xEA, 0xEF, 0xF2);
    pub const BORDER: Color32 = Color32::from_rgb(0xD4, 0xDA, 0xE0);
    pub const FG: Color32 = Color32::from_rgb(0x2C, 0x2F, 0x31);
    pub const FG_MUTED: Color32 = Color32::from_rgb(0x5E, 0x62, 0x66);
    pub const PRIMARY: Color32 = Color32::from_rgb(0x00, 0x60, 0xAF); // HNB blue
    pub const ON_PRIMARY: Color32 = Color32::from_rgb(0xFF, 0xFF, 0xFF);
    pub const CYAN: Color32 = Color32::from_rgb(0x00, 0xA2, 0xE8);
    pub const PURPLE: Color32 = Color32::from_rgb(0x4A, 0x1B, 0x78);
    pub const SUCCESS: Color32 = Color32::from_rgb(0x15, 0x80, 0x3D);
    pub const DANGER: Color32 = Color32::from_rgb(0xDC, 0x26, 0x26);
    pub const WARN: Color32 = Color32::from_rgb(0xB4, 0x53, 0x09);
    pub const SKY: Color32 = Color32::from_rgb(0x00, 0x7D, 0xB8);
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Bank {
    Hnb,
    Other,
}

impl Bank {
    fn label(self) -> &'static str {
        match self {
            Bank::Hnb => "HNB",
            Bank::Other => "Other Bank",
        }
    }
    fn icon(self) -> &'static str {
        match self {
            Bank::Hnb => icon::BANK,
            Bank::Other => icon::BUILDINGS,
        }
    }
    fn code(self) -> &'static str {
        match self {
            Bank::Hnb => "HNB",
            Bank::Other => "OTHER",
        }
    }
    fn from_code(s: &str) -> Self {
        if s == "HNB" {
            Bank::Hnb
        } else {
            Bank::Other
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
#[allow(clippy::enum_variant_names)] // names mirror the product brand
enum Product {
    SoloMax,
    SoloCard,
    SoloBankAcc,
}

impl Product {
    const ALL: [Product; 3] = [Product::SoloMax, Product::SoloCard, Product::SoloBankAcc];

    fn label(self) -> &'static str {
        match self {
            Product::SoloMax => "Solo Max",
            Product::SoloCard => "Solo Credit/Debit Card",
            Product::SoloBankAcc => "Solo Bank Acc",
        }
    }
    fn code(self) -> &'static str {
        match self {
            Product::SoloMax => "SOLO_MAX",
            Product::SoloCard => "SOLO_CARD",
            Product::SoloBankAcc => "SOLO_BANK_ACC",
        }
    }
    fn from_code(s: &str) -> Self {
        match s {
            "SOLO_CARD" => Product::SoloCard,
            "SOLO_BANK_ACC" => Product::SoloBankAcc,
            _ => Product::SoloMax,
        }
    }
    fn icon(self) -> &'static str {
        match self {
            Product::SoloMax => icon::LIGHTNING,
            Product::SoloCard => icon::CREDIT_CARD,
            Product::SoloBankAcc => icon::BANK,
        }
    }
    fn color(self) -> Color32 {
        match self {
            Product::SoloMax => theme::PURPLE,
            Product::SoloCard => theme::SKY,
            Product::SoloBankAcc => theme::SUCCESS,
        }
    }
}

#[derive(Clone)]
struct Entry {
    id: i64,
    phone: String,
    bank: Bank,
    product: Product,
    timestamp: String,
}

// ---------- SQLite storage ----------
struct Db {
    conn: Connection,
    path: PathBuf,
}

impl Db {
    fn open() -> rusqlite::Result<Self> {
        let base = std::env::var_os("APPDATA")
            .map(PathBuf::from)
            .unwrap_or_else(|| PathBuf::from("."));
        let dir = base.join("HNB Solo Tracker");
        let _ = std::fs::create_dir_all(&dir);
        let path = dir.join("hnb_solo_tracker.db");
        let conn = Connection::open(&path)?;
        conn.execute_batch(
            "PRAGMA journal_mode=WAL;
             CREATE TABLE IF NOT EXISTS entries (
                 id         INTEGER PRIMARY KEY AUTOINCREMENT,
                 phone      TEXT NOT NULL,
                 bank       TEXT NOT NULL,
                 product    TEXT NOT NULL,
                 created_at TEXT NOT NULL
             );
             CREATE INDEX IF NOT EXISTS idx_entries_product ON entries(product);",
        )?;
        settings::init(&conn)?;
        let db = Self { conn, path };
        db.migrate_json(&dir.join("data.json"));
        Ok(db)
    }

    /// One-time import of the old data.json store from v0.1.
    fn migrate_json(&self, json_path: &PathBuf) {
        let Ok(text) = std::fs::read_to_string(json_path) else {
            return;
        };
        let Ok(v) = serde_json::from_str::<serde_json::Value>(&text) else {
            return;
        };
        let Some(items) = v["entries"].as_array() else {
            return;
        };
        for e in items {
            let bank = match e["bank"].as_str() {
                Some("Hnb") => Bank::Hnb,
                _ => Bank::Other,
            };
            let product = match e["product"].as_str() {
                Some("SoloCard") => Product::SoloCard,
                Some("SoloBankAcc") => Product::SoloBankAcc,
                _ => Product::SoloMax,
            };
            let _ = self.insert(
                e["phone"].as_str().unwrap_or_default(),
                bank,
                product,
                e["timestamp"].as_str().unwrap_or_default(),
            );
        }
        let _ = std::fs::rename(json_path, json_path.with_extension("json.migrated"));
    }

    fn insert(&self, phone: &str, bank: Bank, product: Product, ts: &str) -> rusqlite::Result<()> {
        self.conn.execute(
            "INSERT INTO entries (phone, bank, product, created_at) VALUES (?1, ?2, ?3, ?4)",
            params![phone, bank.code(), product.code(), ts],
        )?;
        Ok(())
    }

    fn delete(&self, id: i64) -> rusqlite::Result<()> {
        self.conn
            .execute("DELETE FROM entries WHERE id = ?1", params![id])?;
        Ok(())
    }

    /// Writes a consistent copy of the database to `dest`.
    fn backup(&self, dest: &std::path::Path) -> rusqlite::Result<()> {
        let _ = std::fs::remove_file(dest);
        self.conn
            .execute("VACUUM INTO ?1", params![dest.to_string_lossy()])?;
        Ok(())
    }

    fn clear(&self) -> rusqlite::Result<()> {
        self.conn.execute("DELETE FROM entries", [])?;
        Ok(())
    }

    fn all(&self) -> rusqlite::Result<Vec<Entry>> {
        let mut stmt = self
            .conn
            .prepare("SELECT id, phone, bank, product, created_at FROM entries ORDER BY id")?;
        let rows = stmt.query_map([], |r| {
            Ok(Entry {
                id: r.get(0)?,
                phone: r.get(1)?,
                bank: Bank::from_code(&r.get::<_, String>(2)?),
                product: Product::from_code(&r.get::<_, String>(3)?),
                timestamp: r.get(4)?,
            })
        })?;
        rows.collect()
    }
}

// ---------- App state ----------
enum Step {
    Idle,
    ChooseBank { phone: String },
    ChooseProduct { phone: String, bank: Bank },
}

#[derive(PartialEq)]
enum Tab {
    Columns,
    Transactions,
    Settings,
}

#[derive(Clone, Copy)]
enum Tone {
    Ok,
    Warn,
    Err,
}

struct App {
    db: Db,
    entries: Vec<Entry>,
    phone_input: String,
    step: Step,
    tab: Tab,
    search: String,
    status: Option<(String, Tone)>,
    focus_input: bool,
    confirm_clear: bool,
    update: Option<updater::Shared>,
    startup_check_done: bool,
    settings: Settings,
    applied_scale: f32,
}

fn csv_field(s: &str) -> String {
    if s.contains([',', '"', '\n']) {
        format!("\"{}\"", s.replace('"', "\"\""))
    } else {
        s.to_string()
    }
}

impl App {
    fn new(db: Db) -> Self {
        let mut app = Self {
            db,
            entries: Vec::new(),
            phone_input: String::new(),
            step: Step::Idle,
            tab: Tab::Columns,
            search: String::new(),
            status: None,
            focus_input: true,
            confirm_clear: false,
            update: None,
            startup_check_done: false,
            settings: Settings::default(),
            applied_scale: 0.0,
        };
        app.settings = settings::load(&app.db.conn);
        app.reload();
        app
    }

    fn reload(&mut self) {
        match self.db.all() {
            Ok(v) => self.entries = v,
            Err(e) => self.status = Some((format!("Database read failed: {e}"), Tone::Err)),
        }
    }

    fn count(&self, product: Product, bank: Option<Bank>) -> usize {
        self.entries
            .iter()
            .filter(|e| e.product == product && bank.is_none_or(|b| e.bank == b))
            .count()
    }

    fn submit_phone(&mut self) {
        let phone: String = self
            .phone_input
            .chars()
            .filter(|c| c.is_ascii_digit() || *c == '+')
            .collect();
        let digits = phone.chars().filter(|c| c.is_ascii_digit()).count();
        let (min, max) = (
            self.settings.min_digits as usize,
            self.settings.max_digits as usize,
        );
        if !(min..=max).contains(&digits) {
            let rule = if min == max {
                format!("{min} digits")
            } else {
                format!("{min}–{max} digits")
            };
            self.status = Some((format!("Enter a valid phone number ({rule})."), Tone::Err));
            self.focus_input = true;
            return;
        }
        self.status = None;
        self.step = Step::ChooseBank { phone };
    }

    fn add_entry(&mut self, phone: String, bank: Bank, product: Product) {
        let duplicate = self
            .entries
            .iter()
            .any(|e| e.phone == phone && e.product == product);
        if duplicate && self.settings.duplicate_policy == DuplicatePolicy::Block {
            self.status = Some((
                format!("{phone} is already in {}. Not saved.", product.label()),
                Tone::Err,
            ));
            self.step = Step::Idle;
            self.focus_input = true;
            return;
        }
        let duplicate = duplicate && self.settings.duplicate_policy == DuplicatePolicy::Warn;
        let ts = chrono::Local::now().format("%Y-%m-%d %H:%M:%S").to_string();
        if let Err(e) = self.db.insert(&phone, bank, product, &ts) {
            self.status = Some((format!("Could not save: {e}"), Tone::Err));
            return;
        }
        self.reload();
        self.status = Some(if duplicate {
            (
                format!(
                    "{phone} added to {} — already existed in this column",
                    product.label()
                ),
                Tone::Warn,
            )
        } else {
            (
                format!("{phone} added to {} · {}", product.label(), bank.label()),
                Tone::Ok,
            )
        });
        self.phone_input.clear();
        self.step = Step::Idle;
        self.focus_input = true;
    }

    fn export_csv(&mut self) {
        let Some(path) = rfd::FileDialog::new()
            .set_file_name(format!(
                "hnb_solo_transactions_{}.csv",
                chrono::Local::now().format("%Y%m%d")
            ))
            .add_filter("CSV", &["csv"])
            .set_directory(self.export_dir())
            .save_file()
        else {
            return;
        };
        let mut out = String::from("No,Date Time,Phone Number,Bank,Product\n");
        for (i, e) in self.entries.iter().enumerate() {
            out.push_str(&format!(
                "{},{},{},{},{}\n",
                i + 1,
                csv_field(&e.timestamp),
                // Excel-friendly so leading zeros are kept
                csv_field(&format!("=\"{}\"", e.phone)),
                csv_field(e.bank.label()),
                csv_field(e.product.label())
            ));
        }
        out.push_str("\nSummary,HNB,Other Bank,Total\n");
        for p in Product::ALL {
            out.push_str(&format!(
                "{},{},{},{}\n",
                csv_field(p.label()),
                self.count(p, Some(Bank::Hnb)),
                self.count(p, Some(Bank::Other)),
                self.count(p, None)
            ));
        }
        out.push_str(&format!("Grand Total,,,{}\n", self.entries.len()));
        out.push('\n');
        if !self.settings.staff_name.trim().is_empty() {
            out.push_str(&format!(
                "Staff,{}\n",
                csv_field(self.settings.staff_name.trim())
            ));
        }
        if !self.settings.branch.trim().is_empty() {
            out.push_str(&format!(
                "Branch,{}\n",
                csv_field(self.settings.branch.trim())
            ));
        }
        out.push_str(&format!(
            "Exported,{}\n",
            chrono::Local::now().format("%Y-%m-%d %H:%M:%S")
        ));
        self.status = Some(match std::fs::write(&path, out) {
            Ok(_) => (format!("Exported to {}", path.display()), Tone::Ok),
            Err(e) => (format!("Export failed: {e}"), Tone::Err),
        });
    }

    // ---------- Views ----------
    fn header(&mut self, ui: &mut egui::Ui, dialog_open: bool) {
        ui.add_space(14.0);
        ui.horizontal(|ui| {
            // Brand mark
            let (rect, _) = ui.allocate_exact_size(egui::vec2(58.0, 36.0), egui::Sense::hover());
            ui.painter().rect_filled(rect, 6.0, theme::PRIMARY);
            ui.painter().text(
                rect.center(),
                egui::Align2::CENTER_CENTER,
                "HNB",
                egui::FontId::proportional(18.0),
                theme::ON_PRIMARY,
            );
            ui.add_space(6.0);
            ui.vertical(|ui| {
                ui.label(
                    RichText::new("HNB Solo Tracker")
                        .size(20.0)
                        .strong()
                        .color(theme::FG),
                );
                ui.label(
                    RichText::new(chrono::Local::now().format("%A, %d %B %Y").to_string())
                        .size(12.5)
                        .color(theme::FG_MUTED),
                );
            });
            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                if self.confirm_clear {
                    if secondary_button(ui, &format!("{}  Cancel", icon::X)).clicked() {
                        self.confirm_clear = false;
                    }
                    if danger_button(ui, &format!("{}  Delete everything", icon::TRASH)).clicked() {
                        match self.db.clear() {
                            Ok(_) => self.status = Some(("All entries cleared.".into(), Tone::Ok)),
                            Err(e) => self.status = Some((format!("Clear failed: {e}"), Tone::Err)),
                        }
                        self.reload();
                        self.confirm_clear = false;
                    }
                    ui.label(RichText::new("Delete all entries permanently?").color(theme::DANGER));
                } else {
                    if secondary_button(ui, &format!("{}  Clear all", icon::TRASH)).clicked() {
                        self.confirm_clear = true;
                    }
                    let in_settings = self.tab == Tab::Settings;
                    let label = format!("{}  Settings", icon::GEAR_SIX);
                    let clicked = if in_settings {
                        primary_button(ui, &label).clicked()
                    } else {
                        secondary_button(ui, &label).clicked()
                    };
                    if clicked {
                        self.tab = if in_settings {
                            Tab::Columns
                        } else {
                            Tab::Settings
                        };
                    }
                    if primary_button(ui, &format!("{}  Export CSV", icon::FILE_CSV)).clicked() {
                        self.export_csv();
                    }
                }
            });
        });
        ui.add_space(14.0);

        if self.tab == Tab::Settings {
            if let Some((msg, tone)) = &self.status {
                status_line(ui, msg, *tone);
                ui.add_space(8.0);
            }
            return;
        }

        // Entry bar
        surface(ui, |ui| {
            ui.add_enabled_ui(!dialog_open, |ui| {
                ui.label(
                    RichText::new(format!("{}  Phone number", icon::PHONE))
                        .size(13.0)
                        .strong()
                        .color(theme::FG_MUTED),
                );
                ui.add_space(4.0);
                ui.horizontal(|ui| {
                    let resp = ui.add(
                        egui::TextEdit::singleline(&mut self.phone_input)
                            .hint_text("07X XXX XXXX")
                            .font(egui::FontId::monospace(22.0))
                            .margin(egui::vec2(12.0, 10.0))
                            .desired_width(320.0),
                    );
                    if self.focus_input && !dialog_open {
                        resp.request_focus();
                        self.focus_input = false;
                    }
                    let enter = resp.lost_focus() && ui.input(|i| i.key_pressed(egui::Key::Enter));
                    if ui
                        .add(sized(
                            primary(
                                RichText::new(format!("Next  {}", icon::ARROW_RIGHT)).size(16.0),
                            ),
                            120.0,
                            46.0,
                        ))
                        .clicked()
                        || enter
                    {
                        self.submit_phone();
                    }
                    ui.add_space(12.0);
                    ui.label(
                        RichText::new(format!(
                            "{} Enter   {}   choose bank   {}   choose product",
                            icon::KEY_RETURN,
                            icon::CARET_RIGHT,
                            icon::CARET_RIGHT
                        ))
                        .size(12.5)
                        .color(theme::FG_MUTED),
                    );
                });
                if let Some((msg, tone)) = &self.status {
                    ui.add_space(6.0);
                    let (col, mark) = match tone {
                        Tone::Ok => (theme::SUCCESS, icon::CHECK_CIRCLE),
                        Tone::Warn => (theme::WARN, icon::WARNING),
                        Tone::Err => (theme::DANGER, icon::X_CIRCLE),
                    };
                    ui.label(
                        RichText::new(format!("{mark}  {msg}"))
                            .size(13.5)
                            .color(col),
                    );
                }
            });
        });
        ui.add_space(14.0);
    }

    fn summary_cards(&self, ui: &mut egui::Ui) {
        ui.columns(4, |cols| {
            for (i, p) in Product::ALL.into_iter().enumerate() {
                stat_card(
                    &mut cols[i],
                    p.icon(),
                    p.label(),
                    self.count(p, None),
                    p.color(),
                    &format!(
                        "HNB {}   ·   Other {}",
                        self.count(p, Some(Bank::Hnb)),
                        self.count(p, Some(Bank::Other))
                    ),
                );
            }
            let hnb = self.entries.iter().filter(|e| e.bank == Bank::Hnb).count();
            stat_card(
                &mut cols[3],
                icon::CHART_BAR,
                "Total collected",
                self.entries.len(),
                theme::FG,
                &format!("HNB {}   ·   Other {}", hnb, self.entries.len() - hnb),
            );
        });
    }

    fn columns_view(&self, ui: &mut egui::Ui) {
        ui.columns(3, |cols| {
            for (i, p) in Product::ALL.into_iter().enumerate() {
                let ui = &mut cols[i];
                surface(ui, |ui| {
                    ui.set_min_height(ui.available_height() - 28.0);
                    ui.horizontal(|ui| {
                        icon_badge(ui, p.icon(), p.color(), 28.0);
                        ui.label(
                            RichText::new(p.label())
                                .size(15.0)
                                .strong()
                                .color(theme::FG),
                        );
                        ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                            pill(ui, &self.count(p, None).to_string(), p.color());
                        });
                    });
                    ui.add_space(6.0);
                    ui.separator();
                    egui::ScrollArea::vertical()
                        .id_salt(i)
                        .auto_shrink([false, false])
                        .stick_to_bottom(true)
                        .show(ui, |ui| {
                            let mut n = 0;
                            for e in self.entries.iter().filter(|e| e.product == p) {
                                n += 1;
                                ui.horizontal(|ui| {
                                    ui.add_sized(
                                        [32.0, 24.0],
                                        egui::Label::new(
                                            RichText::new(format!("{n}"))
                                                .monospace()
                                                .color(theme::FG_MUTED),
                                        ),
                                    );
                                    ui.label(
                                        RichText::new(&e.phone)
                                            .monospace()
                                            .size(15.0)
                                            .color(theme::FG),
                                    );
                                    ui.with_layout(
                                        egui::Layout::right_to_left(egui::Align::Center),
                                        |ui| {
                                            bank_tag(ui, e.bank);
                                        },
                                    );
                                });
                            }
                            if n == 0 {
                                ui.add_space(24.0);
                                ui.vertical_centered(|ui| {
                                    ui.label(
                                        RichText::new("No numbers yet").color(theme::FG_MUTED),
                                    );
                                });
                            }
                        });
                });
            }
        });
    }

    fn transactions_view(&mut self, ui: &mut egui::Ui) {
        ui.horizontal(|ui| {
            ui.label(
                RichText::new(format!("{}  Search", icon::MAGNIFYING_GLASS)).color(theme::FG_MUTED),
            );
            ui.add(
                egui::TextEdit::singleline(&mut self.search)
                    .hint_text("Phone number")
                    .margin(egui::vec2(10.0, 6.0))
                    .desired_width(240.0),
            );
        });
        ui.add_space(8.0);
        let q = self.search.trim().to_string();
        let mut delete = None;
        surface(ui, |ui| {
            egui::ScrollArea::vertical()
                .auto_shrink([false, false])
                .show(ui, |ui| {
                    egui::Grid::new("tx")
                        .striped(true)
                        .num_columns(6)
                        .spacing([28.0, 10.0])
                        .min_col_width(40.0)
                        .show(ui, |ui| {
                            for h in ["#", "Date / time", "Phone number", "Bank", "Product", ""] {
                                ui.label(
                                    RichText::new(h).size(12.5).strong().color(theme::FG_MUTED),
                                );
                            }
                            ui.end_row();
                            for (i, e) in self.entries.iter().enumerate().rev() {
                                if !q.is_empty() && !e.phone.contains(&q) {
                                    continue;
                                }
                                ui.label(
                                    RichText::new((i + 1).to_string())
                                        .monospace()
                                        .color(theme::FG_MUTED),
                                );
                                ui.label(RichText::new(&e.timestamp).color(theme::FG));
                                ui.label(
                                    RichText::new(&e.phone)
                                        .monospace()
                                        .size(15.0)
                                        .color(theme::FG),
                                );
                                bank_tag(ui, e.bank);
                                ui.horizontal(|ui| {
                                    ui.label(
                                        RichText::new(e.product.icon())
                                            .size(16.0)
                                            .color(e.product.color()),
                                    );
                                    ui.label(RichText::new(e.product.label()).color(theme::FG));
                                });
                                if ui
                                    .add(
                                        egui::Button::new(
                                            RichText::new(format!("{}  Delete", icon::TRASH))
                                                .size(12.5)
                                                .color(theme::DANGER),
                                        )
                                        .fill(Color32::TRANSPARENT)
                                        .stroke(Stroke::new(1.0_f32, theme::BORDER)),
                                    )
                                    .clicked()
                                {
                                    delete = Some(e.id);
                                }
                                ui.end_row();
                            }
                        });
                    if self.entries.is_empty() {
                        ui.add_space(20.0);
                        ui.label(
                            RichText::new(
                                "No transactions yet. Enter a phone number above to start.",
                            )
                            .color(theme::FG_MUTED),
                        );
                    }
                });
        });
        if let Some(id) = delete {
            match self.db.delete(id) {
                Ok(_) => self.status = Some(("Entry deleted.".into(), Tone::Ok)),
                Err(e) => self.status = Some((format!("Delete failed: {e}"), Tone::Err)),
            }
            self.reload();
        }
    }

    fn dialogs(&mut self, ctx: &egui::Context) {
        let esc = ctx.input(|i| i.key_pressed(egui::Key::Escape));
        let keys = [egui::Key::Num1, egui::Key::Num2, egui::Key::Num3];
        let mut next: Option<Step> = None;
        let mut add: Option<(String, Bank, Product)> = None;

        match &self.step {
            Step::Idle => return,
            Step::ChooseBank { phone } => {
                modal(ctx, 1, "Which bank?", phone, |ui| {
                    ui.horizontal(|ui| {
                        for (i, b) in [Bank::Hnb, Bank::Other].into_iter().enumerate() {
                            let accent = if b == Bank::Hnb {
                                theme::PRIMARY
                            } else {
                                theme::FG_MUTED
                            };
                            if choice_tile(ui, i + 1, b.icon(), b.label(), accent).clicked()
                                || ui.input(|inp| inp.key_pressed(keys[i]))
                            {
                                next = Some(Step::ChooseProduct {
                                    phone: phone.clone(),
                                    bank: b,
                                });
                            }
                        }
                    });
                });
            }
            Step::ChooseProduct { phone, bank } => {
                let mut back = false;
                modal(
                    ctx,
                    2,
                    &format!("Which product?  ·  {}", bank.label()),
                    phone,
                    |ui| {
                        ui.horizontal(|ui| {
                            for (i, p) in Product::ALL.into_iter().enumerate() {
                                if choice_tile(ui, i + 1, p.icon(), p.label(), p.color()).clicked()
                                    || ui.input(|inp| inp.key_pressed(keys[i]))
                                {
                                    add = Some((phone.clone(), *bank, p));
                                }
                            }
                        });
                        ui.add_space(10.0);
                        back = secondary_button(ui, &format!("{}  Back", icon::ARROW_LEFT))
                            .clicked()
                            || ui.input(|i| i.key_pressed(egui::Key::Backspace));
                    },
                );
                if back {
                    next = Some(Step::ChooseBank {
                        phone: phone.clone(),
                    });
                }
            }
        }
        if esc {
            next = Some(Step::Idle);
            self.focus_input = true;
        }
        if let Some((phone, bank, product)) = add {
            self.add_entry(phone, bank, product);
        } else if let Some(s) = next {
            self.step = s;
        }
    }
}

impl App {
    fn update_banner(&mut self, ctx: &egui::Context) {
        let Some(shared) = self.update.clone() else {
            return;
        };
        let state = shared.lock().unwrap().clone();
        let (text, color) = match &state {
            updater::State::Available { version, .. } => (
                format!(
                    "A new version v{version} is available (you have v{})",
                    updater::CURRENT
                ),
                theme::PRIMARY,
            ),
            updater::State::Downloading { version, progress } => (
                format!("Downloading v{version}…  {:.0}%", progress * 100.0),
                theme::SKY,
            ),
            updater::State::Installed { version } => (
                format!("v{version} installed. Restart to use it."),
                theme::SUCCESS,
            ),
            updater::State::Failed(e) => (e.clone(), theme::DANGER),
            _ => return,
        };
        egui::TopBottomPanel::top("update_banner")
            .frame(
                egui::Frame::none()
                    .fill(color.gamma_multiply(0.18))
                    .inner_margin(egui::Margin::symmetric(24.0, 8.0)),
            )
            .show(ctx, |ui| {
                ui.horizontal(|ui| {
                    ui.label(RichText::new(text).strong().color(color));
                    if let updater::State::Available { notes, .. } = &state {
                        if !notes.trim().is_empty() {
                            ui.label(
                                RichText::new("· release notes")
                                    .size(12.5)
                                    .color(theme::FG_MUTED),
                            )
                            .on_hover_text(notes.as_str());
                        }
                    }
                    ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                        match &state {
                            updater::State::Available { version, url, .. } => {
                                if secondary_button(ui, "Later").clicked() {
                                    *shared.lock().unwrap() = updater::State::Dismissed;
                                }
                                if primary_button(
                                    ui,
                                    &format!("{}  Install update", icon::DOWNLOAD_SIMPLE),
                                )
                                .clicked()
                                {
                                    updater::install(
                                        shared.clone(),
                                        ctx.clone(),
                                        version.clone(),
                                        url.clone(),
                                    );
                                }
                            }
                            updater::State::Downloading { progress, .. } => {
                                ui.add(egui::ProgressBar::new(*progress).desired_width(220.0));
                            }
                            updater::State::Installed { .. } => {
                                if secondary_button(ui, "Later").clicked() {
                                    *shared.lock().unwrap() = updater::State::Dismissed;
                                }
                                if primary_button(
                                    ui,
                                    &format!("{}  Restart now", icon::ARROW_CLOCKWISE),
                                )
                                .clicked()
                                {
                                    updater::restart();
                                }
                            }
                            updater::State::Failed(_)
                                if secondary_button(ui, "Dismiss").clicked() =>
                            {
                                *shared.lock().unwrap() = updater::State::Dismissed;
                            }
                            _ => {}
                        }
                    });
                });
            });
    }
}

impl App {
    fn export_dir(&self) -> PathBuf {
        let dir = PathBuf::from(self.settings.export_folder.trim());
        if !self.settings.export_folder.trim().is_empty() && dir.is_dir() {
            dir
        } else {
            std::env::var_os("USERPROFILE")
                .map(|h| PathBuf::from(h).join("Documents"))
                .unwrap_or_else(|| PathBuf::from("."))
        }
    }

    fn backup_db(&mut self) {
        let Some(path) = rfd::FileDialog::new()
            .set_file_name(format!(
                "hnb_solo_backup_{}.db",
                chrono::Local::now().format("%Y%m%d_%H%M")
            ))
            .add_filter("SQLite database", &["db"])
            .set_directory(self.export_dir())
            .save_file()
        else {
            return;
        };
        self.status = Some(match self.db.backup(&path) {
            Ok(_) => (format!("Backup saved to {}", path.display()), Tone::Ok),
            Err(e) => (format!("Backup failed: {e}"), Tone::Err),
        });
    }

    fn settings_view(&mut self, ui: &mut egui::Ui, ctx: &egui::Context) {
        let before = self.settings.clone();
        egui::ScrollArea::vertical()
            .auto_shrink([false, false])
            .show(ui, |ui| {
                ui.columns(2, |cols| {
                    // ----- Left column -----
                    let ui = &mut cols[0];
                    settings_section(ui, icon::USER, "Profile", |ui| {
                        field_label(ui, "Staff name", "Added to CSV exports");
                        ui.add(
                            egui::TextEdit::singleline(&mut self.settings.staff_name)
                                .hint_text("e.g. Nimal Perera")
                                .margin(egui::vec2(10.0, 8.0))
                                .desired_width(f32::INFINITY),
                        );
                        ui.add_space(8.0);
                        field_label(ui, "Branch", "Added to CSV exports");
                        ui.add(
                            egui::TextEdit::singleline(&mut self.settings.branch)
                                .hint_text("e.g. Colombo 03")
                                .margin(egui::vec2(10.0, 8.0))
                                .desired_width(f32::INFINITY),
                        );
                    });
                    ui.add_space(12.0);
                    settings_section(ui, icon::PHONE, "Data entry", |ui| {
                        field_label(ui, "Phone number length", "Allowed number of digits");
                        ui.horizontal(|ui| {
                            ui.label("Min");
                            ui.add(
                                egui::DragValue::new(&mut self.settings.min_digits).range(6..=15),
                            );
                            ui.add_space(12.0);
                            ui.label("Max");
                            ui.add(
                                egui::DragValue::new(&mut self.settings.max_digits).range(6..=15),
                            );
                        });
                        ui.add_space(10.0);
                        field_label(
                            ui,
                            "Duplicate numbers",
                            "Same number under the same product",
                        );
                        ui.horizontal(|ui| {
                            for p in DuplicatePolicy::ALL {
                                segment(ui, &mut self.settings.duplicate_policy, p, p.label());
                            }
                        });
                        let hint = match self.settings.duplicate_policy {
                            DuplicatePolicy::Allow => "Saved with no message.",
                            DuplicatePolicy::Warn => "Saved, with a warning message.",
                            DuplicatePolicy::Block => "Not saved; an error is shown.",
                        };
                        ui.label(RichText::new(hint).size(12.5).color(theme::FG_MUTED));
                    });
                    ui.add_space(12.0);
                    settings_section(ui, icon::TEXT_AA, "Appearance", |ui| {
                        field_label(
                            ui,
                            "Interface size",
                            "Makes text and controls larger or smaller",
                        );
                        ui.horizontal(|ui| {
                            for (pct, label) in
                                [(0.9, "90%"), (1.0, "100%"), (1.15, "115%"), (1.3, "130%")]
                            {
                                segment(ui, &mut self.settings.ui_scale, pct, label);
                            }
                        });
                    });

                    // ----- Right column -----
                    let ui = &mut cols[1];
                    settings_section(ui, icon::FILE_CSV, "Export", |ui| {
                        field_label(
                            ui,
                            "Default export folder",
                            "Where CSV and backup dialogs open",
                        );
                        ui.horizontal(|ui| {
                            let shown = if self.settings.export_folder.is_empty() {
                                "Documents (default)".to_string()
                            } else {
                                self.settings.export_folder.clone()
                            };
                            ui.add(
                                egui::Label::new(RichText::new(shown).monospace().color(theme::FG))
                                    .truncate(),
                            );
                        });
                        ui.horizontal(|ui| {
                            if secondary_button(ui, &format!("{}  Browse", icon::FOLDER_OPEN))
                                .clicked()
                            {
                                if let Some(dir) = rfd::FileDialog::new()
                                    .set_directory(self.export_dir())
                                    .pick_folder()
                                {
                                    self.settings.export_folder = dir.display().to_string();
                                }
                            }
                            if !self.settings.export_folder.is_empty()
                                && secondary_button(
                                    ui,
                                    &format!("{}  Use default", icon::ARROW_COUNTER_CLOCKWISE),
                                )
                                .clicked()
                            {
                                self.settings.export_folder.clear();
                            }
                        });
                    });
                    ui.add_space(12.0);
                    settings_section(ui, icon::ARROW_CIRCLE_DOWN, "Updates", |ui| {
                        ui.checkbox(
                            &mut self.settings.check_updates_on_start,
                            "Check for updates when the app starts",
                        );
                        ui.add_space(6.0);
                        ui.horizontal(|ui| {
                            let state = self.update.as_ref().map(|s| s.lock().unwrap().clone());
                            let busy = matches!(
                                state,
                                Some(updater::State::Checking)
                                    | Some(updater::State::Downloading { .. })
                            );
                            if ui
                                .add_enabled_ui(!busy, |ui| {
                                    secondary_button(
                                        ui,
                                        &format!("{}  Check now", icon::ARROWS_CLOCKWISE),
                                    )
                                })
                                .inner
                                .clicked()
                            {
                                self.update = Some(updater::check(ctx.clone(), true));
                            }
                            let (text, col) = match state {
                                Some(updater::State::Checking) => {
                                    ("Checking…".to_string(), theme::FG_MUTED)
                                }
                                Some(updater::State::UpToDate) => (
                                    format!("{}  You have the latest version", icon::CHECK_CIRCLE),
                                    theme::SUCCESS,
                                ),
                                Some(updater::State::Available { version, .. }) => (
                                    format!("v{version} available, see the bar at the top"),
                                    theme::PRIMARY,
                                ),
                                Some(updater::State::Failed(e)) => (e, theme::DANGER),
                                _ => (String::new(), theme::FG_MUTED),
                            };
                            ui.label(RichText::new(text).size(13.0).color(col));
                        });
                        ui.label(
                            RichText::new(format!("Installed version: v{}", updater::CURRENT))
                                .size(12.5)
                                .color(theme::FG_MUTED),
                        );
                    });
                    ui.add_space(12.0);
                    settings_section(ui, icon::DATABASE, "Data", |ui| {
                        ui.label(
                            RichText::new(format!(
                                "{} entries saved in\n{}",
                                self.entries.len(),
                                self.db.path.display()
                            ))
                            .size(12.5)
                            .color(theme::FG_MUTED),
                        );
                        ui.add_space(6.0);
                        ui.horizontal_wrapped(|ui| {
                            if primary_button(
                                ui,
                                &format!("{}  Back up database", icon::FLOPPY_DISK),
                            )
                            .clicked()
                            {
                                self.backup_db();
                            }
                            if secondary_button(
                                ui,
                                &format!("{}  Open data folder", icon::FOLDER_OPEN),
                            )
                            .clicked()
                            {
                                if let Some(dir) = self.db.path.parent() {
                                    let _ = std::process::Command::new("explorer").arg(dir).spawn();
                                }
                            }
                            if secondary_button(
                                ui,
                                &format!("{}  Reset settings", icon::ARROW_COUNTER_CLOCKWISE),
                            )
                            .clicked()
                            {
                                self.settings = Settings::default();
                                self.status =
                                    Some(("Settings reset to defaults.".into(), Tone::Ok));
                            }
                        });
                    });
                });
            });

        if self.settings.min_digits > self.settings.max_digits {
            if self.settings.min_digits != before.min_digits {
                self.settings.max_digits = self.settings.min_digits;
            } else {
                self.settings.min_digits = self.settings.max_digits;
            }
        }
        if self.settings != before {
            if let Err(e) = settings::save(&self.db.conn, &self.settings) {
                self.status = Some((format!("Could not save settings: {e}"), Tone::Err));
            }
        }
    }
}

fn settings_section(ui: &mut egui::Ui, glyph: &str, title: &str, add: impl FnOnce(&mut egui::Ui)) {
    surface(ui, |ui| {
        ui.horizontal(|ui| {
            icon_badge(ui, glyph, theme::PRIMARY, 28.0);
            ui.label(RichText::new(title).size(15.0).strong().color(theme::FG));
        });
        ui.add_space(10.0);
        add(ui);
    });
}

fn field_label(ui: &mut egui::Ui, title: &str, help: &str) {
    ui.label(RichText::new(title).strong().color(theme::FG));
    ui.label(RichText::new(help).size(12.0).color(theme::FG_MUTED));
    ui.add_space(2.0);
}

fn segment<T: PartialEq + Copy>(ui: &mut egui::Ui, value: &mut T, option: T, label: &str) {
    let sel = *value == option;
    let b = egui::Button::new(RichText::new(label).size(13.5).color(if sel {
        theme::ON_PRIMARY
    } else {
        theme::FG
    }))
    .fill(if sel { theme::PRIMARY } else { theme::PANEL })
    .stroke(Stroke::new(
        1.0_f32,
        if sel { theme::PRIMARY } else { theme::BORDER },
    ))
    .rounding(8.0)
    .min_size(egui::vec2(72.0, 32.0));
    if ui.add(b).clicked() {
        *value = option;
    }
}

fn status_line(ui: &mut egui::Ui, msg: &str, tone: Tone) {
    let (col, mark) = match tone {
        Tone::Ok => (theme::SUCCESS, icon::CHECK_CIRCLE),
        Tone::Warn => (theme::WARN, icon::WARNING),
        Tone::Err => (theme::DANGER, icon::X_CIRCLE),
    };
    ui.label(
        RichText::new(format!("{mark}  {msg}"))
            .size(13.5)
            .color(col),
    );
}

// ---------- Components ----------
fn surface(ui: &mut egui::Ui, add: impl FnOnce(&mut egui::Ui)) {
    egui::Frame::none()
        .fill(theme::CARD)
        .stroke(Stroke::new(1.0_f32, theme::BORDER))
        .rounding(10.0)
        .inner_margin(16.0)
        .show(ui, |ui| {
            ui.set_min_width(ui.available_width());
            add(ui);
        });
}

fn pill(ui: &mut egui::Ui, text: &str, color: Color32) {
    egui::Frame::none()
        .fill(color.gamma_multiply(0.18))
        .rounding(999.0)
        .inner_margin(egui::Margin::symmetric(10.0, 3.0))
        .show(ui, |ui| {
            ui.label(RichText::new(text).strong().size(14.0).color(color));
        });
}

fn bank_tag(ui: &mut egui::Ui, bank: Bank) {
    let (fg, bg) = match bank {
        Bank::Hnb => (theme::PRIMARY, theme::PRIMARY.gamma_multiply(0.15)),
        Bank::Other => (theme::FG_MUTED, theme::MUTED),
    };
    egui::Frame::none()
        .fill(bg)
        .rounding(4.0)
        .inner_margin(egui::Margin::symmetric(8.0, 2.0))
        .show(ui, |ui| {
            ui.label(
                RichText::new(format!(
                    "{} {}",
                    bank.icon(),
                    match bank {
                        Bank::Hnb => "HNB",
                        Bank::Other => "OTHER",
                    }
                ))
                .size(11.5)
                .strong()
                .color(fg),
            );
        });
}

fn stat_card(
    ui: &mut egui::Ui,
    glyph: &str,
    title: &str,
    value: usize,
    accent: Color32,
    sub: &str,
) {
    egui::Frame::none()
        .fill(theme::CARD)
        .stroke(Stroke::new(1.0_f32, theme::BORDER))
        .rounding(10.0)
        .inner_margin(16.0)
        .show(ui, |ui| {
            ui.set_min_width(ui.available_width());
            ui.horizontal(|ui| {
                icon_badge(ui, glyph, accent, 30.0);
                ui.label(
                    RichText::new(title)
                        .size(13.0)
                        .strong()
                        .color(theme::FG_MUTED),
                );
            });
            ui.add_space(4.0);
            ui.label(
                RichText::new(value.to_string())
                    .size(34.0)
                    .strong()
                    .color(theme::FG),
            );
            ui.label(RichText::new(sub).size(12.5).color(theme::FG_MUTED));
        });
}

fn primary(text: RichText) -> egui::Button<'static> {
    egui::Button::new(text.strong().color(theme::ON_PRIMARY))
        .fill(theme::PRIMARY)
        .rounding(8.0)
}

fn sized(b: egui::Button<'static>, w: f32, h: f32) -> egui::Button<'static> {
    b.min_size(egui::vec2(w, h))
}

fn primary_button(ui: &mut egui::Ui, text: &str) -> egui::Response {
    ui.add(sized(primary(RichText::new(text).size(14.0)), 0.0, 38.0))
}

fn secondary_button(ui: &mut egui::Ui, text: &str) -> egui::Response {
    ui.add(
        egui::Button::new(RichText::new(text).size(14.0).color(theme::FG))
            .fill(Color32::TRANSPARENT)
            .stroke(Stroke::new(1.0_f32, theme::BORDER))
            .rounding(8.0)
            .min_size(egui::vec2(0.0, 38.0)),
    )
}

fn danger_button(ui: &mut egui::Ui, text: &str) -> egui::Response {
    ui.add(
        egui::Button::new(
            RichText::new(text)
                .size(14.0)
                .strong()
                .color(Color32::WHITE),
        )
        .fill(theme::DANGER)
        .rounding(8.0)
        .min_size(egui::vec2(0.0, 38.0)),
    )
}

fn icon_badge(ui: &mut egui::Ui, glyph: &str, color: Color32, size: f32) {
    let (rect, _) = ui.allocate_exact_size(egui::vec2(size, size), egui::Sense::hover());
    ui.painter()
        .rect_filled(rect, 8.0, color.gamma_multiply(0.14));
    ui.painter().text(
        rect.center(),
        egui::Align2::CENTER_CENTER,
        glyph,
        egui::FontId::proportional(size * 0.6),
        color,
    );
}

fn choice_tile(
    ui: &mut egui::Ui,
    key: usize,
    glyph: &str,
    label: &str,
    accent: Color32,
) -> egui::Response {
    let size = egui::vec2(200.0, 96.0);
    let (rect, resp) = ui.allocate_exact_size(size, egui::Sense::click());
    let hovered = resp.hovered() || resp.has_focus();
    let p = ui.painter();
    p.rect(
        rect,
        10.0,
        if hovered {
            accent.gamma_multiply(0.16)
        } else {
            theme::MUTED
        },
        Stroke::new(
            if hovered { 2.0_f32 } else { 1.0 },
            if hovered { accent } else { theme::BORDER },
        ),
    );
    // key badge
    let badge =
        egui::Rect::from_min_size(rect.min + egui::vec2(14.0, 14.0), egui::vec2(26.0, 26.0));
    p.rect_filled(badge, 6.0, accent);
    p.text(
        badge.center(),
        egui::Align2::CENTER_CENTER,
        key.to_string(),
        egui::FontId::monospace(15.0),
        theme::ON_PRIMARY,
    );
    p.text(
        rect.right_top() + egui::vec2(-16.0, 12.0),
        egui::Align2::RIGHT_TOP,
        glyph,
        egui::FontId::proportional(30.0),
        accent,
    );
    p.text(
        rect.left_bottom() + egui::vec2(14.0, -18.0),
        egui::Align2::LEFT_BOTTOM,
        label,
        egui::FontId::proportional(16.0),
        theme::FG,
    );
    resp.on_hover_cursor(egui::CursorIcon::PointingHand)
}

fn modal(
    ctx: &egui::Context,
    step: u8,
    title: &str,
    phone: &str,
    body: impl FnOnce(&mut egui::Ui),
) {
    let screen = ctx.screen_rect();
    egui::Area::new(egui::Id::new("scrim"))
        .order(egui::Order::Middle)
        .fixed_pos(screen.min)
        .show(ctx, |ui| {
            ui.painter()
                .rect_filled(screen, 0.0, Color32::from_black_alpha(110));
            ui.allocate_rect(screen, egui::Sense::click());
        });
    egui::Window::new("step_modal")
        .title_bar(false)
        .order(egui::Order::Foreground)
        .resizable(false)
        .anchor(egui::Align2::CENTER_CENTER, [0.0, 0.0])
        .frame(
            egui::Frame::none()
                .fill(theme::PANEL)
                .stroke(Stroke::new(1.0_f32, theme::BORDER))
                .rounding(14.0)
                .inner_margin(24.0)
                .shadow(egui::epaint::Shadow {
                    offset: egui::vec2(0.0, 12.0),
                    blur: 40.0,
                    spread: 0.0,
                    color: Color32::from_black_alpha(50),
                }),
        )
        .show(ctx, |ui| {
            ui.label(
                RichText::new(format!("STEP {step} OF 2"))
                    .size(11.5)
                    .strong()
                    .color(theme::PRIMARY),
            );
            ui.label(RichText::new(title).size(20.0).strong().color(theme::FG));
            ui.add_space(2.0);
            ui.label(
                RichText::new(phone)
                    .monospace()
                    .size(16.0)
                    .color(theme::FG_MUTED),
            );
            ui.add_space(16.0);
            body(ui);
            ui.add_space(12.0);
            ui.label(
                RichText::new("Press a number key to choose  ·  Esc to cancel")
                    .size(12.0)
                    .color(theme::FG_MUTED),
            );
        });
}

fn apply_theme(ctx: &egui::Context) {
    let mut fonts = egui::FontDefinitions::default();
    egui_phosphor::add_to_fonts(&mut fonts, egui_phosphor::Variant::Regular);
    ctx.set_fonts(fonts);

    let mut v = egui::Visuals::light();
    v.panel_fill = theme::BG;
    v.window_fill = theme::PANEL;
    v.extreme_bg_color = theme::PANEL; // text inputs
    v.faint_bg_color = theme::MUTED; // striped rows
    v.override_text_color = None;
    v.selection.bg_fill = theme::PRIMARY.gamma_multiply(0.25);
    v.selection.stroke = Stroke::new(1.5_f32, theme::PRIMARY);
    v.widgets.noninteractive.bg_stroke = Stroke::new(1.0_f32, theme::BORDER);
    v.widgets.noninteractive.fg_stroke = Stroke::new(1.0_f32, theme::FG);
    v.widgets.inactive.bg_fill = theme::MUTED;
    v.widgets.inactive.weak_bg_fill = theme::MUTED;
    v.widgets.inactive.bg_stroke = Stroke::new(1.0_f32, theme::BORDER);
    v.widgets.hovered.bg_stroke = Stroke::new(1.0_f32, theme::FG_MUTED);
    v.widgets.active.bg_stroke = Stroke::new(1.5_f32, theme::PRIMARY);
    for w in [
        &mut v.widgets.inactive,
        &mut v.widgets.hovered,
        &mut v.widgets.active,
        &mut v.widgets.open,
    ] {
        w.rounding = egui::Rounding::same(8.0);
    }
    ctx.set_visuals(v);
    ctx.style_mut(|s| {
        s.spacing.item_spacing = egui::vec2(10.0, 8.0);
        s.spacing.button_padding = egui::vec2(14.0, 8.0);
        s.text_styles
            .insert(egui::TextStyle::Body, egui::FontId::proportional(14.5));
        s.text_styles
            .insert(egui::TextStyle::Button, egui::FontId::proportional(14.5));
    });
}

impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        let dialog_open = !matches!(self.step, Step::Idle);
        if !self.startup_check_done {
            self.startup_check_done = true;
            if self.settings.check_updates_on_start {
                self.update = Some(updater::check(ctx.clone(), false));
            }
        }
        if self.applied_scale != self.settings.ui_scale {
            self.applied_scale = self.settings.ui_scale;
            ctx.set_zoom_factor(self.settings.ui_scale);
        }
        self.update_banner(ctx);

        // HNB blue / cyan brand stripe
        egui::TopBottomPanel::top("brand_stripe")
            .exact_height(4.0)
            .frame(egui::Frame::none().fill(theme::PRIMARY))
            .show(ctx, |ui| {
                let r = ui.max_rect();
                let half = egui::Rect::from_min_max(egui::pos2(r.center().x, r.min.y), r.max);
                ui.painter().rect_filled(half, 0.0, theme::CYAN);
            });

        egui::TopBottomPanel::top("header")
            .frame(
                egui::Frame::none()
                    .fill(theme::BG)
                    .inner_margin(egui::Margin::symmetric(24.0, 0.0)),
            )
            .show(ctx, |ui| self.header(ui, dialog_open));

        egui::TopBottomPanel::bottom("footer")
            .frame(
                egui::Frame::none()
                    .fill(theme::PANEL)
                    .inner_margin(egui::Margin::symmetric(24.0, 6.0)),
            )
            .show(ctx, |ui| {
                ui.label(
                    RichText::new(format!(
                        "{}  v{}   ·   SQLite  {}",
                        icon::DATABASE,
                        updater::CURRENT,
                        self.db.path.display()
                    ))
                    .size(11.5)
                    .color(theme::FG_MUTED),
                );
            });

        egui::CentralPanel::default()
            .frame(
                egui::Frame::none()
                    .fill(theme::BG)
                    .inner_margin(egui::Margin {
                        left: 24.0,
                        right: 24.0,
                        top: 0.0,
                        bottom: 16.0,
                    }),
            )
            .show(ctx, |ui| {
                if self.tab == Tab::Settings {
                    ui.horizontal(|ui| {
                        if secondary_button(ui, &format!("{}  Back", icon::ARROW_LEFT)).clicked() {
                            self.tab = Tab::Columns;
                        }
                        ui.add_space(6.0);
                        ui.label(
                            RichText::new(format!("{}  Settings", icon::GEAR_SIX))
                                .size(20.0)
                                .strong()
                                .color(theme::FG),
                        );
                    });
                    ui.add_space(12.0);
                    self.settings_view(ui, ctx);
                    return;
                }
                self.summary_cards(ui);
                ui.add_space(14.0);
                ui.horizontal(|ui| {
                    for (t, name) in [
                        (Tab::Columns, format!("{}  Columns", icon::COLUMNS)),
                        (
                            Tab::Transactions,
                            format!("{}  Transactions", icon::LIST_BULLETS),
                        ),
                    ] {
                        let sel = self.tab == t;
                        let b = egui::Button::new(RichText::new(name).size(14.5).strong().color(
                            if sel {
                                theme::ON_PRIMARY
                            } else {
                                theme::FG_MUTED
                            },
                        ))
                        .fill(if sel {
                            theme::PRIMARY
                        } else {
                            Color32::TRANSPARENT
                        })
                        .stroke(Stroke::new(
                            1.0_f32,
                            if sel { theme::PRIMARY } else { theme::BORDER },
                        ))
                        .rounding(8.0)
                        .min_size(egui::vec2(120.0, 34.0));
                        if ui.add(b).clicked() {
                            self.tab = t;
                        }
                    }
                });
                ui.add_space(10.0);
                match self.tab {
                    Tab::Columns => self.columns_view(ui),
                    Tab::Transactions => self.transactions_view(ui),
                    Tab::Settings => {}
                }
            });

        self.dialogs(ctx);
    }
}

fn main() -> eframe::Result {
    let db = match Db::open() {
        Ok(db) => db,
        Err(e) => {
            rfd::MessageDialog::new()
                .set_title("HNB Solo Tracker")
                .set_description(format!("Could not open the database: {e}"))
                .show();
            std::process::exit(1);
        }
    };
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_title("HNB Solo Tracker")
            .with_inner_size([1180.0, 760.0])
            .with_min_inner_size([900.0, 560.0])
            .with_icon(
                eframe::icon_data::from_png_bytes(include_bytes!("../assets/icon.png"))
                    .unwrap_or_default(),
            ),
        ..Default::default()
    };
    eframe::run_native(
        "HNB Solo Tracker",
        options,
        Box::new(|cc| {
            apply_theme(&cc.egui_ctx);
            Ok(Box::new(App::new(db)))
        }),
    )
}
