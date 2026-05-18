# garmin-toggl

A Garmin Connect IQ watch app that starts and stops [Toggl Track](https://toggl.com/track/) time entries straight from your wrist.

一款 Garmin Connect IQ 手表 app，让你在手腕上直接控制 [Toggl Track](https://toggl.com/track/) 计时。

Target device: Forerunner 570 (47mm). Should work on other CIQ 6+ watches with a manifest tweak.

[English](#english) · [中文](#中文)

---

## English

### What it does

- **Idle screen** shows the app name and a prompt to press START.
- **Press START** to open the category menu. Pick one — Toggl starts a running timer.
- **Running screen** shows the active category and a live elapsed counter (updates every second).
- **Press START on the running screen** to stop the current timer and immediately open the category menu. Pick another to switch, or press BACK to just leave it stopped.
- **Press BACK** to exit the app. A running timer keeps running on Toggl — next time you open the app it re-syncs from Toggl's "current running entry" endpoint.
- **Glance view** (swipe up/down on the watch face) shows the active category and live elapsed time, or just "TimeLogger" when idle.
- **15-min check-in.** While a timer is running the watch buzzes every 15 minutes and the next time you open the app it asks "Still doing X?". Yes keeps it running, No stops it. Worst-case drift if you forget is 15 minutes.
- All timestamps are sent in UTC; Toggl renders them in your local time.

### Custom categories

Categories live in `source/Categories.mc`, which is gitignored so it can hold your real Toggl project IDs. Copy `Categories.mc.example` to `source/Categories.mc` and edit. The format is a list of buckets:

```monkeyc
{ :name => "Deep Work", :projectId => 217175265, :subs => ["IC Work", "Coding", "Blog"] }
```

A bucket with empty `:subs` starts the timer immediately when selected. A bucket with sub-activities opens a sub-menu where "Just <name>" uses the bucket name as the description. Editing categories requires a rebuild.

### Setup

1. **Toggl credentials**

   - API token: <https://track.toggl.com/profile> (bottom of page).
   - Workspace ID: visible in any Toggl URL under `/workspaces/<id>/...`.

2. **Auth header** — compute the base64 once:

   ```bash
   echo -n "YOUR_TOKEN:api_token" | base64
   ```

3. **Secrets file** — copy `Secrets.mc.example` to `source/Secrets.mc` and fill in the three constants. This file is gitignored.

4. **SDK + developer key** — install the Garmin Connect IQ SDK and create a developer key (see Garmin docs).

### Build

For the watch (release):

```bash
java -jar "$CIQ_SDK/bin/monkeybrains.jar" \
  -o bin/TimeLogger.prg \
  -f monkey.jungle \
  -y /path/to/developer_key \
  -d fr57047mm -r -w
```

For the simulator (debug): swap `fr57047mm` for `fr57047mm_sim` and drop the `-r` flag.

### Install on the watch

Connect via USB, copy `bin/TimeLogger.prg` to `GARMIN/APPS/`. Launch from **Start → Apps → TimeLogger**.

---

## 中文

### 它是什么

- **空闲页面**显示 app 名字，提示按 START。
- **按 START** 打开类别菜单，选一个，Toggl 立刻开始一个运行中的 timer。
- **运行页面**显示当前类别和实时计时器（每秒刷新）。
- **运行页面按 START**：先停掉当前 timer，立刻弹出类别菜单。选下一个等于切换，按 BACK 等于只停不开。
- **任何时候按 BACK**：退出 app。timer 继续在 Toggl 跑，下次开 app 会通过 Toggl 的"current running entry"接口同步回来。
- **Glance view**（表盘上下滑动的卡片）：running 时显示当前类别和实时秒数，idle 时只显示 "TimeLogger"。
- **15 分钟 check-in**：timer 在跑的时候每 15 分钟手表会震一下，下次打开 app 会问"Still doing X?"，Yes 继续 / No 立刻停。万一忘了切换，最大误差就是 15 分钟。
- 所有时间戳用 UTC 发送，Toggl 会按你当地时区显示。

### 自定义类别

类别配置在 `source/Categories.mc`，这个文件已被 gitignore，可以放真实的 Toggl project ID。把 `Categories.mc.example` 复制成 `source/Categories.mc` 然后编辑。格式是一个 bucket 列表：

```monkeyc
{ :name => "Deep Work", :projectId => 217175265, :subs => ["IC Work", "Coding", "Blog"] }
```

`:subs` 为空的 bucket 选中就直接开始计时；带子项的会先进入子菜单，其中"Just <name>"用 bucket 名作为描述。改完需要重新编译。

### 配置

1. **Toggl 凭据**

   - API token：<https://track.toggl.com/profile> 页面底部。
   - Workspace ID：任何 Toggl URL 里 `/workspaces/<id>/...` 那段数字。

2. **Auth header** — 算一次 base64：

   ```bash
   echo -n "YOUR_TOKEN:api_token" | base64
   ```

3. **Secrets 文件** — 把 `Secrets.mc.example` 复制成 `source/Secrets.mc`，填入三个常量。这个文件已被 gitignore，不会进 git。

4. **SDK + Developer Key** — 装 Garmin Connect IQ SDK，建一个 developer key（参考 Garmin 官方文档）。

### 编译

手表版（release）：

```bash
java -jar "$CIQ_SDK/bin/monkeybrains.jar" \
  -o bin/TimeLogger.prg \
  -f monkey.jungle \
  -y /path/to/developer_key \
  -d fr57047mm -r -w
```

模拟器版（debug）：把 `fr57047mm` 换成 `fr57047mm_sim`，去掉 `-r`。

### 装到手表

USB 连手表，把 `bin/TimeLogger.prg` 拷到 `GARMIN/APPS/`。打开方式：**Start 键 → Apps → TimeLogger**。
