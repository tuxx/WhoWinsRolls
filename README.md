# 🎲 WhoWinsRolls - WoW Classic Addon

📊 *WhoWinsRolls* keeps track of every roll between **you** and that one **loot goblin** in your party who *always* wins the good stuff. Whether you’re the king of Need rolls or the eternal loser in a cloak-off, this addon remembers — so you don’t have to.

---

## 💔 Features

- 🎯 Tracks roll stats against **one nemesis** at a time (revenge is personal).
- 🧾 Stores your **Wins, Losses, and Win Rate**.
- 📦 Works with **/roll**, **Greed**, and **Need** loot rolls.
- 💾 Remembers stats between sessions.
- 📉 Provides cold, statistical evidence that you are, in fact, cursed.
- 📢 Alerts you **in real-time** when you've been robbed (again).
- 🤝 Slash commands so simple, even your tank can use them.

---

## 🧠 Installation

### Curseforge

- https://legacy.curseforge.com/wow/addons/whowinsrolls

### Manual

1. 📁 Create a folder called `WhoWinsRolls` in your `Interface/AddOns/` directory.
2. 📄 Drop in the files: `WhoWinsRolls.lua` and `WhoWinsRolls.toc`.
3. 🔄 Restart WoW Classic or type `/reload`.
4. 👀 Make sure the addon is enabled in the character AddOns list.

---

## ⚙️ Commands

```
/whowinsrolls <player>   🎯 Track a player (e.g. /whowinsrolls Dave)
/whowinsrolls            📊 Show your current stats
/whowinsrolls reset      🔄 Reset your stats
/whowinsrolls help       📚 Display help
/wwr                     🪄 Short alias for the above
```

---

## 📈 How It Works

1. You set your **nemesis** using `/whowinsrolls <player>`.
2. When either of you rolls (via `/roll`, **Need**, or **Greed**):
   - The addon records the results
   - Compares the numbers
   - Updates your personal **W/L** stats
   - Instantly lets you know if you're the hero or the clown
3. Rinse, repeat, suffer, cope, gloat.

> 📝 Note: Only tracks **you vs one player at a time** — perfect for long-term grudges.

---

## 🔧 Troubleshooting

- ❌ Not working?
  - ✅ Make sure it's enabled in the AddOns menu
  - 🔄 Try `/reload`
  - 🎯 Use `/whowinsrolls <name>` to set a target
  - 👀 Ensure you're actually rolling — it's not psychic... yet

---

## ⚠️ Disclaimer

This addon may cause:
- 😤 Vendettas
- 🧮 Spreadsheet duels
- 🤬 Sudden outbursts of “This game is rigged!”

---

## 🤖 Requirements

- 🕹️ World of Warcraft Classic 1.15.7
- 🚫 No extra libraries or dependencies

---

## 🙌 Credits

Made with salt, sarcasm, and statistical rigor by someone who lost one too many **[Spaulders of Valor]** rolls.
