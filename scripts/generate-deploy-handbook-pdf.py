# -*- coding: utf-8 -*-
"""
生成《作品集网站部署 & 资源管理操作手册》PDF
- 内容：部署流程、100MB 红线应对、图片/视频压缩、腾讯云 COS 使用
- 中文字体：微软雅黑（C:\\Windows\\Fonts\\msyh.ttc）
- 输出：项目根目录 / 2026-05-15-portfolio-deploy-handbook.pdf
"""

from pathlib import Path
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    PageBreak,
    Table,
    TableStyle,
    KeepTogether,
)

# ---------- 字体注册 ----------
FONT_REG = "MSYH"
FONT_BOLD = "MSYH-Bold"
pdfmetrics.registerFont(TTFont(FONT_REG, r"C:\Windows\Fonts\msyh.ttc", subfontIndex=0))
pdfmetrics.registerFont(TTFont(FONT_BOLD, r"C:\Windows\Fonts\msyhbd.ttc", subfontIndex=0))

# ---------- 颜色 ----------
C_PRIMARY = colors.HexColor("#0F172A")  # slate-900
C_ACCENT = colors.HexColor("#2563EB")   # blue-600
C_MUTED = colors.HexColor("#64748B")    # slate-500
C_BG_CODE = colors.HexColor("#F1F5F9")  # slate-100
C_BG_TIP = colors.HexColor("#FEF3C7")   # amber-100
C_BG_DANGER = colors.HexColor("#FEE2E2")  # red-100
C_BG_OK = colors.HexColor("#DCFCE7")    # green-100
C_BORDER = colors.HexColor("#E2E8F0")
C_TBL_HEAD = colors.HexColor("#1E293B")

# ---------- 样式 ----------
styles = getSampleStyleSheet()

S_TITLE = ParagraphStyle(
    "TitleZH", parent=styles["Title"], fontName=FONT_BOLD, fontSize=24,
    leading=30, textColor=C_PRIMARY, alignment=TA_CENTER, spaceAfter=6,
)
S_SUBTITLE = ParagraphStyle(
    "SubTitleZH", parent=styles["Normal"], fontName=FONT_REG, fontSize=11,
    leading=16, textColor=C_MUTED, alignment=TA_CENTER, spaceAfter=20,
)
S_H1 = ParagraphStyle(
    "H1ZH", parent=styles["Heading1"], fontName=FONT_BOLD, fontSize=18,
    leading=24, textColor=C_ACCENT, spaceBefore=18, spaceAfter=10,
)
S_H2 = ParagraphStyle(
    "H2ZH", parent=styles["Heading2"], fontName=FONT_BOLD, fontSize=14,
    leading=20, textColor=C_PRIMARY, spaceBefore=12, spaceAfter=6,
)
S_H3 = ParagraphStyle(
    "H3ZH", parent=styles["Heading3"], fontName=FONT_BOLD, fontSize=11.5,
    leading=18, textColor=C_PRIMARY, spaceBefore=8, spaceAfter=4,
)
S_BODY = ParagraphStyle(
    "BodyZH", parent=styles["Normal"], fontName=FONT_REG, fontSize=10.5,
    leading=18, textColor=C_PRIMARY, alignment=TA_LEFT, spaceAfter=4,
)
S_LIST = ParagraphStyle(
    "ListZH", parent=S_BODY, fontName=FONT_REG, fontSize=10.5,
    leading=18, leftIndent=14, bulletIndent=2, spaceAfter=2,
)
S_CODE = ParagraphStyle(
    "CodeZH", parent=styles["Code"], fontName="Courier", fontSize=9.5,
    leading=14, textColor=C_PRIMARY, leftIndent=8, rightIndent=8,
    spaceBefore=4, spaceAfter=8, backColor=C_BG_CODE, borderPadding=8,
)
S_TIP = ParagraphStyle(
    "TipZH", parent=S_BODY, fontName=FONT_REG, fontSize=10,
    leading=16, leftIndent=10, rightIndent=10, spaceBefore=4, spaceAfter=8,
    backColor=C_BG_TIP, borderPadding=8, textColor=C_PRIMARY,
)
S_DANGER = ParagraphStyle(
    "DangerZH", parent=S_TIP, backColor=C_BG_DANGER,
)
S_OK = ParagraphStyle(
    "OkZH", parent=S_TIP, backColor=C_BG_OK,
)
S_FOOTER = ParagraphStyle(
    "FooterZH", parent=styles["Normal"], fontName=FONT_REG, fontSize=8.5,
    leading=12, textColor=C_MUTED, alignment=TA_CENTER,
)


