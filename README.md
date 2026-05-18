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
- **Press BACK on the running screen** to stop the timer.
- **Press START on the running screen** to switch: pick a different category and Toggl atomically stops the old timer and starts a new one.
- All timestamps are sent in UTC; Toggl renders them in your local time.

### Custom categories

Default list: `Deep Work, Meeting, Commute, Workout, Life Ops, Spanish, Reading, Personal`.

You can replace it with your own, **no rebuild required**:

1. Install the app on your watch.
2. On your phone, open **Garmin Connect Mobile** → your device → **Activities & App Management** → **Connect IQ Apps** → **TimeLogger** → **Settings**.
3. Edit the **Categories** field. Format: comma-separated string. Example: `Code, Email, Lunch, Walk, Sleep`.
4. Save. The new list shows up next time you open the app on the watch.

If you'd rather change the built-in default, edit both `resources/properties.xml` and the fallback in `source/TimeLoggerDelegate.mc` (`initialize` function), then rebuild.

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
- **运行页面按 BACK** 停止当前 timer。
- **运行页面按 START** 切换：选另一个类别，Toggl 会自动停掉旧 timer 并开新的。
- 所有时间戳用 UTC 发送，Toggl 会按你当地时区显示。

### 自定义类别

默认列表：`Deep Work, Meeting, Commute, Workout, Life Ops, Spanish, Reading, Personal`。

你可以换成自己的类别，**不需要重新编译**：

1. 把 app 装到手表上。
2. 手机上打开 **Garmin Connect Mobile** → 你的设备 → **活动与 app 管理** → **Connect IQ 应用** → **TimeLogger** → **设置**。
3. 编辑 **Categories** 字段，格式是逗号分隔的字符串，比如：`Code, Email, Lunch, Walk, Sleep`。
4. 保存。下次在手表上打开 app 时新列表生效。

如果想改源码里的默认值，同时编辑 `resources/properties.xml` 和 `source/TimeLoggerDelegate.mc` 里 `initialize` 函数中的 fallback 字符串，然后重新编译。

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
