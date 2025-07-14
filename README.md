
# Domain Checker Bash Script

A powerful and customizable Bash script to check the availability of domain names using `whois`.

---

## 🔧 Features

- Supports `.com`, `.net`, or any custom suffix
- Supports any custom prefix (`pattern`)
- Saves results into organized directories (`available/`, `taken/`, `results/`, `logs/`)
- JSON output support
- Fast mode (no delay between checks)
- Interactive mode to confirm before saving available domains
- Optional debug logs with full whois response
- Sound notification and desktop alerts when available domains are found (if supported - need to ffmpeg)
- Estimated time tracking and progress display

---

## 📦 Dependencies

Make sure the following tools are installed:

- `whois`
- `bc` (for accurate time estimations)
- `notify-send` (optional, for desktop notifications - need to GUI)
- `ffmpeg` (optional, for sound notifications)

Install on Debian/Ubuntu:

```bash
sudo apt install whois bc libnotify-bin ffmpeg
```

---

## 📁 Directory Structure

```
.
├── available/      # Stores available domains
├── taken/          # Stores taken domains
├── results/        # Full logs of checked domains (output + json)
├── logs/           # Debug whois logs (if enabled)
├── input.txt       # List of domain names to check (without suffix)
├── ding.mp3        # Optional notification sound
└── main.sh         # The main script
```

---

## 🚀 Usage

```bash
./main.sh [OPTIONS]
```

### 📌 Options

| Option                    | Description                                                |
|---------------------------|------------------------------------------------------------|
| `-i`, `--input`           | Input file (default: `input.txt`)                          |
| `-o`, `--output`          | Output file (default: `output_TIMESTAMP.txt`)              |
| `-a`, `--available`       | Available domains file                                     |
| `-t`, `--taken`           | Taken domains file                                         |
| `-j`, `--json`            | Save results to JSON format                                |
| `-s`, `--sleep`           | Sleep time between requests (default: 5 second)            |
| `-p`, `--prefix=dani`     | Check domains with `dani` (Pattern) prefix (default: none) |
| `-N`, `--non-domain=.xyz` | Check domains with `.xyz` suffix (default: none)           |
| `--no-save`               | Do not save any output files (Nothing - even debug)        |
| `--debug`                 | Save full whois debug logs                                 |
| `--sound`                 | Play a sound when available domain is found                |
| `--notify`                | Send a desktop notification                                |
| `--interactive`           | Confirm each available domain manually                     |
| `--fast`                  | Disable sleep delay (may cause rate limits)                |
| `-h`, `--help`            | Show this help menu                                        |

---

## 📝 Example

Check domains in `input.txt` with a 2-second delay and save results to JSON:

```bash
./main.sh -s 2 -j result.josn
```

Use `.net` suffix and sound notification:

```bash
./main.sh -N .net --sound
```

Check domains in `custom.txt` with `.ir` suffix + `doctor` prefix + sound + notify + `output.txt`:

```bash
./main.sh -i custom.txt -N .ir -p doctor --sound --notify -o out.txt
```

---

## 👨‍💻 Author

Created by AmirRoox

---

## 🧠 Tip

To generate potential domains, you can use tools like:

```bash
crunch 4 4 abcdefghijklmnopqrstuvwxyz -o input.txt
```

Or online generators to populate your `input.txt`.

---
