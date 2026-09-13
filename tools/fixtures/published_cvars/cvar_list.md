# KTP League CVAR Requirements (fixture)

Hand-written for tools/test_check_published_cvars.py, in the shape of
afraznein/KTP_Documentation `KTP Cvar List.md`. It states the rules in
fixture ktp_cvar.sma independently; it is not generated from it.

- [Fixed Value CVARs](#fixed-value-cvars)
- [Range-Based CVARs](#range-based-cvars)

## Fixed Value CVARs

### Graphics & Rendering

| CVAR | Value | Description |
|------|-------|-------------|
| `r_fullbright` | `0` | Maximum brightness in local games only |
| `r_glowshellfreq` | `2.20` | Glow shell animation speed |

### Movement & Input

| CVAR | Value | Description |
|------|-------|-------------|
| `m_pitch` | `0.022` or `-0.022` | Mouse pitch. **Inverted-mouse players set `-0.022`**. |

### Network & Prediction

| CVAR | Value | Description |
|------|-------|-------------|
| `rate` | `100000` | Client to server transmission rate. **Do not change.** |

#### Player-tunable network cvars (no enforcement)

| CVAR | Default | Notes |
|------|---------|-------|
| `cl_lc` | `1` | Lag compensation for your shots. |

### HUD & Interface

| CVAR | Value | Description |
|------|-------|-------------|
| `hud_takesshots` | `1` | Enforced in **competitive matches only** (`.ktp`, `.ktpOT`). |

---

## Range-Based CVARs

| CVAR | Range | Default | Description |
|------|-------|---------|-------------|
| `lightgamma` | **1.809** - **3.0** | 2.5 | Lighting gamma value |
| `cl_updaterate` | **100** - **120** | - | Updates requested from server per second |
| `ex_interp` | **0.01** - **0.05** | - | Interpolation time. **Set 0.01**. |

---

## Quick Reference

```
ex_interp 0.01
cl_updaterate 102
```
