# AGENTS.md — tiger-game 项目档案

> 这份文件是给**接下这个项目的 AI**（OpenCode / Cline / 任何 agent）看的。
> 每次开新会话先读一遍，你就不必从零摸索，也不会推翻已经定好的东西。
> 最后更新：2026-10-23

---

## 1. 这是什么

浏览器里的虎式坦克打靶小游戏。玩家选一门炮，把场上 8 个靶子全部打掉。

**在线地址**：https://gangliu8.github.io/tiger-131-game/
**技术栈**：纯 Three.js r169（本地 vendor），单文件 HTML，无框架、无构建、无 npm。

---

## 2. 项目主人（重要，决定你怎么干活）

- 叫他**刚哥**。3D 出身（3ds Max + Blender + ZBrush），**不写代码，也不打算学**。
- 他靠**看效果**验收，不读代码。所以：
  - 改完必须用**人话**说清"玩家会看到什么变化"，不要只贴 diff
  - 报错要翻译成人话（"这是啥、要不要紧、怎么处理"）
  - 不要假设他能看懂 `useEffect`、`state`、`drawcall` 这类词
- 他**看得出好坏**：造型、配色、手感、节奏，一眼就能挑出毛病。别糊弄。
- 花钱敏感：免费的活优先用免费模型，大改动才升舱。

## 3. 硬约束（违反就是错）

| 约束 | 原因 |
|---|---|
| **单文件 `index.html`，不引入框架、不引入构建** | 部署就是扔静态文件，双击 bat 就能跑。别提议上 Vite/React |
| **依赖只放 `vendor/`，不走 CDN** | 要能离线打开、要能在国内网络下跑 |
| **不能直接双击 `index.html` 预览** | `file://` 下浏览器禁止加载 glb 和 ES 模块，必须走 http |
| **`index.html` 必须在仓库根目录** | GitHub Pages 配置如此，挪位置就 404 |
| **不用 `--auto` 改文件，除非刚哥点头** | 他的主力工具是 OpenCode，不能被搞坏 |
| **动手前先 commit** | 这是唯一的回滚保险 |

## 4. 架构约定（改代码前必读）

### 火炮是配置驱动的

`index.html` 里有一个 `GUNS` 数组（约第 768 行），**每一门炮 = 一个模型 + 一份参数表**：

```js
{ id, no, name, code, tag, model, img,
  reload, shellSpeed, gravity, ballistic,
  aim: 'turret' | 'chassis', turretSpeed, pitchSpeed, pitch, recoil,
  drive: true/false, nodes: {turret, gun}, spawn, camDist, dial, keys, tip }
```

**加一门新炮，只需要往 `GUNS` 里加一项 + 放一个 glb + 一张车卡图。主循环不用动。**
这是现有架构最重要的约定，不要为了加一门炮去改渲染逻辑或输入逻辑。

**模型是按需下载的**：进页面只加载选炮界面的车卡图（JPEG，几十 KB）；
选中哪门炮，700 ms 后在后台预取它的 glb；点「出击」时如果还没下完，按钮显示「载 入 中…」等它。
所以首屏不会同时下两门炮的模型，加第三门炮也不会拖慢首屏。

### 现有的两门炮

| id | 名字 | 装填 | 特点 |
|---|---|---|---|
| `tiger` | 虎式 I 型（88mm KwK 36） | 2.4 s | 可行驶、炮塔可转、平射 |
| `ming` | 明代前装炮（实为**虎蹲炮**，崇祯年造铁铸） | 9.0 s | 固定炮位、整门旋转、弹道下沉 |

> 注意：代码和 UI 里的显示名是"明代前装炮"，但实际造型和考据依据是明代的**虎蹲炮**（戚继光《练兵实纪》记载的轻型前装炮）。改名要跟刚哥确认。

### 坦克零件的约定

- `Turret_Pivot` 炮塔（绕 Y，网页里限速 1.35 rad/s）
- `Gun` 炮管（原点在耳轴，绕 X 俯仰，带后坐）
- `Wheel_L/R_00..09` 20 个轮子、`Track_L/R_00..51` 104 片履带板
- 履带不是逐帧动画，而是：读初始位置 → 连成闭合折线 → 按弧长参数化 → 每帧按速度推移
- 差速：`vL = v − ω·1.41`、`vR = v + ω·1.41`（原地转向时两条履带反向）

## 5. 踩过的坑（别再踩一遍）

**Blender 导出侧**
1. 所有零件的旋转/缩放都烘进了网格（`transform_apply(rotation=True, scale=True)`）。从合并网格分出来的零件带着 −78° 物体旋转，网页里直接写 `rotation.x` 会打架。
2. 导出前必须 `hide_view_clear`。**隐藏物体会被 `use_selection` 静默漏掉**，曾经漏过一片 `Track_L_35`。
3. Blender 是**中文界面**，`nodes.get("Principled BSDF")` 取不到，要按 `node.type == 'BSDF_PRINCIPLED'` 找。
4. 金属材质在纯黑世界里会渲染成石膏——必须有环境可反射。

**OpenCode CLI 侧**

5. `opencode run` 不带 `--auto` 时，非交互模式遇到权限确认会**无限等待**（CPU 几乎为零、日志零输出）。只读任务可以带 `--auto`，改文件的活要人点头。

**浏览器侧**

6. 移动端和桌面端的布局是两套 CSS（有 `@media` 分界），改 UI 要两边都看。

## 6. 怎么验收一次改动

按顺序，缺一不可：

1. **本地起服务看一眼** —— 双击 `本地预览.bat`，或 `python -m http.server 8778`
2. **两门炮都试** —— 改武器相关代码时，`tiger` 和 `ming` 都要能正常切
3. **控制台无报错** —— 打开 DevTools 看 Console
4. **手机上试一遍** —— 触屏操作、性能、布局（电脑正常≠手机正常）
5. **`git diff --stat` 拉清单** —— 确认改动范围没有超出预期

完整的审核标准见上级目录的 `REVIEW.md`。

## 7. 部署

```bash
git add -A && git commit -m "说明" && git push
```
- 推上去后 GitHub Pages 自动构建，等 1~2 分钟生效
- **验证线上**：访问真实地址，确认版本是新的（别只看 push 成功）
- 注意：`github.com` 在国内可能连不上，Pages 站点本身通常能访问。推送失败时可尝试 `ssh.github.com:443`

## 8. 文件清单

| 路径 | 说明 |
|---|---|
| `index.html` | 游戏全部内容（约 66 KB，单文件） |
| `tiger.glb` | 虎式坦克模型 + 1K 烘焙贴图（1.2 MB） |
| `ming_cannon.glb` | 虎蹲炮模型（0.9 MB，JPEG 贴图） |
| `img/` | 车卡预览图（tiger_hero.jpg / ming_hero.jpg，各约 45 KB） |
| `vendor/` | Three.js r169 + GLTFLoader |
| `Tiger_game.blend` | Blender 源文件（炮塔可转、104 片履带独立） |
| `_preview/` `_mock/` | 预览与草稿，不参与部署 |
| `本地预览.bat` | 起本地服务器并打开浏览器 |
