#Requires AutoHotkey v2.0
#SingleInstance Force

global DropFiles := []
global FontSize := 20
global Outline := 2
global Shadow := 0
global Color := "D8D8D8"
global Alpha := "50"

Main := Gui(,"ASS HDR 字幕优化工具 Roylor")
Main.BackColor := "202020"
Main.SetFont("s10","Microsoft YaHei")

Main.AddText("x20 y20 w520 Center cFFFFFF"
,"请把 ASS 字幕拖到下面区域")

Drop := Main.AddEdit("x20 y50 w520 h120 ReadOnly Center -VScroll vDropBox")
Drop.Opt("+Background303030 cFFFFFF")

Drop.Value :=
(
"📂 请拖拽 ASS 字幕文件或文件夹到这里`r`n`r`n"
"支持批量拖拽、自动识别子文件夹`r`n`r`n"
"等待加载..."
)

Main.AddText("x20 y205 cFFFFFF","字号")
EditSize := Main.AddEdit("x70 y200 w60",FontSize)

Main.AddText("x150 y205 cFFFFFF","描边")
EditOutline := Main.AddEdit("x200 y200 w60",Outline)

Main.AddText("x280 y205 cFFFFFF","阴影")
EditShadow := Main.AddEdit("x330 y200 w60",Shadow)

Main.AddText("x410 y205 cFFFFFF","颜色")
EditColor := Main.AddEdit("x455 y200 w85",Color)

Main.AddText("x20 y235 cFFFFFF","透明")
EditAlpha := Main.AddEdit("x70 y230 w60", Alpha)

Main.AddText("x150 y235 cFFFFFF","输出前缀")
EditPrefix := Main.AddEdit("x220 y230 w320","")

Main.AddText("x20 y265 cFFFFFF","命名模板")
EditTemplate := Main.AddEdit("x90 y260 w450","")

Main.AddText("x20 y290 cFFFFFF","命名方式")

ModePrefix := Main.AddRadio("x20 y315 Checked cFFFFFF","输出前缀")
ModeTemplate := Main.AddRadio("x170 y315 cFFFFFF","命名模板")



Preset := Main.AddButton("x40 y350 w120 h35","HDR预设")
Btn := Main.AddButton("x180 y350 w180 h35","开始转换")
Reset := Main.AddButton("x390 y350 w120 h35","恢复默认")

Preset.OnEvent("Click",LoadHDRPreset)
Btn.OnEvent("Click",Convert)
Reset.OnEvent("Click",ResetValue)

Main.OnEvent("DropFiles",GuiDropFiles)
Main.OnEvent("Close",(*)=>ExitApp())
SetCueBanner(EditPrefix.Hwnd, "例：遮天S01 生成结果为：遮天S01E*")
SetCueBanner(EditTemplate.Hwnd, "例：斗破苍穹2015第十一版第一季第一集  或 遮天S01E01  或  第01集")
Main.AddText(
"x20 y410 w520 Center c808080",
"Version 2.0.0    © Royalor    版权所有 盗版必究"
)
Main.Show("w560 h480")

return



GuiDropFiles(GuiObj, GuiCtrl, Files, X, Y)
{
    global DropFiles

    DropFiles := []

    FolderCount := 0

    for item in Files
    {
        if DirExist(item)
        {
            FolderCount++

            Loop Files item "\*.ass", "R"
                DropFiles.Push(A_LoopFileFullPath)

            Loop Files item "\*.srt", "R"
                DropFiles.Push(A_LoopFileFullPath)
        }
        else
        {
            SplitPath(item, , , &ext)

            ext := StrLower(ext)

            if (ext="ass" || ext="srt")
                DropFiles.Push(item)
        }
    }

    msg := "📂 已加载 " DropFiles.Length " 个字幕文件"

    if FolderCount
        msg .= "`r`n`r`n来自 " FolderCount " 个文件夹"

    msg .= "`r`n`r`n点击【开始转换】"

    GuiObj["DropBox"].Value := msg
}

Convert(*)
{
    global EditAlpha
    global DropFiles
global Main
    global EditSize
    global EditOutline
    global EditShadow
    global EditColor
    global EditPrefix
    global EditTemplate
    global ModePrefix
global ModeTemplate

    if (DropFiles.Length = 0)
    {
        MsgBox("没有找到ASS字幕")
        return
    }

    ok := 0
    fail := 0

    for file in DropFiles
    {
        try
        {
            ConvertOne(
    file,
    Integer(EditSize.Value),
    Integer(EditOutline.Value),
    Integer(EditShadow.Value),
    Trim(EditColor.Value),
    Trim(EditAlpha.Value),
    NormalizePrefix(EditPrefix.Value),
    Trim(EditTemplate.Value),
    ModeTemplate.Value
)
            ok++
        }
        catch Error as e
        {
            fail++
        }
    }
Main["DropBox"].Value :=
(
"✅ 转换完成！`r`n`r`n"
"共输出 " DropFiles.Length " 个字幕文件"
)
    MsgBox(
        "完成！`n`n成功：" ok "`n失败：" fail
    )
}