# ---------- 工具函数 ----------
def h1(text):
    return Paragraph(text, S_H1)

def h2(text):
    return Paragraph(text, S_H2)

def h3(text):
    return Paragraph(text, S_H3)

def p(text):
    return Paragraph(text, S_BODY)

def li(text):
    return Paragraph(f"• {text}", S_LIST)

def code(text):
    # reportlab Paragraph 里换行用 <br/>
    safe = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    safe = safe.replace("\n", "<br/>")
    return Paragraph(safe, S_CODE)

def tip(text):
    return Paragraph(f"<b>提示：</b>{text}", S_TIP)

def danger(text):
    return Paragraph(f"<b>⚠ 注意：</b>{text}", S_DANGER)

def ok(text):
    return Paragraph(f"<b>✓ 正确做法：</b>{text}", S_OK)

def spacer(h=8):
    return Spacer(1, h)

def make_table(data, col_widths, header=True):
    t = Table(data, colWidths=col_widths, repeatRows=1 if header else 0)
    style = [
        ("FONTNAME", (0, 0), (-1, -1), FONT_REG),
        ("FONTSIZE", (0, 0), (-1, -1), 9.5),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("GRID", (0, 0), (-1, -1), 0.4, C_BORDER),
    ]
    if header:
        style += [
            ("BACKGROUND", (0, 0), (-1, 0), C_TBL_HEAD),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), FONT_BOLD),
            ("ALIGN", (0, 0), (-1, 0), "CENTER"),
        ]
    # 斑马纹
    for row_i in range(1, len(data)):
        if row_i % 2 == 0:
            style.append(("BACKGROUND", (0, row_i), (-1, row_i), colors.HexColor("#F8FAFC")))
    t.setStyle(TableStyle(style))
    return t


# ---------- 页眉页脚 ----------
def on_page(canvas, doc):
    canvas.saveState()
    # 页脚
    canvas.setFont(FONT_REG, 8.5)
    canvas.setFillColor(C_MUTED)
    canvas.drawCentredString(
        A4[0] / 2, 1.2 * cm,
        f"作品集网站部署 & 资源管理手册  |  guoxuyang618/portfolio  |  第 {doc.page} 页"
    )
    # 页眉装饰线
    canvas.setStrokeColor(C_BORDER)
    canvas.setLineWidth(0.5)
    canvas.line(2 * cm, A4[1] - 1.5 * cm, A4[0] - 2 * cm, A4[1] - 1.5 * cm)
    canvas.restoreState()


