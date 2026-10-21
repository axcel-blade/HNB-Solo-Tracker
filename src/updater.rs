//! Checks GitHub Releases for a newer version and replaces the running exe.

use std::io::Read;
use std::sync::{Arc, Mutex};

const REPO: &str = "axcel-blade/HNB-Solo-Tracker";
pub const CURRENT: &str = env!("CARGO_PKG_VERSION");

#[derive(Clone)]
pub enum State {
    Checking,
    UpToDate,
    Available {
        version: String,
        url: String,
        notes: String,
    },
    Downloading {
        version: String,
        progress: f32,
    },
    Installed {
        version: String,
    },
    Failed(String),
    Dismissed,
}

pub type Shared = Arc<Mutex<State>>;

fn agent() -> ureq::Agent {
    ureq::AgentBuilder::new()
        .timeout(std::time::Duration::from_secs(30))
        .user_agent(concat!("hnb-solo-tracker/", env!("CARGO_PKG_VERSION")))
        .build()
}

/// `manual` checks report "up to date" and errors; start-up checks stay quiet.
pub fn check(ctx: eframe::egui::Context, manual: bool) -> Shared {
    let state: Shared = Arc::new(Mutex::new(State::Checking));
    let s = state.clone();
    std::thread::spawn(move || {
        let result = latest_release();
        *s.lock().unwrap() = match result {
            Ok(Some(st)) => st,
            Ok(None) if manual => State::UpToDate,
            Ok(None) => State::Dismissed,
            Err(e) if manual => State::Failed(format!("Update check failed: {e}")),
            // Offline or rate limited: stay quiet at startup
            Err(_) => State::Dismissed,
        };
        ctx.request_repaint();
    });
    state
}

fn latest_release() -> Result<Option<State>, String> {
    let v: serde_json::Value = agent()
        .get(&format!(
            "https://api.github.com/repos/{REPO}/releases/latest"
        ))
        .set("Accept", "application/vnd.github+json")
        .call()
        .map_err(|e| e.to_string())?
        .into_json()
        .map_err(|e| e.to_string())?;
    let tag = v["tag_name"].as_str().unwrap_or_default();
    let latest = semver::Version::parse(tag.trim_start_matches('v')).map_err(|e| e.to_string())?;
    let current = semver::Version::parse(CURRENT).map_err(|e| e.to_string())?;
    if latest <= current {
        return Ok(None);
    }
    let asset = v["assets"]
        .as_array()
        .and_then(|a| {
            a.iter()
                .find(|x| x["name"].as_str().is_some_and(|n| n.ends_with(".exe")))
        })
        .ok_or("Release has no .exe asset")?;
    Ok(Some(State::Available {
        version: latest.to_string(),
        url: asset["browser_download_url"]
            .as_str()
            .unwrap_or_default()
            .to_string(),
        notes: v["body"].as_str().unwrap_or_default().to_string(),
    }))
}

pub fn install(state: Shared, ctx: eframe::egui::Context, version: String, url: String) {
    *state.lock().unwrap() = State::Downloading {
        version: version.clone(),
        progress: 0.0,
    };
    std::thread::spawn(move || {
        let result = (|| -> Result<(), String> {
            let resp = agent().get(&url).call().map_err(|e| e.to_string())?;
            let total: usize = resp
                .header("Content-Length")
                .and_then(|v| v.parse().ok())
                .unwrap_or(0);
            let mut reader = resp.into_reader();
            let mut data = Vec::with_capacity(total);
            let mut buf = [0u8; 64 * 1024];
            loop {
                let n = reader.read(&mut buf).map_err(|e| e.to_string())?;
                if n == 0 {
                    break;
                }
                data.extend_from_slice(&buf[..n]);
                if total > 0 {
                    *state.lock().unwrap() = State::Downloading {
                        version: version.clone(),
                        progress: data.len() as f32 / total as f32,
                    };
                    ctx.request_repaint();
                }
            }
            if data.len() < 1024 || &data[..2] != b"MZ" {
                return Err("Downloaded file is not a valid Windows executable".into());
            }
            let tmp = std::env::temp_dir().join(format!("hnb-solo-tracker-{version}.exe"));
            std::fs::write(&tmp, &data).map_err(|e| e.to_string())?;
            self_replace::self_replace(&tmp).map_err(|e| e.to_string())?;
            let _ = std::fs::remove_file(&tmp);
            Ok(())
        })();
        *state.lock().unwrap() = match result {
            Ok(()) => State::Installed { version },
            Err(e) => State::Failed(format!("Update failed: {e}")),
        };
        ctx.request_repaint();
    });
}

pub fn restart() -> ! {
    if let Ok(exe) = std::env::current_exe() {
        let _ = std::process::Command::new(exe).spawn();
    }
    std::process::exit(0);
}