ConvertOne(file, FontSize, Outline, Shadow, Color, Alpha, Prefix, Template, UseTemplate)

{
    txt := FileRead(file, "UTF-8")

    ; ========= 修改颜色 =========

    txt := RegExReplace(txt,"i)&H00FFFFFF","&H" Alpha Color)
    txt := RegExReplace(txt,"i)&H00FEFEFE","&H" Alpha Color)

    lines := StrSplit(txt, "`n")

    out := ""

    inStyle := false

    for line in lines
    {
        line := RTrim(line,"`r")

        ;=========================
        ; 判断进入 Styles 区域
        ;=========================

        if (line = "[V4+ Styles]")
        {
            inStyle := true
            out .= line "`r`n"
            continue
        }

        if (SubStr(line,1,1)="[" && line!="[V4+ Styles]")
        {
            inStyle := false
        }

        ;=========================
        ; 处理所有 Style
        ;=========================

        if (inStyle && SubStr(line,1,6)="Style:")
        {
            arr := StrSplit(line,",")

            if(arr.Length>=23)
            {
                ; 字号
                arr[3]:=FontSize

                ; Outline
                arr[17]:=Outline

                ; Shadow
                arr[18]:=Shadow

                ; 主颜色

                arr[4] := "&H" Alpha Color
            }

            newline:=""

            Loop arr.Length
            {
                newline .= arr[A_Index]

                if(A_Index<arr.Length)
                    newline .= ","
            }

            line:=newline
        }

        out .= line "`r`n"
    }

    SplitPath file,&Name,&Dir,&Ext,&NameNoExt

Episode := GetEpisodeNumber(NameNoExt)

if (Episode = "")
{
    Episode := "00"
}

if (UseTemplate && Trim(Template) != "")
{
    NewName := BuildTemplateName(Template, Episode) ".ass"
}
else
{
    if (Prefix != "")
        NewName := Prefix "E" Episode ".ass"
    else
        NewName := "E" Episode ".ass"
}

save := Dir "\" NewName

    if FileExist(save)
        FileDelete(save)

    FileAppend(out,save,"UTF-8")
}
LoadHDRPreset(*)
{
    global EditSize
    global EditOutline
    global EditShadow
    global EditColor
    global EditAlpha

    EditSize.Value := 20
    EditOutline.Value := 2
    EditShadow.Value := 0
    EditColor.Value := "D8D8D8"
    EditAlpha.Value := "50"
}



ResetValue(*)
{
    global EditSize
    global EditOutline
    global EditShadow
    global EditColor

    EditSize.Value := 19
    EditOutline.Value := 1
    EditShadow.Value := 1
    EditColor.Value := "FFFFFF"
}


GetEpisodeNumber(Name)
{
    ;=========================
    ; 先清理容易干扰的标签
    ;=========================

    s := Name

    ; 删除分辨率、编码等信息
    s := RegExReplace(s, "i)\b(2160|1080|720|480)p\b")
    s := RegExReplace(s, "i)\b(x264|x265|h264|h265|hevc|av1)\b")
    s := RegExReplace(s, "i)\b(aac|ac3|ddp|truehd|dts|atmos)\b")
    s := RegExReplace(s, "i)\b(remux|bluray|web[- ]?dl|hdr|dovi|dv)\b")

    ;=========================
    ; S01E08
    ;=========================

    if RegExMatch(s, "i)S\d+\s*E(\d+)", &m)
        return Format("{:02}", Integer(m[1]))

    ;=========================
    ; 单独 E08
    ;=========================

    if RegExMatch(s, "i)\bE(\d+)\b", &m)
        return Format("{:02}", Integer(m[1]))

    ;=========================
    ; EP08 / Episode08
    ;=========================

    if RegExMatch(s, "i)\bEP(?:ISODE)?\s*(\d+)\b", &m)
        return Format("{:02}", Integer(m[1]))

    ;=========================
    ; 第08集
    ;=========================

    if RegExMatch(s, "第\s*(\d+)\s*集", &m)
        return Format("{:02}", Integer(m[1]))

    ;=========================
    ; [08]
    ;=========================

    if RegExMatch(s, "\[(\d{1,3})\]", &m)
        return Format("{:02}", Integer(m[1]))

    ;=========================
    ; - 08
    ;=========================

    if RegExMatch(s, "-\s*(\d{1,3})", &m)
        return Format("{:02}", Integer(m[1]))

    ;=========================
    ; 最后一个数字（忽略年份）
    ;=========================

    last := ""

    pos := 1

    while RegExMatch(s, "(\d+)", &m, pos)
    {
        n := Integer(m[1])

        ; 忽略年份
        if !(n >= 1900 && n <= 2099)
            last := n

        pos := m.Pos + m.Len
    }

    if (last != "")
        return Format("{:02}", last)

   
    ;=========================
    ; 中文集数
    ;=========================

if RegExMatch(s, "第([零一二三四五六七八九十]+)集", &m)
{
    ep := ChineseToNumber(m[1])

    if (ep != "")
        return Format("{:02}", ep)
}

return ""
}