# ---------- 内容 ----------
def build_story():
    s = []

    # ======== 封面 ========
    s.append(Spacer(1, 4 * cm))
    s.append(Paragraph("作品集网站", S_TITLE))
    s.append(Paragraph("部署 & 资源管理操作手册", S_TITLE))
    s.append(spacer(12))
    s.append(Paragraph(
        "PowerShell 一键部署 · 媒体文件压缩 · 100MB 红线应对 · 腾讯云 COS 接入",
        S_SUBTITLE,
    ))
    s.append(spacer(40))

    # 元信息表
    meta = [
        ["项目仓库", "github.com/guoxuyang618/portfolio"],
        ["部署平台", "EdgeOne Pages（自动构建）"],
        ["主分支",   "master"],
        ["编写日期", "2026-05-15"],
        ["版本号",   "v1.0 deploy-handbook"],
        ["适用对象", "matthewguo（独立设计师 / 前端开发）"],
    ]
    s.append(make_table(meta, [4 * cm, 11 * cm], header=False))

    s.append(spacer(40))
    s.append(Paragraph(
        "本手册为操作型文档，章节按"
        "<b>「日常部署 → 媒体压缩 → 突破 100MB → 腾讯云 COS」</b>"
        "的递进顺序编排，可按需跳读。",
        S_BODY,
    ))
    s.append(PageBreak())

    # ======== 目录 ========
    s.append(h1("目录"))
    toc = [
        ["第 1 章", "部署流程：PowerShell 三连完成上线", "P.3"],
        ["第 2 章", "媒体资源规则：图片 / 视频上传前自查", "P.5"],
        ["第 3 章", "图片压缩：转 WebP 的两种方式", "P.7"],
        ["第 4 章", "视频压缩：HandBrake & ffmpeg", "P.8"],
        ["第 5 章", "突破 100MB：腾讯云 COS 接入指南", "P.10"],
        ["第 6 章", "应急 & 回滚：翻车了怎么办", "P.13"],
        ["附录 A",  "PowerShell 速查命令清单", "P.14"],
        ["附录 B",  "EdgeOne 控制台关键页面", "P.15"],
    ]
    s.append(make_table(
        [["章节", "标题", "页码"]] + toc,
        [2.5 * cm, 10 * cm, 2.5 * cm],
    ))
    s.append(PageBreak())

    # ======== 第 1 章 ========
    s.append(h1("第 1 章  部署流程：PowerShell 三连"))

    s.append(h2("1.1  部署链路真相"))
    s.append(p("无论用 VSCode、CodeBuddy 还是 PowerShell，本质都是把代码 push 到 GitHub。"
               "<b>EdgeOne 监听 GitHub master 分支</b>，有新 commit 就自动构建上线。"))
    s.append(code(
        "你改代码（任何编辑器）\n"
        "        ↓\n"
        "git add . / git commit / git push origin master\n"
        "        ↓\n"
        "GitHub 收到 push 事件\n"
        "        ↓\n"
        "EdgeOne webhook 触发 → 自动 npm install + build\n"
        "        ↓\n"
        "外网生效（约 1-3 分钟）"
    ))

    s.append(h2("1.2  日常部署三连命令"))
    s.append(p("在 PowerShell 里执行（复制即用）："))
    s.append(code(
        "cd c:\\Users\\matthewguo\\CodeBuddy\\portfolio-website\n"
        "git add .\n"
        "git commit -m \"你的改动描述\"\n"
        "git push"
    ))
    s.append(tip("<b>commit message 写法建议：</b>用动词开头，简洁直白。例如：<br/>"
                 "• feat: 新增 Tencent CSIG 项目页<br/>"
                 "• fix: 修复 about 页手机端 hero 图溢出<br/>"
                 "• style: 调整 works 卡片间距<br/>"
                 "• docs: 更新 README 说明"))

    s.append(h2("1.3  推送后如何验证"))
    s.append(li("打开 EdgeOne 控制台 → xydesign 项目页"))
    s.append(li("观察「构建次数」+1，状态从 <b>Building</b> 变为 <b>Running</b>"))
    s.append(li("等 1-3 分钟后，刷新外网域名验证"))
    s.append(li("如果 5 分钟未触发，控制台点「重新部署」手动触发"))

    s.append(h2("1.4  常用辅助命令"))
    cmd_table = [
        ["目的", "命令"],
        ["查看当前改了哪些文件", "git status"],
        ["查看具体改动差异", "git diff"],
        ["查看最近 5 条提交", "git log --oneline -5"],
        ["撤销未提交的本地改动", "git checkout -- 文件名"],
        ["拉取最新远端代码", "git pull"],
        ["查看远端地址", "git remote -v"],
    ]
    s.append(make_table(cmd_table, [5 * cm, 10 * cm]))

    s.append(PageBreak())

    # ======== 第 2 章 ========
    s.append(h1("第 2 章  媒体资源规则：上传前自查"))

    s.append(h2("2.1  GitHub 单文件大小红线"))
    size_table = [
        ["文件大小", "GitHub 行为", "是否能 push"],
        ["< 50 MB",   "完全正常", "✅ 可以"],
        ["50 - 100 MB", "弹警告但放行", "⚠ 不建议"],
        ["> 100 MB",  "直接拒收", "❌ 不可以"],
    ]
    s.append(make_table(size_table, [4 * cm, 6 * cm, 4 * cm]))
    s.append(danger("一旦带 &gt;100MB 文件 commit 并 push，GitHub 会拒收。"
                    "需要先用 <b>git filter-repo</b> 把文件从历史中清除，过程有风险。"
                    "本手册第 6 章有完整应对流程。"))

    s.append(h2("2.2  push 前自查脚本"))
    s.append(p("把以下命令保存为 <b>check-size.ps1</b>，每次 push 前先跑一遍："))
    s.append(code(
        "# 列出 public/ 和 src/ 下所有 > 50MB 的文件\n"
        "Get-ChildItem public,src -Recurse -File `\n"
        "  | Where-Object { $_.Length -gt 50MB } `\n"
        "  | Select-Object @{N='MB';E={[math]::Round($_.Length/1MB,1)}}, FullName `\n"
        "  | Sort-Object MB -Descending"
    ))
    s.append(ok("如果输出为空 → 安全 push。<br/>"
                "如果有 &gt;100MB 项 → 不要 push，先按第 3-5 章处理。"))

    s.append(h2("2.3  仓库整体大小自查"))
    s.append(code(
        '"{0:N1} MB" -f ((Get-ChildItem .git -Recurse `\n'
        "  | Measure-Object -Property Length -Sum).Sum / 1MB)"
    ))
    s.append(p("正常的作品集仓库 .git 应该在 <b>50MB 以内</b>。"
               "如果超过 200MB，说明历史里混入了大文件，需要清理。"))

    s.append(h2("2.4  作品集媒体格式建议"))
    fmt_table = [
        ["资源类型", "推荐格式", "推荐尺寸 / 大小"],
        ["项目封面图",     "WebP",   "1600×900，<300 KB"],
        ["作品详情大图",   "WebP",   "宽 1920，<500 KB / 张"],
        ["头像 / 小图标",  "WebP / SVG", "<50 KB"],
        ["展示视频",       "MP4 (H.264)", "720p 30fps，<30 MB / 条"],
        ["背景循环视频",   "MP4 / WebM",  "720p，<10 MB（必须 muted loop）"],
    ]
    s.append(make_table(fmt_table, [4 * cm, 4 * cm, 7 * cm]))

    s.append(PageBreak())

    # ======== 第 3 章 ========
    s.append(h1("第 3 章  图片压缩：转 WebP"))

    s.append(h2("3.1  方式 A：Squoosh 在线工具（推荐新手）"))
    s.append(li("打开 <b>https://squoosh.app</b>"))
    s.append(li("拖入图片 → 右侧选择 <b>WebP</b> 格式"))
    s.append(li("Quality 滑块设为 <b>80-85</b>（人眼无明显差异）"))
    s.append(li("点右下角 ↓ 下载"))
    s.append(tip("Squoosh 是 Google 出品，纯前端不上传服务器，隐私安全。"))

    s.append(h2("3.2  方式 B：批量命令行（适合一次几十张）"))
    s.append(p("用 <b>cwebp</b>（Google 官方 WebP 压缩器）。"
               "下载地址：developers.google.com/speed/webp/download"))
    s.append(p("PowerShell 批量转换："))
    s.append(code(
        "# 把当前目录所有 jpg/png 转成 webp（quality 85）\n"
        "Get-ChildItem -File -Include *.jpg,*.png -Recurse `\n"
        "  | ForEach-Object {\n"
        "      $out = [System.IO.Path]::ChangeExtension($_.FullName, '.webp')\n"
        "      cwebp -q 85 $_.FullName -o $out\n"
        "  }"
    ))

    s.append(h2("3.3  压缩效果参考"))
    cmp_table = [
        ["原图类型", "原始大小", "WebP q=85", "缩减比例"],
        ["1920×1080 PNG 截图", "2.4 MB", "240 KB", "↓ 90%"],
        ["3000×2000 JPG 照片", "4.1 MB", "680 KB", "↓ 83%"],
        ["1080p 设计稿 PNG",   "5.8 MB", "520 KB", "↓ 91%"],
    ]
    s.append(make_table(cmp_table, [5 * cm, 3 * cm, 3 * cm, 3 * cm]))

    s.append(h2("3.4  代码引用"))
    s.append(code(
        '<!-- src/pages/works.astro -->\n'
        '<img src="/works/csig/cover.webp" alt="CSIG 项目封面"\n'
        '     loading="lazy" decoding="async" />'
    ))
    s.append(tip("加上 <b>loading=\"lazy\"</b> 可让首屏外的图延迟加载，提升手机端打开速度。"))

    s.append(PageBreak())

    # ======== 第 4 章 ========
    s.append(h1("第 4 章  视频压缩"))

    s.append(h2("4.1  方式 A：HandBrake 图形界面（推荐）"))
    s.append(li("下载安装：<b>https://handbrake.fr</b>"))
    s.append(li("打开 → 拖入源视频"))
    s.append(li("右侧 Preset 选择：<b>Web → Gmail Large 3 Min 720p30</b>"))
    s.append(li("如果文件还偏大，把 Quality (RF) 从 22 调到 <b>26-28</b>"))
    s.append(li("点 <b>Start Encode</b> 输出"))

    s.append(h2("4.2  方式 B：ffmpeg 命令行（精准控制）"))
    s.append(p("下载 ffmpeg：<b>https://www.gyan.dev/ffmpeg/builds/</b>（选 release essentials）"))
    s.append(p("解压后把 bin 目录加入系统 PATH，PowerShell 里直接用："))
    s.append(code(
        "# 标准压缩：720p H.264，CRF 28（值越大越小但越糊）\n"
        "ffmpeg -i input.mp4 `\n"
        "  -vcodec libx264 -crf 28 -preset slow `\n"
        "  -vf \"scale=-2:720\" `\n"
        "  -acodec aac -b:a 96k `\n"
        "  -movflags +faststart `\n"
        "  output.mp4"
    ))
    s.append(tip("<b>-movflags +faststart</b> 把视频元数据放到文件开头，"
                 "网页边下边播体验更好。<b>务必加上</b>。"))

    s.append(h2("4.3  极限压缩（背景循环视频）"))
    s.append(p("用作 hero 区域装饰的视频，可压得更狠："))
    s.append(code(
        "ffmpeg -i input.mp4 `\n"
        "  -vcodec libx264 -crf 32 -preset veryslow `\n"
        "  -vf \"scale=-2:540,fps=24\" `\n"
        "  -an `\n"
        "  -movflags +faststart `\n"
        "  hero-bg.mp4\n\n"
        "# -an 去掉音轨（背景视频不需要声音）\n"
        "# fps=24 降帧率，CRF 32 进一步压"
    ))

    s.append(h2("4.4  双端兼容的视频标签"))
    s.append(code(
        '<video\n'
        '  src="/videos/hero-bg.mp4"\n'
        '  autoplay\n'
        '  muted\n'
        '  loop\n'
        '  playsinline   // ⭐ iOS 必须，否则全屏播放\n'
        '  preload="metadata"\n'
        '  style="width:100%; height:100%; object-fit:cover;"\n'
        '></video>'
    ))
    s.append(danger("iOS Safari 必须同时满足 <b>muted + playsinline + autoplay</b> "
                    "三个属性才能自动播放。缺一个都会播不出。"))

    s.append(h2("4.5  压缩效果参考"))
    vcmp_table = [
        ["原始", "压缩参数", "压缩后", "用途"],
        ["1080p / 30s / 220 MB",  "CRF 28, 720p",  "12 MB",  "项目展示"],
        ["1080p / 60s / 480 MB",  "CRF 28, 720p",  "26 MB",  "Demo 演示"],
        ["1080p / 15s / 90 MB",   "CRF 32, 540p",  "3.2 MB", "Hero 背景"],
    ]
    s.append(make_table(vcmp_table, [4.5 * cm, 4 * cm, 3 * cm, 3.5 * cm]))

    s.append(PageBreak())

    # ======== 第 5 章 ========
    s.append(h1("第 5 章  突破 100MB：腾讯云 COS"))

    s.append(h2("5.1  什么时候需要 COS？"))
    s.append(li("单个视频压完仍 &gt; 80MB（如 4K 完整 demo）"))
    s.append(li("项目素材累计超过 1GB，仓库太重"))
    s.append(li("需要给客户分享单独大文件链接"))

    s.append(p("<b>COS = Cloud Object Storage</b>，腾讯云的对象存储服务。"
               "可以理解为「专门存大文件的网盘，每个文件有公开 URL，可以直接在网页里引用」。"))

    s.append(h2("5.2  开通 COS（首次 5 分钟）"))
    s.append(li("登录 <b>console.cloud.tencent.com</b>"))
    s.append(li("搜索「对象存储」→ 进入控制台"))
    s.append(li("点「创建存储桶」"))

    bucket_table = [
        ["配置项", "推荐填写"],
        ["名称", "portfolio-assets-{随机数字}（全局唯一）"],
        ["所属地域", "广州 / 上海（看你受众）"],
        ["访问权限", "<b>公有读私有写</b>（必选）"],
        ["请求域名", "默认即可"],
    ]
    s.append(make_table(bucket_table, [4 * cm, 11 * cm]))

    s.append(h3("成本预估"))
    s.append(li("存储费：0.118 元 / GB / 月（标准存储）"))
    s.append(li("外网下行流量：0.5 元 / GB"))
    s.append(li("假设 5GB 素材 + 月访问 100GB → 月成本 ≈ 50 元"))
    s.append(tip("新用户有免费额度（50GB 存储 + 10GB 流量 / 月，半年）。"
                 "作品集这种低频访问，前期基本免费。"))

    s.append(h2("5.3  上传文件并获取 URL"))
    s.append(li("进入存储桶 → 点「上传文件」"))
    s.append(li("拖拽视频/大图到上传区域"))
    s.append(li("上传完成后点文件名 → 复制「对象地址」"))
    s.append(p("对象地址格式："))
    s.append(code(
        "https://portfolio-assets-1234567890.cos.ap-guangzhou.myqcloud.com/videos/demo.mp4"
    ))

    s.append(h2("5.4  在代码里引用 COS 文件"))
    s.append(p("跟引用本地文件几乎一样，只是 src 换成完整 URL："))
    s.append(code(
        '<!-- 视频 -->\n'
        '<video\n'
        '  src="https://portfolio-assets-xxx.cos.ap-guangzhou.myqcloud.com/videos/demo.mp4"\n'
        '  autoplay muted loop playsinline\n'
        '></video>\n\n'
        '<!-- 大图 -->\n'
        '<img\n'
        '  src="https://portfolio-assets-xxx.cos.ap-guangzhou.myqcloud.com/works/4k-cover.webp"\n'
        '  loading="lazy"\n'
        '/>'
    ))

    s.append(h2("5.5  推荐做法：把 COS 域名提取成变量"))
    s.append(p("以后换桶或换 CDN 时，只要改一个常量。"))
    s.append(code(
        '// src/config/assets.ts\n'
        'export const CDN = "https://portfolio-assets-xxx.cos.ap-guangzhou.myqcloud.com";\n\n'
        '// 使用\n'
        'import { CDN } from "../config/assets";\n'
        '<video src={`${CDN}/videos/demo.mp4`} ... />'
    ))

    s.append(h2("5.6  常见问题"))
    qa_table = [
        ["问题", "解决"],
        ["视频跨域无法播放",   "存储桶 → 安全管理 → 跨域访问 CORS 设置 → 添加规则：Origin=*，Methods=GET"],
        ["手机端加载慢",       "开通 COS 加速域名（CDN），延迟降到 <100ms"],
        ["文件被恶意盗链",     "存储桶 → 安全管理 → 防盗链：白名单填你的域名"],
        ["上传速度慢",         "选择就近的存储地域；或用 COSBrowser 客户端"],
    ]
    s.append(make_table(qa_table, [5 * cm, 10 * cm]))

    s.append(PageBreak())

    # ======== 第 6 章 ========
    s.append(h1("第 6 章  应急 & 回滚"))

    s.append(h2("6.1  误 push 大文件被 GitHub 拒收"))
    s.append(p("典型报错："))
    s.append(code(
        "remote: error: File xxx.mp4 is 145.32 MB;\n"
        "this exceeds GitHub's file size limit of 100.00 MB"
    ))
    s.append(p("处理流程："))
    s.append(li("先打安全 tag：<b>git tag safety-before-cleanup-YYYY-MM-DD</b>"))
    s.append(li("安装清理工具：<b>pip install git-filter-repo</b>"))
    s.append(li("清除大文件：<b>python -m git_filter_repo --path 大文件路径 --invert-paths --force</b>"))
    s.append(li("重新加 origin：<b>git remote add origin https://github.com/guoxuyang618/portfolio.git</b>"))
    s.append(li("强推：<b>git push origin master --force</b>"))
    s.append(danger("<b>--force</b> 会改写远端历史。执行前务必确认远端没有别人在协作。"
                    "本项目是单人维护，可以放心 force。"))

    s.append(h2("6.2  本地代码搞砸了想回退"))
    s.append(code(
        "# 看最近 10 条提交，找到要回到的那条的 sha\n"
        "git log --oneline -10\n\n"
        "# 硬回退（丢弃所有当前未提交改动）\n"
        "git reset --hard {sha}\n\n"
        "# 软回退（保留改动到工作区）\n"
        "git reset --soft {sha}"
    ))

    s.append(h2("6.3  线上版本想回滚"))
    s.append(p("两种方式："))
    s.append(li("<b>方式 1：EdgeOne 控制台</b> → 部署历史 → 找到老版本点「回滚到此版本」"))
    s.append(li("<b>方式 2：git 反向提交</b><br/>"
                "<font face='Courier'>git revert {sha}</font> 然后 push，触发 EdgeOne 重新部署"))
    s.append(tip("方式 1 不改 git 历史，最安全。方式 2 留痕清晰，方便审计。"))

    s.append(h2("6.4  本项目已有的安全 tag"))
    s.append(p("以下 tag 是历史关键节点，必要时可用作回退锚点："))
    tag_table = [
        ["Tag 名", "含义"],
        ["safety-before-cleanup-2026-05-15", "filter-repo 清理 dist-deploy.zip 之前的 HEAD"],
        ["backup-remote-master-2026-05-15",  "force push 之前远端的 10 个 commit"],
        ["deploy-v1.9.0-2026-05-15",         "本次正式部署的里程碑 tag"],
    ]
    s.append(make_table(tag_table, [7 * cm, 8 * cm]))

    s.append(PageBreak())

    # ======== 附录 A ========
    s.append(h1("附录 A  PowerShell 速查命令"))

    s.append(h2("A.1  日常部署"))
    s.append(code(
        "cd c:\\Users\\matthewguo\\CodeBuddy\\portfolio-website\n"
        "git status                          # 查看改了什么\n"
        "git add .                           # 暂存所有改动\n"
        "git commit -m \"feat: xxx\"           # 提交\n"
        "git push                            # 推送到 GitHub"
    ))

    s.append(h2("A.2  本地开发"))
    s.append(code(
        "npm install                         # 首次/依赖变化时\n"
        "npm run dev                         # 启动本地服务（默认 4321）\n"
        "npm run build                       # 本地构建（验证用）\n"
        "npm run preview                     # 预览构建产物"
    ))

    s.append(h2("A.3  媒体大小自查"))
    s.append(code(
        "# 找 public/src 下 >50MB 文件\n"
        "Get-ChildItem public,src -Recurse -File `\n"
        "  | Where-Object { $_.Length -gt 50MB } `\n"
        "  | Select-Object @{N='MB';E={[math]::Round($_.Length/1MB,1)}}, FullName\n\n"
        "# 仓库总大小\n"
        '"{0:N1} MB" -f ((Get-ChildItem .git -Recurse `\n'
        "  | Measure-Object -Property Length -Sum).Sum / 1MB)"
    ))

    s.append(h2("A.4  紧急回滚"))
    s.append(code(
        "git tag                             # 看所有 tag\n"
        "git reset --hard {tag-or-sha}       # 回退本地\n"
        "git push origin master --force      # 同步到远端（慎用）"
    ))

    s.append(PageBreak())

    # ======== 附录 B ========
    s.append(h1("附录 B  EdgeOne 控制台关键页面"))

    page_table = [
        ["页面", "用途"],
        ["项目概览",       "看构建次数、最近部署状态、外网域名"],
        ["部署历史",       "查看每次部署详情、回滚老版本"],
        ["构建日志",       "构建失败时排查原因（npm install / build 报错）"],
        ["域名管理",       "绑定自定义域名、配置 HTTPS"],
        ["环境变量",       "配置 NODE_VERSION 等构建参数"],
        ["功能（Functions）", "如需 SSR、API 时使用（当前作品集为纯静态，不用）"],
    ]
    s.append(make_table(page_table, [4 * cm, 11 * cm]))

    s.append(spacer(20))
    s.append(h2("B.1  常见构建失败原因"))
    fail_table = [
        ["报错关键字", "原因 / 解决"],
        ["ENOSPC",            "EdgeOne 临时空间不足，重试或精简依赖"],
        ["npm ERR! peer dep", "依赖版本冲突，本地 npm install 重现 → 改 package.json"],
        ["module not found",  "import 路径写错或文件没 push 上去"],
        ["build timeout",     "构建超时（默认 10 分钟），优化构建脚本"],
    ]
    s.append(make_table(fail_table, [5 * cm, 10 * cm]))

    s.append(spacer(30))
    s.append(Paragraph(
        "—— 本手册结束 ——",
        ParagraphStyle("End", parent=S_BODY, alignment=TA_CENTER,
                       fontName=FONT_BOLD, textColor=C_MUTED, fontSize=10),
    ))
    s.append(spacer(8))
    s.append(Paragraph(
        "如有补充内容（比如新增了 Cloudflare Pages 备用部署），"
        "可在原项目对话里让 CodeBuddy 重新生成新版本。",
        ParagraphStyle("EndNote", parent=S_BODY, alignment=TA_CENTER,
                       fontSize=9, textColor=C_MUTED),
    ))

    return s


# ---------- 生成 ----------
def main():
    out = Path(__file__).resolve().parent.parent / "2026-05-15-portfolio-deploy-handbook.pdf"
    doc = SimpleDocTemplate(
        str(out),
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
        title="作品集网站部署 & 资源管理操作手册",
        author="matthewguo + CodeBuddy",
        subject="Portfolio Deploy & Asset Management Handbook",
    )
    doc.build(build_story(), onFirstPage=on_page, onLaterPages=on_page)
    size_kb = out.stat().st_size / 1024
    print(f"OK  -> {out}")
    print(f"     size = {size_kb:.1f} KB")


if __name__ == "__main__":
    main()