ChineseToNumber(str)
{
    nums := Map(
        "零",0,
        "一",1,
        "二",2,
        "三",3,
        "四",4,
        "五",5,
        "六",6,
        "七",7,
        "八",8,
        "九",9
    )

    if RegExMatch(str, "^十([一二三四五六七八九]?)$", &m)
    {
        return 10 + (m[1]="" ? 0 : nums[m[1]])
    }

    if RegExMatch(str, "^([一二三四五六七八九])十([一二三四五六七八九]?)$", &m)
    {
        return nums[m[1]]*10 + (m[2]="" ? 0 : nums[m[2]])
    }

    if nums.Has(str)
        return nums[str]

    return ""
}

NormalizePrefix(prefix)
{
    prefix := Trim(prefix)

    ; 去掉最后面的 SxxExx
    prefix := RegExReplace(prefix, "i)S\d+\s*E\d+$", "S$0")

    ; 上面不能直接用，所以重新处理
    if RegExMatch(prefix, "i)^(.*?S\d+)\s*E\d+$", &m)
        prefix := m[1]

    ; 去掉最后面的单独E
    prefix := RegExReplace(prefix, "i)E$", "")

    ; 去掉空格
    prefix := Trim(prefix)

    return prefix
}

BuildTemplateName(Template, Episode)
{
    ep := Integer(Episode)
    ep2 := Format("{:02}", ep)

    ;--------------------------
    ; 中文数字（第一集）
    ;--------------------------
    if RegExMatch(Template, "第[零一二三四五六七八九十百千]+集")
    {
        return RegExReplace(
            Template,
            "第[零一二三四五六七八九十百千]+集",
            "第" NumberToChinese(ep) "集"
        )
    }

    ;--------------------------
    ; 第01集 / 第001集
    ;--------------------------
    if RegExMatch(Template, "第\d{2,}集")
    {
        return RegExReplace(
            Template,
            "第\d+集",
            "第" ep2 "集"
        )
    }

    ;--------------------------
    ; 第1集
    ;--------------------------
    if RegExMatch(Template, "第\d集")
    {
        return RegExReplace(
            Template,
            "第\d+集",
            "第" ep "集"
        )
    }

    ;--------------------------
    ; S01E01
    ;--------------------------
    if RegExMatch(Template,"i)S\d+E\d+")
    {
        return RegExReplace(
            Template,
            "i)E\d+",
            "E" ep2
        )
    }

    ;--------------------------
    ; E01
    ;--------------------------
    if RegExMatch(Template,"i)^E\d+$")
        return "E" ep2

    ;--------------------------
    ; 默认：替换最后一个数字
    ;--------------------------
    return RegExReplace(
        Template,
        "\d+(?!.*\d)",
        ep2
    )
}


NumberToChinese(num)
{
    if (num <= 0)
        return ""

    nums := ["零","一","二","三","四","五","六","七","八","九"]

    if (num < 10)
        return nums[num+1]

    if (num < 20)
    {
        if (num=10)
            return "十"

        return "十" nums[Mod(num,10)+1]
    }

    if (num < 100)
    {
        ten := Floor(num/10)
        one := Mod(num,10)

        txt := nums[ten+1] "十"

        if (one)
            txt .= nums[one+1]

        return txt
    }

    if (num < 1000)
    {
        hundred := Floor(num/100)

        remain := Mod(num,100)

        txt := nums[hundred+1] "百"

        if (remain=0)
            return txt

        if (remain<10)
            txt .= "零"

        return txt NumberToChinese(remain)
    }

    return num
}


SetCueBanner(hWnd, Text)
{
    static EM_SETCUEBANNER := 0x1501

    BufferText := Buffer((StrLen(Text) + 1) * 2, 0)
    StrPut(Text, BufferText, "UTF-16")

    DllCall(
        "SendMessageW",
        "Ptr", hWnd,
        "UInt", EM_SETCUEBANNER,
        "Ptr", True,
        "Ptr", BufferText,
        "Ptr"
    )
}
