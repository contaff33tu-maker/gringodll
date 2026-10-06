-- Garante que o menu anterior seja limpo antes de rodar o novo
-- (procura no CoreGui e no gethui(), onde o menu pode estar)
do
    local pais = { game.CoreGui }
    pcall(function() if gethui then table.insert(pais, gethui()) end end)
    for _, pai in ipairs(pais) do
        local velho = pai:FindFirstChild("GringoScripts")
        if velho then velho:Destroy() end
    end
end

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- VARIAVEIS GLOBAIS DE BOTAO (usadas pelo codigo de logica abaixo)
local ScreenGui, MainFrame, ConfigFrame
local NoclipButton, BrightnessButton, SpeedButton
local SpeedDownButton, SpeedUpButton, SpeedLabel
local FlyButton, FlyDownButton, FlyUpButton, FlyLabel
local TPNameInput, TPButton, TPListaFrame
local atualizarListaTP
local GS = {}  -- funcoes dos blocos isolados (limite de 200 locals do Luau)
-- Onde as janelas ficam: gethui() quando o executor tem (mais estavel que
-- CoreGui em varios PCs/Windows), senao CoreGui.
pcall(function() if gethui then GS.pai = gethui() end end)
GS.pai = GS.pai or game.CoreGui
GS.animsInfinitas = {}   -- animacoes em loop (pausadas no MODO LEVE)
local GhostButton, EspButton, AntiTravaButton
local PuxarButton, DerrubaButton
local PuxarNomeInput, PuxarUmButton
local TamanhoSlider
local BikeAntiQuedaButton, BikeAntiQuedaKeyButton
local ParedeButton, ParedeConfirmButton, ParedeRemoverButton
local CorGlobalButton, CorHexInput, CorAplicarButton, CorPreview
local CorSwatches = {}
local CarregarNomeInput, CarregarSegurarButton, CarregarStatus, CarregarListaFrame, CostasButton
local CostasCtrl = {}  -- botoes +/- de distancia/altura das costas
local RegenUI = {}     -- botoes de regenerar / anti-void
local ConfigTabButton, ConfigTitle, KeybindButton, UnloadButton, ConfigCloseButton
local teclaMenu, escutandoTecla

do
-- ═══════════════════════════════════════════════════════════════
--   VISUAL v6 — VIDRO ROXO (ESTILO VISIONOS) + ICONES REAIS (LUCIDE)
-- ═══════════════════════════════════════════════════════════════
--   SO VISUAL: nenhuma funcao foi mexida. Os botoes que a logica usa
--   continuam sendo os mesmos objetos (TextButton/TextBox/TextLabel)
--   guardados nas mesmas variaveis globais de antes.
--   • Barra lateral de icones (abas) + subabas no topo
--   • Cada categoria na sua tela (nada de tudo numa aba so)
--   • Busca no topo: digita o nome da funcao e ele abre a aba certa
--   • Sem emoji: icones de verdade (pacote lucide-roblox, imagens
--     publicas no Roblox). Emoji que a logica escrever em texto e
--     filtrado na hora de mostrar (o texto real do botao nao muda).
--   Montado dentro de uma funcao propria → nao pesa no limite de
--   200 locals do Luau.
-- ═══════════════════════════════════════════════════════════════
(function()
    local LP = game:GetService("Players").LocalPlayer
    local BRANCO = Color3.new(1, 1, 1)
    local T = {
        -- v9.1.2: roxo bem mais escuro (o destaque "ligado" continua vivo)
        bg        = Color3.fromRGB(12, 3, 26),
        header    = Color3.fromRGB(28, 8, 60),
        side      = Color3.fromRGB(44, 14, 92),
        card      = Color3.fromRGB(58, 22, 118),
        cardHover = Color3.fromRGB(82, 36, 160),
        ctrl      = Color3.fromRGB(70, 30, 140),
        stroke    = Color3.fromRGB(96, 52, 170),
        strokeHi  = Color3.fromRGB(196, 150, 255),
        text      = Color3.fromRGB(255, 255, 255),
        dim       = Color3.fromRGB(215, 205, 238),
        mute      = Color3.fromRGB(168, 140, 215),
        on        = Color3.fromRGB(138, 60, 240),
        off       = Color3.fromRGB(46, 20, 90),
        knobOn    = Color3.fromRGB(255, 255, 255),
        knobOff   = Color3.fromRGB(238, 232, 250),
        perigo    = Color3.fromRGB(122, 34, 64),
        perigoTxt = Color3.fromRGB(255, 180, 198),
        roxoA     = Color3.fromRGB(46, 10, 104),   -- topo da janela
        roxoB     = Color3.fromRGB(10, 2, 24),     -- fundo da janela
        vidro     = Color3.fromRGB(150, 96, 230),  -- tom dos cards de vidro
    }
    -- Transparencia do vidro (0 = solido, 1 = invisivel).
    -- Quer a janela mais transparente? aumenta "janela" (ex: 0.35).
    local V = {
        janela = 0.08,  -- fundo roxo da janela
        campo  = 0.9,   -- barra lateral, busca, campos de texto
        linha  = 0.9,   -- cards das funcoes
        grupo  = 0.94,  -- caixa que agrupa varias funcoes
        borda  = 0.84,  -- contorno branco dos cards
        card   = 0.5,   -- botoes de selecao dos modulos (modos, dancas...)
    }

    -- ── Icones Lucide (48px, spritesheet publico no Roblox) ──
    local ICONES = {
        users = {16898613869, 967, 98},
        target = {16898613869, 514, 771},
        flame = {16898613353, 967, 306},
        ["mouse-pointer-click"] = {16898613613, 771, 710},
        maximize = {16898613613, 771, 563},
        ["scan-eye"] = {16898613699, 869, 759},
        ["move-right"] = {16898613613, 49, 967},
        smile = {16898613777, 869, 563},
        ["smile-plus"] = {16898613777, 918, 514},
        anchor = {16898612629, 306, 869},
        ["arrow-big-up"] = {16898612629, 918, 306},
        ["arrow-down-right"] = {16898612629, 820, 661},
        ["arrow-right"] = {16898612629, 453, 820},
        ["arrow-up"] = {16898612629, 967, 355},
        ["arrow-up-to-line"] = {16898612629, 196, 869},
        backpack = {16898612629, 710, 869},
        ban = {16898612629, 196, 967},
        bike = {16898612819, 771, 563},
        bomb = {16898612819, 257, 869},
        brain = {16898612819, 967, 257},
        ["brick-wall"] = {16898612819, 918, 306},
        check = {16898612819, 710, 869},
        ["circle-dot"] = {16898613044, 514, 771},
        clipboard = {16898613044, 49, 869},
        crosshair = {16898613044, 453, 869},
        crown = {16898613044, 404, 918},
        eye = {16898613353, 771, 563},
        feather = {16898613353, 771, 98},
        gauge = {16898613353, 771, 955},
        ghost = {16898613353, 869, 906},
        globe = {16898613509, 771, 563},
        ["hand-heart"] = {16898613509, 869, 514},
        heart = {16898613509, 661, 771},
        info = {16898613509, 612, 869},
        keyboard = {16898613509, 453, 820},
        ["life-buoy"] = {16898613509, 661, 918},
        magnet = {16898613509, 967, 906},
        ["map-pin"] = {16898613613, 820, 257},
        minus = {16898613613, 771, 196},
        music = {16898613613, 967, 563},
        package = {16898613613, 918, 196},
        ["paint-bucket"] = {16898613613, 196, 918},
        palette = {16898613613, 453, 918},
        ["person-standing"] = {16898613699, 563, 771},
        plane = {16898613699, 98, 820},
        plug = {16898613699, 404, 771},
        plus = {16898613699, 257, 918},
        rabbit = {16898613699, 869, 355},
        radar = {16898613699, 820, 404},
        ["refresh-cw"] = {16898613699, 404, 869},
        ruler = {16898613699, 710, 869},
        scaling = {16898613699, 967, 661},
        ["scan-search"] = {16898613699, 710, 918},
        search = {16898613699, 918, 857},
        settings = {16898613777, 771, 257},
        shield = {16898613777, 869, 0},
        ["shield-check"] = {16898613777, 820, 257},
        skull = {16898613777, 49, 869},
        ["sliders-horizontal"] = {16898613777, 820, 355},
        sun = {16898613777, 967, 453},
        swords = {16898613777, 967, 759},
        ["trash-2"] = {16898613869, 257, 918},
        ["triangle-alert"] = {16898613869, 967, 0},
        user = {16898613869, 661, 869},
        wrench = {16898613869, 820, 906},
        x = {16898613869, 869, 906},
        zap = {16898613869, 918, 906},
    }
    -- emoji que os modulos passam → icone equivalente
    local EMOJI = {
        ["🔌"]="plug", ["🎯"]="crosshair", ["👁"]="eye", ["📦"]="package", ["🛡"]="shield",
        ["🧠"]="brain", ["🚫"]="ban", ["🏃"]="person-standing", ["🧱"]="brick-wall", ["⬆"]="arrow-up",
        ["↘"]="arrow-down-right", ["🔴"]="circle-dot", ["⚡"]="zap", ["➡"]="arrow-right",
        ["📋"]="clipboard", ["🦘"]="rabbit", ["💃"]="music", ["💥"]="bomb", ["🧲"]="magnet",
        ["🆘"]="life-buoy", ["♻"]="refresh-cw", ["🎒"]="backpack", ["💞"]="heart", ["🎨"]="palette",
        ["✔"]="check", ["✖"]="x", ["✓"]="check", ["✕"]="x", ["🔎"]="search", ["🔍"]="search",
        ["🚲"]="bike", ["🏎"]="gauge", ["✈"]="plane", ["📏"]="ruler", ["🔧"]="wrench", ["👤"]="user",
        ["🌐"]="globe", ["📍"]="map-pin", ["⚔"]="swords", ["⚙"]="settings", ["👑"]="crown",
        ["🪶"]="feather", ["⚠"]="triangle-alert", ["⚓"]="anchor",
    }

    -- tira emoji/simbolos de um texto (acentos e letras normais ficam)
    local function semEmoji(s)
        if type(s) ~= "string" then return "" end
        if s == "" then return s end
        local ok, r = pcall(function()
            local partes = {}
            for _, c in utf8.codes(s) do
                local tira = c == 0x200D or c == 0x20E3 or (c >= 0xFE00 and c <= 0xFE0F)
                    or (c >= 0x2190 and c <= 0x2BFF) or c >= 0x1F000
                partes[#partes + 1] = tira and "\1" or utf8.char(c)
            end
            return table.concat(partes)
        end)
        if not ok then return s end
        -- emoji no comeco/fim some; no meio vira um separador " · "
        r = r:gsub("^[%s\1]+", ""):gsub("[%s\1]+$", "")
        r = r:gsub("%s*\1[%s\1]*", " · ")
        r = r:gsub("%s+", " ")
        return r
    end
    -- nome de icone a partir de: nome lucide, emoji solto, ou emoji no comeco do texto
    local function nomeIcone(x)
        if type(x) ~= "string" or x == "" then return nil end
        if ICONES[x] then return x end
        local p = x:match("^%s*(%S+)")
        if not p then return nil end
        p = p:gsub("\239\184\143", "")
        return EMOJI[p]
    end

    local function tw(o, props, t, estilo, dir)
        local tween = TweenService:Create(o, TweenInfo.new(t or 0.22, estilo or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
        tween:Play()
        return tween
    end
    local function mkC(r,p) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r) end
    local function mkS(t,c,p,tr) local s=Instance.new("UIStroke",p); s.Thickness=t; s.Color=c; s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s end
    local function redondo(p) Instance.new("UICorner",p).CornerRadius=UDim.new(1,0) end

    local function icone(pai, nome, tam, cor)
        local d = nome and ICONES[nome]
        if not d then return nil end
        local im = Instance.new("ImageLabel")
        im.Name = "Icone"; im.BackgroundTransparency = 1; im.BorderSizePixel = 0
        im.AnchorPoint = Vector2.new(0.5, 0.5); im.Position = UDim2.fromScale(0.5, 0.5)
        im.Size = UDim2.fromOffset(tam, tam)
        im.Image = "rbxassetid://" .. d[1]
        im.ImageRectSize = Vector2.new(48, 48); im.ImageRectOffset = Vector2.new(d[2], d[3])
        im.ImageColor3 = cor or T.text
        im.Parent = pai
        return im
    end

    -- Vidro automatico pros botoes que os modulos criam com T.card
    -- (seletores de modo/danca): fica translucido, e quando a logica
    -- pinta de T.on (selecionado) ele vai ficando solido.
    local function perto(a, b) return math.abs(a.R-b.R)+math.abs(a.G-b.G)+math.abs(a.B-b.B) < 0.03 end
    local DIST_CARD_ON = math.abs(T.card.R-T.on.R)+math.abs(T.card.G-T.on.G)+math.abs(T.card.B-T.on.B)
    local function vidro(o)
        if not o:IsA("GuiObject") or o:GetAttribute("Vidro") then return end
        if o.BackgroundTransparency > 0.01 then return end
        if not (perto(o.BackgroundColor3, T.card) or perto(o.BackgroundColor3, T.on)) then return end
        o:SetAttribute("Vidro", true)
        local function ajustar()
            local c = o.BackgroundColor3
            local d = math.abs(c.R-T.on.R)+math.abs(c.G-T.on.G)+math.abs(c.B-T.on.B)
            o.BackgroundTransparency = V.card * math.clamp(d / DIST_CARD_ON, 0, 1)
        end
        ajustar()
        o:GetPropertyChangedSignal("BackgroundColor3"):Connect(ajustar)
    end
    local function mkCVidro(r, p) mkC(r, p); vidro(p) end

    -- efeito de onda ao clicar
    local function ripple(btn)
        btn.ClipsDescendants=true
        btn.MouseButton1Down:Connect(function()
            if GS.leve then return end
            local m=UserInputService:GetMouseLocation()
            local c=Instance.new("Frame")
            c.AnchorPoint=Vector2.new(0.5,0.5); c.BackgroundColor3=BRANCO
            c.BackgroundTransparency=0.82; c.BorderSizePixel=0; c.ZIndex=btn.ZIndex+1
            c.Position=UDim2.fromOffset(m.X-btn.AbsolutePosition.X, m.Y-btn.AbsolutePosition.Y)
            c.Size=UDim2.fromOffset(0,0); redondo(c); c.Parent=btn
            local d=math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y)*2.2
            tw(c,{Size=UDim2.fromOffset(d,d), BackgroundTransparency=1},0.6)
            task.delay(0.65,function() c:Destroy() end)
        end)
    end
    -- aperta (encolhe) e volta com elastico
    local function press(btn)
        local sc=Instance.new("UIScale",btn)
        btn.MouseButton1Down:Connect(function() tw(sc,{Scale=0.96},0.08) end)
        local function volta() tw(sc,{Scale=1},0.35,Enum.EasingStyle.Back) end
        btn.MouseButton1Up:Connect(volta); btn.MouseLeave:Connect(volta)
    end
    -- vidro clareia no hover (mexe so na transparencia, nao na cor)
    local function hover(btn)
        local base
        btn.MouseEnter:Connect(function()
            base=btn.BackgroundTransparency
            tw(btn,{BackgroundTransparency=math.max(0, base-0.08)},0.15)
        end)
        btn.MouseLeave:Connect(function()
            if base then tw(btn,{BackgroundTransparency=base},0.2) base=nil end
        end)
    end
    local function vidroRoxo(o, rot)
        o.BackgroundColor3 = BRANCO
        local g = Instance.new("UIGradient", o)
        g.Color = ColorSequence.new(T.roxoA, T.roxoB); g.Rotation = rot or 60
        return g
    end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GringoScripts"; ScreenGui.DisplayOrder = 99
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GS.pai

    -- ── Notificacoes (canto inferior direito) ──
    local ToastBox=Instance.new("Frame",ScreenGui)
    ToastBox.AnchorPoint=Vector2.new(1,1); ToastBox.Position=UDim2.new(1,-18,1,-18)
    ToastBox.Size=UDim2.new(0,280,0,320); ToastBox.BackgroundTransparency=1
    do
        local l=Instance.new("UIListLayout",ToastBox); l.VerticalAlignment=Enum.VerticalAlignment.Bottom
        l.HorizontalAlignment=Enum.HorizontalAlignment.Right; l.Padding=UDim.new(0,8); l.SortOrder=Enum.SortOrder.LayoutOrder
    end
    local toastN=0
    GS.toast = function(msg, ligado)
        toastN=toastN+1
        local holder=Instance.new("Frame",ToastBox); holder.Size=UDim2.new(0,268,0,46)
        holder.BackgroundTransparency=1; holder.LayoutOrder=toastN
        local card=Instance.new("Frame",holder); card.Size=UDim2.new(1,0,1,0); card.Position=UDim2.new(0,300,0,0)
        card.BackgroundTransparency=0.1; card.BorderSizePixel=0; vidroRoxo(card, 0)
        mkC(18,card); mkS(1,BRANCO,card,0.78)
        local bolha=Instance.new("Frame",card); bolha.Size=UDim2.fromOffset(26,26); bolha.Position=UDim2.new(0,10,0.5,-13)
        bolha.BackgroundColor3 = ligado==false and T.off or T.on; bolha.BorderSizePixel=0; redondo(bolha)
        icone(bolha, ligado==false and "x" or "check", 14, BRANCO)
        local l=Instance.new("TextLabel",card); l.Size=UDim2.new(1,-56,1,0); l.Position=UDim2.new(0,46,0,0)
        l.BackgroundTransparency=1; l.Font=Enum.Font.GothamMedium; l.TextSize=12; l.TextColor3=T.text
        l.TextXAlignment=Enum.TextXAlignment.Left; l.TextTruncate=Enum.TextTruncate.AtEnd
        l.Text=semEmoji(tostring(msg))
        tw(card,{Position=UDim2.new(0,0,0,0)},0.45,Enum.EasingStyle.Back)
        task.delay(2.4,function()
            tw(card,{Position=UDim2.new(0,300,0,0)},0.35,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
            task.wait(0.4); holder:Destroy()
        end)
    end

    -- REDE DE SEGURANCA: roda um modulo protegido. Se der erro, NAO trava o
    -- resto do menu: avisa na tela (toast) e escreve o erro dentro do painel,
    -- pra dar pra ver o motivo em vez de ficar vazio.
    GS.rodar = function(nome, fn, painelErro)
        local ok, err = pcall(fn)
        if not ok then
            pcall(function() if GS.toast then GS.toast("ERRO em " .. nome .. ": " .. tostring(err), false) end end)
            if painelErro then
                pcall(function()
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, -20, 0, 160); lbl.Position = UDim2.fromOffset(10, 10)
                    lbl.BackgroundColor3 = Color3.fromRGB(45, 10, 10); lbl.BackgroundTransparency = 0.1
                    lbl.BorderSizePixel = 0; lbl.TextColor3 = Color3.fromRGB(255, 130, 130)
                    lbl.TextWrapped = true; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
                    lbl.TextYAlignment = Enum.TextYAlignment.Top
                    lbl.Text = nome .. " falhou ao montar:\n\n" .. tostring(err)
                    lbl.ZIndex = 50; lbl.Parent = painelErro
                    local c = Instance.new("UICorner", lbl); c.CornerRadius = UDim.new(0, 10)
                    local pad = Instance.new("UIPadding", lbl)
                    pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
                    pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
                end)
            end
        end
        return ok
    end

    -- ═══════════════ JANELA ═══════════════
    local TITULO_H = 40   -- barra do nome GRINGOdll v9.1.2
    local W, H = 800, 540 + TITULO_H
    local HEADER_H = 48
    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.fromOffset(W, H); MainFrame.Position = UDim2.new(0.5,-W/2,0.5,-H/2)
    MainFrame.BackgroundTransparency = V.janela; MainFrame.BorderSizePixel = 0
    MainFrame.Active = true; MainFrame.Parent = ScreenGui
    MainFrame.ClipsDescendants = true
    vidroRoxo(MainFrame, 60)
    mkC(28, MainFrame)
    -- borda de vidro com brilho lilas passando
    do
        local ms = mkS(1.2, BRANCO, MainFrame, 0.45)
        local g = Instance.new("UIGradient", ms)
        g.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(92, 40, 180)),
            ColorSequenceKeypoint.new(0.45,Color3.fromRGB(92, 40, 180)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235, 220, 255)),
            ColorSequenceKeypoint.new(0.55,Color3.fromRGB(92, 40, 180)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(92, 40, 180)),
        }
        local giro = TweenService:Create(g,TweenInfo.new(7,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=360})
        giro:Play(); table.insert(GS.animsInfinitas, giro)
        -- reflexo suave no topo (vidro)
        local reflexo = Instance.new("Frame", MainFrame)
        reflexo.Size = UDim2.new(1, 0, 0, 140); reflexo.BackgroundColor3 = BRANCO
        reflexo.BackgroundTransparency = 0.94; reflexo.BorderSizePixel = 0; reflexo.ZIndex = 0
        local rg = Instance.new("UIGradient", reflexo); rg.Rotation = 90
        rg.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}
        mkC(28, reflexo)
    end

    -- ═══════════ FUNDO VIVO: aurora + estrelinhas ═══════════
    -- Tudo atras do conteudo (ZIndex 0) e pausa no MODO LEVE.
    do
        local fundoVivo = Instance.new("Frame", MainFrame)
        fundoVivo.Name = "FundoVivo"; fundoVivo.Size = UDim2.fromScale(1, 1)
        fundoVivo.BackgroundTransparency = 1; fundoVivo.ZIndex = 0
        -- aurora: manchas de luz roxa passeando devagar
        local MANCHAS = {
            { cor = Color3.fromRGB(120, 40, 255), tam = 420, de = UDim2.new(0, -120, 0, -160), para = UDim2.new(0.45, 0, 0, -60), tempo = 11 },
            { cor = Color3.fromRGB(190, 60, 255), tam = 360, de = UDim2.new(0.7, 0, 0.55, 0),  para = UDim2.new(0.25, 0, 0.7, 0), tempo = 14 },
            { cor = Color3.fromRGB(70, 30, 200),  tam = 300, de = UDim2.new(0.35, 0, 0.3, 0),  para = UDim2.new(0.8, 0, -0.1, 0), tempo = 9 },
        }
        for _, m in ipairs(MANCHAS) do
            local f = Instance.new("Frame", fundoVivo)
            f.Size = UDim2.fromOffset(m.tam, m.tam); f.Position = m.de
            f.BackgroundColor3 = m.cor; f.BackgroundTransparency = 0.82; f.BorderSizePixel = 0; f.ZIndex = 0
            redondo(f)
            local g = Instance.new("UIGradient", f)
            g.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1) }
            g.Rotation = math.random(0, 359)
            local passeio = TweenService:Create(f, TweenInfo.new(m.tempo, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = m.para })
            passeio:Play(); table.insert(GS.animsInfinitas, passeio)
            local giro = TweenService:Create(g, TweenInfo.new(m.tempo * 1.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = g.Rotation + 360 })
            giro:Play(); table.insert(GS.animsInfinitas, giro)
        end
        -- estrelinhas subindo e apagando, cada uma no seu ritmo
        for _ = 1, 18 do
            local e = Instance.new("Frame", fundoVivo)
            local tam, x = math.random(2, 4), math.random()
            e.Size = UDim2.fromOffset(tam, tam); e.Position = UDim2.new(x, 0, 1, 10)
            e.BackgroundColor3 = Color3.fromRGB(225, 205, 255); e.BackgroundTransparency = 0.35
            e.BorderSizePixel = 0; e.ZIndex = 0; redondo(e)
            local sobe = TweenService:Create(e,
                TweenInfo.new(math.random(70, 140) / 10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, math.random(0, 40) / 10),
                { Position = UDim2.new(x + (math.random() - 0.5) * 0.12, 0, 0, -10), BackgroundTransparency = 1 })
            sobe:Play(); table.insert(GS.animsInfinitas, sobe)
        end
    end

    -- escala: tela pequena (celular/notebook) → janela encolhe pra caber
    local escalaBase = 1
    pcall(function()
        local vp = workspace.CurrentCamera.ViewportSize
        escalaBase = math.clamp(math.min((vp.X - 30) / W, (vp.Y - 30) / H), 0.55, 1)
    end)
    -- ═══════════ ABERTURA: TELA DE CARREGAMENTO "GRINGO" (~14s) ═══════════
    -- GRINGO no meio (letras sobem uma por uma), bolinha girando, mensagens
    -- trocando com porcentagem, barrinha enchendo e o insta embaixo.
    -- (as mensagens sao so visual: o script nao desativa nada do Roblox)
    local function splash()
        local NOME = "GRINGO"
        local ETAPAS = {   -- { mensagem, ate quantos %, segundos }
            { "injetando...",                         30, 4.0 },
            { "iniciando painel...",                  65, 4.0 },
            { "desativando anti cheat do roblox...", 100, 4.5 },
        }
        local vivos = {}   -- animacoes em loop daqui (param no fim)
        local fundo = Instance.new("Frame")
        fundo.Name = "GringoSplash"; fundo.Size = UDim2.fromScale(1, 1)
        fundo.BackgroundColor3 = Color3.fromRGB(6, 1, 14); fundo.BackgroundTransparency = 1
        fundo.BorderSizePixel = 0; fundo.ZIndex = 200; fundo.Parent = ScreenGui
        tw(fundo, {BackgroundTransparency = 0.12}, 0.4)
        -- brilho roxo atras do nome, respirando
        local halo = Instance.new("Frame", fundo)
        halo.AnchorPoint = Vector2.new(0.5, 0.5); halo.Position = UDim2.new(0.5, 0, 0.5, -40)
        halo.Size = UDim2.fromOffset(120, 120); halo.BackgroundColor3 = T.on; halo.BackgroundTransparency = 1
        halo.BorderSizePixel = 0; halo.ZIndex = 201; redondo(halo)
        local hg = Instance.new("UIGradient", halo); hg.Rotation = 90
        hg.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }
        tw(halo, {Size = UDim2.fromOffset(560, 560), BackgroundTransparency = 0.62}, 1.1, Enum.EasingStyle.Quint)
        task.delay(1.1, function()
            if not halo.Parent then return end
            local r = TweenService:Create(halo, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { Size = UDim2.fromOffset(640, 640), BackgroundTransparency = 0.72 })
            r:Play(); table.insert(vivos, r)
        end)
        -- GRINGO
        local linha = Instance.new("Frame", fundo)
        linha.AnchorPoint = Vector2.new(0.5, 0.5); linha.Position = UDim2.new(0.5, 0, 0.5, -54)
        linha.Size = UDim2.fromOffset(0, 84); linha.AutomaticSize = Enum.AutomaticSize.X
        linha.BackgroundTransparency = 1; linha.ZIndex = 202
        do
            local l = Instance.new("UIListLayout", linha); l.FillDirection = Enum.FillDirection.Horizontal
            l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 4)
            l.VerticalAlignment = Enum.VerticalAlignment.Center
        end
        local letras = {}
        for i = 1, #NOME do
            local caixa = Instance.new("Frame", linha)
            caixa.BackgroundTransparency = 1; caixa.LayoutOrder = i; caixa.ZIndex = 202
            caixa.Size = UDim2.fromOffset(0, 84); caixa.AutomaticSize = Enum.AutomaticSize.X
            local t = Instance.new("TextLabel", caixa)
            t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBlack; t.TextSize = 76
            t.Text = string.sub(NOME, i, i); t.TextColor3 = BRANCO; t.TextTransparency = 1
            t.Size = UDim2.fromOffset(0, 84); t.AutomaticSize = Enum.AutomaticSize.X
            t.Position = UDim2.fromOffset(0, 40); t.ZIndex = 203
            local g = Instance.new("UIGradient", t); g.Rotation = 90
            g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(160, 100, 255))
            local st = Instance.new("UIStroke", t); st.Color = T.on; st.Thickness = 2; st.Transparency = 1
            letras[i] = { t = t, st = st }
        end
        for i, L in ipairs(letras) do
            task.delay((i - 1) * 0.08, function()
                tw(L.t, {Position = UDim2.fromOffset(0, 0), TextTransparency = 0}, 0.5, Enum.EasingStyle.Back)
                tw(L.st, {Transparency = 0.45}, 0.5)
            end)
        end
        -- bolinha de carregamento girando (arco: contorno com metade apagada)
        local giraFrame = Instance.new("Frame", fundo)
        giraFrame.AnchorPoint = Vector2.new(0.5, 0.5); giraFrame.Position = UDim2.new(0.5, 0, 0.5, 34)
        giraFrame.Size = UDim2.fromOffset(34, 34); giraFrame.BackgroundTransparency = 1; giraFrame.ZIndex = 202
        redondo(giraFrame)
        local arco = Instance.new("UIStroke", giraFrame); arco.Thickness = 3.5; arco.Color = T.strokeHi
        local ag = Instance.new("UIGradient", arco)
        ag.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.55, 0.15),
                                              NumberSequenceKeypoint.new(0.56, 1), NumberSequenceKeypoint.new(1, 1) }
        local gira = TweenService:Create(giraFrame, TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
        gira:Play(); table.insert(vivos, gira)
        -- mensagem + porcentagem
        local msg = Instance.new("TextLabel", fundo)
        msg.AnchorPoint = Vector2.new(0.5, 0); msg.Position = UDim2.new(0.5, 0, 0.5, 64)
        msg.Size = UDim2.fromOffset(420, 22); msg.BackgroundTransparency = 1
        msg.Font = Enum.Font.GothamMedium; msg.TextSize = 15; msg.Text = ""
        msg.TextColor3 = Color3.fromRGB(215, 195, 255); msg.ZIndex = 202
        local pct = Instance.new("TextLabel", fundo)
        pct.AnchorPoint = Vector2.new(0.5, 0); pct.Position = UDim2.new(0.5, 0, 0.5, 112)
        pct.Size = UDim2.fromOffset(120, 18); pct.BackgroundTransparency = 1
        pct.Font = Enum.Font.GothamBold; pct.TextSize = 13; pct.Text = "0%"
        pct.TextColor3 = Color3.fromRGB(180, 150, 235); pct.ZIndex = 202
        -- barrinha
        local trilho = Instance.new("Frame", fundo)
        trilho.AnchorPoint = Vector2.new(0.5, 0); trilho.Position = UDim2.new(0.5, 0, 0.5, 96)
        trilho.Size = UDim2.fromOffset(300, 5); trilho.BackgroundColor3 = BRANCO
        trilho.BackgroundTransparency = 0.85; trilho.BorderSizePixel = 0; trilho.ZIndex = 202; redondo(trilho)
        local enche = Instance.new("Frame", trilho)
        enche.Size = UDim2.fromScale(0, 1); enche.BackgroundColor3 = T.strokeHi
        enche.BorderSizePixel = 0; enche.ZIndex = 203; redondo(enche)
        do
            local eg = Instance.new("UIGradient", enche)
            eg.Color = ColorSequence.new(Color3.fromRGB(140, 70, 255), Color3.fromRGB(235, 215, 255))
        end
        -- insta embaixo
        local insta = Instance.new("TextLabel", fundo)
        insta.AnchorPoint = Vector2.new(0.5, 1); insta.Position = UDim2.new(0.5, 0, 1, -28)
        insta.Size = UDim2.fromOffset(300, 22); insta.BackgroundTransparency = 1
        insta.Font = Enum.Font.GothamBold; insta.TextSize = 16; insta.Text = "insta @henrique_system"
        insta.TextColor3 = Color3.fromRGB(200, 170, 255); insta.TextTransparency = 1; insta.ZIndex = 202
        tw(insta, {TextTransparency = 0.1}, 0.8)
        local brilhoInsta = TweenService:Create(insta, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = 0.5 })
        task.delay(0.8, function() if insta.Parent then brilhoInsta:Play() end end)
        table.insert(vivos, brilhoInsta)

        task.wait(#NOME * 0.08 + 0.4)
        -- etapas: mensagem troca com fade, barrinha e % sobem junto
        local atual = 0
        for _, e in ipairs(ETAPAS) do
            local texto, ate, dur = e[1], e[2], e[3]
            tw(msg, {TextTransparency = 1}, 0.15); task.wait(0.15)
            msg.Text = texto
            tw(msg, {TextTransparency = 0}, 0.2)
            tw(enche, {Size = UDim2.fromScale(ate / 100, 1)}, dur, Enum.EasingStyle.Sine)
            local inicio, de = os.clock(), atual
            while os.clock() - inicio < dur do
                local k = math.clamp((os.clock() - inicio) / dur, 0, 1)
                pct.Text = math.floor(de + (ate - de) * k) .. "%"
                task.wait(0.05)
            end
            atual = ate
            pct.Text = ate .. "%"
        end
        tw(msg, {TextTransparency = 1}, 0.15); task.wait(0.15)
        msg.Text = "pronto!"; msg.TextColor3 = BRANCO
        tw(msg, {TextTransparency = 0}, 0.2)
        task.wait(0.6)
        -- saida: tudo sobe sumindo e o fundo clareia
        for _, a in ipairs(vivos) do pcall(function() a:Cancel() end) end
        for _, L in ipairs(letras) do
            tw(L.t, {TextTransparency = 1, Position = UDim2.fromOffset(0, -24)}, 0.3)
            tw(L.st, {Transparency = 1}, 0.3)
        end
        tw(msg, {TextTransparency = 1}, 0.25); tw(pct, {TextTransparency = 1}, 0.25)
        tw(insta, {TextTransparency = 1}, 0.25); tw(arco, {Transparency = 1}, 0.25)
        tw(trilho, {BackgroundTransparency = 1}, 0.25); tw(enche, {BackgroundTransparency = 1}, 0.25)
        tw(halo, {BackgroundTransparency = 1, Size = UDim2.fromOffset(900, 900)}, 0.4)
        tw(fundo, {BackgroundTransparency = 1}, 0.4)
        task.delay(0.45, function() fundo:Destroy() end)
        task.wait(0.15)
    end

    -- janela: splash primeiro, depois sobe + cresce com elastico. Se o splash
    -- der erro a janela abre igual (e tem limite de 17s de seguranca).
    local abrirScale=Instance.new("UIScale",MainFrame); abrirScale.Scale=escalaBase*0.85
    MainFrame.Position=UDim2.new(0.5,-W/2,0.5,-H/2+40)
    MainFrame.Visible=false
    task.spawn(function()
        local aberta = false
        local function abrirJanela()
            if aberta then return end
            aberta = true
            MainFrame.Visible = true
            tw(MainFrame,{Position=UDim2.new(0.5,-W/2,0.5,-H/2)},0.55)
            tw(abrirScale,{Scale=escalaBase},0.55,Enum.EasingStyle.Back)
        end
        task.delay(17, abrirJanela)   -- seguranca: carregamento leva ~14s
        pcall(splash)
        abrirJanela()
    end)

    -- ── Barra lateral (abas por icone) ──
    local Sidebar=Instance.new("Frame",MainFrame)
    Sidebar.Position=UDim2.fromOffset(12,12); Sidebar.Size=UDim2.new(0,60,1,-24)
    Sidebar.BackgroundColor3=T.vidro; Sidebar.BackgroundTransparency=V.campo; Sidebar.BorderSizePixel=0
    mkC(22,Sidebar); mkS(1,BRANCO,Sidebar,V.borda)
    -- v9.1.2: sem logo na lateral (o nome fica na barra de titulo)
    -- lista de abas: do topo ate a engrenagem; se um dia tiver aba demais
    -- ela rola em vez de passar por cima da engrenagem
    local ListaAbas=Instance.new("ScrollingFrame",Sidebar)
    ListaAbas.Position=UDim2.fromOffset(0,14); ListaAbas.Size=UDim2.new(1,0,1,-74)
    ListaAbas.BackgroundTransparency=1; ListaAbas.BorderSizePixel=0
    ListaAbas.ScrollBarThickness=0; ListaAbas.ScrollingDirection=Enum.ScrollingDirection.Y
    ListaAbas.CanvasSize=UDim2.new(0,0,0,0); ListaAbas.AutomaticCanvasSize=Enum.AutomaticSize.Y
    do
        local l=Instance.new("UIListLayout",ListaAbas); l.SortOrder=Enum.SortOrder.LayoutOrder
        l.Padding=UDim.new(0,3); l.HorizontalAlignment=Enum.HorizontalAlignment.Center
    end

    -- Dica com o nome da aba (aparece no hover)
    local Dica=Instance.new("TextLabel",MainFrame)
    Dica.AutomaticSize=Enum.AutomaticSize.X; Dica.Size=UDim2.fromOffset(0,28)
    Dica.BackgroundColor3=T.bg; Dica.BackgroundTransparency=0.1; Dica.BorderSizePixel=0
    Dica.Font=Enum.Font.GothamMedium; Dica.TextSize=12; Dica.TextColor3=T.text; Dica.Text=""
    Dica.Visible=false; Dica.ZIndex=20; mkC(10,Dica); mkS(1,BRANCO,Dica,0.8)
    do local p=Instance.new("UIPadding",Dica); p.PaddingLeft=UDim.new(0,10); p.PaddingRight=UDim.new(0,10) end
    local function dica(btn, txt)
        btn.MouseEnter:Connect(function()
            Dica.Text=txt
            local y = (btn.AbsolutePosition.Y - MainFrame.AbsolutePosition.Y) / math.max(abrirScale.Scale, 0.01)
            Dica.Position=UDim2.fromOffset(80, y + 6)
            Dica.Visible=true
        end)
        btn.MouseLeave:Connect(function() Dica.Visible=false end)
    end

    -- ═══════════ TITULO: GRINGOdll v9.1.2 ═══════════
    local Titulo = Instance.new("Frame", MainFrame)
    Titulo.Name = "Titulo"; Titulo.Position = UDim2.fromOffset(84, 12)
    Titulo.Size = UDim2.new(1, -96, 0, TITULO_H); Titulo.BackgroundTransparency = 1; Titulo.Active = true
    do
        local l = Instance.new("UIListLayout", Titulo); l.FillDirection = Enum.FillDirection.Horizontal
        l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 10)
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        local pad = Instance.new("UIPadding", Titulo); pad.PaddingLeft = UDim.new(0, 10)
        -- o nome, com um brilho branco correndo pelas letras
        local marca = Instance.new("TextLabel", Titulo)
        marca.Name = "Marca"; marca.LayoutOrder = 1; marca.BackgroundTransparency = 1
        marca.Size = UDim2.fromOffset(0, TITULO_H); marca.AutomaticSize = Enum.AutomaticSize.X
        marca.Font = Enum.Font.GothamBlack; marca.TextSize = 24; marca.Text = "GRINGOdll"
        marca.TextColor3 = BRANCO; marca.TextXAlignment = Enum.TextXAlignment.Left
        local mg = Instance.new("UIGradient", marca)
        mg.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(176, 120, 255)),
            ColorSequenceKeypoint.new(0.42, Color3.fromRGB(176, 120, 255)),
            ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.58, Color3.fromRGB(176, 120, 255)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(176, 120, 255)),
        }
        mg.Offset = Vector2.new(-1, 0)
        local brilho = TweenService:Create(mg, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.2), { Offset = Vector2.new(1, 0) })
        brilho:Play(); table.insert(GS.animsInfinitas, brilho)
        -- aura respirando em volta das letras
        local aura = Instance.new("UIStroke", marca); aura.Color = T.on; aura.Thickness = 1.6; aura.Transparency = 0.75
        local respira = TweenService:Create(aura, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.25, Thickness = 2.4 })
        respira:Play(); table.insert(GS.animsInfinitas, respira)
        -- versao numa pilula de vidro
        local pilula = Instance.new("Frame", Titulo)
        pilula.LayoutOrder = 2; pilula.Size = UDim2.fromOffset(0, 22); pilula.AutomaticSize = Enum.AutomaticSize.X
        pilula.BackgroundColor3 = T.on; pilula.BackgroundTransparency = 0.7; pilula.BorderSizePixel = 0
        redondo(pilula); mkS(1, BRANCO, pilula, 0.7)
        do local pp = Instance.new("UIPadding", pilula); pp.PaddingLeft = UDim.new(0, 10); pp.PaddingRight = UDim.new(0, 10) end
        local ver = Instance.new("TextLabel", pilula)
        ver.BackgroundTransparency = 1; ver.Size = UDim2.fromOffset(0, 22); ver.AutomaticSize = Enum.AutomaticSize.X
        ver.Font = Enum.Font.GothamBold; ver.TextSize = 12; ver.Text = "v9.1.2"; ver.TextColor3 = BRANCO
        -- bolinha pulsando (onda que abre e some)
        local vivo = Instance.new("Frame", Titulo)
        vivo.LayoutOrder = 3; vivo.Size = UDim2.fromOffset(18, 18); vivo.BackgroundTransparency = 1
        local onda = Instance.new("Frame", vivo)
        onda.AnchorPoint = Vector2.new(0.5, 0.5); onda.Position = UDim2.fromScale(0.5, 0.5)
        onda.Size = UDim2.fromOffset(8, 8); onda.BackgroundColor3 = Color3.fromRGB(190, 140, 255)
        onda.BackgroundTransparency = 0.2; onda.BorderSizePixel = 0; redondo(onda)
        local ponto = Instance.new("Frame", vivo)
        ponto.AnchorPoint = Vector2.new(0.5, 0.5); ponto.Position = UDim2.fromScale(0.5, 0.5)
        ponto.Size = UDim2.fromOffset(8, 8); ponto.BackgroundColor3 = Color3.fromRGB(190, 140, 255)
        ponto.BorderSizePixel = 0; redondo(ponto)
        local pulso = TweenService:Create(onda, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), { Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
        pulso:Play(); table.insert(GS.animsInfinitas, pulso)
        -- linha de luz embaixo do titulo, com uma faisca indo e voltando
        local fio = Instance.new("Frame", MainFrame)
        fio.Name = "FioTitulo"; fio.Position = UDim2.fromOffset(94, 12 + TITULO_H); fio.Size = UDim2.new(1, -116, 0, 1)
        fio.BackgroundColor3 = BRANCO; fio.BackgroundTransparency = 0.82; fio.BorderSizePixel = 0
        local fg = Instance.new("UIGradient", fio)
        fg.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0),
                                              NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) }
        local faisca = Instance.new("Frame", fio)
        faisca.AnchorPoint = Vector2.new(0.5, 0.5); faisca.Position = UDim2.new(0, 0, 0.5, 0)
        faisca.Size = UDim2.fromOffset(70, 3); faisca.BackgroundColor3 = Color3.fromRGB(215, 180, 255)
        faisca.BorderSizePixel = 0; redondo(faisca)
        local sg = Instance.new("UIGradient", faisca)
        sg.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }
        local viaja = TweenService:Create(faisca, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.new(1, 0, 0.5, 0) })
        viaja:Play(); table.insert(GS.animsInfinitas, viaja)
    end

    -- ── Topo: subabas + busca + minimizar/fechar + avatar ──
    local Header=Instance.new("Frame",MainFrame)
    Header.Position=UDim2.fromOffset(84,12+TITULO_H); Header.Size=UDim2.new(1,-96,0,HEADER_H)
    Header.BackgroundTransparency=1; Header.Active=true

    -- Arrastar janela — SO pelo topo (evita conflito com sliders/botoes)
    do
        local dragging, dragInput, dragStart, startPos
        for _, alca in ipairs({ Header, Titulo }) do   -- arrasta pelo topo e pelo titulo
            alca.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging=true; dragStart=inp.Position; startPos=MainFrame.Position
                    inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
                end
            end)
            alca.InputChanged:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end
            end)
        end
        UserInputService.InputChanged:Connect(function(inp)
            if inp==dragInput and dragging then
                local d=inp.Position-dragStart
                MainFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end)
    end

    local SubBar=Instance.new("Frame",Header)
    SubBar.Size=UDim2.new(1,-330,1,0); SubBar.BackgroundTransparency=1
    do
        local l=Instance.new("UIListLayout",SubBar); l.FillDirection=Enum.FillDirection.Horizontal
        l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,22)
        l.VerticalAlignment=Enum.VerticalAlignment.Center
        local p=Instance.new("UIPadding",SubBar); p.PaddingLeft=UDim.new(0,8)
    end

    -- avatar
    do
        local av=Instance.new("ImageLabel",Header); av.Size=UDim2.fromOffset(38,38); av.Position=UDim2.new(1,-40,0.5,-19)
        av.BackgroundColor3=T.vidro; av.BackgroundTransparency=0.85; av.BorderSizePixel=0; redondo(av)
        mkS(1.5,BRANCO,av,0.6)
        pcall(function() av.Image="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=48&h=48" end)
    end
    local function botaoTopo(nomeIco, x, corHover)
        local b=Instance.new("TextButton",Header)
        b.Size=UDim2.fromOffset(34,34); b.Position=UDim2.new(1,x,0.5,-17)
        b.BackgroundColor3=T.vidro; b.BackgroundTransparency=V.campo; b.AutoButtonColor=false
        b.Text=""; b.BorderSizePixel=0; redondo(b); mkS(1,BRANCO,b,V.borda); press(b)
        local ic=icone(b,nomeIco,16,T.dim)
        b.MouseEnter:Connect(function()
            tw(b,{BackgroundColor3=corHover or BRANCO,BackgroundTransparency=corHover and 0.1 or 0.75},0.15)
            if ic then tw(ic,{ImageColor3=BRANCO},0.15) end
        end)
        b.MouseLeave:Connect(function()
            tw(b,{BackgroundColor3=T.vidro,BackgroundTransparency=V.campo},0.2)
            if ic then tw(ic,{ImageColor3=T.dim},0.2) end
        end)
        return b
    end
    local XBtn=botaoTopo("x",-82,Color3.fromRGB(200,50,80))
    local MinBtn=botaoTopo("minus",-122)
    XBtn.MouseButton1Click:Connect(function()
        tw(abrirScale,{Scale=escalaBase*0.8},0.25,Enum.EasingStyle.Back,Enum.EasingDirection.In)
        tw(MainFrame,{Position=MainFrame.Position+UDim2.new(0,0,0,40)},0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        task.wait(0.26)
        ScreenGui:Destroy()
    end)
    local mini=false
    MinBtn.MouseButton1Click:Connect(function()
        mini=not mini
        local ic=MinBtn:FindFirstChild("Icone")
        if ic then
            local d=ICONES[mini and "plus" or "minus"]
            ic.Image="rbxassetid://"..d[1]; ic.ImageRectOffset=Vector2.new(d[2],d[3])
        end
        tw(MainFrame,{Size=mini and UDim2.fromOffset(W,TITULO_H+HEADER_H+24) or UDim2.fromOffset(W,H)},0.4)
    end)

    -- busca
    local Busca
    do
        local caixa=Instance.new("Frame",Header); caixa.Size=UDim2.fromOffset(186,36); caixa.Position=UDim2.new(1,-318,0.5,-18)
        caixa.BackgroundColor3=T.vidro; caixa.BackgroundTransparency=V.campo; caixa.BorderSizePixel=0
        redondo(caixa); local st=mkS(1,BRANCO,caixa,V.borda)
        local ic=icone(caixa,"search",15,T.mute); ic.Position=UDim2.new(0,18,0.5,0)
        Busca=Instance.new("TextBox",caixa); Busca.Size=UDim2.new(1,-44,1,0); Busca.Position=UDim2.fromOffset(34,0)
        Busca.BackgroundTransparency=1; Busca.Font=Enum.Font.GothamMedium; Busca.TextSize=13
        Busca.PlaceholderText="Buscar"; Busca.PlaceholderColor3=T.mute; Busca.Text=""; Busca.TextColor3=T.text
        Busca.TextXAlignment=Enum.TextXAlignment.Left; Busca.ClearTextOnFocus=false; Busca.TextTruncate=Enum.TextTruncate.AtEnd
        Busca.Focused:Connect(function() tw(st,{Color=T.strokeHi,Transparency=0.3},0.2) tw(caixa,{BackgroundTransparency=0.82},0.2) end)
        Busca.FocusLost:Connect(function() tw(st,{Color=BRANCO,Transparency=V.borda},0.25) tw(caixa,{BackgroundTransparency=V.campo},0.25) end)
    end

    -- ── Area de conteudo ──
    local CA=Instance.new("ScrollingFrame",MainFrame)
    CA.Position=UDim2.fromOffset(84,TITULO_H+HEADER_H+22); CA.Size=UDim2.new(1,-96,1,-(TITULO_H+HEADER_H+34))
    CA.BackgroundTransparency=1; CA.BorderSizePixel=0
    CA.ScrollBarThickness=3; CA.ScrollBarImageColor3=BRANCO; CA.ScrollBarImageTransparency=0.6
    CA.CanvasSize=UDim2.new(0,0,0,0); CA.AutomaticCanvasSize=Enum.AutomaticSize.Y
    CA.ClipsDescendants=true; CA.ScrollingDirection=Enum.ScrollingDirection.Y
    local cp=Instance.new("UIPadding",CA); cp.PaddingTop=UDim.new(0,2); cp.PaddingLeft=UDim.new(0,2); cp.PaddingRight=UDim.new(0,10); cp.PaddingBottom=UDim.new(0,12)
    do
        local l=Instance.new("UIListLayout",CA); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,10)
        l.HorizontalAlignment=Enum.HorizontalAlignment.Center
    end

    local function criarPanel(ord)
        local f=Instance.new("Frame",CA); f.Size=UDim2.new(1,0,0,1)
        f.AutomaticSize=Enum.AutomaticSize.Y; f.BackgroundTransparency=1
        f.Visible=false; f.LayoutOrder=ord
        local l=Instance.new("UIListLayout",f); l.SortOrder=Enum.SortOrder.LayoutOrder
        l.Padding=UDim.new(0,10); l.HorizontalAlignment=Enum.HorizontalAlignment.Center
        return f
    end

    -- ═══════════════ COMPONENTES ═══════════════
    -- titulo de secao (pequeno, como o "Actions" da imagem)
    local function sec(pai,titulo,ico,ord)
        local f=Instance.new("Frame",pai); f.Size=UDim2.new(1,0,0,28)
        f.BackgroundTransparency=1; f.BorderSizePixel=0; f.LayoutOrder=ord
        local x=6
        local ic=icone(f,nomeIcone(ico) or nomeIcone(titulo),14,T.mute)
        if ic then ic.Position=UDim2.new(0,13,0,17); x=26 end
        local lbl=Instance.new("TextLabel",f); lbl.Size=UDim2.new(1,-x,0,20); lbl.Position=UDim2.new(0,x,0,7)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold
        lbl.Text=semEmoji(titulo); lbl.TextColor3=T.mute; lbl.TextSize=11
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextTruncate=Enum.TextTruncate.AtEnd
    end

    -- card de vidro de uma linha
    local function linhaBase(pai, altura, ord)
        local row=Instance.new("Frame",pai); row.Size=UDim2.new(1,0,0,altura)
        row.BackgroundColor3=T.vidro; row.BackgroundTransparency=V.linha
        row.BorderSizePixel=0; row.LayoutOrder=ord; mkC(18,row)
        local st=mkS(1,BRANCO,row,V.borda)
        return row, st
    end

    -- caixa que agrupa funcoes (como o "Module One" da imagem)
    local function grupo(pai, titulo, subtitulo, ico, ord)
        local f=Instance.new("Frame",pai); f.Size=UDim2.new(1,0,0,0); f.AutomaticSize=Enum.AutomaticSize.Y
        f.BackgroundColor3=T.vidro; f.BackgroundTransparency=V.grupo; f.BorderSizePixel=0; f.LayoutOrder=ord
        mkC(24,f); mkS(1,BRANCO,f,0.86)
        local p=Instance.new("UIPadding",f); p.PaddingTop=UDim.new(0,14); p.PaddingBottom=UDim.new(0,14)
        p.PaddingLeft=UDim.new(0,14); p.PaddingRight=UDim.new(0,14)
        local l=Instance.new("UIListLayout",f); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,8)
        local topo=Instance.new("Frame",f); topo.Size=UDim2.new(1,0,0,subtitulo and 40 or 24)
        topo.BackgroundTransparency=1; topo.LayoutOrder=0
        local x=2
        if ico and ICONES[ico] then
            local bolha=Instance.new("Frame",topo); bolha.Size=UDim2.fromOffset(34,34); bolha.Position=UDim2.fromOffset(0,subtitulo and 3 or -5)
            bolha.BackgroundColor3=T.vidro; bolha.BackgroundTransparency=0.86; bolha.BorderSizePixel=0; redondo(bolha)
            icone(bolha,ico,17,T.text)
            x=46
        end
        local t1=Instance.new("TextLabel",topo); t1.Size=UDim2.new(1,-x,0,20); t1.Position=UDim2.fromOffset(x,subtitulo and 1 or 2)
        t1.BackgroundTransparency=1; t1.Font=Enum.Font.GothamBold; t1.TextSize=15; t1.TextColor3=T.text
        t1.TextXAlignment=Enum.TextXAlignment.Left; t1.Text=titulo
        if subtitulo then
            local t2=Instance.new("TextLabel",topo); t2.Size=UDim2.new(1,-x,0,16); t2.Position=UDim2.fromOffset(x,22)
            t2.BackgroundTransparency=1; t2.Font=Enum.Font.Gotham; t2.TextSize=11; t2.TextColor3=T.mute
            t2.TextXAlignment=Enum.TextXAlignment.Left; t2.TextTruncate=Enum.TextTruncate.AtEnd; t2.Text=subtitulo
        end
        return f
    end

    -- grade de cards quadrados (como "Thing 1 / Thing 2" da imagem)
    local function grade(pai, ord, colunas, altura)
        local g=Instance.new("Frame",pai); g.Size=UDim2.new(1,0,0,0); g.AutomaticSize=Enum.AutomaticSize.Y
        g.BackgroundTransparency=1; g.LayoutOrder=ord
        local gl=Instance.new("UIGridLayout",g); gl.SortOrder=Enum.SortOrder.LayoutOrder
        gl.CellPadding=UDim2.fromOffset(10,10)
        gl.CellSize=UDim2.new(1/colunas, -math.ceil(10*(colunas-1)/colunas), 0, altura)
        return g
    end

    -- ── Chave liga/desliga ──
    -- A VERDADE e o .Text que a funcao escreve (ON/OFF) no botao invisivel
    -- por cima do card. O desenho da chave e recalculado disso o tempo
    -- todo (sync a cada 0.3s), entao evento atrasado, animacao interrompida
    -- ou clique perdido nunca deixam a chave no lado errado.
    local KNOB_ON, KNOB_OFF = UDim2.new(1,-21,0.5,-9), UDim2.new(0,3,0.5,-9)
    local function trilho(pai, pos)
        local track=Instance.new("Frame",pai); track.Size=UDim2.fromOffset(44,24); track.Position=pos
        track.BackgroundColor3=T.off; track.BackgroundTransparency=0.3; track.BorderSizePixel=0; redondo(track)
        local knob=Instance.new("Frame",track); knob.Size=UDim2.fromOffset(18,18); knob.Position=KNOB_OFF
        knob.BackgroundColor3=T.knobOff; knob.BorderSizePixel=0; redondo(knob)
        return track, knob
    end
    local function chave(o)
        local t, row, lbl, sub, track, knob = o.t, o.row, o.lbl, o.sub, o.track, o.knob
        local on, ultimaAnim = false, 0
        local function pintar(animado)
            local alvos = { track = track, knob = knob, st = o.st, lbl = lbl }
            local props = {
                track = { BackgroundColor3 = on and T.on or T.off, BackgroundTransparency = on and 0 or 0.3 },
                knob  = { Position = on and KNOB_ON or KNOB_OFF, BackgroundColor3 = on and T.knobOn or T.knobOff },
                st    = { Color = on and T.strokeHi or BRANCO, Transparency = on and 0.4 or V.borda },
                lbl   = { TextColor3 = on and T.text or T.dim },
            }
            if o.ic then alvos.ic = o.ic; props.ic = { ImageColor3 = on and BRANCO or T.dim } end
            if o.bolha then
                alvos.bolha = o.bolha
                props.bolha = { BackgroundColor3 = on and T.on or T.vidro, BackgroundTransparency = on and 0 or 0.86 }
            end
            if animado then
                ultimaAnim = os.clock()
                for k, p in pairs(props) do
                    if k == "knob" then tw(alvos[k], p, 0.35, Enum.EasingStyle.Back) else tw(alvos[k], p, 0.25) end
                end
            else
                for k, p in pairs(props) do
                    for prop, v in pairs(p) do alvos[k][prop] = v end
                end
            end
        end
        local function setOn(v)
            if on==v then return end
            on=v
            pintar(true)
            -- na abertura as sub-opcoes ja nascem marcadas (config padrao) e
            -- cada uma disparava "X ativado": parecia que ligou tudo sozinho.
            -- Aviso so depois que o painel terminou de carregar.
            if GS.avisosLiberados then
                GS.toast(o.nome..(on and " ativado" or " desativado"), on)
            end
        end
        local function lerTexto()
            local up = string.upper(t.Text)
            if up:find("%f[%w]ON%f[%W]") then return true end
            if up:find("%f[%w]OFF%f[%W]") then return false end
            return nil
        end
        local function sync()
            local v = lerTexto()
            if v ~= nil and v ~= on then setOn(v) end
            -- animacao ja devia ter acabado: crava o desenho no estado certo
            if os.clock() - ultimaAnim > 0.5 and knob.Position ~= (on and KNOB_ON or KNOB_OFF) then
                pintar(false)
            end
        end
        GS.syncToggles = GS.syncToggles or {}
        table.insert(GS.syncToggles, sync)
        local msgId=0
        local function aviso(txt)
            msgId=msgId+1; local meu=msgId
            sub.Text=semEmoji(txt)
            tw(lbl,{Position=o.posAviso},0.2); tw(sub,{TextTransparency=0},0.2)
            task.delay(2.8,function()
                if msgId~=meu then return end
                tw(lbl,{Position=o.pos},0.25); tw(sub,{TextTransparency=1},0.25)
            end)
        end
        -- "Controlado": a chave so obedece ao .Text que a logica escreve
        -- (evita a chave mostrar OFF com a funcao ligada)
        t.MouseButton1Click:Connect(function()
            if not t:GetAttribute("Controlado") then setOn(not on) end
            task.delay(0.1, sync)   -- confere logo depois que a funcao escreveu o texto
        end)
        t:GetPropertyChangedSignal("Text"):Connect(function()
            local txt=t.Text
            if txt=="" then return end
            local v = lerTexto()
            if v ~= nil then setOn(v) else aviso(txt) end
        end)
        t.MouseEnter:Connect(function() tw(row,{BackgroundTransparency=V.linha-0.05},0.15) end)
        t.MouseLeave:Connect(function() tw(row,{BackgroundTransparency=V.linha},0.2) end)
        return t
    end
    local function botaoInvisivel(row)
        local t=Instance.new("TextButton",row); t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1
        t.Text=""; t.TextTransparency=1; t.AutoButtonColor=false; t.ZIndex=3
        ripple(t)
        return t
    end
    local function bolhaIcone(pai, ico, tam, pos)
        local bolha=Instance.new("Frame",pai); bolha.Size=UDim2.fromOffset(tam,tam); bolha.Position=pos
        bolha.BackgroundColor3=T.vidro; bolha.BackgroundTransparency=0.86; bolha.BorderSizePixel=0; redondo(bolha)
        local ic=icone(bolha,ico,math.floor(tam*0.52),T.dim)
        return bolha, ic
    end

    -- Toggle em linha (o mesmo de sempre: retorna o TextButton que a logica usa)
    local function tog(pai,rotulo,ord,ico)
        ico = nomeIcone(ico) or nomeIcone(rotulo)
        local nome = semEmoji(rotulo)
        local row, st = linhaBase(pai, 52, ord)
        local x0, bolha, ic = 16, nil, nil
        if ico then
            bolha, ic = bolhaIcone(row, ico, 32, UDim2.new(0,11,0.5,-16))
            x0 = 54
        end
        local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-x0-72,1,0); lbl.Position=UDim2.new(0,x0,0,0)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamMedium; lbl.Text=nome
        lbl.TextColor3=T.dim; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.TextTruncate=Enum.TextTruncate.AtEnd
        local sub=Instance.new("TextLabel",row); sub.Size=UDim2.new(1,-x0-72,0,14); sub.Position=UDim2.new(0,x0,0,29)
        sub.BackgroundTransparency=1; sub.Font=Enum.Font.Gotham; sub.TextSize=10; sub.TextColor3=T.mute
        sub.TextXAlignment=Enum.TextXAlignment.Left; sub.TextTruncate=Enum.TextTruncate.AtEnd
        sub.TextTransparency=1; sub.Text=""
        local track, knob = trilho(row, UDim2.new(1,-58,0.5,-12))
        local t = botaoInvisivel(row)
        return chave{ t=t, row=row, st=st, lbl=lbl, sub=sub, track=track, knob=knob, ic=ic, bolha=bolha,
                      nome=nome, pos=UDim2.new(0,x0,0,0), posAviso=UDim2.new(0,x0,0,-8) }
    end

    -- Toggle em card quadrado (vai dentro de grade())
    local function tile(pai,rotulo,ico,ord)
        local nome = semEmoji(rotulo)
        local row=Instance.new("Frame",pai); row.BackgroundColor3=T.vidro; row.BackgroundTransparency=V.linha
        row.BorderSizePixel=0; row.LayoutOrder=ord; mkC(22,row)
        local st=mkS(1,BRANCO,row,V.borda)
        local bolha, ic = bolhaIcone(row, nomeIcone(ico), 36, UDim2.fromOffset(12,12))
        local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-28,0,20); lbl.Position=UDim2.new(0,14,1,-34)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamMedium; lbl.Text=nome
        lbl.TextColor3=T.dim; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.TextTruncate=Enum.TextTruncate.AtEnd
        local sub=Instance.new("TextLabel",row); sub.Size=UDim2.new(1,-28,0,14); sub.Position=UDim2.new(0,14,1,-18)
        sub.BackgroundTransparency=1; sub.Font=Enum.Font.Gotham; sub.TextSize=10; sub.TextColor3=T.mute
        sub.TextXAlignment=Enum.TextXAlignment.Left; sub.TextTruncate=Enum.TextTruncate.AtEnd
        sub.TextTransparency=1; sub.Text=""
        local track, knob = trilho(row, UDim2.new(1,-56,0,18))
        local t = botaoInvisivel(row)
        return chave{ t=t, row=row, st=st, lbl=lbl, sub=sub, track=track, knob=knob, ic=ic, bolha=bolha,
                      nome=nome, pos=UDim2.new(0,14,1,-34), posAviso=UDim2.new(0,14,1,-48) }
    end

    -- Botao: o texto que a logica escreve fica no .Text (invisivel) e e
    -- mostrado num rotulo por cima, sem emoji. Cor do texto tambem copia.
    local function botaoBase(pai,txt,ord,cor,altura,tam,ico)
        local b=Instance.new("TextButton",pai); b.Size=UDim2.new(1,0,0,altura)
        b.AutoButtonColor=false; b.BorderSizePixel=0; b.LayoutOrder=ord
        b.Font=Enum.Font.GothamBold; b.Text=txt; b.TextSize=tam
        local corBorda, trBorda = BRANCO, V.borda
        if cor=="perigo" then
            b.BackgroundColor3=T.perigo; b.BackgroundTransparency=0.25; b.TextColor3=T.perigoTxt
            corBorda, trBorda = T.perigoTxt, 0.6
        elseif cor=="primario" then
            b.BackgroundColor3=T.on; b.BackgroundTransparency=0.3; b.TextColor3=T.text
            corBorda, trBorda = T.strokeHi, 0.45
        elseif typeof(cor)=="Color3" then
            b.BackgroundColor3=cor; b.BackgroundTransparency=0; b.TextColor3=BRANCO
        else
            b.BackgroundColor3=T.vidro; b.BackgroundTransparency=0.88; b.TextColor3=T.text
        end
        mkC(math.floor(altura/2),b); mkS(1,corBorda,b,trBorda)
        -- conteudo centralizado: [icone] texto
        local miolo=Instance.new("Frame",b); miolo.AnchorPoint=Vector2.new(0.5,0.5); miolo.Position=UDim2.fromScale(0.5,0.5)
        miolo.AutomaticSize=Enum.AutomaticSize.X; miolo.Size=UDim2.fromOffset(0,altura); miolo.BackgroundTransparency=1
        do
            local l=Instance.new("UIListLayout",miolo); l.FillDirection=Enum.FillDirection.Horizontal
            l.VerticalAlignment=Enum.VerticalAlignment.Center; l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,8)
        end
        local ic=icone(miolo,nomeIcone(ico) or nomeIcone(txt),16,b.TextColor3)
        if ic then ic.AnchorPoint=Vector2.zero; ic.LayoutOrder=1 end
        local lbl=Instance.new("TextLabel",miolo); lbl.Name="Rotulo"; lbl.BackgroundTransparency=1; lbl.LayoutOrder=2
        lbl.AutomaticSize=Enum.AutomaticSize.X; lbl.Size=UDim2.fromOffset(0,altura)
        lbl.Font=b.Font; lbl.TextSize=tam; lbl.TextTruncate=Enum.TextTruncate.AtEnd
        do local lim=Instance.new("UISizeConstraint",lbl); lim.MaxSize=Vector2.new(560,altura) end
        b.TextTransparency=1
        local function espelhar()
            lbl.Text=semEmoji(b.Text)
            lbl.TextColor3=b.TextColor3
            lbl.TextStrokeTransparency=b.TextStrokeTransparency
            if ic then ic.ImageColor3=b.TextColor3 end
        end
        espelhar()
        b:GetPropertyChangedSignal("Text"):Connect(espelhar)
        b:GetPropertyChangedSignal("TextColor3"):Connect(espelhar)
        b:GetPropertyChangedSignal("TextStrokeTransparency"):Connect(espelhar)
        hover(b); press(b); ripple(b)
        return b
    end
    local function acao(pai,txt,ico,ord,cor)
        return botaoBase(pai,txt,ord,cor or "primario",46,13,ico)
    end
    local function pequeno(pai,txt,cor,ord,ico)
        return botaoBase(pai,txt,ord,cor,40,12,ico)
    end

    -- Linha com  –  valor  +
    local function ctrl(pai,rotulo,val,ord)
        local row=linhaBase(pai,52,ord)
        local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-190,1,0); lbl.Position=UDim2.new(0,16,0,0)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamMedium; lbl.Text=semEmoji(rotulo)
        lbl.TextColor3=T.dim; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.TextTruncate=Enum.TextTruncate.AtEnd
        local function bt(nomeIco,x)
            local b=Instance.new("TextButton",row); b.Size=UDim2.fromOffset(32,32); b.Position=UDim2.new(1,x,0.5,-16)
            b.BackgroundColor3=T.vidro; b.BackgroundTransparency=0.84; b.Text=""; b.AutoButtonColor=false
            b.BorderSizePixel=0; redondo(b); mkS(1,BRANCO,b,0.8)
            icone(b,nomeIco,16,T.text)
            hover(b); press(b)
            return b
        end
        local bm=bt("minus",-158)
        local vl=Instance.new("TextLabel",row); vl.Size=UDim2.fromOffset(78,32); vl.Position=UDim2.new(1,-120,0.5,-16)
        vl.BackgroundColor3=T.bg; vl.BackgroundTransparency=0.45; vl.Font=Enum.Font.GothamBold; vl.Text=tostring(val)
        vl.TextColor3=T.text; vl.TextSize=12; vl.BorderSizePixel=0; redondo(vl); mkS(1,BRANCO,vl,0.85)
        vl.TextScaled=false; vl.TextTruncate=Enum.TextTruncate.AtEnd
        local bp=bt("plus",-38)
        -- valor "pula" quando muda
        local vs=Instance.new("UIScale",vl)
        vl:GetPropertyChangedSignal("Text"):Connect(function()
            vs.Scale=1.15; tw(vs,{Scale=1},0.3,Enum.EasingStyle.Back)
        end)
        return bm, bp, vl
    end

    -- Slider arrastavel (mouse/touch) — retorna um objeto com :Get(),
    -- :Set(valor) e .Changed (BindableEvent) disparado ao arrastar
    local function slider(pai, rotulo, minV, maxV, valInicial, ord)
        local row=linhaBase(pai,68,ord)
        local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-32,0,20); lbl.Position=UDim2.new(0,16,0,10)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamMedium
        lbl.Text=rotulo..": "..string.format("%.1f",valInicial).."x"
        lbl.TextColor3=T.text; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left

        local track=Instance.new("Frame",row); track.Size=UDim2.new(1,-32,0,8); track.Position=UDim2.new(0,16,0,44)
        track.BackgroundColor3=BRANCO; track.BackgroundTransparency=0.75; track.BorderSizePixel=0; redondo(track)
        local fill=Instance.new("Frame",track); fill.BackgroundColor3=T.on; fill.BorderSizePixel=0
        fill.Size=UDim2.new((valInicial-minV)/(maxV-minV),0,1,0); redondo(fill)
        do
            local g=Instance.new("UIGradient",fill)
            g.Color=ColorSequence.new(Color3.fromRGB(196,150,255), T.on)
        end
        local knob=Instance.new("Frame",track); knob.Size=UDim2.new(0,18,0,18)
        knob.AnchorPoint=Vector2.new(0.5,0.5); knob.BackgroundColor3=BRANCO
        knob.BorderSizePixel=0; knob.ZIndex=2
        knob.Position=UDim2.new((valInicial-minV)/(maxV-minV),0,0.5,0); redondo(knob)
        mkS(2,T.on,knob,0.2)

        local valorAtual = valInicial
        local changedEvent = Instance.new("BindableEvent")

        local function aplicarValor(v)
            v = math.clamp(v, minV, maxV)
            valorAtual = v
            local pct = (v-minV)/(maxV-minV)
            fill.Size = UDim2.new(pct,0,1,0)
            knob.Position = UDim2.new(pct,0,0.5,0)
            lbl.Text = rotulo..": "..string.format("%.1f",v).."x"
            changedEvent:Fire(v)
        end

        local arrastando = false
        local function posicaoParaValor(inputX)
            local abs = track.AbsolutePosition.X
            local size = track.AbsoluteSize.X
            local pct = math.clamp((inputX - abs) / size, 0, 1)
            return minV + pct * (maxV - minV)
        end
        local function setArrastando(v)
            arrastando = v
            tw(knob,{Size=v and UDim2.new(0,24,0,24) or UDim2.new(0,18,0,18)},0.25,Enum.EasingStyle.Back)
        end

        track.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                setArrastando(true)
                aplicarValor(posicaoParaValor(inp.Position.X))
                inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then setArrastando(false) end end)
            end
        end)
        knob.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                setArrastando(true)
                inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then setArrastando(false) end end)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if arrastando and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
                aplicarValor(posicaoParaValor(inp.Position.X))
            end
        end)

        return {
            Changed = changedEvent.Event,
            Get = function() return valorAtual end,
            Set = function(_, v) aplicarValor(v) end,
        }
    end

    -- Campo de texto (pilula de vidro; lupa quando o texto pede busca).
    -- Retorna o TextBox de sempre; a pilula e uma moldura em volta dele.
    local function inp(pai,ph,ord)
        local lupa = type(ph)=="string" and (ph:find("🔎",1,true) or ph:find("🔍",1,true)) and true or false
        local caixa=Instance.new("Frame",pai); caixa.Size=UDim2.new(1,0,0,44); caixa.LayoutOrder=ord
        caixa.BackgroundColor3=T.vidro; caixa.BackgroundTransparency=V.campo; caixa.BorderSizePixel=0; mkC(22,caixa)
        local st=mkS(1,BRANCO,caixa,V.borda)
        local x = 18
        if lupa then
            local ic=icone(caixa,"search",16,T.mute); ic.Position=UDim2.new(0,22,0.5,0)
            x = 42
        end
        local i=Instance.new("TextBox",caixa); i.Size=UDim2.new(1,-(x+14),1,0); i.Position=UDim2.fromOffset(x,0)
        i.BackgroundTransparency=1; i.Font=Enum.Font.GothamMedium
        i.PlaceholderText=semEmoji(ph); i.PlaceholderColor3=T.mute; i.ClearTextOnFocus=false
        i.Text=""; i.TextColor3=T.text; i.TextSize=13; i.TextXAlignment=Enum.TextXAlignment.Left
        i.TextTruncate=Enum.TextTruncate.AtEnd; i.BorderSizePixel=0
        i.Focused:Connect(function() tw(st,{Color=T.strokeHi,Transparency=0.3},0.2) tw(caixa,{BackgroundTransparency=0.84},0.2) end)
        i.FocusLost:Connect(function() tw(st,{Color=BRANCO,Transparency=V.borda},0.25) tw(caixa,{BackgroundTransparency=V.campo},0.25) end)
        -- se a logica trocar o placeholder (ex.: "HEX invalido"), tira emoji tambem
        i:GetPropertyChangedSignal("PlaceholderText"):Connect(function()
            local limpo = semEmoji(i.PlaceholderText)
            if limpo ~= i.PlaceholderText then i.PlaceholderText = limpo end
        end)
        return i
    end

    -- Lista rolavel (players). As linhas sao criadas pela logica com cor
    -- cinza fixa → aqui viram vidro roxo automaticamente.
    local CINZA_LINHA, CINZA_SEL = Color3.fromRGB(26,26,31), Color3.fromRGB(70,70,80)
    local function lista(pai,altura,ord)
        local f=Instance.new("ScrollingFrame",pai)
        f.Size=UDim2.new(1,0,0,altura); f.LayoutOrder=ord
        f.BackgroundColor3=T.bg; f.BackgroundTransparency=0.6; f.BorderSizePixel=0
        f.ScrollBarThickness=3; f.ScrollBarImageColor3=BRANCO; f.ScrollBarImageTransparency=0.6
        f.CanvasSize=UDim2.new(0,0,0,0); f.AutomaticCanvasSize=Enum.AutomaticSize.Y
        mkC(18,f); mkS(1,BRANCO,f,0.88)
        local ll=Instance.new("UIListLayout",f); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,5)
        local lp=Instance.new("UIPadding",f); lp.PaddingTop=UDim.new(0,7); lp.PaddingBottom=UDim.new(0,7)
        lp.PaddingLeft=UDim.new(0,7); lp.PaddingRight=UDim.new(0,11)
        f.ChildAdded:Connect(function(ch)
            if not ch:IsA("GuiButton") then return end
            local function ajustar()
                local c = ch.BackgroundColor3
                if perto(c, CINZA_LINHA) then ch.BackgroundColor3 = T.card return end
                if perto(c, CINZA_SEL) then ch.BackgroundColor3 = T.on return end
                ch.BackgroundTransparency = perto(c, T.on) and 0.15 or 0.55
            end
            ch:GetPropertyChangedSignal("BackgroundColor3"):Connect(ajustar)
            task.defer(ajustar)
            task.defer(function()
                local cr = ch:FindFirstChildOfClass("UICorner")
                if cr then cr.CornerRadius = UDim.new(0,12) end
            end)
        end)
        return f
    end

    -- helpers expostos pros modulos do fim do arquivo (mesmos nomes/assinaturas)
    GS.ui = { T=T, tw=tw, mkC=mkCVidro, mkS=mkS, redondo=redondo, press=press, hover=hover,
              sec=sec, tog=tog, acao=acao, pequeno=pequeno, inp=inp, ctrl=ctrl,
              tile=tile, grupo=grupo, grade=grade, icone=icone, semEmoji=semEmoji }

    -- ═══════════════ ABAS E SUBABAS ═══════════════
    local ABAS = {
        { nome="Jogador",   ico="user",        subs={"Movimento","Personagem","Proteção"} },
        { nome="Monstros",  ico="skull",       subs={"Puxar","Derrubar"} },
        { nome="Visual",    ico="eye",         subs={"Visual"} },
        { nome="Teleporte", ico="map-pin",     subs={"Players","Puxar jogador","Carregar"} },
        { nome="Veículo",   ico="bike",        subs={"Bike"} },
        { nome="Mundo",     ico="globe",       subs={"Parede","Cor global"} },
        { nome="Rastrear",  ico="scan-search", subs={"Objetos"} },
        { nome="Combate",   ico="swords",      subs={"Combate","Silent Aim","No Recoil","Munição"} },
        { nome="Resolver",  ico="brain",       subs={"Resolver"} },
        { nome="Emotes",    ico="smile",       subs={"Emotes"}, ordem=1.5 },
        { nome="Duelo da Bola", ico="flame",   subs={"Auto Toque"}, ordem=8.5 },
        { nome="Liberdade", ico="shield-check", subs={"Se Soltar"}, ordem=1.7 },
    }
    do
        local ordem = 0
        for _, a in ipairs(ABAS) do
            for j, nome in ipairs(a.subs) do
                ordem = ordem + 1
                a.subs[j] = { nome = nome, painel = criarPanel(ordem) }
            end
        end
    end
    local function painel(ai, si) return ABAS[ai].subs[si].painel end

    local abaAtual, subAtual = 0, 0
    local subBotoes = {}
    local abrir
    local function pintarSubabas()
        for i, b in ipairs(subBotoes) do
            local ativo = i == subAtual
            b.Font = ativo and Enum.Font.GothamBold or Enum.Font.GothamMedium
            tw(b, {TextColor3 = ativo and T.text or T.mute}, 0.2)
            local ponto = b:FindFirstChild("Ponto")
            if ponto then tw(ponto, {BackgroundTransparency = ativo and 0 or 1}, 0.2) end
        end
    end
    local function montarSubabas(ai)
        for _, b in ipairs(subBotoes) do b:Destroy() end
        subBotoes = {}
        for j, s in ipairs(ABAS[ai].subs) do
            local b=Instance.new("TextButton",SubBar); b.AutomaticSize=Enum.AutomaticSize.X
            b.Size=UDim2.new(0,0,0,32); b.BackgroundTransparency=1; b.AutoButtonColor=false
            b.Font=Enum.Font.GothamMedium; b.TextSize=15; b.Text=s.nome; b.TextColor3=T.mute; b.LayoutOrder=j
            local ponto=Instance.new("Frame",b); ponto.Name="Ponto"; ponto.AnchorPoint=Vector2.new(0.5,0)
            ponto.Size=UDim2.fromOffset(16,3); ponto.Position=UDim2.new(0.5,0,1,1)
            ponto.BackgroundColor3=T.strokeHi; ponto.BackgroundTransparency=1; ponto.BorderSizePixel=0; redondo(ponto)
            b.MouseEnter:Connect(function() if j ~= subAtual then tw(b,{TextColor3=T.dim},0.15) end end)
            b.MouseLeave:Connect(function() if j ~= subAtual then tw(b,{TextColor3=T.mute},0.2) end end)
            b.MouseButton1Click:Connect(function() abrir(ai, j) end)
            subBotoes[j]=b
        end
    end
    abrir = function(ai, si)
        si = si or ABAS[ai].ultima or 1
        if ai == abaAtual and si == subAtual then return end
        local trocouAba = ai ~= abaAtual
        abaAtual, subAtual = ai, si
        ABAS[ai].ultima = si
        for i, a in ipairs(ABAS) do
            local ativo = i == ai
            if a.botao then
                tw(a.botao, {BackgroundTransparency = ativo and 0.8 or 1}, 0.2)
                tw(a.traco, {Transparency = ativo and 0.55 or 1}, 0.2)
                if a.icone then tw(a.icone, {ImageColor3 = ativo and T.text or T.mute}, 0.2) end
            end
            for j, s in ipairs(a.subs) do s.painel.Visible = ativo and j == si end
        end
        if trocouAba then montarSubabas(ai) end
        pintarSubabas()
        -- transicao: conteudo desliza pra cima
        CA.CanvasPosition=Vector2.new(0,0)
        cp.PaddingTop=UDim.new(0,30)
        tw(cp,{PaddingTop=UDim.new(0,2)},0.4)
    end

    for i, a in ipairs(ABAS) do
        local b=Instance.new("TextButton",ListaAbas)
        b.Size=UDim2.fromOffset(32,32); b.BackgroundColor3=T.vidro; b.BackgroundTransparency=1
        b.Text=""; b.AutoButtonColor=false; b.BorderSizePixel=0; b.LayoutOrder=math.floor((a.ordem or i)*10); redondo(b)
        a.traco=mkS(1,BRANCO,b,1)
        a.icone=icone(b,a.ico,17,T.mute)
        a.botao=b
        b.MouseEnter:Connect(function()
            if abaAtual ~= i then tw(b,{BackgroundTransparency=0.9},0.15) if a.icone then tw(a.icone,{ImageColor3=T.dim},0.15) end end
        end)
        b.MouseLeave:Connect(function()
            if abaAtual ~= i then tw(b,{BackgroundTransparency=1},0.2) if a.icone then tw(a.icone,{ImageColor3=T.mute},0.2) end end
        end)
        b.MouseButton1Click:Connect(function() abrir(i) end)
        press(b); dica(b, a.nome)
    end

    -- Botao configuracoes (embaixo da barra lateral)
    local cfgBtn=Instance.new("TextButton",Sidebar)
    cfgBtn.Size=UDim2.fromOffset(38,38); cfgBtn.Position=UDim2.new(0.5,-19,1,-50)
    cfgBtn.BackgroundColor3=T.vidro; cfgBtn.BackgroundTransparency=0.88; cfgBtn.AutoButtonColor=false
    cfgBtn.Text=""; cfgBtn.BorderSizePixel=0; redondo(cfgBtn); mkS(1,BRANCO,cfgBtn,V.borda)
    do
        local ic=icone(cfgBtn,"settings",18,T.dim)
        cfgBtn.MouseEnter:Connect(function() if ic then tw(ic,{ImageColor3=BRANCO,Rotation=60},0.3) end end)
        cfgBtn.MouseLeave:Connect(function() if ic then tw(ic,{ImageColor3=T.dim,Rotation=0},0.3) end end)
    end
    hover(cfgBtn); press(cfgBtn); dica(cfgBtn, "Configurações")

    -- ═══════════════ CONTEUDO DAS ABAS ═══════════════
    -- ── JOGADOR › Movimento ──
    do
        local p = painel(1,1)
        GS.painelMovimento = p
        local g = grade(p, 1, 3, 104)
        NoclipButton = tile(g, "Wallhack",   "ghost", 1)
        SpeedButton  = tile(g, "Speed hack", "gauge", 2)
        FlyButton    = tile(g, "Modo livre", "plane", 3)
        NoclipButton:SetAttribute("Controlado", true)
        SpeedButton:SetAttribute("Controlado", true)
        local gv = grupo(p, "Velocidade", "Ajuste do speed hack e do voo", "sliders-horizontal", 2)
        SpeedDownButton, SpeedUpButton, SpeedLabel = ctrl(gv,"Velocidade",50,1)
        SpeedLabel.Text = "VEL: 50"
        FlyDownButton, FlyUpButton, FlyLabel = ctrl(gv,"Voo",50,2)
        FlyLabel.Text = "VOO: 50"
        local gp = grupo(p, "Super pulo", "Todo mundo vê · aperte espaço pra pular", "rabbit", 3)
        GS.puloBtn = tog(gp,"Super pulo (aperte espaço)",1,"arrow-big-up")
        GS.puloMenos, GS.puloMais, GS.puloLbl = ctrl(gp,"Altura do pulo",100,2)
        -- CHAO INVISIVEL e montado aqui pelo modulo do fim do arquivo
    end

    -- ── JOGADOR › Personagem ──
    do
        local p = painel(1,2)
        GS.painelPlayer = p
        GS.painelPersonagem = p
        local g = grade(p, 1, 3, 104)
        GhostButton      = tile(g, "Invencível", "shield",    1)
        AntiTravaButton  = tile(g, "Anti-trava", "anchor",    2)
        RegenUI.antiVoid = tile(g, "Anti-void",  "life-buoy", 3)
        local gs = grupo(p, "Socorro", "Caiu no void ou travou? Volte na hora", "life-buoy", 2)
        RegenUI.regenerar = acao(gs,"REGENERAR / RENASCER (TECLA K)","refresh-cw",1)
        RegenUI.voltar    = pequeno(gs,"VOLTAR PRO ÚLTIMO CHÃO (TECLA L)",nil,2,"arrow-up-to-line")
    end

    -- ── JOGADOR › Proteção ── (montada pelos modulos ANTI-SCRIPTS e ANTI-ASSEDIO)
    GS.painelProtecao = painel(1,3)

    -- ── MONSTROS › Puxar ──
    do
        local p = painel(2,1)
        local gx = grupo(p, "Puxar todos", "Trava os monstros em volta de você", "magnet", 1)
        local box=Instance.new("Frame",gx); box.Size=UDim2.new(1,0,0,1)
        box.AutomaticSize=Enum.AutomaticSize.Y; box.BackgroundTransparency=1; box.LayoutOrder=1
        local bl=Instance.new("UIListLayout",box); bl.SortOrder=Enum.SortOrder.LayoutOrder; bl.Padding=UDim.new(0,8)
        PuxarButton    = tog(box,"Puxar todos (trava os monstros)",1,"magnet")
        GS.dancaBtn    = tog(box,"Dança dos monstros",2,"music")
        PuxarButton:SetAttribute("Controlado", true)
        GS.dancaBtn:SetAttribute("Controlado", true)
        GS.puxarStatus = pequeno(box,"🧲 PRESOS: 0",nil,3,"magnet")
        GS.puxarStatus.AutoButtonColor=false; GS.puxarStatus.TextColor3=T.dim
        GS.puxarBox    = box  -- seletor de dancas + ESCUDO sao criados pelos modulos
    end

    -- ── MONSTROS › Derrubar ──
    do
        local p = painel(2,2)
        local gd = grupo(p, "Derruba monstros", "Liga e aperte a tecla perto do monstro", "bomb", 1)
        DerrubaButton      = tog(gd,"Derruba monstros (aperte a tecla)",1,"zap")
        DerrubaButton:SetAttribute("Controlado", true)
        GS.derrubaTeclaBtn = pequeno(gd,"TECLA DERRUBA: X",nil,2,"keyboard")
    end

    -- ── VISUAL ──
    do
        local p = painel(3,1)
        local g = grade(p, 1, 3, 104)
        BrightnessButton = tile(g, "Super brilho",     "sun",   1)
        EspButton        = tile(g, "Rastrear monstro", "radar", 2)
        local gt = grupo(p, "Tamanho", "Visual local — só você vê", "scaling", 2)
        TamanhoSlider = slider(gt,"Tamanho",0.5,25,1,1)
    end

    -- ── TELEPORTE › Players ──
    do
        local p = painel(4,1)
        local gt = grupo(p, "Teleportar", "Clique num player da lista ou busque pelo nome", "map-pin", 1)
        TPNameInput  = inp(gt,"🔎  Buscar player (filtra a lista)...",1)
        TPButton     = pequeno(gt,"TELEPORTAR",nil,2,"arrow-right")
        TPListaFrame = lista(gt,230,3)
    end

    -- ── TELEPORTE › Puxar jogador ──
    do
        local p = painel(4,2)
        local gp = grupo(p, "Puxar jogador", "Gruda o amigo do seu lado (só você vê)", "magnet", 1)
        PuxarNomeInput = inp(gp,"Nome do amigo...",1)
        PuxarUmButton  = acao(gp,"PUXAR JOGADOR","magnet",2)
    end

    -- ── TELEPORTE › Carregar ──
    do
        local p = painel(4,3)
        local gc = grupo(p, "Carregar no braço", "Os dois precisam do script", "heart", 1)
        CarregarNomeInput     = inp(gc,"Nome dela (clica na lista ou vazio = mais perto)...",1)
        CarregarListaFrame    = lista(gc,150,2)
        CarregarSegurarButton = acao(gc,"SEGURE AQUI OU A TECLA G PRA PEDIR","hand-heart",3)
        CarregarStatus        = pequeno(gc,"STATUS: LIVRE",nil,4,"info")
        CarregarStatus.TextColor3 = T.dim
        CarregarStatus.AutoButtonColor = false
        local gk = grupo(p, "Subir nas costas", "Só você precisa do script", "backpack", 2)
        CostasButton = acao(gk,"SUBIR NAS COSTAS DELA (SÓ VOCÊ PRECISA DO SCRIPT)","backpack",1)
        CostasCtrl.atrasMenos, CostasCtrl.atrasMais, CostasCtrl.atrasLbl = ctrl(gk,"Distância",1.6,2)
        CostasCtrl.alturaMenos, CostasCtrl.alturaMais, CostasCtrl.alturaLbl = ctrl(gk,"Altura",0.9,3)
        CostasCtrl.delayMenos, CostasCtrl.delayMais, CostasCtrl.delayLbl = ctrl(gk,"Anti-delay (ms)","AUTO",4)
    end

    -- ── VEICULO ──
    do
        local p = painel(5,1)
        local gb = grupo(p, "Bike grau", "Empina sem cair · segure a tecla pra travar o grau", "bike", 1)
        acao(gb,"BIKE GRAU","bike",1)
        BikeAntiQuedaButton    = tog(gb,"Anti-queda grau",2,"shield-check")
        BikeAntiQuedaKeyButton = pequeno(gb,"TECLA ANTI-QUEDA: E",nil,3,"keyboard")
    end

    -- ── MUNDO › Parede ──
    do
        local p = painel(6,1)
        local gw = grupo(p, "Parede", "Coloca, confirma e remove paredes", "brick-wall", 1)
        ParedeButton        = acao(gw,"PAREDE: OFF","brick-wall",1)
        ParedeConfirmButton = pequeno(gw,"CONFIRMAR PAREDE",nil,2,"check")
        ParedeRemoverButton = pequeno(gw,"REMOVER PAREDES","perigo",3,"trash-2")
    end

    -- ── MUNDO › Cor global ──
    do
        local p = painel(6,2)
        local gc = grupo(p, "Cor global", "Todo mundo vê", "palette", 1)
        -- Paleta de cores vibrantes (clica pra escolher)
        local paletaF=Instance.new("Frame",gc); paletaF.Size=UDim2.new(1,0,0,44)
        paletaF.BackgroundTransparency=1; paletaF.LayoutOrder=1
        local gl=Instance.new("UIGridLayout",paletaF); gl.CellSize=UDim2.new(0,38,0,38)
        gl.CellPadding=UDim2.new(0,12,0,0); gl.SortOrder=Enum.SortOrder.LayoutOrder
        gl.HorizontalAlignment=Enum.HorizontalAlignment.Center
        local paleta={
            Color3.fromRGB(255,0,0),   Color3.fromRGB(255,120,0), Color3.fromRGB(255,255,0),
            Color3.fromRGB(0,255,0),   Color3.fromRGB(0,255,255), Color3.fromRGB(0,80,255),
            Color3.fromRGB(170,0,255), Color3.fromRGB(255,0,200),
        }
        for i,c in ipairs(paleta) do
            local b=Instance.new("TextButton",paletaF); b.Text=""; b.BackgroundColor3=c; b.AutoButtonColor=false
            b.BorderSizePixel=0; b.LayoutOrder=i; redondo(b)
            local st=mkS(2,BRANCO,b,0.7)
            press(b)
            b.MouseEnter:Connect(function() tw(st,{Transparency=0},0.15) end)
            b.MouseLeave:Connect(function() tw(st,{Transparency=0.7},0.2) end)
            table.insert(CorSwatches,{botao=b,cor=c})
        end
        CorHexInput      = inp(gc,"Ou digite a cor em HEX (ex: FF00FF)...",2)
        CorPreview       = pequeno(gc,"COR ESCOLHIDA",Color3.fromRGB(255,0,200),3)
        CorPreview.TextColor3 = Color3.fromRGB(255,255,255); CorPreview.AutoButtonColor = false
        CorPreview.TextStrokeTransparency = 0.6
        CorAplicarButton = acao(gc,"APLICAR COR AGORA","palette",4)
        CorGlobalButton  = tog(gc,"Cor global (mantém aplicando)",5,"paint-bucket")
    end

    -- ── RASTREAR / COMBATE / RESOLVER ── (montadas pelos modulos do fim do arquivo)
    GS.painelRastrear = painel(7,1)
    GS.painelCombate  = painel(8,1)
    GS.painelSilent   = painel(8,2)   -- SILENT AIM: montada pelo modulo do fim do arquivo
    GS.painelRecoil   = painel(8,3)   -- NO RECOIL: montada pelo modulo do fim do arquivo
    GS.painelMunicao  = painel(8,4)   -- MUNICAO INFINITA: montada pelo modulo do fim do arquivo
    GS.painelSoltar   = painel(12,1)  -- LIBERDADE > SE SOLTAR: montada pelo modulo do fim do arquivo
    GS.painelBola     = painel(11,1)  -- DUELO DA BOLA: AUTO TOQUE monta aqui (antes ficava no Combate)
    GS.painelResolver = painel(9,1)

    -- ── EMOTES ── (o clique e ligado pelo modulo EMOTES no fim do arquivo)
    do
        local p = painel(10,1)
        GS.painelEmotes = p
        local ge = grupo(p, "Emotes", "Abre o painel de emotes pra adicionar e usar emotes", "smile", 1)
        GS.emotesBtn    = acao(ge,"ABRIR EMOTES","smile-plus",1)
        GS.emotesStatus = pequeno(ge,"STATUS: NÃO CARREGADO",nil,2,"info")
        GS.emotesStatus.AutoButtonColor = false; GS.emotesStatus.TextColor3 = T.dim
    end

    abrir(1, 1)

    -- ═══════════════ BUSCA ═══════════════
    -- Digita o nome da funcao → abre a aba/subaba dela, rola ate ela e
    -- pisca o card. Nao esconde nada (nao mexe no Visible das funcoes).
    do
        local function visivelAte(o, topo)
            while o and o ~= topo do
                if o:IsA("GuiObject") and not o.Visible then return false end
                o = o.Parent
            end
            return o == topo
        end
        local function destacar(alvo)
            task.wait()  -- espera o layout da aba nova
            pcall(function()
                local y = alvo.AbsolutePosition.Y - CA.AbsolutePosition.Y + CA.CanvasPosition.Y - 20
                CA.CanvasPosition = Vector2.new(0, math.max(0, y))
            end)
            local luz=Instance.new("Frame"); luz.Size=UDim2.new(1,0,1,0); luz.BackgroundColor3=T.on
            luz.BackgroundTransparency=0.45; luz.BorderSizePixel=0; luz.ZIndex=6; mkC(18,luz); luz.Parent=alvo
            tw(luz,{BackgroundTransparency=1},1.2)
            task.delay(1.3,function() luz:Destroy() end)
        end
        local function buscar(q, avisar)
            q = string.lower(semEmoji(q or ""))
            if #q < 2 then return end
            for ai, a in ipairs(ABAS) do
                for si, s in ipairs(a.subs) do
                    for _, d in ipairs(s.painel:GetDescendants()) do
                        local txt
                        if d:IsA("TextBox") then
                            txt = d.PlaceholderText
                        elseif (d:IsA("TextLabel") or d:IsA("TextButton")) and d.TextTransparency < 1 then
                            txt = d.Text
                        end
                        if txt and string.find(string.lower(txt), q, 1, true) and visivelAte(d, s.painel) then
                            abrir(ai, si)
                            local alvo = d
                            if d.Name == "Rotulo" and d.Parent and d.Parent.Parent and d.Parent.Parent:IsA("TextButton") then
                                alvo = d.Parent.Parent          -- texto espelhado → o botao
                            elseif d:IsA("TextLabel") and d.Parent and d.Parent ~= s.painel and d.Parent:IsA("GuiObject") then
                                alvo = d.Parent                 -- rotulo → o card dele
                            end
                            -- nunca joga a luz dentro de um container com layout
                            if alvo:FindFirstChildWhichIsA("UIGridStyleLayout") then alvo = d end
                            task.spawn(destacar, alvo)
                            return true
                        end
                    end
                end
            end
            if avisar then GS.toast("Nada encontrado: "..q, false) end
        end
        local buscaId = 0
        Busca:GetPropertyChangedSignal("Text"):Connect(function()
            buscaId = buscaId + 1; local meu = buscaId
            task.delay(0.5, function() if meu == buscaId then pcall(buscar, Busca.Text, false) end end)
        end)
        Busca.FocusLost:Connect(function(enter) if enter then pcall(buscar, Busca.Text, true) end end)
    end

    -- ═══════════════ CONFIGURACOES ═══════════════
    ConfigFrame=Instance.new("Frame",ScreenGui)
    ConfigFrame.BackgroundTransparency=0.08; ConfigFrame.BorderSizePixel=0
    ConfigFrame.Position=UDim2.new(0.5,-130,0.5,-134); ConfigFrame.Size=UDim2.new(0,260,0,268)
    ConfigFrame.Visible=false; vidroRoxo(ConfigFrame, 70); mkC(24,ConfigFrame); mkS(1.2,BRANCO,ConfigFrame,0.6)
    local cfgScale=Instance.new("UIScale",ConfigFrame)
    do
        local ic=icone(ConfigFrame,"settings",18,T.dim); ic.Position=UDim2.fromOffset(28,28)
    end
    ConfigTitle=Instance.new("TextLabel",ConfigFrame); ConfigTitle.Size=UDim2.new(1,-60,0,24); ConfigTitle.Position=UDim2.fromOffset(46,16)
    ConfigTitle.BackgroundTransparency=1; ConfigTitle.Font=Enum.Font.GothamBold; ConfigTitle.TextXAlignment=Enum.TextXAlignment.Left
    ConfigTitle.Text="Configurações"; ConfigTitle.TextColor3=T.text; ConfigTitle.TextSize=15
    local function mkCB(txt,posY)
        local b=Instance.new("TextButton",ConfigFrame); b.Size=UDim2.new(1,-28,0,40); b.Position=UDim2.new(0,14,0,posY)
        b.BackgroundColor3=T.vidro; b.BackgroundTransparency=0.88; b.Font=Enum.Font.GothamBold; b.Text=txt; b.AutoButtonColor=false
        b.TextColor3=T.text; b.TextSize=12; b.BorderSizePixel=0; mkC(20,b); mkS(1,BRANCO,b,V.borda)
        hover(b); press(b); ripple(b)
        return b
    end
    KeybindButton=mkCB("KEYBIND: RightControl",56)
    GS.leveBtn=mkCB("MODO LEVE: OFF",104)
    UnloadButton=mkCB("ENCERRAR TUDO",152)
    UnloadButton.BackgroundColor3=T.perigo; UnloadButton.BackgroundTransparency=0.25; UnloadButton.TextColor3=T.perigoTxt
    ConfigCloseButton=mkCB("FECHAR",212)
    cfgBtn.MouseButton1Click:Connect(function()
        if ConfigFrame.Visible then
            ConfigFrame.Visible=false
        else
            ConfigFrame.Visible=true
            cfgScale.Scale=0.8*escalaBase; tw(cfgScale,{Scale=escalaBase},0.35,Enum.EasingStyle.Back)
        end
    end)
    ConfigCloseButton.MouseButton1Click:Connect(function() ConfigFrame.Visible=false end)

    -- Botao config invisivel (compatibilidade)
    ConfigTabButton=Instance.new("TextButton",ScreenGui); ConfigTabButton.Visible=false

    -- Abrir/fechar pela tecla tambem anima
    MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if MainFrame.Visible then
            abrirScale.Scale=escalaBase*0.9; tw(abrirScale,{Scale=escalaBase},0.35,Enum.EasingStyle.Back)
        else
            Dica.Visible=false
        end
    end)
end)()
end  -- fim do bloco do

-- Keybind
teclaMenu = Enum.KeyCode.RightControl
escutandoTecla = false
KeybindButton.MouseButton1Click:Connect(function()
    escutandoTecla=true; KeybindButton.Text="[PRESSIONE UMA TECLA]"
end)
UserInputService.InputBegan:Connect(function(input,_gp)
    if escutandoTecla then
        if input.UserInputType==Enum.UserInputType.Keyboard then
            teclaMenu=input.KeyCode; escutandoTecla=false
            KeybindButton.Text="KEYBIND: "..teclaMenu.Name
        end
    else
        if input.KeyCode==teclaMenu then
            MainFrame.Visible=not MainFrame.Visible
            if not MainFrame.Visible then ConfigFrame.Visible=false end
        end
    end
end)

-- ═══════════════════════════════════
--   SISTEMAS INTERNOS
-- ═══════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local noclipAtivado = false
local noclipConnection = nil

-- WALLHACK v3:
--   • atravessa parede: CanCollide=false em TODAS as pecas do boneco
--     (inclusive boneco customizado), antes e depois da fisica;
--   • NUNCA CAI: raycast pro chao todo frame — se o boneco afundar no
--     chao, ele e recolocado em cima; se nao tiver chao nenhum embaixo
--     (fora do mapa / vazio), ele fica flutuando na mesma altura.
--     Segure LeftControl pra descer de proposito;
--   • desligou → devolve a colisao original de cada peca NA HORA.
local function alternarNoclip()
    noclipAtivado = not noclipAtivado
    if noclipAtivado then
        NoclipButton.Text = "WALLHACK: ON"
        GS.noclipOrig = {}
        local function atravessar()
            local character = LocalPlayer.Character
            if not character then return end
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    if GS.noclipOrig[part] == nil then GS.noclipOrig[part] = true end
                    part.CanCollide = false
                end
            end
        end
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local function nuncaCai()
            local character = LocalPlayer.Character
            local hum = character and character:FindFirstChildOfClass("Humanoid")
            local root = hum and hum.RootPart
            if not root or root.Anchored then return end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and not UserInputService:GetFocusedTextBox() then return end
            rp.FilterDescendantsInstances = { character, workspace.CurrentCamera }
            local altura = hum.HipHeight + root.Size.Y / 2
            if hum.RigType == Enum.HumanoidRigType.R6 then altura = root.Size.Y / 2 + 2 end
            local pos = root.Position
            local vel = root.AssemblyLinearVelocity
            local chao = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -(altura + 600), 0), rp)
            if chao then
                local alvoY = chao.Position.Y + altura
                -- afundou no chao: recoloca em cima e corta a queda
                if pos.Y < alvoY - 0.15 and vel.Y <= 0 then
                    root.CFrame = root.CFrame + Vector3.new(0, alvoY - pos.Y, 0)
                    root.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
                end
            elseif vel.Y < 0 then
                -- sem chao embaixo (vazio): flutua na mesma altura
                root.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
            end
        end
        noclipConnection = RunService.Stepped:Connect(atravessar)
        GS.noclipConn2 = RunService.Heartbeat:Connect(function()
            atravessar()
            pcall(nuncaCai)
        end)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local r = hum and hum.RootPart
        if r and r.Anchored then
            task.delay(0.4, function() NoclipButton.Text = "⚠ O jogo ancorou seu boneco (não dá pra mover)" end)
        end
    else
        NoclipButton.Text = "WALLHACK: OFF"
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
        if GS.noclipConn2 then GS.noclipConn2:Disconnect() GS.noclipConn2 = nil end
        -- devolve a colisao NA HORA
        for part in pairs(GS.noclipOrig or {}) do
            pcall(function() if part.Parent then part.CanCollide = true end end)
        end
        GS.noclipOrig = {}
        -- se estiver dentro de uma parede/chao, sobe pra cima dele
        pcall(function()
            local character = LocalPlayer.Character
            local hum = character and character:FindFirstChildOfClass("Humanoid")
            local root = hum and hum.RootPart
            if not root then return end
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { character, workspace.CurrentCamera }
            local altura = hum.HipHeight + root.Size.Y / 2
            local chao = workspace:Raycast(root.Position + Vector3.new(0, 4, 0), Vector3.new(0, -(altura + 8), 0), rp)
            if chao and root.Position.Y < chao.Position.Y + altura then
                root.CFrame = root.CFrame + Vector3.new(0, chao.Position.Y + altura - root.Position.Y + 0.2, 0)
            end
        end)
    end
end

local Lighting = game:GetService("Lighting")
local fullbrightAtivado = false
local localLight = nil
local originalAmbient, originalOutdoorAmbient, originalBrightness, originalFog =
    Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.Brightness, Lighting.FogEnd

local function alternarBrilho()
    fullbrightAtivado = not fullbrightAtivado
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if fullbrightAtivado then
        BrightnessButton.Text = "SUPER BRILHO: ON"
        Lighting.Ambient = Color3.fromRGB(140, 140, 140)
        Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
        Lighting.Brightness = 1.8
        Lighting.FogEnd = 999999
        if root and not localLight then
            localLight = Instance.new("PointLight")
            localLight.Range = 200
            localLight.Brightness = 4
            localLight.Color = Color3.fromRGB(255, 255, 255)
            localLight.Shadows = false
            localLight.Parent = root
        end
    else
        BrightnessButton.Text = "SUPER BRILHO: OFF"
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.Brightness = originalBrightness
        Lighting.FogEnd = originalFog
        if localLight then localLight:Destroy() localLight = nil end
    end
end

Lighting.Changed:Connect(function()
    if fullbrightAtivado then
        Lighting.Ambient = Color3.fromRGB(140, 140, 140)
        Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
        Lighting.Brightness = 1.8
    end
end)

local speedAtivado = false
local velocidadeCustomizada = 50
local speedConnection = nil
local speedBodyVelocity = nil

-- SPEED v2 (universal):
--   1) WalkSpeed reaplicado todo frame.
--   2) Se o jogo segurar a velocidade (anti-cheat local, WalkSpeed travado,
--      boneco customizado), completa o que falta com passo de CFrame.
--   Direcao vem do Humanoid.MoveDirection (teclado, celular, controle);
--   se o jogo nao usar, cai pro WASD pela camera. Sem BodyVelocity (que
--   muito anti-cheat procura e apaga).
local function alternarSpeed()
    speedAtivado = not speedAtivado
    if speedAtivado then
        SpeedButton.Text = "SPEED: ON"
        if speedBodyVelocity then speedBodyVelocity:Destroy() speedBodyVelocity = nil end
        local avisouAncorado = false
        speedConnection = RunService.Heartbeat:Connect(function(dt)
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local r    = (hum and hum.RootPart) or (char and char:FindFirstChild("HumanoidRootPart"))
            if not r then return end
            if r.Anchored then
                if not avisouAncorado then
                    avisouAncorado = true
                    SpeedButton.Text = "⚠ O jogo ancorou seu boneco (não dá pra mover)"
                end
                return
            end
            if hum and hum.WalkSpeed ~= velocidadeCustomizada then
                pcall(function() hum.WalkSpeed = velocidadeCustomizada end)
            end

            local dir = hum and hum.MoveDirection or Vector3.zero
            if dir.Magnitude < 0.05 and not UserInputService:GetFocusedTextBox() then
                local cam = workspace.CurrentCamera
                local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
                local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
            end
            dir = Vector3.new(dir.X, 0, dir.Z)
            if dir.Magnitude < 0.05 then return end
            dir = dir.Unit

            local v = r.AssemblyLinearVelocity
            local atual = math.max(Vector3.new(v.X, 0, v.Z):Dot(dir), 0)
            local falta = velocidadeCustomizada - atual
            if falta > 2 then
                r.CFrame = r.CFrame + dir * falta * dt
            end
        end)
    else
        SpeedButton.Text = "SPEED: OFF"
        if speedConnection then speedConnection:Disconnect() speedConnection = nil end
        if speedBodyVelocity then speedBodyVelocity:Destroy() speedBodyVelocity = nil end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

local flyAtivado = false
local velocidadeVoo = 50
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

local function alternarFly()
    flyAtivado = not flyAtivado
    if flyAtivado then
        FlyButton.Text = "MODO LIVRE: ON"
        flyConnection = RunService.RenderStepped:Connect(function()
            -- Atualiza referencias todo frame (jogo pode ter resetado o char)
            local c = LocalPlayer.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if not r or not h then return end

            -- Mantém PlatformStand ligado todo frame
            -- (alguns jogos resetam isso para derrubar o boneco)
            if not h.PlatformStand then
                pcall(function() h.PlatformStand = true end)
            end

            -- Recria BodyVelocity se o jogo destruiu (causa do descida)
            if not bodyVelocity or not bodyVelocity.Parent then
                pcall(function()
                    if bodyVelocity then bodyVelocity:Destroy() end
                    bodyVelocity = Instance.new("BodyVelocity"); bodyVelocity.Name = "GringoVooVel"
                    bodyVelocity.Velocity   = Vector3.new(0, 0, 0)
                    bodyVelocity.MaxForce   = Vector3.new(math.huge, math.huge, math.huge)
                    bodyVelocity.Parent     = r
                end)
            end

            -- Recria BodyGyro se o jogo destruiu (causa da rotacao bugada)
            if not bodyGyro or not bodyGyro.Parent then
                pcall(function()
                    if bodyGyro then bodyGyro:Destroy() end
                    bodyGyro = Instance.new("BodyGyro"); bodyGyro.Name = "GringoVooGyro"
                    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    bodyGyro.D         = 100
                    bodyGyro.P         = 30000
                    bodyGyro.Parent    = r
                end)
            end

            -- Atualiza direcao de voo
            local cam = workspace.CurrentCamera
            pcall(function() bodyGyro.CFrame = cam.CFrame end)

            local UIS    = game:GetService("UserInputService")
            local dir    = Vector3.new(0, 0, 0)
            if UIS:IsKeyDown(Enum.KeyCode.W)           then dir = dir + cam.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)           then dir = dir - cam.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)           then dir = dir - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)           then dir = dir + cam.CFrame.RightVector end
            -- Subir/descer com Space e LeftControl (independente da camera)
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir = dir + Vector3.new(0, 1, 0)  end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0)  end

            pcall(function()
                bodyVelocity.Velocity = dir * velocidadeVoo
            end)
        end)
    else
        FlyButton.Text = "MODO LIVRE: OFF"
        if flyConnection then flyConnection:Disconnect() flyConnection = nil end
        if bodyVelocity  then bodyVelocity:Destroy()    bodyVelocity  = nil end
        if bodyGyro      then bodyGyro:Destroy()         bodyGyro      = nil end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h.PlatformStand = false end) end
    end
end

-- ═══════════════════════════════════════════════════════════════
--   TAMANHO — ESCALA O PERSONAGEM (VISUAL LOCAL: SO VOCE VE)
-- ═══════════════════════════════════════════════════════════════
-- ATENCAO: isso NAO replica. Mudanca de tamanho feita pelo client
-- fica so na sua tela. So o servidor do jogo consegue mudar o
-- tamanho que os outros veem (ex: loja/avatar do proprio jogo).
--
--
-- Metodo: Character:ScaleTo() (API moderna, funciona em R15 e R6);
-- fallback manual via Humanoid.BodyHeightScale/WidthScale/DepthScale/
-- HeadScale pra executores/jogos que nao tenham ScaleTo ainda.
-- ═══════════════════════════════════════════════════════════════
local tamanhoAtual = 1

local function aplicarTamanho(valor)
    tamanhoAtual = valor
    local char = LocalPlayer.Character
    if not char then return end
    local ok = pcall(function()
        char:ScaleTo(valor)
    end)
    if not ok then
        -- Fallback manual (R15) — escala cada eixo do Humanoid
        pcall(function()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.BodyHeightScale.Value = valor
                hum.BodyWidthScale.Value  = valor
                hum.BodyDepthScale.Value  = valor
                hum.HeadScale.Value       = valor
            end
        end)
    end
end

-- Reaplica o tamanho quando o personagem renasce (respawn zera a escala)
LocalPlayer.CharacterAdded:Connect(function(novoChar)
    task.wait(0.5)
    pcall(function() aplicarTamanho(tamanhoAtual) end)
end)

local function executarTeleporte()
    local textoDigitado = string.lower(TPNameInput.Text)
    local meuChar = LocalPlayer.Character
    local meuRoot = meuChar and meuChar:FindFirstChild("HumanoidRootPart")
    if textoDigitado == "" or not meuRoot then return end
    local alvoEncontrado = nil
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and string.sub(string.lower(player.Name), 1, #textoDigitado) == textoDigitado then
            alvoEncontrado = player.Character; break
        end
    end
    if not alvoEncontrado then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Parent and string.sub(string.lower(obj.Parent.Name), 1, #textoDigitado) == textoDigitado then
                alvoEncontrado = obj.Parent; break
            end
        end
    end
    if alvoEncontrado then
        local alvoRoot = alvoEncontrado:FindFirstChild("HumanoidRootPart")
        if alvoRoot then meuRoot.CFrame = alvoRoot.CFrame * CFrame.new(0, 3, 0) end
    end
end

do
-- ═══════════════════════════════════════════════════════════════
--   LISTA DE TELEPORTE — PLAYERS DO SERVIDOR (AUTOMATICA)
-- ═══════════════════════════════════════════════════════════════
-- Mostra todo mundo que ta no servidor (foto + nome + distancia).
-- Clicou no nome → teleporta. Atualiza sozinha quando alguem entra
-- ou sai, e a distancia a cada segundo. O campo de busca filtra.
-- ═══════════════════════════════════════════════════════════════
local tpLinhas = {}   -- { [Player] = { botao, info } }

local function teleportarParaPlayer(player)
    local meuChar  = LocalPlayer.Character
    local meuRoot  = meuChar and meuChar:FindFirstChild("HumanoidRootPart")
    local alvoRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if meuRoot and alvoRoot then
        meuRoot.CFrame = alvoRoot.CFrame * CFrame.new(0, 3, 0)
        meuRoot.AssemblyLinearVelocity = Vector3.zero
    end
end

local function _criarLinhaTP(player)
    local b = Instance.new("TextButton", TPListaFrame)
    b.Size = UDim2.new(1, 0, 0, 40); b.BackgroundColor3 = Color3.fromRGB(26, 26, 31)
    b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

    local foto = Instance.new("ImageLabel", b)
    foto.Size = UDim2.new(0, 32, 0, 32); foto.Position = UDim2.new(0, 4, 0.5, -16)
    foto.BackgroundColor3 = Color3.fromRGB(36, 36, 42); foto.BorderSizePixel = 0
    foto.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
    Instance.new("UICorner", foto).CornerRadius = UDim.new(1, 0)

    local nome = Instance.new("TextLabel", b)
    nome.Size = UDim2.new(1, -120, 0, 20); nome.Position = UDim2.new(0, 44, 0, 2)
    nome.BackgroundTransparency = 1; nome.Font = Enum.Font.GothamBold; nome.TextSize = 13
    nome.TextColor3 = Color3.fromRGB(236, 236, 240); nome.TextXAlignment = Enum.TextXAlignment.Left
    nome.TextTruncate = Enum.TextTruncate.AtEnd; nome.Text = player.DisplayName

    local user = Instance.new("TextLabel", b)
    user.Size = UDim2.new(1, -120, 0, 16); user.Position = UDim2.new(0, 44, 0, 21)
    user.BackgroundTransparency = 1; user.Font = Enum.Font.Gotham; user.TextSize = 11
    user.TextColor3 = Color3.fromRGB(130, 130, 140); user.TextXAlignment = Enum.TextXAlignment.Left
    user.TextTruncate = Enum.TextTruncate.AtEnd; user.Text = "@" .. player.Name

    local info = Instance.new("TextLabel", b)
    info.Size = UDim2.new(0, 70, 1, 0); info.Position = UDim2.new(1, -74, 0, 0)
    info.BackgroundTransparency = 1; info.Font = Enum.Font.GothamBold; info.TextSize = 12
    info.TextColor3 = Color3.fromRGB(236, 236, 240); info.TextXAlignment = Enum.TextXAlignment.Right
    info.Text = "-- m"

    b.MouseButton1Click:Connect(function()
        teleportarParaPlayer(player)
        info.Text = "✔ FOI!"
        task.delay(0.8, function() pcall(function() info.Text = "-- m" end) end)
    end)
    tpLinhas[player] = { botao = b, info = info }
end

atualizarListaTP = function()
    local filtro = string.lower(TPNameInput.Text or "")
    local meuRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local ordem = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not tpLinhas[player] then _criarLinhaTP(player) end
            local linha = tpLinhas[player]
            local bate = filtro == ""
                or string.find(string.lower(player.Name), filtro, 1, true)
                or string.find(string.lower(player.DisplayName), filtro, 1, true)
            linha.botao.Visible = bate and true or false
            local alvoRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local dist = (meuRoot and alvoRoot) and (meuRoot.Position - alvoRoot.Position).Magnitude or math.huge
            if linha.info.Text ~= "✔ FOI!" then
                linha.info.Text = dist == math.huge and "-- m" or (math.floor(dist) .. " m")
            end
            table.insert(ordem, { linha = linha, dist = dist })
        end
    end
    -- mais perto primeiro
    table.sort(ordem, function(a, b) return a.dist < b.dist end)
    for i, item in ipairs(ordem) do item.linha.botao.LayoutOrder = i end
end

Players.PlayerAdded:Connect(function() task.wait(0.5) atualizarListaTP() end)
Players.PlayerRemoving:Connect(function(player)
    local linha = tpLinhas[player]
    if linha then linha.botao:Destroy() tpLinhas[player] = nil end
end)
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        pcall(atualizarListaTP)
        task.wait(1)
    end
end)
end  -- fim LISTA DE TELEPORTE

local ghostAtivado      = false
local ghostConnection   = nil
local ghostHealthConn   = nil
local ghostDiedConn     = nil
local ghostSteppedConn  = nil
local bypassHealthBlock = false   -- nossa propria escrita passa; server nao passa

-- ═══════════════════════════════════════════════════════════════
--   INVENCIVEL NIVEL DEUS — HOOK DE METATABELA (NIVEL ENGINE)
-- ═══════════════════════════════════════════════════════════════
-- CAMADA 0 (mais profunda possivel):
--   hookmetamethod intercepta __namecall → bloqueia TakeDamage antes de executar
--   getrawmetatable + __newindex → bloqueia atribuicao de Health vinda do servidor
--   Isso acontece ANTES de qualquer HealthChanged, ANTES de qualquer Heartbeat
--   O dano literalmente nao chega no personagem
-- CAMADAS 1-7: mantidas como fallback caso executor nao suporte hooks
-- math.huge = infinito real de Lua
-- ═══════════════════════════════════════════════════════════════
local VIDA_INF = math.huge

-- Salva hooks originais para nao quebrar o jogo inteiro
local _hookNamecallOriginal = nil
local _hookNewIndexOriginal = nil
local _hookAtivoNamecall    = false
local _hookAtivoNewIndex    = false

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function aplicarVidaBruta(h)
    if not h then return end
    bypassHealthBlock = true
    pcall(function() h.MaxHealth = VIDA_INF end)
    pcall(function() h.Health    = VIDA_INF end)
    bypassHealthBlock = false
    pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead,        false) end)
    pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.FallingDown,  false) end)
    pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,      false) end)
    pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Physics,      false) end)
end

-- HOOK 1: __namecall — intercepta TakeDamage, BreakJoints, ApplyImpulse, etc.
local function instalarHookNamecall()
    local ok = pcall(function()
        _hookNamecallOriginal = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if ghostAtivado then
                local metodo = getnamecallmethod()
                local c      = LocalPlayer.Character

                -- Bloqueia dano/morte no Humanoid
                if metodo == "TakeDamage" or metodo == "BreakJoints" then
                    local hum = getHum()
                    if hum and self == hum then
                        return  -- BLOQUEADO
                    end
                end

                -- Bloqueia ApplyImpulse/ApplyAngularImpulse em partes do personagem
                -- (knockback do Capitão Clark — ele aplica forcas fisicas, nao dano)
                if metodo == "ApplyImpulse" or metodo == "ApplyAngularImpulse" then
                    if c and self:IsDescendantOf(c) then
                        return  -- BLOQUEADO — nenhum impulso externo no boneco
                    end
                end

                -- Bloqueia SetNetworkOwner que pode ser usado para controlar o boneco
                if metodo == "SetNetworkOwner" then
                    if c and self:IsDescendantOf(c) then
                        return  -- BLOQUEADO
                    end
                end

                -- Bloqueia TeleportService:Teleport() — impede ser mandado pro lobby
                -- (Casa do Locusto usa isso quando te pega)
                if metodo == "Teleport" or metodo == "TeleportToPlaceInstance"
                or metodo == "TeleportAsync" or metodo == "TeleportPartyAsync" then
                    local ts = game:GetService("TeleportService")
                    if self == ts then
                        return  -- BLOQUEADO — nao sai do servidor
                    end
                end

                -- Bloqueia Kick do jogador
                if metodo == "Kick" then
                    if self == LocalPlayer then
                        return  -- BLOQUEADO
                    end
                end
            end
            return _hookNamecallOriginal(self, ...)
        end))
        _hookAtivoNamecall = true
    end)
    return ok
end

-- HOOK 2: __newindex — intercepta Health/PlatformStand/Sit pelo servidor
local function instalarHookNewIndex()
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        _hookNewIndexOriginal = rawget(mt, "__newindex")
        mt.__newindex = newcclosure(function(self, chave, valor)
            if ghostAtivado and not bypassHealthBlock then
                local c   = LocalPlayer.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                -- Bloqueia reducao de vida vinda do servidor
                if (chave == "Health" or chave == "MaxHealth") and hum and self == hum then
                    if type(valor) == "number" and valor < VIDA_INF then
                        return  -- BLOQUEADO
                    end
                end
                -- Bloqueia PlatformStand=true (grab mechanic precisa disso)
                if chave == "PlatformStand" and valor == true and hum and self == hum then
                    return  -- BLOQUEADO — nao deixa imobilizar o boneco
                end
                -- Bloqueia Sit=true (outra forma de grab)
                if chave == "Sit" and valor == true and hum and self == hum then
                    return  -- BLOQUEADO
                end
                -- Bloqueia Jump=false (alguns grabs desativam pulo)
                if chave == "Jump" and valor == false and hum and self == hum then
                    return  -- BLOQUEADO
                end

                -- Bloqueia WalkSpeed=0 e JumpPower=0 (sequencia de morte/jumpscare)
                -- O jogo trava o boneco antes de matar; a gente impede o travamento
                if hum and self == hum then
                    if chave == "WalkSpeed" and type(valor) == "number" and valor < 2 then
                        return  -- BLOQUEADO — nao deixa travar movimento
                    end
                    if chave == "JumpPower" and type(valor) == "number" and valor < 2 then
                        return  -- BLOQUEADO
                    end
                    if chave == "AutoRotate" and valor == false then
                        return  -- BLOQUEADO — alguns jogos travam rotacao na morte
                    end
                end

                -- Bloqueia knockback via AssemblyLinearVelocity em partes do personagem
                -- (Capitao Clark usa isso para jogar o boneco no chao)
                if chave == "AssemblyLinearVelocity" or chave == "AssemblyAngularVelocity" then
                    if c and self:IsDescendantOf(c) then
                        -- Permite velocidade normal de movimento (< 80 studs/s)
                        -- Bloqueia apenas velocidades de knockback brutais
                        if type(valor) == "userdata" then
                            local mag = valor.Magnitude
                            if mag > 80 then
                                return  -- BLOQUEADO — knockback detectado
                            end
                        end
                    end
                end

                -- Bloqueia Velocity (legado R6) em partes do personagem
                if chave == "Velocity" then
                    if c and self:IsDescendantOf(c) then
                        if type(valor) == "userdata" then
                            local mag = valor.Magnitude
                            if mag > 80 then
                                return  -- BLOQUEADO — knockback detectado
                            end
                        end
                    end
                end
            end
            return _hookNewIndexOriginal(self, chave, valor)
        end)
        setreadonly(mt, true)
        _hookAtivoNewIndex = true
    end)
    return ok
end

-- Desativa os hooks quando desligar
local function removerHooks()
    if _hookAtivoNamecall and _hookNamecallOriginal then
        pcall(function()
            hookmetamethod(game, "__namecall", _hookNamecallOriginal)
        end)
        _hookAtivoNamecall = false
    end
    if _hookAtivoNewIndex and _hookNewIndexOriginal then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__newindex = _hookNewIndexOriginal
            setreadonly(mt, true)
        end)
        _hookAtivoNewIndex = false
    end
end

local function conectorInvencivel(hum, char)
    ghostHealthConn = hum.HealthChanged:Connect(function()
        if not ghostAtivado then return end
        task.spawn(function()
            local h = char and char:FindFirstChildOfClass("Humanoid")
            if h then aplicarVidaBruta(h) end
        end)
    end)
    ghostDiedConn = hum.Died:Connect(function()
        if not ghostAtivado then return end
        task.spawn(function()
            task.wait(0.05)
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h then
                aplicarVidaBruta(h)
                pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end)
            end
        end)
    end)
end

do
    -- ANTI-DESMONTAR: guarda as juntas (Motor6D) do boneco e recria na
    -- hora qualquer uma que sumir/trocar de peca. Sem RootJoint o boneco
    -- nao anda; sem Neck o Humanoid morre (por isso RequiresNeck=false).
    local salvas, charSalvo = {}, nil
    GS.salvarJuntas = function(c)
        salvas, charSalvo = {}, c
        if not c then return end
        for _, j in ipairs(c:GetDescendants()) do
            if j:IsA("Motor6D") and j.Part0 and j.Part1 then
                table.insert(salvas, { obj=j, nome=j.Name, pai=j.Parent, p0=j.Part0, p1=j.Part1, c0=j.C0, c1=j.C1 })
            end
        end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            pcall(function() h.BreakJointsOnDeath = false end)
            pcall(function() h.RequiresNeck = false end)
        end
    end
    -- retorna true se precisou remontar alguma junta
    GS.repararJuntas = function(c)
        if not c or c ~= charSalvo then return false end
        local remontou = {}
        for _, s in ipairs(salvas) do
            local j = s.obj
            local quebrada = not j or not j.Parent or j.Part0 ~= s.p0 or j.Part1 ~= s.p1
            if quebrada and s.p0:IsDescendantOf(c) and s.p1:IsDescendantOf(c) then
                pcall(function()
                    if j and j.Parent then j:Destroy() end
                    local novo = Instance.new("Motor6D")
                    novo.Name = s.nome; novo.Part0 = s.p0; novo.Part1 = s.p1
                    novo.C0 = s.c0; novo.C1 = s.c1
                    novo.Parent = (s.pai and s.pai:IsDescendantOf(c)) and s.pai or s.p0
                    s.obj = novo
                    table.insert(remontou, s.nome)
                end)
            end
        end
        if #remontou > 0 then
            warn("[GRINGO INVENCIVEL] juntas quebradas e remontadas: " .. table.concat(remontou, ", "))
            return true
        end
        return false
    end
end

local function alternarGhost()
    ghostAtivado = not ghostAtivado
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")

    if ghostAtivado then
        GhostButton.Text = "INVENCIVEL: ON"

        -- Instala hooks de nivel engine (mais brutal possivel)
        instalarHookNamecall()
        instalarHookNewIndex()

        aplicarVidaBruta(hum)
        if hum then conectorInvencivel(hum, char) end
        GS.salvarJuntas(char)

        -- Rastreia ultima posicao segura no chao para escape de grab
        local ultimaPosSegura = nil
        local tempoUltimoPiso = 0

        -- ANTI-GRAB: quebra qualquer Weld/Constraint externo no personagem
        local function quebrarWeldsExternos(c)
            for _, part in pairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    -- Destroi Welds onde a outra parte nao eh do nosso personagem
                    for _, w in pairs(part:GetJoints()) do
                        if w:IsA("Weld") or w:IsA("WeldConstraint") then
                            local p0 = w:IsA("WeldConstraint") and w.Part0 or w.Part0
                            local p1 = w:IsA("WeldConstraint") and w.Part1 or w.Part1
                            local externoP0 = p0 and not p0:IsDescendantOf(c)
                            local externoP1 = p1 and not p1:IsDescendantOf(c)
                            if externoP0 or externoP1 then
                                pcall(function() w:Destroy() end)
                            end
                        end
                    end
                    -- Destroi NoCollisionConstraint e RigidConstraint externos
                    for _, co in pairs(part:GetChildren()) do
                        if co:IsA("RigidConstraint") or co:IsA("BallSocketConstraint")
                        or co:IsA("HingeConstraint") or co:IsA("SlidingBallConstraint") then
                            local a0 = co:FindFirstChild("Attachment0") or rawget(co, "Attachment0")
                            -- Se tem Attachment que nao pertence ao char, destroi
                            pcall(function()
                                if co.Attachment0 and not co.Attachment0.Parent:IsDescendantOf(c) then
                                    co:Destroy()
                                elseif co.Attachment1 and not co.Attachment1.Parent:IsDescendantOf(c) then
                                    co:Destroy()
                                end
                            end)
                        end
                    end
                end
            end
        end

        -- Heartbeat — fallback + anti-grab ativo todo frame
        ghostConnection = RunService.Heartbeat:Connect(function()
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if not h then return end
            local root = c:FindFirstChild("HumanoidRootPart")

            aplicarVidaBruta(h)

            -- ANTI-DESMONTAR: remonta o boneco e tira de baixo do chao
            if GS.repararJuntas(c) and root and ultimaPosSegura then
                pcall(function()
                    root.CFrame = CFrame.new(ultimaPosSegura + Vector3.new(0, 3, 0))
                    root.AssemblyLinearVelocity = Vector3.zero
                end)
            end

            -- Garante PlatformStand/Sit desligados (fallback se hook falhar)
            pcall(function() if h.PlatformStand then h.PlatformStand = false end end)
            pcall(function() if h.Sit then h.Sit = false end end)

            -- ANTI-KNOCKBACK: zera velocidade absurda (murro do Capitao Clark)
            -- Velocidade normal de corrida = ~16-32 studs/s. Knockback = >80
            if root then
                local vel = root.AssemblyLinearVelocity
                if vel.Magnitude > 80 then
                    pcall(function()
                        root.AssemblyLinearVelocity = Vector3.new(0, vel.Y > 0 and vel.Y or 0, 0)
                    end)
                end
                -- Tambem reseta rotacao absurda (ragdoll gira o boneco)
                local angVel = root.AssemblyAngularVelocity
                if angVel.Magnitude > 5 then
                    pcall(function()
                        root.AssemblyAngularVelocity = Vector3.zero
                    end)
                end
            end

            if h:GetState() == Enum.HumanoidStateType.Dead then
                pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end)
                aplicarVidaBruta(h)
            end

            -- ANTI-GRAB: destrói welds externos todo frame
            quebrarWeldsExternos(c)

            -- Rastreia posicao segura quando no chao
            if root then
                local pos = root.Position
                local ray = workspace:Raycast(pos, Vector3.new(0, -5, 0))
                if ray then
                    ultimaPosSegura = pos
                    tempoUltimoPiso = tick()
                end

                -- Detecta grab: levantado no ar perto de NPC nao-player
                local alturaDoChao = pos.Y
                if not ray and (tick() - tempoUltimoPiso) > 0.3 then
                    -- Verifica se tem NPC perto (o Locusto)
                    local grabbedByNPC = false
                    for _, obj in pairs(workspace:GetChildren()) do
                        if obj:IsA("Model") and obj ~= c and not Players:GetPlayerFromCharacter(obj) then
                            local npcRoot = obj:FindFirstChild("HumanoidRootPart")
                            if npcRoot then
                                local dist = (pos - npcRoot.Position).Magnitude
                                if dist < 12 then  -- perto o suficiente para ser um grab
                                    grabbedByNPC = true
                                    break
                                end
                            end
                        end
                    end
                    if grabbedByNPC and ultimaPosSegura then
                        -- ESCAPE: teletransporta de volta ao chao e reseta velocidade
                        pcall(function()
                            root.CFrame = CFrame.new(ultimaPosSegura)
                            root.Velocity = Vector3.new(0, 0, 0)
                            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            if root:FindFirstChild("BodyVelocity") then
                                root.BodyVelocity:Destroy()
                            end
                        end)
                        -- Destrói welds imediatamente após escape
                        quebrarWeldsExternos(c)
                        aplicarVidaBruta(h)
                    end
                end
            end

            for _, obj in pairs(c:GetDescendants()) do
                if (obj:IsA("LocalScript") or obj:IsA("Script")) and not obj.Disabled then
                    local n = obj.Name:lower()
                    if n:find("health") or n:find("death") or n:find("damage") or n:find("kill") then
                        pcall(function() obj.Disabled = true end)
                    end
                end
            end

            -- ANTI-JUMPSCARE / ANTI-TELA DE MORTE:
            -- Detecta e destroi GUIs de morte/jumpscare que o jogo injeta
            -- (Casa do Locusto, horror games — mostram tela vermelha quando pegam voce)
            pcall(function()
                for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") then
                        local n = gui.Name:lower()
                        -- Nome suspeito de morte
                        if n:find("death") or n:find("dead") or n:find("die")
                        or n:find("jump") or n:find("scare") or n:find("caught")
                        or n:find("kill") or n:find("lose") or n:find("gameover")
                        or n:find("end") or n:find("over") or n:find("fail") then
                            gui:Destroy()
                        else
                            -- Verifica se e uma GUI fullscreen escura/vermelha (jumpscare visual)
                            for _, frame in pairs(gui:GetDescendants()) do
                                if frame:IsA("Frame") or frame:IsA("ImageLabel") then
                                    local size = frame.Size
                                    local isFullscreen = size.X.Scale >= 0.9 and size.Y.Scale >= 0.9
                                    if isFullscreen then
                                        local col = frame.BackgroundColor3
                                        -- Vermelho escuro = jumpscare tipico
                                        if col.R > 0.5 and col.G < 0.3 and col.B < 0.3 then
                                            pcall(function() gui:Destroy() end)
                                            break
                                        end
                                        -- Completamente preto = tela de morte
                                        if col.R < 0.05 and col.G < 0.05 and col.B < 0.05
                                        and frame.BackgroundTransparency < 0.3 then
                                            pcall(function() gui:Destroy() end)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end)

        -- Stepped — segunda frequencia independente
        ghostSteppedConn = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if not h then return end
            aplicarVidaBruta(h)
            if h:GetState() == Enum.HumanoidStateType.Dead then
                pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end)
                aplicarVidaBruta(h)
            end
        end)

        -- Reconecta apos respawn
        LocalPlayer.CharacterAdded:Connect(function(newChar)
            if not ghostAtivado then return end
            task.wait(0.3)
            local newHum = newChar:FindFirstChildOfClass("Humanoid")
            GS.salvarJuntas(newChar)
            if newHum then
                aplicarVidaBruta(newHum)
                conectorInvencivel(newHum, newChar)
            end
        end)

    else
        GhostButton.Text = "INVENCIVEL: OFF"
        removerHooks()
        if ghostConnection   then ghostConnection:Disconnect()   ghostConnection   = nil end
        if ghostHealthConn   then ghostHealthConn:Disconnect()   ghostHealthConn   = nil end
        if ghostDiedConn     then ghostDiedConn:Disconnect()     ghostDiedConn     = nil end
        if ghostSteppedConn  then ghostSteppedConn:Disconnect()  ghostSteppedConn  = nil end
        bypassHealthBlock = false
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then
            pcall(function() h.MaxHealth = 100 end)
            pcall(function() h.Health    = 100 end)
            pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead,        true) end)
            pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.FallingDown,  true) end)
            pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,      true) end)
            pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Physics,      true) end)
        end
    end
end

do
-- ═══════════════════════════════════════════════════════════════
--   ESP BRUTAL — RASTREAR MONSTRO (VERSAO 3.0)
-- ═══════════════════════════════════════════════════════════════
-- Deteccao (pega mais tipos de monstro que a v2):
--   • Model com Humanoid vivo (NPC/monstro classico)
--   • Model com AnimationController (monstro sem Humanoid — muito
--     comum em jogo de terror, a v2 nao achava esses)
--   • Model com nome suspeito mesmo sem nada disso
--   Nome suspeito (ingles/portugues/CHINES): monster, enemy, killer,
--   ghost, zombie, boss... 怪 鬼 敌 僵尸 杀手 魔 妖 尸 怨 凶 恶 丧尸
--   → nome suspeito = VERMELHO "⚠ MONSTRO"; outros NPCs = LARANJA
-- Ignora qualquer coisa dentro do personagem de um player.
-- Visualizacao:
--   1. Highlight atraves da parede (Roblox so desenha ~31 por vez,
--      entao liga so nos mais perto, monstro tem prioridade)
--   2. Nome + vida + distancia em cima
--   3. Linha da parte de baixo da tela ate o monstro
--   4. Aviso no topo: monstro mais perto + distancia (pisca < 40 m)
-- Performance: varredura completa a cada 3s + deteccao instantanea
-- quando alguma coisa nova aparece no mapa (DescendantAdded).
-- ═══════════════════════════════════════════════════════════════
local ESP = {
    ativo = false, cache = {}, conn = nil, addConn = nil,
    gui = nil, hud = nil, timer = 0, timerHL = 0,
}
local ESP_CFG = {
    RESCAN        = 3,    -- segundos entre varreduras completas
    MAX_HIGHLIGHT = 28,   -- limite de Highlights ligados ao mesmo tempo
    PERIGO        = 40,   -- studs: abaixo disso o aviso fica vermelho piscando
    PALAVRAS = {
        "monster", "monstro", "enemy", "inimigo", "killer", "assassin",
        "ghost", "fantasma", "zombie", "zumbi", "beast", "boss", "creature",
        "demon", "devil", "entity", "hunter", "stalker", "seeker", "chaser",
        "spirit", "witch", "clown", "doll", "slender", "mimic", "figure",
        "怪", "鬼", "敌", "僵尸", "丧尸", "杀手", "魔", "妖", "尸", "怨",
        "凶", "恶", "灵", "追", "猎", "boss",
    },
    COR_MONSTRO = Color3.fromRGB(255, 0, 60),
    COR_NPC     = Color3.fromRGB(255, 170, 0),
}

local function _nomeSuspeito(model)
    local n = string.lower(model.Name)
    for _, palavra in ipairs(ESP_CFG.PALAVRAS) do
        if string.find(n, palavra, 1, true) then return true end
    end
    return false
end

local function _dePlayer(obj)
    if obj == LocalPlayer.Character then return true end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and (obj == p.Character or obj:IsDescendantOf(p.Character)) then return true end
    end
    return false
end

local function _ancoragem(model)
    local r = model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Head")
    if r and r:IsA("BasePart") then return r end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

-- Retorna "monstro", "npc" ou nil
local function _avaliar(model)
    if not model or not model:IsA("Model") or not model.Parent then return nil end
    if model == workspace then return nil end
    if _dePlayer(model) then return nil end
    if not _ancoragem(model) then return nil end
    local suspeito = _nomeSuspeito(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.Health <= 0 and not suspeito then return nil end
        return suspeito and "monstro" or "npc"
    end
    local ac = model:FindFirstChildOfClass("AnimationController")
    if ac then
        if suspeito then return "monstro" end
        if model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") then return "npc" end
        return nil
    end
    if suspeito then return "monstro" end
    return nil
end

-- Pra qualquer objeto, devolve o Model que pode ser monstro
local function _candidato(obj)
    if obj:IsA("Humanoid") or obj:IsA("AnimationController") then
        return obj.Parent
    end
    if obj:IsA("Model") and _nomeSuspeito(obj) then
        return obj
    end
    return nil
end

local function _destruirEntrada(itens)
    pcall(function()
        if itens.Highlight then itens.Highlight:Destroy() end
        if itens.Gui       then itens.Gui:Destroy()       end
        if itens.Linha     then itens.Linha:Destroy()     end
    end)
end

local function _criarEntrada(model, tipo)
    local anc = _ancoragem(model)
    local cor = tipo == "monstro" and ESP_CFG.COR_MONSTRO or ESP_CFG.COR_NPC

    local hl = Instance.new("Highlight")
    hl.FillColor = cor; hl.FillTransparency = 0.55
    hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model; hl.Enabled = false; hl.Parent = ESP.gui

    local bgui = Instance.new("BillboardGui")
    bgui.AlwaysOnTop = true; bgui.Size = UDim2.new(0, 200, 0, 58)
    bgui.StudsOffset = Vector3.new(0, 4, 0); bgui.Adornee = anc
    bgui.LightInfluence = 0; bgui.Parent = ESP.gui
    local bg = Instance.new("Frame", bgui)
    bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5; bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)
    local function lbl(y, h, fonte, tam, c)
        local l = Instance.new("TextLabel", bgui)
        l.Size = UDim2.new(1, -6, 0, h); l.Position = UDim2.new(0, 3, 0, y)
        l.BackgroundTransparency = 1; l.Font = fonte; l.TextSize = tam; l.TextColor3 = c
        l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); l.TextStrokeTransparency = 0.3
        l.TextXAlignment = Enum.TextXAlignment.Left; l.TextTruncate = Enum.TextTruncate.AtEnd
        return l
    end
    local nomeLbl = lbl(2, 20, Enum.Font.GothamBold, 13, Color3.fromRGB(255, 255, 255))
    nomeLbl.Text = (tipo == "monstro" and "⚠ " or "") .. model.Name
    local vidaLbl = lbl(22, 17, Enum.Font.RobotoMono, 11, cor)
    local distLbl = lbl(39, 16, Enum.Font.RobotoMono, 11, Color3.fromRGB(220, 220, 220))

    local linha
    if tipo == "monstro" then
        linha = Instance.new("Frame", ESP.gui)
        linha.AnchorPoint = Vector2.new(0.5, 0.5); linha.BorderSizePixel = 0
        linha.BackgroundColor3 = cor; linha.BackgroundTransparency = 0.2; linha.Visible = false
    end

    return {
        Model = model, Tipo = tipo, Ancoragem = anc, Highlight = hl, Gui = bgui,
        VidaLbl = vidaLbl, DistLbl = distLbl, Linha = linha, Dist = math.huge,
    }
end

local function _adicionar(model)
    if not ESP.ativo or not model or ESP.cache[model] then return end
    local tipo = _avaliar(model)
    if tipo then ESP.cache[model] = _criarEntrada(model, tipo) end
end

local function _varrerTudo()
    local vistos = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        local m = _candidato(obj)
        if m and not vistos[m] then
            vistos[m] = true
            _adicionar(m)
        end
    end
    -- remove o que morreu / sumiu / virou invalido
    for model, itens in pairs(ESP.cache) do
        if _avaliar(model) == nil then
            _destruirEntrada(itens)
            ESP.cache[model] = nil
        end
    end
end

-- Liga Highlight so nos mais perto (monstro primeiro)
local function _distribuirHighlights()
    local lista = {}
    for _, itens in pairs(ESP.cache) do table.insert(lista, itens) end
    table.sort(lista, function(a, b)
        if a.Tipo ~= b.Tipo then return a.Tipo == "monstro" end
        return a.Dist < b.Dist
    end)
    for i, itens in ipairs(lista) do
        itens.Highlight.Enabled = i <= ESP_CFG.MAX_HIGHLIGHT
    end
end

local function _desenharLinha(f, a, b)
    local d = b - a
    f.Size = UDim2.fromOffset(d.Magnitude, 2)
    f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
    f.Rotation = math.deg(math.atan2(d.Y, d.X))
end

local function limparESP()
    if ESP.conn then ESP.conn:Disconnect() ESP.conn = nil end
    if ESP.addConn then ESP.addConn:Disconnect() ESP.addConn = nil end
    for _, itens in pairs(ESP.cache) do _destruirEntrada(itens) end
    ESP.cache = {}
    if ESP.gui then ESP.gui:Destroy() ESP.gui = nil end
    ESP.hud = nil
end

local function alternarEsp()
    ESP.ativo = not ESP.ativo
    if not ESP.ativo then
        EspButton.Text = "RASTREAR MONSTRO: OFF"
        limparESP()
        return
    end
    EspButton.Text = "RASTREAR MONSTRO: ON"

    ESP.gui = Instance.new("ScreenGui")
    ESP.gui.Name = "GringoESP"; ESP.gui.IgnoreGuiInset = true
    ESP.gui.ResetOnSpawn = false; ESP.gui.DisplayOrder = 98
    ESP.gui.Parent = GS.pai

    ESP.hud = Instance.new("TextLabel", ESP.gui)
    ESP.hud.Size = UDim2.new(0, 360, 0, 30); ESP.hud.Position = UDim2.new(0.5, -180, 0, 40)
    ESP.hud.BackgroundColor3 = Color3.fromRGB(0, 0, 0); ESP.hud.BackgroundTransparency = 0.35
    ESP.hud.Font = Enum.Font.GothamBold; ESP.hud.TextSize = 15; ESP.hud.BorderSizePixel = 0
    ESP.hud.TextColor3 = Color3.fromRGB(255, 255, 255); ESP.hud.Text = "👹 PROCURANDO MONSTRO..."
    Instance.new("UICorner", ESP.hud).CornerRadius = UDim.new(0, 8)

    ESP.timer = ESP_CFG.RESCAN   -- varre ja no primeiro frame
    ESP.addConn = workspace.DescendantAdded:Connect(function(obj)
        task.defer(function()
            pcall(function()
                local m = _candidato(obj)
                if m then _adicionar(m) end
            end)
        end)
    end)

    ESP.conn = RunService.Heartbeat:Connect(function(dt)
        local meuChar = LocalPlayer.Character
        local meuRoot = meuChar and meuChar:FindFirstChild("HumanoidRootPart")
        if not meuRoot then return end

        ESP.timer = ESP.timer + dt
        if ESP.timer >= ESP_CFG.RESCAN then
            ESP.timer = 0
            pcall(_varrerTudo)
        end

        local cam = workspace.CurrentCamera
        local vp  = cam.ViewportSize
        local origem = Vector2.new(vp.X / 2, vp.Y)
        local maisPerto, maisPertoD = nil, math.huge

        for model, itens in pairs(ESP.cache) do
            pcall(function()
                local anc = itens.Ancoragem
                if not anc or not anc.Parent then
                    itens.Ancoragem = _ancoragem(model); anc = itens.Ancoragem
                    if not anc then return end
                    itens.Gui.Adornee = anc
                end
                local dist = (meuRoot.Position - anc.Position).Magnitude
                itens.Dist = dist
                itens.DistLbl.Text = string.format("◈ %.0f m", dist)

                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then
                    local hp, maxhp = math.ceil(hum.Health), math.ceil(hum.MaxHealth)
                    if maxhp >= 1e9 or maxhp ~= maxhp then
                        itens.VidaLbl.Text = string.format("♥ %d / INF", hp)
                    else
                        itens.VidaLbl.Text = string.format("♥ %d / %d", hp, maxhp)
                    end
                else
                    itens.VidaLbl.Text = itens.Tipo == "monstro" and "♥ (sem vida visivel)" or "NPC"
                end

                if itens.Tipo == "monstro" then
                    if dist < maisPertoD then maisPerto, maisPertoD = model, dist end
                    local pos, naTela = cam:WorldToViewportPoint(anc.Position)
                    if pos.Z > 0 then
                        _desenharLinha(itens.Linha, origem, Vector2.new(pos.X, pos.Y))
                        itens.Linha.Visible = true
                    else
                        itens.Linha.Visible = false
                    end
                end
            end)
        end

        ESP.timerHL = ESP.timerHL + dt
        if ESP.timerHL >= 0.5 then
            ESP.timerHL = 0
            pcall(_distribuirHighlights)
        end

        if maisPerto then
            ESP.hud.Text = string.format("👹 %s — %.0f m", maisPerto.Name, maisPertoD)
            if maisPertoD < ESP_CFG.PERIGO then
                local pisca = math.floor(tick() * 4) % 2 == 0
                ESP.hud.BackgroundColor3 = pisca and Color3.fromRGB(200, 0, 40) or Color3.fromRGB(0, 0, 0)
            else
                ESP.hud.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            end
        else
            ESP.hud.Text = "👹 NENHUM MONSTRO ACHADO"
            ESP.hud.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        end
    end)
end

GS.alternarEsp = alternarEsp
GS.limparESP   = function() ESP.ativo = false limparESP() end
end  -- fim ESP

-- ═══════════════════════════════════
--   ANTI-TRAVA BRUTAL
-- ═══════════════════════════════════
-- Tecnica: BodyGyro com torque maximo nos eixos X e Z para travar o boneco ereto
-- + desabilita todos os estados de queda no Humanoid a cada frame
-- + forca sair do estado de queda se entrar nele
-- + reseta PlatformStand e Sit continuamente
local antiTravaAtivado = false
local antiTravaConnection = nil
local antiTravaGyro = nil

local ESTADOS_QUEDA = {
    Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Ragdoll,
    Enum.HumanoidStateType.GettingUp,
}

local function alternarAntiTrava()
    antiTravaAtivado = not antiTravaAtivado
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if antiTravaAtivado then
        AntiTravaButton.Text = "ANTI-TRAVA: ON"

        -- Desabilita estados de queda imediatamente
        if hum then
            for _, estado in ipairs(ESTADOS_QUEDA) do
                hum:SetStateEnabled(estado, false)
            end
        end

        -- BodyGyro: trava a rotacao do boneco nos eixos X e Z (nao deixa tombar)
        -- MaxTorque Y = 0 para nao interferir na rotacao do personagem ao andar
        if root then
            antiTravaGyro = Instance.new("BodyGyro"); antiTravaGyro.Name = "GringoAntiTravaGyro"
            antiTravaGyro.MaxTorque = Vector3.new(math.huge, 0, math.huge)
            antiTravaGyro.P = 9999999  -- rigidez maxima
            antiTravaGyro.D = 1000     -- amortecimento para nao vibrar
            antiTravaGyro.CFrame = CFrame.new(root.Position) -- ereto, sem rotacao X/Z
            antiTravaGyro.Parent = root
        end

        antiTravaConnection = RunService.Heartbeat:Connect(function()
            local c   = LocalPlayer.Character
            local h   = c and c:FindFirstChildOfClass("Humanoid")
            local r   = c and c:FindFirstChild("HumanoidRootPart")
            if not h or not r then return end

            -- Reaplica desativacao de estados a cada frame (jogo pode resetar)
            for _, estado in ipairs(ESTADOS_QUEDA) do
                h:SetStateEnabled(estado, false)
            end

            -- Se o humanoid entrou em queda mesmo assim, arranca ele de la na forca
            local estadoAtual = h:GetState()
            if estadoAtual == Enum.HumanoidStateType.FallingDown
            or estadoAtual == Enum.HumanoidStateType.Ragdoll then
                -- Muda direto pro estado de Running, sem passar pelo GettingUp
                h:ChangeState(Enum.HumanoidStateType.Running)
            end

            -- Recria o BodyGyro se o servidor destruiu
            if not antiTravaGyro or not antiTravaGyro.Parent then
                antiTravaGyro = Instance.new("BodyGyro"); antiTravaGyro.Name = "GringoAntiTravaGyro"
                antiTravaGyro.MaxTorque = Vector3.new(math.huge, 0, math.huge)
                antiTravaGyro.P = 9999999
                antiTravaGyro.D = 1000
                antiTravaGyro.Parent = r
            end

            -- Trava o boneco ereto: CFrame sem inclinacao X/Z
            -- Preserva apenas o Y (direcao que o boneco ta olhando no plano horizontal)
            local cf = r.CFrame
            local _, ry, _ = cf:ToEulerAnglesYXZ()
            antiTravaGyro.CFrame = CFrame.fromEulerAnglesYXZ(0, ry, 0)

            -- Reseta PlatformStand e Sit (alguns jogos usam isso pra derrubar)
            if h.PlatformStand and not flyAtivado then
                h.PlatformStand = false
            end
            if h.Sit then
                h.Sit = false
            end

            -- Reseta Jump se o jogo travar o pulo como parte do knockback
            h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            h:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
        end)

    else
        AntiTravaButton.Text = "ANTI-TRAVA: OFF"
        if antiTravaConnection then antiTravaConnection:Disconnect() antiTravaConnection = nil end
        if antiTravaGyro then antiTravaGyro:Destroy() antiTravaGyro = nil end

        -- Reabilita os estados ao desligar
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then
            for _, estado in ipairs(ESTADOS_QUEDA) do
                h:SetStateEnabled(estado, true)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--   PUXAR TODOS — ARRASTA JOGADORES PRO SEU REDOR
-- ═══════════════════════════════════════════════════════════════
-- Logica: BodyPosition com MaxForce infinito instalado no HumanoidRootPart
--   de cada outro jogador (ate 10), atualizado todo frame.
--   Posicao alvo = CFrame local do jogador * offset em leque atras dele.
--   Quando flyAtivado, MaxForce Y = math.huge → eles sobem junto no voo.
--   Jogador local nao e afetado de nenhuma forma, anda/voa normalmente.
--   Ao desligar: destroi todos os BodyPositions instalados (cleanup total).
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
-- PUXAR TODOS v5 — TRAVA BRUTA + 11 DANCAS
-- ═══════════════════════════════════════════════════════════════
-- Por que funciona:
--   O Roblox passa a fisica de NPC solto pro jogador mais perto
--   (network ownership). Com a fisica no nosso PC, o que fazemos com
--   o NPC replica pra todo mundo.
-- Camadas da trava (todas reaplicadas TODO frame):
--   1) AlignPosition + AlignOrientation RIGIDOS no root do monstro.
--   2) Teleporte direto do root pro lugar dele + velocidade zerada.
--   3) Pernas mortas: WalkSpeed/JumpPower 0, AutoRotate off, PlatformStand.
--   4) Anti-empurrao: BodyMovers/LinearVelocity/VectorForce/Align que o
--      jogo coloca no monstro pra "dar vida" sao desligados no nosso PC.
--   5) Animacoes do monstro paradas (fica duro dancando, mais engracado).
--   6) Registro por eventos: monstro novo (ex.: estatua que vira monstro
--      e e trocada por outro modelo) e pego no mesmo frame.
-- Limite real: se o jogo tomar a fisica de volta pro servidor
-- (SetNetworkOwner(nil)), nada no cliente segura o monstro. Com
-- isnetworkowner disponivel, o contador mostra quantos estao assim.
-- Personagem de outro JOGADOR nao e movido (a fisica e do PC dele);
-- pra eles so vale a corda (RopeConstraint), como na versao antiga.
-- v9.1.2 — MONSTRO QUE "LIGA" (ex.: animatronico que comeca parado):
--   7) Detector de monstro solto: ancorado, isnetworkowner=false ou o
--      servidor puxando ele de volta 12 quadros seguidos = o servidor
--      assumiu. Ele e solto (parar de fingir que esta preso) e vira AMEACA.
--   8) Fuga automatica: ameaca SE MEXENDO dentro do raio -> voce e
--      teleportado pro ponto seguro mais longe de todas (seu personagem e
--      do seu PC, o servidor aceita). Estatua parada perto nao dispara.
--   9) Anti-toque: suas partes param de registrar toque (CanTouch=false),
--      entao morte por encostar no monstro nao pega.
-- ═══════════════════════════════════════════════════════════════
local puxarConnection = nil
local PX = { ativo=false, dancar=false, danca="MIX", ctrl={}, reg={}, cordasReg={}, cordas={},
             regConns=nil, slotN=0, t0=0, avisou=false,
             -- v9.1.2: monstro que LIGA (o servidor assume) nao te mata
             fuga=true, raioFuga=18, antiToque=true, perdidos={}, rastro={}, seguros={},
             ultimaFuga=0, ultimoSeguro=0, fugas=0, toqueOrig={}, ultimoToque=0 }

do
    local ZERO = Vector3.zero
    local MOVERS = { LinearVelocity=true, AngularVelocity=true, VectorForce=true, LineForce=true,
                     Torque=true, AlignPosition=true, AlignOrientation=true, BodyMover=true }

    PX.DANCAS = { "MIX","REBOLADO","GIRO","PULA-PULA","CABEÇADA","HELICÓPTERO","MINHOCA",
                  "ROBÔ","CAMBALHOTA","MOONWALK","AGACHADINHA","TRENZINHO" }

    local function ehNPC(m, meuChar)
        if not m or not m:IsA("Model") or m == meuChar then return false end
        if Players:GetPlayerFromCharacter(m) then return false end
        local h = m:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then return false end
        local r = m:FindFirstChild("HumanoidRootPart") or h.RootPart
        if not r or not r:IsA("BasePart") then return false end
        if r.Anchored then return false, "ancorado" end
        return true, h, r
    end

    -- ── Registro por eventos (nada de varrer o mapa todo frame) ──
    local function registrar(d)
        if d:IsA("Humanoid") then
            PX.reg[d] = true
            -- VACINA 1: monstro recriado e preso no instante em que nasce
            if PX.ativo then
                task.defer(function()
                    local m = d.Parent
                    if not PX.ativo or not m or PX.ctrl[m] then return end
                    local ok, hh, r = ehNPC(m, LocalPlayer.Character)
                    if ok then pcall(PX.prender, m, hh, r) end
                end)
            end
        elseif d:IsA("RopeConstraint") then PX.cordasReg[d] = true end
    end
    PX.iniciarRegistro = function()
        if PX.regConns then return end
        PX.regConns = {}
        for _, d in ipairs(workspace:GetDescendants()) do registrar(d) end
        table.insert(PX.regConns, workspace.DescendantAdded:Connect(registrar))
        table.insert(PX.regConns, workspace.DescendantRemoving:Connect(function(d)
            PX.reg[d] = nil; PX.cordasReg[d] = nil
        end))
    end
    ScreenGui.Destroying:Connect(function()
        for _, c in ipairs(PX.regConns or {}) do pcall(function() c:Disconnect() end) end
        PX.regConns = nil
    end)

    -- ── Anti-empurrao ──
    local function neutralizar(c, o)
        if o.Name:sub(1, 6) == "Gringo" then return end
        local ehMover = MOVERS[o.ClassName] or o:IsA("BodyMover")
        if not ehMover then return end
        pcall(function()
            if o:IsA("BodyMover") then
                table.insert(c.movers, { o=o, pai=o.Parent })
                o.Parent = nil                     -- so no nosso PC; volta ao soltar
            elseif o.Enabled then
                table.insert(c.movers, { o=o, enabled=true })
                o.Enabled = false
            end
        end)
    end

    local function bracosNormais(c)
        for _, o in ipairs(c.ombros) do
            pcall(function() if o.j.Parent then o.j.C0 = o.c0 end end)
        end
    end

    PX.prender = function(m, h, r)
        PX.slotN = PX.slotN + 1
        local c = { model=m, root=r, hum=h, ombros={}, movers={}, slot=PX.slotN, animT=0 }
        c.orig = { ws=h.WalkSpeed, jp=h.JumpPower, jh=h.JumpHeight, ar=h.AutoRotate, ps=h.PlatformStand }
        for _, d in ipairs(m:GetDescendants()) do
            neutralizar(c, d)
            if d:IsA("Motor6D") then
                if d.Name == "Left Shoulder" or d.Name == "LeftShoulder" then
                    table.insert(c.ombros, { j=d, c0=d.C0, lado=-1 })
                elseif d.Name == "Right Shoulder" or d.Name == "RightShoulder" then
                    table.insert(c.ombros, { j=d, c0=d.C0, lado=1 })
                end
            end
        end
        c.conn = m.DescendantAdded:Connect(function(d) neutralizar(c, d) end)
        c.att = Instance.new("Attachment"); c.att.Name = "GringoPuxarAtt"; c.att.Parent = r
        c.ap = Instance.new("AlignPosition"); c.ap.Name = "GringoPuxarAP"
        c.ap.Mode = Enum.PositionAlignmentMode.OneAttachment
        c.ap.Attachment0 = c.att; c.ap.RigidityEnabled = true
        c.ap.Position = r.Position; c.ap.Parent = r
        c.ao = Instance.new("AlignOrientation"); c.ao.Name = "GringoPuxarAO"
        c.ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        c.ao.Attachment0 = c.att; c.ao.RigidityEnabled = true
        c.ao.CFrame = r.CFrame; c.ao.Parent = r
        PX.ctrl[m] = c
        return c
    end

    PX.soltar = function(m)
        local c = PX.ctrl[m]
        if not c then return end
        PX.ctrl[m] = nil
        if c.conn then c.conn:Disconnect() end
        for _, o in ipairs({ c.ap, c.ao, c.att }) do pcall(function() o:Destroy() end) end
        for _, mv in ipairs(c.movers) do
            pcall(function()
                if mv.pai then
                    if mv.pai.Parent then mv.o.Parent = mv.pai end
                else
                    mv.o.Enabled = true
                end
            end)
        end
        pcall(function()
            local h, o = c.hum, c.orig
            h.WalkSpeed = o.ws; h.JumpPower = o.jp; h.JumpHeight = o.jh
            h.AutoRotate = o.ar; h.PlatformStand = o.ps
        end)
        bracosNormais(c)
    end

    -- ── Dancas (offset relativo ao lugar do monstro, virado pra voce) ──
    local POSES = {
        ["REBOLADO"] = function(t)
            local s = math.sin(t * 8)
            return CFrame.new(s * 1.2, math.abs(s) * 0.6, 0) * CFrame.Angles(0, 0, s * 0.45)
        end,
        ["GIRO"] = function(t)
            return CFrame.new(0, math.abs(math.sin(t * 6)) * 1.5, 0) * CFrame.Angles(0, t * 5, 0)
        end,
        ["PULA-PULA"] = function(t)
            return CFrame.new(0, math.abs(math.sin(t * 5)) * 4, 0)
        end,
        ["CABEÇADA"] = function(t)
            return CFrame.Angles(math.sin(t * 10) * 0.6, 0, 0)
        end,
        ["HELICÓPTERO"] = function(t)   -- deitado girando muito rapido
            return CFrame.new(0, 1.5, 0) * CFrame.Angles(0, t * 14, 0) * CFrame.Angles(math.pi / 2, 0, 0)
        end,
        ["MINHOCA"] = function(t)       -- de barriga no chao ondulando
            return CFrame.new(0, -1.6 + math.abs(math.sin(t * 4)) * 0.9, 0)
                 * CFrame.Angles(-math.pi / 2 + math.sin(t * 8) * 0.35, 0, 0)
        end,
        ["ROBÔ"] = function(t)          -- movimentos travados, de 4 em 4 por segundo
            local q = math.floor(t * 4)
            return CFrame.new(0, (q % 2) * 0.4, 0) * CFrame.Angles(0, math.rad(((q % 4) - 1.5) * 30), math.rad(((q % 3) - 1) * 12))
        end,
        ["CAMBALHOTA"] = function(t)    -- mortal pra tras sem parar
            local f = (t % 1.2) / 1.2
            return CFrame.new(0, math.sin(f * math.pi) * 5, 0) * CFrame.Angles(-f * math.pi * 2, 0, 0)
        end,
        ["MOONWALK"] = function(t)      -- desliza pra frente e pra tras
            return CFrame.new(0, math.abs(math.sin(t * 8)) * 0.3, math.sin(t * 1.5) * 4) * CFrame.Angles(-0.15, 0, math.sin(t * 8) * 0.08)
        end,
        ["AGACHADINHA"] = function(t)   -- de costas, agachando sem parar
            return CFrame.Angles(0, math.pi, 0) * CFrame.new(0, -math.abs(math.sin(t * 9)) * 1.5, 0)
                 * CFrame.Angles(0.35 + math.sin(t * 18) * 0.15, 0, 0)
        end,
        ["TRENZINHO"] = function(t, idx)  -- o lugar vira fila atras de voce (ver slotCF)
            local p = t * 6 + idx
            return CFrame.new(0, math.abs(math.sin(p)) * 0.8, 0) * CFrame.Angles(0, 0, math.sin(p) * 0.3)
        end,
    }

    local function dancaAtual(t)
        if PX.danca ~= "MIX" then return PX.danca end
        return PX.DANCAS[2 + math.floor(t / 3) % (#PX.DANCAS - 1)]
    end

    local function slotCF(idx, n, meuRoot, trenzinho)
        local centro = meuRoot.Position
        if trenzinho then
            local rot = meuRoot.CFrame - centro
            local pos = (meuRoot.CFrame * CFrame.new(0, 0, 4 + idx * 3.2)).Position
            return CFrame.new(pos) * rot
        end
        local raio = math.max(8, n * 1.3)
        local ang = (idx / n) * math.pi * 2
        local pos = centro + Vector3.new(math.cos(ang) * raio, 0, math.sin(ang) * raio)
        return CFrame.lookAt(pos, Vector3.new(centro.X, pos.Y, centro.Z))
    end

    local function segurar(c, idx, n, meuRoot, t, nomeDanca, dt)
        local h, r = c.hum, c.root
        if h.WalkSpeed ~= 0 then h.WalkSpeed = 0 end
        if h.JumpPower ~= 0 then h.JumpPower = 0 end
        if h.JumpHeight ~= 0 then h.JumpHeight = 0 end
        if h.AutoRotate then h.AutoRotate = false end
        if not h.PlatformStand then h.PlatformStand = true end

        c.animT = c.animT + dt
        if c.animT >= 0.3 then
            c.animT = 0
            local animator = h:FindFirstChildOfClass("Animator")
            if animator then
                for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do tr:Stop(0) end
            end
        end

        local cf = slotCF(idx, n, meuRoot, PX.dancar and nomeDanca == "TRENZINHO")
        if PX.dancar then
            local tt = t + idx * 0.08   -- leve atraso entre eles = efeito "ola"
            cf = cf * POSES[nomeDanca](tt, idx)
            for _, o in ipairs(c.ombros) do
                if o.j.Parent then
                    o.j.C0 = o.c0 * CFrame.Angles(0, 0, o.lado * (2.2 + math.sin(tt * 10) * 0.8))
                end
            end
        end
        c.ap.Position = cf.Position
        c.ao.CFrame = cf
        r.CFrame = cf
        r.AssemblyLinearVelocity = ZERO
        r.AssemblyAngularVelocity = ZERO
        c.cf = cf   -- usado pela re-trava antes da fisica (VACINA 2)
    end

    -- ── Monstro solto: o servidor assumiu? ──
    local function servidorAssumiu(c)
        if c.root.Anchored then return true end
        if isnetworkowner then
            local ok, meu = pcall(isnetworkowner, c.root)
            if ok and meu == false then return true end
        end
        return (c.desvios or 0) >= 12   -- servidor puxando de volta seguido
    end

    -- ── Anti-toque: suas partes nao registram toque ──
    local function aplicarAntiToque(meuChar)
        for _, d in ipairs(meuChar:GetDescendants()) do
            if d:IsA("BasePart") and d.CanTouch then
                if PX.toqueOrig[d] == nil then PX.toqueOrig[d] = true end
                pcall(function() d.CanTouch = false end)
            end
        end
    end
    PX.restaurarToque = function()
        for d in pairs(PX.toqueOrig) do pcall(function() if d.Parent then d.CanTouch = true end end) end
        PX.toqueOrig = {}
    end

    -- ── Fuga: ponto seguro mais longe das ameacas ──
    local function distMin(pos, ameacas)
        local m = math.huge
        for _, a in ipairs(ameacas) do
            local d = (a - pos).Magnitude
            if d < m then m = d end
        end
        return m
    end
    local function chaoEm(pos, meuChar)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { meuChar }
        local r = workspace:Raycast(pos + Vector3.new(0, 25, 0), Vector3.new(0, -80, 0), rp)
        return r and r.Position or nil
    end
    local function fugir(meuRoot, meuChar, ameacas)
        local melhor, melhorD = nil, PX.raioFuga * 2
        for _, p in ipairs(PX.seguros) do
            local d = distMin(p, ameacas)
            if d > melhorD then melhor, melhorD = p, d end
        end
        if not melhor then
            -- sem ponto guardado: corre 35 studs pro lado oposto da ameaca mais perto
            local perto, pd = nil, math.huge
            for _, a in ipairs(ameacas) do
                local d = (a - meuRoot.Position).Magnitude
                if d < pd then perto, pd = a, d end
            end
            local dir = perto and (meuRoot.Position - perto) or meuRoot.CFrame.LookVector
            dir = Vector3.new(dir.X, 0, dir.Z)
            if dir.Magnitude < 0.1 then dir = Vector3.new(1, 0, 0) end
            melhor = chaoEm(meuRoot.Position + dir.Unit * 35, meuChar) or (meuRoot.Position + dir.Unit * 35)
        end
        local rot = meuRoot.CFrame - meuRoot.Position
        meuRoot.CFrame = CFrame.new(melhor + Vector3.new(0, 3, 0)) * rot
        meuRoot.AssemblyLinearVelocity = ZERO
        PX.fugas = PX.fugas + 1
    end

    PX.passo = function(dt)
        local meuChar = LocalPlayer.Character
        local meuRoot = meuChar and meuChar:FindFirstChild("HumanoidRootPart")
        if not meuRoot then return end
        local agora = os.clock()

        -- monstro que o servidor assumiu: solta e vira ameaca
        for m, c in pairs(PX.ctrl) do
            if servidorAssumiu(c) then
                PX.perdidos[m] = agora
                PX.soltar(m)
            end
        end

        -- anti-toque (confere 1x por segundo: roupa/arma nova tambem entra)
        if PX.antiToque and agora - PX.ultimoToque > 1 then
            PX.ultimoToque = agora
            aplicarAntiToque(meuChar)
        end

        -- ameacas: monstro vivo, NAO preso, se mexendo e perto
        local ameacas, perto = {}, false
        for h in pairs(PX.reg) do
            local m = h.Parent
            if m and m:IsA("Model") and m ~= meuChar and not PX.ctrl[m] and h.Health > 0
            and not Players:GetPlayerFromCharacter(m) then
                local r = m:FindFirstChild("HumanoidRootPart") or h.RootPart or m.PrimaryPart
                if r then
                    local pos = r.Position
                    local ant = PX.rastro[m]
                    local vel = ant and dt > 0 and (pos - ant).Magnitude / dt or 0
                    PX.rastro[m] = pos
                    if vel > 2 or PX.perdidos[m] then
                        table.insert(ameacas, pos)
                        if (pos - meuRoot.Position).Magnitude < PX.raioFuga then perto = true end
                    end
                end
            end
        end
        -- guarda ponto seguro (no chao, longe de toda ameaca), 4x por segundo
        if agora - PX.ultimoSeguro > 0.25 then
            PX.ultimoSeguro = agora
            local hum = meuChar:FindFirstChildOfClass("Humanoid")
            local noChao = hum and hum.FloorMaterial ~= Enum.Material.Air
            if noChao and distMin(meuRoot.Position, ameacas) > PX.raioFuga * 2 then
                local ultimo = PX.seguros[#PX.seguros]
                if not ultimo or (ultimo - meuRoot.Position).Magnitude > 6 then
                    table.insert(PX.seguros, meuRoot.Position)
                    if #PX.seguros > 40 then table.remove(PX.seguros, 1) end
                end
            end
        end
        if PX.fuga and perto and agora - PX.ultimaFuga > 0.6 then
            PX.ultimaFuga = agora
            pcall(fugir, meuRoot, meuChar, ameacas)
        end

        -- pega monstro novo na hora (e conta os ancorados: esses o servidor
        -- move por CFrame/Tween e nenhum cliente consegue segurar)
        local ancorados = 0
        for h in pairs(PX.reg) do
            local m = h.Parent
            if m and not PX.ctrl[m] and not (PX.perdidos[m] and agora - PX.perdidos[m] < 3) then
                local ok, hh, r = ehNPC(m, meuChar)
                if ok then pcall(PX.prender, m, hh, r)
                elseif hh == "ancorado" then ancorados = ancorados + 1 end
            end
        end
        -- solta quem morreu ou sumiu
        for m, c in pairs(PX.ctrl) do
            if not m:IsDescendantOf(workspace) or not c.root:IsDescendantOf(m)
            or not c.hum.Parent or c.hum.Health <= 0 then
                PX.soltar(m)
            end
        end

        -- cordas entre jogadores (metodo antigo)
        for rope in pairs(PX.cordasReg) do
            pcall(function()
                if PX.cordas[rope] == nil then
                    local m0 = rope.Attachment0 and rope.Attachment0:FindFirstAncestorOfClass("Model")
                    local m1 = rope.Attachment1 and rope.Attachment1:FindFirstAncestorOfClass("Model")
                    local p0 = m0 and Players:GetPlayerFromCharacter(m0)
                    local p1 = m1 and Players:GetPlayerFromCharacter(m1)
                    PX.cordas[rope] = (p0 and p1 and p0 ~= p1) and rope.Length or false
                end
                if PX.cordas[rope] then rope.Length = 1; rope.Restitution = 0 end
            end)
        end

        local lista = {}
        for _, c in pairs(PX.ctrl) do table.insert(lista, c) end
        table.sort(lista, function(a, b) return a.slot < b.slot end)

        local n = #lista
        local t = os.clock() - PX.t0
        local nomeDanca = dancaAtual(t)
        local doServidor = 0
        for idx, c in ipairs(lista) do
            pcall(segurar, c, idx, n, meuRoot, t, nomeDanca, dt)
            if isnetworkowner then
                local ok, meu = pcall(isnetworkowner, c.root)
                if ok and meu == false then doServidor = doServidor + 1 end
            end
        end

        if GS.puxarStatus then
            local txt = "🧲 PRESOS: " .. (n - doServidor)
            if doServidor > 0 then txt = txt .. "   ⚠ SERVIDOR SEGURANDO: " .. doServidor end
            local soltos = 0
            for m, quando in pairs(PX.perdidos) do
                if agora - quando < 3 then soltos = soltos + 1 else PX.perdidos[m] = nil end
            end
            if soltos > 0 then txt = txt .. "   🔓 LIGARAM: " .. soltos end
            if PX.fugas > 0 then txt = txt .. "   🏃 FUGAS: " .. PX.fugas end
            if ancorados > 0 then txt = txt .. "   ⚓ ANCORADOS: " .. ancorados end
            if PX.dancar then txt = txt .. "   💃 " .. nomeDanca end
            if GS.puxarStatus.Text ~= txt then GS.puxarStatus.Text = txt end
        end
    end

    -- ── Seletor de dancas ──
    local botoesDanca = {}
    local function pintarDancas()
        local U = GS.ui
        for nome, b in pairs(botoesDanca) do
            local sel = nome == PX.danca
            U.tw(b, { BackgroundColor3 = sel and U.T.on or U.T.card, TextColor3 = sel and U.T.knobOn or U.T.dim }, 0.15)
        end
    end
    if GS.puxarBox and GS.ui then
        local U = GS.ui
        local grade = Instance.new("Frame", GS.puxarBox)
        grade.Size = UDim2.new(1, 0, 0, 0); grade.AutomaticSize = Enum.AutomaticSize.Y
        grade.BackgroundTransparency = 1; grade.LayoutOrder = 4
        local gl = Instance.new("UIGridLayout", grade)
        gl.CellSize = UDim2.new(1/3, -6, 0, 30); gl.CellPadding = UDim2.new(0, 8, 0, 8)
        gl.SortOrder = Enum.SortOrder.LayoutOrder
        for i, nome in ipairs(PX.DANCAS) do
            local b = Instance.new("TextButton", grade)
            b.Text = nome; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.AutoButtonColor = false
            b.BackgroundColor3 = U.T.card; b.TextColor3 = U.T.dim; b.BorderSizePixel = 0; b.LayoutOrder = i
            U.mkC(8, b); U.mkS(1, U.T.stroke, b); U.press(b)
            b.MouseButton1Click:Connect(function()
                PX.danca = nome; PX.t0 = os.clock()
                pintarDancas()
                GS.toast("💃  Dança: " .. nome, true)
            end)
            botoesDanca[nome] = b
        end
        pintarDancas()

        local togFuga  = U.tog(GS.puxarBox, "Fugir de monstro que ligou (teleporta você)", 10, "rabbit")
        local fMenos, fMais, fLbl = U.ctrl(GS.puxarBox, "Raio da fuga (studs)", tostring(PX.raioFuga), 11)
        local togToque = U.tog(GS.puxarBox, "Anti-toque (encostar não mata)", 12, "shield")
        togFuga.Text = "FUGA: ON"; togToque.Text = "ANTI-TOQUE: ON"
        togFuga.MouseButton1Click:Connect(function()
            PX.fuga = not PX.fuga
            togFuga.Text = PX.fuga and "FUGA: ON" or "FUGA: OFF"
        end)
        togToque.MouseButton1Click:Connect(function()
            PX.antiToque = not PX.antiToque
            togToque.Text = PX.antiToque and "ANTI-TOQUE: ON" or "ANTI-TOQUE: OFF"
            if not PX.antiToque then PX.restaurarToque() else PX.ultimoToque = 0 end
        end)
        fMenos.MouseButton1Click:Connect(function() PX.raioFuga = math.max(8, PX.raioFuga - 2); fLbl.Text = tostring(PX.raioFuga) end)
        fMais.MouseButton1Click:Connect(function() PX.raioFuga = math.min(60, PX.raioFuga + 2); fLbl.Text = tostring(PX.raioFuga) end)
    end

    GS.alternarDanca = function()
        PX.dancar = not PX.dancar
        GS.dancaBtn.Text = PX.dancar and "DANÇA: ON" or "DANÇA: OFF"
        PX.t0 = os.clock()
        if not PX.dancar then
            for _, c in pairs(PX.ctrl) do bracosNormais(c) end
        end
    end
end

local function _limparPuxar()
    if PX.stepConn then PX.stepConn:Disconnect() PX.stepConn = nil end
    for m in pairs(PX.ctrl) do PX.soltar(m) end
    PX.ctrl = {}
    for rope, len in pairs(PX.cordas) do
        if len then pcall(function() if rope.Parent then rope.Length = len end end) end
    end
    PX.cordas = {}
    if PX.restaurarToque then PX.restaurarToque() end
    PX.perdidos, PX.rastro, PX.seguros, PX.fugas = {}, {}, {}, 0
    if GS.puxarStatus then GS.puxarStatus.Text = "🧲 PRESOS: 0" end
end

local function alternarPuxar()
    PX.ativo = not PX.ativo
    if PX.ativo then
        PuxarButton.Text = "PUXAR TODOS: ON"
        PX.t0 = os.clock(); PX.avisou = false
        if puxarConnection then puxarConnection:Disconnect() end
        puxarConnection = RunService.Heartbeat:Connect(function(dt)
            if not PX.regConns then return end
            local ok, err = pcall(PX.passo, dt)
            if not ok and not PX.avisou then
                PX.avisou = true
                warn("[GRINGO PUXAR] " .. tostring(err))
            end
        end)
        task.defer(PX.iniciarRegistro)   -- varre o mapa 1 vez so, sem travar o clique
        -- VACINA 2: re-trava ANTES da fisica — se o servidor teleportar o
        -- monstro, ele volta pro lugar no mesmo passo
        if PX.stepConn then PX.stepConn:Disconnect() end
        PX.stepConn = RunService.Stepped:Connect(function()
            for _, c in pairs(PX.ctrl) do
                if c.cf and c.root.Parent then
                    pcall(function()
                        -- longe de onde deixamos = o servidor moveu ele (conta)
                        if (c.root.Position - c.cf.Position).Magnitude > 6 then
                            c.desvios = (c.desvios or 0) + 1
                        elseif (c.desvios or 0) > 0 then
                            c.desvios = c.desvios - 1
                        end
                        c.root.CFrame = c.cf
                        c.root.AssemblyLinearVelocity = Vector3.zero
                    end)
                end
            end
        end)
    else
        PuxarButton.Text = "PUXAR TODOS: OFF"
        if puxarConnection then puxarConnection:Disconnect() puxarConnection = nil end
        _limparPuxar()
    end
end

-- ═══════════════════════════════════════════════════════════════
--   PUXAR JOGADOR (por nome) — TELEPORTE VISUAL CONTINUO
-- ═══════════════════════════════════════════════════════════════
-- Digita o nome (ou parte do nome) do amigo, aperta o botao e o
-- personagem dele "spawna"/aparece do seu lado — igual aos paineis
-- que so tem essa funcao de puxar 1 jogador especifico.
--
-- IMPORTANTE (limitacao real do Roblox, sem enganacao):
--   Isso funciona escrevendo o CFrame do HumanoidRootPart do alvo
--   direto, todo frame, pra ele ficar "grudado" do seu lado na SUA
--   tela. Isso e o mesmo metodo que qualquer painel de "puxar jogador"
--   usa. So que so VOCE ve ele ali do seu lado — o jogo real (server)
--   e as telas dos OUTROS jogadores continuam mostrando ele na posicao
--   de verdade, porque o Roblox so deixa o proprio client do jogador
--   mover o personagem dele de forma que os outros vejam (FilteringEnabled).
--   Nao existe jeito 100% client-side de teleportar OUTRO jogador de
--   verdade pro mapa inteiro ver — nenhum executor consegue isso sem
--   um exploit de servidor, que nao existe nos executores atuais.
-- ═══════════════════════════════════════════════════════════════
local puxarUmAtivado = false
local puxarUmConn    = nil
local puxarUmAlvo    = nil

local function localizarJogadorPorNome(texto)
    texto = string.lower(texto or "")
    if texto == "" then return nil end
    -- match exato no inicio do nome
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and string.sub(string.lower(p.Name), 1, #texto) == texto then
            return p
        end
    end
    -- match no display name
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local disp = string.lower(p.DisplayName or p.Name)
            if string.sub(disp, 1, #texto) == texto or string.find(disp, texto, 1, true) then
                return p
            end
        end
    end
    -- match em qualquer parte do nome (fallback mais permissivo)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and string.find(string.lower(p.Name), texto, 1, true) then
            return p
        end
    end
    return nil
end

local function _limparPuxarUm()
    if puxarUmConn then puxarUmConn:Disconnect() puxarUmConn = nil end
    puxarUmAlvo = nil
    puxarUmAtivado = false
    pcall(function() PuxarUmButton.Text = "🧲  PUXAR JOGADOR" end)
end

local function alternarPuxarUm()
    if puxarUmAtivado then
        _limparPuxarUm()
        return
    end

    local alvo = localizarJogadorPorNome(PuxarNomeInput.Text)
    if not alvo then
        -- feedback de erro no proprio botao (nao achou o nome digitado)
        pcall(function()
            local original = PuxarUmButton.Text
            PuxarUmButton.Text = "❌ JOGADOR NÃO ENCONTRADO"
            task.delay(1.5, function()
                pcall(function()
                    if not puxarUmAtivado then PuxarUmButton.Text = original end
                end)
            end)
        end)
        return
    end

    puxarUmAtivado = true
    puxarUmAlvo    = alvo
    PuxarUmButton.Text = "🧲  PUXANDO: " .. alvo.Name

    puxarUmConn = RunService.Heartbeat:Connect(function()
        -- Se o alvo saiu do jogo, desliga sozinho
        if not (puxarUmAlvo and puxarUmAlvo.Parent) then
            _limparPuxarUm()
            return
        end
        local meuChar = LocalPlayer.Character
        local meuRoot = meuChar and meuChar:FindFirstChild("HumanoidRootPart")
        local alvoChar = puxarUmAlvo.Character
        local alvoRoot = alvoChar and alvoChar:FindFirstChild("HumanoidRootPart")
        if not meuRoot or not alvoRoot then return end

        pcall(function()
            -- Tenta assumir ownership tambem (funciona se o alvo for um NPC
            -- disfarcado ou se o jogo permitir; nao tem efeito em players reais)
            if setnetworkowner then pcall(function() setnetworkowner(alvoRoot, LocalPlayer) end) end
            alvoRoot.CFrame = meuRoot.CFrame * CFrame.new(0, 0, -4)
            alvoRoot.AssemblyLinearVelocity  = Vector3.zero
            alvoRoot.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════
--   DERRUBA v3 — NOCAUTE EM MONSTROS (tecla configuravel, padrao X)
-- ═══════════════════════════════════════════════════════════════
-- Apertou a tecla: TODO monstro/NPC num raio de 35 studs cai no chao,
-- tombando pra longe de voce, fica deitado se debatendo 4s e levanta.
-- Mesma base do PUXAR/ESCUDO (fisica do monstro no seu PC = todo mundo
-- ve): trava rigida deitado + teleporte antes e depois da fisica +
-- pernas mortas + forcas do jogo desligadas + animacoes paradas.
-- Pega monstro com Humanoid ou so com AnimationController.
-- Monstro ancorado (movido pelo servidor) nao cai — o aviso conta.
-- ═══════════════════════════════════════════════════════════════
local derrubaXConn = nil
local DR = { ativo=false, tecla=Enum.KeyCode.X, escutando=false, ultimo=0, caidos={}, stepConn=nil }

do
    local ALCANCE, CAIDO, QUEDA, COOLDOWN = 35, 4, 0.35, 0.3
    local ZERO = Vector3.zero
    local MOVERS = { LinearVelocity=true, AngularVelocity=true, VectorForce=true, LineForce=true,
                     Torque=true, AlignPosition=true, AlignOrientation=true }

    local function raizDe(m)
        local h = m:FindFirstChildOfClass("Humanoid")
        local r = (h and h.RootPart) or m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso")
        if r and r:IsA("BasePart") then return r end
        return m:FindFirstChildWhichIsA("BasePart", true)
    end

    local function monstrosPerto(pos)
        local achados, ancorados, maisPerto = {}, 0, math.huge
        local vistos = {}
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Humanoid") or d:IsA("AnimationController") then
                local m = d.Parent
                if m and m:IsA("Model") and not vistos[m] and not Players:GetPlayerFromCharacter(m) then
                    vistos[m] = true
                    local h = m:FindFirstChildOfClass("Humanoid")
                    local r = raizDe(m)
                    if r and (not h or h.Health > 0) then
                        local dist = (r.Position - pos).Magnitude
                        if dist < maisPerto then maisPerto = dist end
                        if dist <= ALCANCE and not DR.caidos[m] and not PX.ctrl[m] then
                            if r.Anchored then
                                if h then ancorados = ancorados + 1 end
                            else
                                table.insert(achados, { m=m, h=h, r=r })
                            end
                        end
                    end
                end
            end
        end
        return achados, ancorados, maisPerto
    end

    local function neutralizar(st, o)
        if o.Name:sub(1, 6) == "Gringo" then return end
        pcall(function()
            if o:IsA("BodyMover") then
                table.insert(st.movers, { o=o, pai=o.Parent }); o.Parent = nil
            elseif MOVERS[o.ClassName] and o.Enabled then
                table.insert(st.movers, { o=o }); o.Enabled = false
            end
        end)
    end

    local function levantar(m)
        local st = DR.caidos[m]
        if not st then return end
        DR.caidos[m] = nil
        if st.conn then st.conn:Disconnect() end
        if st.loop then st.loop:Disconnect() end
        for _, o in ipairs({ st.ap, st.ao, st.att }) do pcall(function() o:Destroy() end) end
        for _, mv in ipairs(st.movers) do
            pcall(function()
                if mv.pai then if mv.pai.Parent then mv.o.Parent = mv.pai end else mv.o.Enabled = true end
            end)
        end
        if st.h and st.orig then
            pcall(function()
                local h, o = st.h, st.orig
                h.WalkSpeed = o.ws; h.JumpPower = o.jp; h.JumpHeight = o.jh; h.AutoRotate = o.ar; h.PlatformStand = o.ps
                h:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end
        -- fica em pe de novo no mesmo lugar
        pcall(function()
            if st.r.Parent then
                st.r.CFrame = CFrame.new(st.chao + Vector3.new(0, st.alturaPe, 0)) * st.yaw
                st.r.AssemblyLinearVelocity = ZERO; st.r.AssemblyAngularVelocity = ZERO
            end
        end)
    end

    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude

    local function derrubar(alvo, minhaPos)
        local m, h, r = alvo.m, alvo.h, alvo.r
        local st = { m=m, h=h, r=r, movers={}, inicio=os.clock(), animT=0 }
        if h then st.orig = { ws=h.WalkSpeed, jp=h.JumpPower, jh=h.JumpHeight, ar=h.AutoRotate, ps=h.PlatformStand } end
        for _, d in ipairs(m:GetDescendants()) do neutralizar(st, d) end
        st.conn = m.DescendantAdded:Connect(function(d) neutralizar(st, d) end)

        -- chao embaixo do monstro + altura do pe
        rp.FilterDescendantsInstances = { LocalPlayer.Character, m }
        local de = r.Position
        local baixo = workspace:Raycast(de, Vector3.new(0, -60, 0), rp)
        st.chao = baixo and baixo.Position or (de - Vector3.new(0, 3, 0))
        st.alturaPe = math.clamp(de.Y - st.chao.Y, 1, 40)
        local okBox, _, tam = pcall(m.GetBoundingBox, m)
        local espessura = okBox and math.min(tam.X, tam.Z) / 2 or 1

        -- tomba pra longe de voce
        local fora = Vector3.new(de.X - minhaPos.X, 0, de.Z - minhaPos.Z)
        fora = fora.Magnitude > 0.1 and fora.Unit or Vector3.new(1, 0, 0)
        st.yaw = CFrame.lookAt(ZERO, -fora)            -- de costas pra direcao da queda
        local eixo = Vector3.new(-fora.Z, 0, fora.X)    -- eixo horizontal perpendicular
        st.empe  = CFrame.new(de) * st.yaw
        st.deitado = CFrame.new(st.chao + fora * (st.alturaPe * 0.6) + Vector3.new(0, espessura, 0))
                   * CFrame.fromAxisAngle(eixo, -math.pi / 2) * st.yaw  -- cabeca pra longe de voce

        st.att = Instance.new("Attachment"); st.att.Name = "GringoDerrubaAtt"; st.att.Parent = r
        st.ap = Instance.new("AlignPosition"); st.ap.Name = "GringoDerrubaAP"
        st.ap.Mode = Enum.PositionAlignmentMode.OneAttachment; st.ap.Attachment0 = st.att
        st.ap.RigidityEnabled = true; st.ap.Position = de; st.ap.Parent = r
        st.ao = Instance.new("AlignOrientation"); st.ao.Name = "GringoDerrubaAO"
        st.ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; st.ao.Attachment0 = st.att
        st.ao.RigidityEnabled = true; st.ao.CFrame = r.CFrame; st.ao.Parent = r
        DR.caidos[m] = st

        st.loop = RunService.Heartbeat:Connect(function(dt)
            local ok = pcall(function()
                if not m:IsDescendantOf(workspace) or not r.Parent or (h and h.Health <= 0) then
                    levantar(m); return
                end
                local t = os.clock() - st.inicio
                if t >= CAIDO then levantar(m); return end
                if h then
                    if h.WalkSpeed ~= 0 then h.WalkSpeed = 0 end
                    if h.JumpPower ~= 0 then h.JumpPower = 0 end
                    if h.JumpHeight ~= 0 then h.JumpHeight = 0 end
                    if h.AutoRotate then h.AutoRotate = false end
                    if not h.PlatformStand then h.PlatformStand = true end
                end
                st.animT = st.animT + dt
                if st.animT >= 0.3 then
                    st.animT = 0
                    local ctrl = h or m:FindFirstChildOfClass("AnimationController")
                    local animator = ctrl and ctrl:FindFirstChildOfClass("Animator")
                    if animator then for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do tr:Stop(0) end end
                end
                local cf
                if t < QUEDA then
                    local a = t / QUEDA
                    cf = st.empe:Lerp(st.deitado, a * a)          -- acelera caindo
                else
                    -- deitado se debatendo
                    local s = math.sin(t * 30) * 0.08
                    cf = st.deitado * CFrame.Angles(s, 0, s * 0.5) + Vector3.new(0, math.abs(math.sin(t * 18)) * 0.25, 0)
                end
                st.cf = cf
                st.ap.Position = cf.Position; st.ao.CFrame = cf
                r.CFrame = cf
                r.AssemblyLinearVelocity = ZERO; r.AssemblyAngularVelocity = ZERO
            end)
            if not ok then levantar(m) end
        end)
    end

    DR.executar = function()
        local agora = os.clock()
        if agora - DR.ultimo < COOLDOWN then return end
        DR.ultimo = agora
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local meuRoot = (hum and hum.RootPart) or (char and char:FindFirstChild("HumanoidRootPart"))
        if not meuRoot then return end
        local achados, ancorados, maisPerto = monstrosPerto(meuRoot.Position)
        for _, alvo in ipairs(achados) do pcall(derrubar, alvo, meuRoot.Position) end
        if #achados > 0 then
            GS.toast("💥  DERRUBOU " .. #achados .. (#achados == 1 and " MONSTRO" or " MONSTROS"), true)
        elseif ancorados > 0 then
            GS.toast("⚓  " .. ancorados .. " perto, mas o servidor segura (ancorado)", false)
        elseif maisPerto < math.huge then
            GS.toast(string.format("✕  Nenhum perto — o mais perto está a %.0f m", maisPerto), false)
        else
            GS.toast("✕  Nenhum monstro no mapa", false)
        end
    end

    -- re-trava ANTES da fisica (servidor teleportou → volta no mesmo passo)
    DR.stepConn = RunService.Stepped:Connect(function()
        for _, st in pairs(DR.caidos) do
            if st.cf and st.r.Parent then
                pcall(function() st.r.CFrame = st.cf; st.r.AssemblyLinearVelocity = ZERO end)
            end
        end
    end)

    DR.limpar = function()
        for m in pairs(DR.caidos) do levantar(m) end
    end
    ScreenGui.Destroying:Connect(function()
        DR.limpar()
        if DR.stepConn then DR.stepConn:Disconnect() DR.stepConn = nil end
    end)

    -- botao pra escolher a tecla
    if GS.derrubaTeclaBtn then
        local b = GS.derrubaTeclaBtn
        b.MouseButton1Click:Connect(function()
            DR.escutando = true
            b.Text = "[APERTE A TECLA]"
        end)
        UserInputService.InputBegan:Connect(function(input)
            if DR.escutando and input.UserInputType == Enum.UserInputType.Keyboard then
                DR.escutando = false
                DR.tecla = input.KeyCode
                b.Text = "TECLA DERRUBA: " .. input.KeyCode.Name
            end
        end)
    end
end

local function alternarDerruba()
    DR.ativo = not DR.ativo
    if DR.ativo then
        DerrubaButton.Text = "DERRUBA: ON"
        derrubaXConn = UserInputService.InputBegan:Connect(function(input, gp)
            if DR.escutando or UserInputService:GetFocusedTextBox() then return end
            if input.KeyCode == DR.tecla then DR.executar() end
        end)
    else
        DerrubaButton.Text = "DERRUBA: OFF"
        if derrubaXConn then derrubaXConn:Disconnect() derrubaXConn = nil end
    end
end

-- ═══════════════════════════════════════════════════════════════
--   BIKE GRAU — SISTEMA COMPLETO DE WHEELIE
-- ═══════════════════════════════════════════════════════════════
-- Como funciona no servidor:
--   Ao entrar num VehicleSeat o Roblox da network ownership do veiculo
--   pra voce. Isso significa que BodyGyro inserido no seat REPLICA
--   pro servidor e todo mundo ve o efeito — nao e visual-only.
--
-- OPCAO 1 — ANTI-QUEDA GRAU:
--   Monitora o angulo de inclinacao do seat todo frame.
--   Quando passa de ANGULO_MAX_QUEDA (82 graus), liga um BodyGyro
--   que segura a bike nesse angulo maximo. Embaixo do limite = fisica
--   normal, voce faz grau livre sem cair.
--
-- OPCAO 2 — GRAU RETO [Q]:
--   Enquanto segura Q, BodyGyro trava a bike em ANGULO_GRAU_RETO
--   (75 graus). MaxTorque Y = 0 para poder virar esquerda/direita.
--   Soltar Q = bike cai normal. Liga/desliga com botao, Q e o gatilho.
-- ═══════════════════════════════════════════════════════════════
local bikeAntiQuedaAtivado   = false
local bikeAntiQuedaConn      = nil
local bikeAntiQuedaKeyConn   = nil
local bikeGyroAntiQueda      = nil
-- Anti-Queda toggle state
local antiQuedaTravado       = false
local antiQuedaCapturaCF     = nil   -- CFrame de inclinacao capturado (sem gimbal lock)
local antiQuedaYawLock       = 0     -- yaw travado: nao segue drift, so atualiza no steering
local ANTI_QUEDA_KEY         = Enum.KeyCode.E
local escutandoAntiQuedaKey  = false

-- Retorna o SeatPart em que o player esta sentado (nil se nao ta na bike)
local function obterSeatPart()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.SeatPart
end

-- ─────────────────────────────────────────────
-- OPCAO 1: ANTI-QUEDA GRAU v3 — TOGGLE POR TECLA
-- Como funciona:
--   • Botão ativa o sistema (começa a ouvir a tecla definida)
--   • Pressiona tecla NA bike durante qualquer grau → captura ângulo atual e TRAVA
--   • Travado: pode virar esq/dir (Y livre), mas NÃO cai pra frente, atrás ou lado
--   • Pressiona tecla de novo → solta (física normal)
--   • D=8000 P=50000 = sem tremor, sem oscilação
-- ─────────────────────────────────────────────
local function _limparAntiQueda()
    antiQuedaTravado   = false
    antiQuedaCapturaCF = nil
    antiQuedaYawLock   = 0
    if bikeGyroAntiQueda and bikeGyroAntiQueda.Parent then
        pcall(function() bikeGyroAntiQueda:Destroy() end)
        bikeGyroAntiQueda = nil
    end
    -- Handoff limpo pra fisica normal: zera velocidade angular residual
    -- na hora exata de soltar, pra nao herdar giro torto de quando tava travado
    pcall(function()
        local seat = obterSeatPart()
        if seat then seat.AssemblyAngularVelocity = Vector3.zero end
    end)
    BikeAntiQuedaButton.BackgroundColor3 = Color3.fromRGB(20, 25, 22)
    BikeAntiQuedaButton.TextColor3 = Color3.fromRGB(236, 236, 240)
end

local function alternarBikeAntiQueda()
    bikeAntiQuedaAtivado = not bikeAntiQuedaAtivado
    if bikeAntiQuedaAtivado then
        BikeAntiQuedaButton.Text = "ANTI-QUEDA [" .. ANTI_QUEDA_KEY.Name .. "]: ON"

        -- Tecla: TOGGLE — 1a pressao trava no angulo atual, 2a solta
        bikeAntiQuedaKeyConn = UserInputService.InputBegan:Connect(function(input, _)
            if input.KeyCode ~= ANTI_QUEDA_KEY then return end
            if escutandoAntiQuedaKey then return end

            if antiQuedaTravado then
                -- JA TRAVADO → solta
                _limparAntiQueda()
                BikeAntiQuedaButton.Text = "ANTI-QUEDA [" .. ANTI_QUEDA_KEY.Name .. "]: ON"
            else
                -- SOLTO → trava no angulo atual
                local seat = obterSeatPart()
                if not seat then return end  -- nao ta na bike

                local cf = seat.CFrame
                local _, ry, _ = cf:ToEulerAnglesYXZ()

                -- ═══════════════════════════════════════════════════
                -- PASSO 1: ZERA VELOCIDADE ANGULAR IMEDIATAMENTE
                -- Sem isso, o momentum da empinada continua girando
                -- a bike mesmo depois do gyro ligar = flip inevitavel
                -- ═══════════════════════════════════════════════════
                pcall(function()
                    seat.AssemblyAngularVelocity = Vector3.zero
                end)

                -- PASSO 2: captura inclinacao como CFrame puro (SEM Euler)
                -- CFrame.Angles(0,-ry,0) remove o yaw atual → sobra só o tilt
                -- Isso evita o gimbal lock que causava o flip de 180° ao travar
                antiQuedaCapturaCF = CFrame.Angles(0, -ry, 0) * (cf - cf.Position)
                antiQuedaYawLock   = ry  -- trava o yaw de referencia aqui
                antiQuedaTravado   = true

                -- PASSO 3: cria gyro IMEDIATAMENTE apontado pro CFrame exato atual
                -- (nao espera o proximo frame do loop — sem janela de flip)
                pcall(function()
                    if bikeGyroAntiQueda and bikeGyroAntiQueda.Parent then
                        bikeGyroAntiQueda:Destroy()
                    end
                    bikeGyroAntiQueda = Instance.new("BodyGyro"); bikeGyroAntiQueda.Name = "GringoBikeGyro"
                    bikeGyroAntiQueda.MaxTorque = Vector3.new(math.huge, 0, math.huge)
                    bikeGyroAntiQueda.D = 20000  -- D altissimo: mata spin residual na hora
                    bikeGyroAntiQueda.P = 200000 -- P bruto: segura forte mesmo contra fisica
                    -- Usa cf exato atual: gyro ja sabe onde estar desde o frame 0
                    bikeGyroAntiQueda.CFrame = cf
                    bikeGyroAntiQueda.Parent = seat
                end)

                -- Feedback visual: laranja = travado
                BikeAntiQuedaButton.BackgroundColor3 = Color3.fromRGB(220, 120, 0)
                BikeAntiQuedaButton.TextColor3 = Color3.fromRGB(0, 0, 0)
                BikeAntiQuedaButton.Text = "ANTI-QUEDA TRAVADO!"
            end
        end)

        -- Loop: mantém o gyro atualizado (Y muda ao virar, tilt fixo por CFrame)
        bikeAntiQuedaConn = RunService.Heartbeat:Connect(function()
            if not antiQuedaTravado or not antiQuedaCapturaCF then return end

            local seat = obterSeatPart()
            if not seat then
                _limparAntiQueda()
                BikeAntiQuedaButton.Text = "ANTI-QUEDA [" .. ANTI_QUEDA_KEY.Name .. "]: ON"
                return
            end

            -- Recria gyro se o jogo destruiu (sem precisar recriar do zero)
            if not bikeGyroAntiQueda or not bikeGyroAntiQueda.Parent then
                pcall(function()
                    bikeGyroAntiQueda = Instance.new("BodyGyro"); bikeGyroAntiQueda.Name = "GringoBikeGyro"
                    bikeGyroAntiQueda.MaxTorque = Vector3.new(math.huge, 0, math.huge)
                    bikeGyroAntiQueda.D = 20000
                    bikeGyroAntiQueda.P = 200000
                    bikeGyroAntiQueda.Parent = seat
                end)
            end

            local cf    = seat.CFrame
            local _, ry, _ = cf:ToEulerAnglesYXZ()
            -- seat.Steer: -1/0/1 em VehicleSeat; or 0 protege seats normais
            local steer = (seat.Steer or 0)

            if steer ~= 0 then
                -- Player virando: ZERO interferencia em Y e Z (roll+yaw).
                -- O bike vira inclinando (banking) pro lado — se a gente mexe
                -- em Z mesmo um pouco, briga com essa inclinacao e inverte
                -- a direcao da curva (D ia pra esquerda, A ia pra direita).
                -- So o X (pitch = capotar pra frente/tras) fica travado
                -- SEMPRE, pra nunca cair, mas nunca durante a virada.
                antiQuedaYawLock = ry
                pcall(function()
                    bikeGyroAntiQueda.MaxTorque = Vector3.new(math.huge, 0, 0)
                    bikeGyroAntiQueda.D = 20000
                    bikeGyroAntiQueda.P = 200000
                end)
            else
                -- Sem steering: TRAVA Y TAMBEM com torque total e P/D no maximo
                -- Isso e o que realmente impede o drift em alta velocidade —
                -- antes so zerava velocidade DEPOIS do drift acontecer (tarde
                -- demais). Agora o gyro luta ATIVAMENTE contra qualquer torque
                -- que a fisica da roda tente aplicar (fricao em alta veloc.)
                pcall(function()
                    bikeGyroAntiQueda.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    bikeGyroAntiQueda.D = 20000
                    bikeGyroAntiQueda.P = 200000
                end)
            end
            -- Usa SEMPRE o yaw travado, nunca o atual
            -- Isso impede que qualquer drift fisico atualize o target
            local targetRot = CFrame.Angles(0, antiQuedaYawLock, 0) * antiQuedaCapturaCF
            pcall(function()
                bikeGyroAntiQueda.CFrame = CFrame.new(cf.Position) * targetRot
            end)

            -- Belt+suspenders: zera velocidade angular residual tambem
            pcall(function()
                if steer == 0 then
                    seat.AssemblyAngularVelocity = Vector3.zero
                else
                    local av = seat.AssemblyAngularVelocity
                    seat.AssemblyAngularVelocity = Vector3.new(0, av.Y, 0)
                end
            end)
        end)

    else
        BikeAntiQuedaButton.Text = "ANTI-QUEDA GRAU: OFF"
        _limparAntiQueda()
        if bikeAntiQuedaKeyConn then bikeAntiQuedaKeyConn:Disconnect() bikeAntiQuedaKeyConn = nil end
        if bikeAntiQuedaConn    then bikeAntiQuedaConn:Disconnect()    bikeAntiQuedaConn    = nil end
    end
end

-- ─────────────────────────────────────────────
-- CONFIGURAR TECLA DO ANTI-QUEDA
-- ─────────────────────────────────────────────
BikeAntiQuedaKeyButton.MouseButton1Click:Connect(function()
    if bikeAntiQuedaAtivado then return end
    escutandoAntiQuedaKey = true
    BikeAntiQuedaKeyButton.Text = "[PRESSIONE TECLA]"
    BikeAntiQuedaKeyButton.TextColor3 = Color3.fromRGB(255, 255, 0)
end)

UserInputService.InputBegan:Connect(function(input, _)
    if not escutandoAntiQuedaKey then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    escutandoAntiQuedaKey = false
    ANTI_QUEDA_KEY = input.KeyCode
    local nome = ANTI_QUEDA_KEY.Name
    BikeAntiQuedaKeyButton.Text = "TECLA ANTI-QUEDA: " .. nome
    BikeAntiQuedaKeyButton.TextColor3 = Color3.fromRGB(236, 236, 240)
    if bikeAntiQuedaAtivado then
        if not antiQuedaTravado then
            BikeAntiQuedaButton.Text = "ANTI-QUEDA [" .. nome .. "]: ON"
        end
    else
        BikeAntiQuedaButton.Text = "ANTI-QUEDA GRAU: OFF"
    end
end)

-- ─────────────────────────────────────────────
-- PAREDE INVISIVEL — cria barreiras solidas no mapa
-- Como funciona:
--   • Aperta "PAREDE: OFF" pra ligar o modo de colocacao
--   • Uma caixa fantasma (vermelha, semi-transparente) segue o mouse
--     igual colocar bloco no Minecraft
--   • Aperta "CONFIRMAR PAREDE" pra travar ali: cria a parede de
--     verdade (solida e invisivel) — quem passar da de cara com ela
--   • Pode confirmar varias vezes sem precisar reativar o modo
--   • "REMOVER PAREDES" apaga todas as paredes ja criadas
-- ─────────────────────────────────────────────
local paredeAtiva     = false
local paredePreview   = nil
local paredeRenderConn = nil
local paredesCriadas  = {}
local PAREDE_TAMANHO  = Vector3.new(12, 10, 2)

local function _limparParedePreview()
    if paredePreview then
        pcall(function() paredePreview:Destroy() end)
        paredePreview = nil
    end
    if paredeRenderConn then
        paredeRenderConn:Disconnect()
        paredeRenderConn = nil
    end
end

local function alternarParede()
    paredeAtiva = not paredeAtiva
    if paredeAtiva then
        ParedeButton.Text = "PAREDE: ON"

        -- Cria a caixa fantasma de preview (segue o mouse)
        paredePreview = Instance.new("Part")
        paredePreview.Name = "GringoParedePreview"
        paredePreview.Size = PAREDE_TAMANHO
        paredePreview.Anchored = true
        paredePreview.CanCollide = false
        paredePreview.Material = Enum.Material.ForceField
        paredePreview.Color = Color3.fromRGB(255, 60, 60)
        paredePreview.Transparency = 0.5
        paredePreview.Parent = workspace

        local mouse = LocalPlayer:GetMouse()
        paredeRenderConn = RunService.RenderStepped:Connect(function()
            if not paredePreview then return end
            local hitPos = mouse.Hit and mouse.Hit.Position
            if not hitPos then return end

            -- Orienta a parede de frente pra camera (perpendicular a visao)
            local camera  = workspace.CurrentCamera
            local lookFlat = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
            if lookFlat.Magnitude < 0.01 then lookFlat = Vector3.new(0, 0, -1) end
            lookFlat = lookFlat.Unit

            local yaw = math.atan2(lookFlat.X, lookFlat.Z)
            local pos = hitPos + Vector3.new(0, PAREDE_TAMANHO.Y / 2, 0)
            pcall(function()
                paredePreview.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
            end)
        end)
    else
        ParedeButton.Text = "PAREDE: OFF"
        _limparParedePreview()
    end
end

ParedeConfirmButton.MouseButton1Click:Connect(function()
    if not paredeAtiva or not paredePreview then return end

    -- Cria a parede de verdade: solida (CanCollide) e invisivel (Transparency 1)
    -- OBS: essa parede so bloqueia o SEU proprio personagem. Uma Part criada
    -- por script local nao existe pro servidor nem pros outros clients, entao
    -- e fisicamente impossivel travar outros jogadores com ela — isso nao e
    -- um bug, e uma limitacao de seguranca do proprio Roblox.
    local parede = Instance.new("Part")
    parede.Name = "GringoParedeInvisivel"
    parede.Size = paredePreview.Size
    parede.CFrame = paredePreview.CFrame
    parede.Anchored = true
    parede.CanCollide = true
    parede.Transparency = 1
    parede.Material = Enum.Material.Plastic
    parede.Parent = workspace

    table.insert(paredesCriadas, parede)

    -- Confirmou: desliga o modo de colocacao sozinho (some a caixa fantasma
    -- vermelha que ficava seguindo o mouse — isso que parecia "parede andando")
    paredeAtiva = false
    ParedeButton.Text = "PAREDE: OFF"
    _limparParedePreview()
end)

ParedeRemoverButton.MouseButton1Click:Connect(function()
    for _, p in ipairs(paredesCriadas) do
        if p and p.Parent then
            pcall(function() p:Destroy() end)
        end
    end
    paredesCriadas = {}
end)

do
-- ═══════════════════════════════════════════════════════════════
--   COR GLOBAL — FORCA BRUTA NOS REMOTES DE COR DO JOGO
-- ═══════════════════════════════════════════════════════════════
-- Mudar cor direto pelo client NAO replica (FilteringEnabled), entao
-- o unico caminho pra todo mundo ver e o SERVIDOR aplicar a cor.
-- Isso varre o jogo inteiro atras de RemoteEvent/RemoteFunction com
-- nome de cor/avatar/skin/pintura e dispara cada um com TODOS os
-- formatos de argumento comuns:
--   Color3, BrickColor, HEX ("FF00FF" / "#FF00FF"), r,g,b (0-255),
--   tabela {R,G,B}, (Character, cor), (Player, cor), (nomeParte, cor)
-- Se o jogo tiver um sistema de cor que aceite qualquer um desses,
-- o servidor aplica e o mapa inteiro ve. Lista dos remotes no F9.
-- ═══════════════════════════════════════════════════════════════
local corEscolhida      = Color3.fromRGB(255,0,200)
local corGlobalAtivado  = false
local corRemotes        = nil   -- cache da varredura
local COR_REPETIR_RATE  = 2     -- segundos entre reaplicacoes no modo continuo
local COR_NOMES_REMOTE  = {
    "color", "colour", "paint", "pintar", "pintura", "rgb", "tint", "hue",
    "skin", "bodycolor", "avatar", "outfit", "appearance", "aparencia",
    "customiz", "personaliz", "dye", "tone",
}
local COR_PARTES = {
    "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg",
    "HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3",
    "LeftLegColor3", "RightLegColor3",
    "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm",
    "LeftUpperLeg", "RightUpperLeg",
}

local function _nomeEhDeCor(nome)
    local n = nome:lower()
    -- "cor" so no comeco/fim do nome (evita pegar "score", "record", "core"...)
    if n == "cor" or n:match("^cor[_%s]") or n:match("^corpo") or n:match("cor$") then
        return true
    end
    for _, chave in ipairs(COR_NOMES_REMOTE) do
        if n:find(chave, 1, true) then return true end
    end
    return false
end

local function _procurarRemotesCor()
    local achados = {}
    local function varrer(raiz)
        pcall(function()
            for _, obj in ipairs(raiz:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent"))
                and _nomeEhDeCor(obj.Name) then
                    table.insert(achados, obj)
                end
            end
        end)
    end
    varrer(game:GetService("ReplicatedStorage"))
    varrer(workspace)
    varrer(LocalPlayer)
    pcall(function() varrer(game:GetService("StarterGui")) end)
    print("[GRINGO COR] Remotes de cor encontrados: " .. #achados)
    for _, r in ipairs(achados) do print("  -> [" .. r.ClassName .. "] " .. r:GetFullName()) end
    return achados
end

local function _argumentosCor(cor)
    local r, g, b = math.floor(cor.R*255+0.5), math.floor(cor.G*255+0.5), math.floor(cor.B*255+0.5)
    local hex = cor:ToHex()
    local lista = {
        { cor },
        { BrickColor.new(cor) },
        { hex }, { "#" .. hex }, { hex:upper() },
        { r, g, b },
        { cor.R, cor.G, cor.B },
        { { R = r, G = g, B = b } },
        { { r, g, b } },
        { LocalPlayer.Character, cor },
        { LocalPlayer, cor },
        { "Color", cor }, { "BodyColor", cor }, { "Skin", cor },
    }
    for _, parte in ipairs(COR_PARTES) do
        table.insert(lista, { parte, cor })
    end
    return lista
end

local function _dispararRemote(remote, args)
    if remote:IsA("RemoteFunction") then
        -- InvokeServer trava esperando resposta: roda separado
        task.spawn(function() pcall(function() remote:InvokeServer(table.unpack(args)) end) end)
    else
        pcall(function() remote:FireServer(table.unpack(args)) end)
    end
end

local function aplicarCorGlobal()
    if not corRemotes then corRemotes = _procurarRemotesCor() end
    if #corRemotes == 0 then
        CorAplicarButton.Text = "🎨  SEM REMOTE DE COR NESSE JOGO"
        return false
    end
    local listaArgs = _argumentosCor(corEscolhida)
    for _, remote in ipairs(corRemotes) do
        if remote.Parent then
            for _, args in ipairs(listaArgs) do
                _dispararRemote(remote, args)
            end
        end
    end
    CorAplicarButton.Text = "🎨  APLICADO EM " .. #corRemotes .. " REMOTE(S)"
    return true
end

local function definirCorEscolhida(cor)
    corEscolhida = cor
    CorPreview.BackgroundColor3 = cor
    CorPreview.Text = "COR ESCOLHIDA: #" .. cor:ToHex():upper()
    if corGlobalAtivado then aplicarCorGlobal() end
end

local function alternarCorGlobal()
    corGlobalAtivado = not corGlobalAtivado
    if corGlobalAtivado then
        CorGlobalButton.Text = "COR GLOBAL: ON"
        corRemotes = _procurarRemotesCor()   -- varre de novo (o jogo pode ter carregado mais coisa)
        task.spawn(function()
            while corGlobalAtivado do
                aplicarCorGlobal()
                task.wait(COR_REPETIR_RATE)
            end
        end)
    else
        CorGlobalButton.Text = "COR GLOBAL: OFF"
    end
end

for _, sw in ipairs(CorSwatches) do
    sw.botao.MouseButton1Click:Connect(function() definirCorEscolhida(sw.cor) end)
end
CorHexInput.FocusLost:Connect(function()
    local txt = CorHexInput.Text:gsub("#", ""):gsub("%s", "")
    if #txt == 6 and txt:match("^%x+$") then
        definirCorEscolhida(Color3.fromHex(txt))
    elseif txt ~= "" then
        CorHexInput.Text = ""
        CorHexInput.PlaceholderText = "HEX invalido — use 6 digitos, ex: FF00FF"
    end
end)
definirCorEscolhida(corEscolhida)
GS.aplicarCorGlobal  = aplicarCorGlobal
GS.alternarCorGlobal = alternarCorGlobal
GS.pararCorGlobal    = function() corGlobalAtivado = false end
end  -- fim COR GLOBAL

do
-- ═══════════════════════════════════════════════════════════════
--   CARREGAR NO BRACO — PEDIDO + ACEITAR (OS DOIS RODAM O SCRIPT)
-- ═══════════════════════════════════════════════════════════════
-- Como funciona:
--   1. Escolhe ela na lista (ou deixa vazio = mais perto) e SEGURA a
--      tecla G (ou o botao do menu) por 0.6s
--   2. O pedido vai por DOIS canais ao mesmo tempo:
--      a) CHAT do jogo ("gs pedir NomeDela") — pode falhar se o chat
--         de algum dos dois for bloqueado/restrito por idade
--      b) SINAL DE ANIMACAO — o script toca uma animacao padrao do
--         proprio boneco (wave/cheer/point) com peso quase zero
--         (invisivel). Animacao do proprio boneco replica pra todo
--         mundo, entao o script DELA enxerga o sinal mesmo sem chat.
--   3. No script DELA aparece: ACEITAR / RECUSAR
--   4. Ela aceita → o script DELA prende o boneco dela no seu braco
--      todo frame. Client dela move o proprio boneco = todo mundo ve.
--   5. Aperta G de novo (qualquer um dos dois) → solta
-- ═══════════════════════════════════════════════════════════════
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CFG = {
    TECLA    = Enum.KeyCode.G,
    SEGURAR  = 0.6,   -- segundos segurando pra mandar o pedido
    ALCANCE  = 40,    -- studs: distancia max pro pedido por sinal / nome filtrado
    TIMEOUT  = 15,    -- segundos pro pedido expirar
    PREFIXO  = "gs",
    -- posicao dela em relacao ao seu HumanoidRootPart: na frente, altura
    -- do braco, de lado (estilo "carregar no colo")
    OFFSET   = CFrame.new(0, 0.4, -1.6) * CFrame.Angles(0, math.rad(90), 0),
    -- modo COSTAS: voce fica atras dela, olhando pra frente. Ajustavel no
    -- menu (+/-) enquanto ta nas costas. ATRAS maior = mais longe dela
    -- (cabeca para de entrar na dela); ALTURA maior = mais alto.
    COSTAS_ATRAS  = 1.6,
    COSTAS_ALTURA = 0.9,
    -- ANTI-DELAY: o boneco dela chega no seu PC atrasado (ping + buffer do
    -- Roblox). O script PREVE onde ela vai estar usando a velocidade dela
    -- e gruda ali, entao voce nao fica "arrastando" atras dela.
    -- -1 = AUTO (calcula pelo seu ping); senao, milissegundos fixos.
    COSTAS_LEAD_MS = -1,
    -- animacoes padrao do script "Animate" usadas como sinal invisivel
    SINAL_PEDIR      = "wave",
    SINAL_CARREGADO  = "cheer",
    SINAL_CARREGANDO = "point",
}

-- Estado (tudo numa tabela pra nao estourar o limite de locals do Luau)
local C = {
    carregando   = nil,   -- (quem carrega) Player no meu braco
    carregadoPor = nil,   -- (ela) Player que me carrega
    pendente     = nil,   -- (quem carrega) { alvo = Player, t = tick() }
    recebido     = nil,   -- (ela) Player que pediu
    recusados    = {},    -- [Player] = true enquanto ele ainda estiver pedindo
    inicio       = 0,     -- tick() do inicio do carregar (tolerancia do sinal)
    semSinalDesde = nil,
    costas       = false, -- true = eu subi nas costas dela (ela nao precisa do script)
    conn         = nil,   -- Heartbeat que prende ela no braco
    colConn      = nil,   -- Stepped que tira colisao
    conns        = {},
    tracks       = {},    -- [nomeSinal] = AnimationTrack
    segurandoDesde = nil,
}
GS.carregarEstado = C   -- o SE SOLTAR le isso (nao soltar quando amigo te carrega)

local function setStatus(txt)
    pcall(function() CarregarStatus.Text = "STATUS: " .. txt end)
end

-- ── Canal 1: CHAT ──
local function enviarChat(msg)
    local ok, err = pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local canais = TextChatService:FindFirstChild("TextChannels")
            local geral  = canais and canais:FindFirstChild("RBXGeneral")
            if not geral then error("sem canal RBXGeneral") end
            geral:SendAsync(msg)
        else
            local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if not (ev and ev:FindFirstChild("SayMessageRequest")) then error("sem chat legado") end
            ev.SayMessageRequest:FireServer(msg, "All")
        end
    end)
    print("[GRINGO CARREGAR] chat '" .. msg .. "' -> " .. (ok and "enviado" or ("FALHOU: " .. tostring(err))))
end

-- ── Canal 2: SINAL DE ANIMACAO ──
local function _animacaoDoSinal(char, nome)
    local animate = char and char:FindFirstChild("Animate")
    local pasta   = animate and animate:FindFirstChild(nome)
    return pasta and pasta:FindFirstChildOfClass("Animation")
end

local function ligarSinal(nome)
    if C.tracks[nome] and C.tracks[nome].IsPlaying then return end
    pcall(function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local animator = hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
        local anim = _animacaoDoSinal(char, nome)
        if not (animator and anim) then
            print("[GRINGO CARREGAR] sinal '" .. nome .. "' indisponivel (jogo sem Animate padrao)")
            return
        end
        local track = animator:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Core
        track.Looped = true
        track:Play(0, 0.01, 1)   -- peso 0.01 = invisivel, mas replica
        C.tracks[nome] = track
    end)
end

local function desligarSinal(nome)
    local t = C.tracks[nome]
    if t then pcall(function() t:Stop(0) end) end
    C.tracks[nome] = nil
end

local function temSinal(player, nome)
    local ok, res = pcall(function()
        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        local anim = _animacaoDoSinal(char, nome)
        if not (animator and anim) then return false end
        for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
            if tr.Animation and tr.Animation.AnimationId == anim.AnimationId then return true end
        end
        return false
    end)
    return ok and res
end

-- ── Utilitarios ──
local function _distancia(a, b)
    local ra = a and a.Character and a.Character:FindFirstChild("HumanoidRootPart")
    local rb = b and b.Character and b.Character:FindFirstChild("HumanoidRootPart")
    if not ra or not rb then return math.huge end
    return (ra.Position - rb.Position).Magnitude
end

local function _maisPerto()
    local melhor, melhorD = nil, CFG.ALCANCE
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local d = _distancia(LocalPlayer, p)
            if d < melhorD then melhor, melhorD = p, d end
        end
    end
    return melhor
end

-- O chat pode censurar nomes com numero (vira ####): aceita se estiver perto
local function _ehPraMim(nome, remetente)
    if not nome or nome == "" then return false end
    if nome:find("#") then return _distancia(LocalPlayer, remetente) <= CFG.ALCANCE end
    return nome:lower() == LocalPlayer.Name:lower()
end

-- Guarda o CanCollide original de cada parte pra devolver depois
-- (antes nao devolvia → ao descer, voce atravessava o chao e caia no void)
C.colOriginal = setmetatable({}, {__mode = "k"})
local function _semColisao(personagem)
    if not personagem then return end
    for _, part in ipairs(personagem:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            if C.colOriginal[part] == nil then C.colOriginal[part] = true end
            part.CanCollide = false
        end
    end
end

local function _pararColisao()
    if C.colConn then C.colConn:Disconnect() C.colConn = nil end
    for part in pairs(C.colOriginal) do
        if part and part.Parent then pcall(function() part.CanCollide = true end) end
    end
    C.colOriginal = setmetatable({}, {__mode = "k"})
end

-- ── Lado DELA: prende o proprio boneco no braco de quem carrega ──
local function _pararDeSerCarregado()
    if C.conn then C.conn:Disconnect() C.conn = nil end
    _pararColisao()
    desligarSinal(CFG.SINAL_CARREGADO)
    C.carregadoPor = nil
    C.costas = false
    pcall(function() CostasButton.Text = "🎒  SUBIR NAS COSTAS DELA (SÓ VOCÊ PRECISA DO SCRIPT)" end)
    local hum = getHum()
    if hum then
        bypassHealthBlock = true
        pcall(function()
            hum.Sit = false
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
        bypassHealthBlock = false
    end
    setStatus("LIVRE")
end

local function _comecarSerCarregado(carregador, costas)
    if C.carregadoPor == carregador then return end
    _pararDeSerCarregado()
    C.carregadoPor = carregador
    C.costas = costas and true or false
    C.inicio = tick(); C.semSinalDesde = nil
    if C.costas then
        setStatus("NAS COSTAS DE " .. carregador.Name:upper() .. " (G DESCE)")
        pcall(function() CostasButton.Text = "🎒  DESCER DAS COSTAS" end)
    else
        ligarSinal(CFG.SINAL_CARREGADO)
        setStatus("NO BRAÇO DE " .. carregador.Name:upper() .. " (G SOLTA)")
    end
    C.colConn = RunService.Stepped:Connect(function()
        _semColisao(LocalPlayer.Character)
    end)
    -- PreSimulation roda ANTES da fisica (1 frame a menos de atraso que o
    -- Heartbeat). Executor/cliente antigo sem ele → Stepped (mesmo momento).
    local sinalFrame = RunService.Stepped
    pcall(function() sinalFrame = RunService.PreSimulation end)
    C.conn = sinalFrame:Connect(function()
        local meuChar = LocalPlayer.Character
        local meuRoot = meuChar and meuChar:FindFirstChild("HumanoidRootPart")
        local hum     = meuChar and meuChar:FindFirstChildOfClass("Humanoid")
        local dele    = carregador.Character and carregador.Character:FindFirstChild("HumanoidRootPart")
        if not carregador.Parent or not dele then _pararDeSerCarregado() return end
        if not meuRoot or not hum then return end
        bypassHealthBlock = true
        pcall(function() hum.Sit = true end)
        bypassHealthBlock = false
        local offset = C.costas and CFrame.new(0, CFG.COSTAS_ALTURA, CFG.COSTAS_ATRAS) or CFG.OFFSET
        local vel    = dele.AssemblyLinearVelocity
        local base   = dele.CFrame
        if C.costas then
            -- previsao: posicao + velocidade * atraso; giro idem
            local lead = CFG.COSTAS_LEAD_MS / 1000
            if CFG.COSTAS_LEAD_MS < 0 then
                local ping = 0.1
                pcall(function() ping = LocalPlayer:GetNetworkPing() end)
                lead = math.clamp(ping * 2 + 0.05, 0, 0.45)
            end
            -- ignora tremidinhas (parada) e pulos pra nao subir/descer doido
            local velPlana = Vector3.new(vel.X, math.clamp(vel.Y, -20, 20), vel.Z)
            if velPlana.Magnitude < 0.5 then velPlana = Vector3.zero end
            local giro = dele.AssemblyAngularVelocity.Y * lead
            base = (base + velPlana * lead) * CFrame.Angles(0, math.clamp(giro, -1, 1), 0)
        end
        meuRoot.CFrame = base * offset
        meuRoot.AssemblyLinearVelocity  = vel
        meuRoot.AssemblyAngularVelocity = Vector3.zero
    end)
end

-- ── Lado de QUEM CARREGA ──
local function _pararDeCarregar()
    _pararColisao()
    desligarSinal(CFG.SINAL_CARREGANDO)
    desligarSinal(CFG.SINAL_PEDIR)
    C.carregando = nil
    C.pendente = nil
    setStatus("LIVRE")
end

local function _comecarCarregar(alvo)
    if C.carregando == alvo then return end
    C.carregando = alvo
    C.pendente = nil
    C.inicio = tick(); C.semSinalDesde = nil
    desligarSinal(CFG.SINAL_PEDIR)
    ligarSinal(CFG.SINAL_CARREGANDO)
    setStatus("CARREGANDO " .. alvo.Name:upper() .. " (G SOLTA)")
    -- no SEU client o boneco dela nao pode te empurrar
    C.colConn = RunService.Stepped:Connect(function()
        if C.carregando and C.carregando.Character then
            _semColisao(C.carregando.Character)
        end
    end)
end

local function soltarCarregar()
    if C.carregando then
        enviarChat(CFG.PREFIXO .. " soltar " .. C.carregando.Name)
        _pararDeCarregar()
    elseif C.carregadoPor then
        if not C.costas then enviarChat(CFG.PREFIXO .. " soltar " .. C.carregadoPor.Name) end
        _pararDeSerCarregado()
    end
end

local function pedirCarregar()
    if C.carregando or C.carregadoPor then return end
    local alvo = localizarJogadorPorNome(CarregarNomeInput.Text) or _maisPerto()
    if not alvo then setStatus("NINGUEM PERTO / NOME NAO ACHADO") return end
    C.pendente = { alvo = alvo, t = tick() }
    ligarSinal(CFG.SINAL_PEDIR)
    enviarChat(CFG.PREFIXO .. " pedir " .. alvo.Name)
    setStatus("PEDIDO ENVIADO PRA " .. alvo.Name:upper() .. "...")
    task.delay(CFG.TIMEOUT, function()
        if C.pendente and C.pendente.alvo == alvo and not C.carregando then
            C.pendente = nil
            desligarSinal(CFG.SINAL_PEDIR)
            setStatus("PEDIDO EXPIROU (ELA RODOU O SCRIPT?)")
        end
    end)
end

-- ── Janelinha de ACEITAR / RECUSAR (aparece na tela dela) ──
local P = {}
do
    P.frame = Instance.new("Frame")
    P.frame.Name = "PopupCarregar"
    P.frame.Size = UDim2.new(0, 320, 0, 120); P.frame.Position = UDim2.new(0.5, -160, 0, 80)
    P.frame.BackgroundColor3 = Color3.fromRGB(16, 16, 19); P.frame.BorderSizePixel = 0
    P.frame.Visible = false; P.frame.ZIndex = 50; P.frame.Parent = ScreenGui
    Instance.new("UICorner", P.frame).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", P.frame); st.Thickness = 2; st.Color = Color3.fromRGB(200, 200, 210)
    P.texto = Instance.new("TextLabel", P.frame)
    P.texto.Size = UDim2.new(1, -20, 0, 56); P.texto.Position = UDim2.new(0, 10, 0, 6)
    P.texto.BackgroundTransparency = 1; P.texto.Font = Enum.Font.GothamBold; P.texto.TextWrapped = true
    P.texto.TextColor3 = Color3.fromRGB(255, 255, 255); P.texto.TextSize = 15; P.texto.ZIndex = 51
    local function botao(txt, cor, x)
        local b = Instance.new("TextButton", P.frame)
        b.Size = UDim2.new(0.5, -15, 0, 40); b.Position = UDim2.new(x, x == 0 and 10 or 5, 1, -50)
        b.BackgroundColor3 = cor; b.Font = Enum.Font.GothamBold; b.Text = txt
        b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 14; b.BorderSizePixel = 0; b.ZIndex = 51
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end
    P.aceitar = botao("✔ ACEITAR", Color3.fromRGB(0, 160, 70), 0)
    P.recusar = botao("✖ RECUSAR", Color3.fromRGB(160, 30, 30), 0.5)
end

local function _mostrarPedido(remetente)
    if C.recebido == remetente or C.carregadoPor then return end
    C.recebido = remetente
    P.texto.Text = "💞 " .. remetente.DisplayName .. " quer te carregar no braço!"
    P.frame.Visible = true
    task.delay(CFG.TIMEOUT, function()
        if C.recebido == remetente then
            C.recebido = nil
            P.frame.Visible = false
        end
    end)
end

P.aceitar.MouseButton1Click:Connect(function()
    local quem = C.recebido
    C.recebido = nil
    P.frame.Visible = false
    if not quem or not quem.Parent then return end
    if C.carregando then _pararDeCarregar() end
    enviarChat(CFG.PREFIXO .. " aceito " .. quem.Name)
    _comecarSerCarregado(quem)
end)
P.recusar.MouseButton1Click:Connect(function()
    local quem = C.recebido
    C.recebido = nil
    P.frame.Visible = false
    if quem then
        C.recusados[quem] = true
        enviarChat(CFG.PREFIXO .. " recuso " .. quem.Name)
    end
end)

-- ── Recebe pelo CHAT: "gs <comando> <nome>" ──
local function processarMensagemCarregar(remetente, texto)
    if not remetente or remetente == LocalPlayer or type(texto) ~= "string" then return end
    local prefixo, cmd, nome = texto:match("^%s*(%S+)%s+(%S+)%s*(%S*)")
    if not prefixo or prefixo:lower() ~= CFG.PREFIXO then return end
    cmd = cmd:lower()
    if not _ehPraMim(nome, remetente) then return end
    print("[GRINGO CARREGAR] chat recebido de " .. remetente.Name .. ": " .. cmd)

    if cmd == "pedir" then
        C.recusados[remetente] = nil
        _mostrarPedido(remetente)
    elseif cmd == "aceito" then
        if C.pendente and C.pendente.alvo == remetente then _comecarCarregar(remetente) end
    elseif cmd == "recuso" then
        if C.pendente and C.pendente.alvo == remetente then
            C.pendente = nil
            desligarSinal(CFG.SINAL_PEDIR)
            setStatus(remetente.Name:upper() .. " RECUSOU")
        end
    elseif cmd == "soltar" then
        if C.carregadoPor == remetente then _pararDeSerCarregado() end
        if C.carregando == remetente then _pararDeCarregar() end
    end
end

pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        table.insert(C.conns, TextChatService.MessageReceived:Connect(function(msg)
            local src = msg.TextSource
            if src then processarMensagemCarregar(Players:GetPlayerByUserId(src.UserId), msg.Text) end
        end))
    else
        local function ouvir(p)
            table.insert(C.conns, p.Chatted:Connect(function(m) processarMensagemCarregar(p, m) end))
        end
        for _, p in ipairs(Players:GetPlayers()) do ouvir(p) end
        table.insert(C.conns, Players.PlayerAdded:Connect(ouvir))
    end
end)

-- ── Recebe pelo SINAL DE ANIMACAO (checa 4x por segundo) ──
local TOLERANCIA_SINAL = 2   -- s sem o sinal do outro antes de soltar
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        pcall(function()
            if C.carregadoPor then
                -- ela: se ele parou de "carregar", solta (modo costas nao usa sinal)
                if not C.costas and tick() - C.inicio > 3 and not temSinal(C.carregadoPor, CFG.SINAL_CARREGANDO) then
                    C.semSinalDesde = C.semSinalDesde or tick()
                    if tick() - C.semSinalDesde > TOLERANCIA_SINAL then _pararDeSerCarregado() end
                else
                    C.semSinalDesde = nil
                end
            elseif C.carregando then
                -- ele: se ela parou de "ser carregada", solta
                if tick() - C.inicio > 3 and not temSinal(C.carregando, CFG.SINAL_CARREGADO) then
                    C.semSinalDesde = C.semSinalDesde or tick()
                    if tick() - C.semSinalDesde > TOLERANCIA_SINAL then _pararDeCarregar() end
                else
                    C.semSinalDesde = nil
                end
            else
                -- ele: ela aceitou?
                if C.pendente and temSinal(C.pendente.alvo, CFG.SINAL_CARREGADO) then
                    _comecarCarregar(C.pendente.alvo)
                end
                -- ela: alguem perto pedindo?
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then
                        local pedindo = _distancia(LocalPlayer, p) <= CFG.ALCANCE and temSinal(p, CFG.SINAL_PEDIR)
                        if pedindo and not C.recusados[p] then
                            _mostrarPedido(p)
                        elseif not pedindo then
                            C.recusados[p] = nil
                        end
                    end
                end
            end
        end)
        task.wait(0.25)
    end
end)

-- ── Segurar tecla G / botao do menu ──
local function _comecarSegurar()
    if C.carregando or C.carregadoPor then soltarCarregar() return end
    local agora = tick()
    C.segurandoDesde = agora
    setStatus("SEGURANDO...")
    task.delay(CFG.SEGURAR, function()
        if C.segurandoDesde == agora then
            C.segurandoDesde = nil
            pedirCarregar()
        end
    end)
end
local function _soltarSegurar()
    if C.segurandoDesde then
        C.segurandoDesde = nil
        if not C.pendente then setStatus("LIVRE") end
    end
end

table.insert(C.conns, UserInputService.InputBegan:Connect(function(input, gp)
    if gp or escutandoTecla then return end
    if input.KeyCode == CFG.TECLA then _comecarSegurar() end
end))
table.insert(C.conns, UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == CFG.TECLA then _soltarSegurar() end
end))
CarregarSegurarButton.MouseButton1Down:Connect(_comecarSegurar)
local function _ajustarCostas(campo, delta, lbl)
    CFG[campo] = math.clamp(math.floor((CFG[campo] + delta) * 10 + 0.5) / 10, -2, 5)
    lbl.Text = string.format("%.1f", CFG[campo])
end
CostasCtrl.atrasMenos.MouseButton1Click:Connect(function()  _ajustarCostas("COSTAS_ATRAS", -0.1, CostasCtrl.atrasLbl) end)
CostasCtrl.atrasMais.MouseButton1Click:Connect(function()   _ajustarCostas("COSTAS_ATRAS",  0.1, CostasCtrl.atrasLbl) end)
CostasCtrl.alturaMenos.MouseButton1Click:Connect(function() _ajustarCostas("COSTAS_ALTURA", -0.1, CostasCtrl.alturaLbl) end)
CostasCtrl.alturaMais.MouseButton1Click:Connect(function()  _ajustarCostas("COSTAS_ALTURA",  0.1, CostasCtrl.alturaLbl) end)
local function _ajustarDelay(delta)
    -- AUTO (-1) → 0 → 20 → 40 ... 400; abaixo de 0 volta pro AUTO
    local v = CFG.COSTAS_LEAD_MS
    if v < 0 then v = delta > 0 and 0 or -1 else v = v + delta end
    if v < 0 then v = -1 end
    CFG.COSTAS_LEAD_MS = math.min(v, 400)
    CostasCtrl.delayLbl.Text = CFG.COSTAS_LEAD_MS < 0 and "AUTO" or tostring(CFG.COSTAS_LEAD_MS)
end
CostasCtrl.delayMenos.MouseButton1Click:Connect(function() _ajustarDelay(-20) end)
CostasCtrl.delayMais.MouseButton1Click:Connect(function()  _ajustarDelay(20)  end)
CostasButton.MouseButton1Click:Connect(function()
    if C.carregadoPor and C.costas then _pararDeSerCarregado() return end
    if C.carregando or C.carregadoPor then soltarCarregar() end
    local alvo = localizarJogadorPorNome(CarregarNomeInput.Text) or _maisPerto()
    if not alvo then setStatus("ESCOLHE ELA NA LISTA") return end
    if not (alvo.Character and alvo.Character:FindFirstChild("HumanoidRootPart")) then
        setStatus(alvo.Name:upper() .. " SEM PERSONAGEM") return
    end
    _comecarSerCarregado(alvo, true)
end)
CarregarSegurarButton.MouseButton1Up:Connect(_soltarSegurar)
CarregarSegurarButton.MouseLeave:Connect(_soltarSegurar)

GS.limparCarregar = function()
    soltarCarregar()
    for nome in pairs(C.tracks) do desligarSinal(nome) end
    for _, c in ipairs(C.conns) do pcall(function() c:Disconnect() end) end
    C.conns = {}
end
end  -- fim CARREGAR NO BRACO

do
-- ═══════════════════════════════════════════════════════════════
--   LISTA DE PLAYERS DO CARREGAR — CLICA PRA ESCOLHER ELA
-- ═══════════════════════════════════════════════════════════════
local linhas = {}  -- [Player] = TextButton
local function atualizar()
    local selecionado = string.lower(CarregarNomeInput.Text or "")
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not linhas[player] then
            local b = Instance.new("TextButton", CarregarListaFrame)
            b.Size = UDim2.new(1, 0, 0, 34); b.BorderSizePixel = 0; b.Text = ""
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
            local foto = Instance.new("ImageLabel", b)
            foto.Size = UDim2.new(0, 26, 0, 26); foto.Position = UDim2.new(0, 4, 0.5, -13)
            foto.BackgroundColor3 = Color3.fromRGB(36, 36, 42); foto.BorderSizePixel = 0
            foto.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
            Instance.new("UICorner", foto).CornerRadius = UDim.new(1, 0)
            local nome = Instance.new("TextLabel", b)
            nome.Name = "Nome"
            nome.Size = UDim2.new(1, -40, 1, 0); nome.Position = UDim2.new(0, 36, 0, 0)
            nome.BackgroundTransparency = 1; nome.Font = Enum.Font.GothamBold; nome.TextSize = 12
            nome.TextXAlignment = Enum.TextXAlignment.Left; nome.TextTruncate = Enum.TextTruncate.AtEnd
            nome.Text = player.DisplayName .. "  (@" .. player.Name .. ")"
            b.MouseButton1Click:Connect(function()
                CarregarNomeInput.Text = player.Name
                atualizar()
            end)
            linhas[player] = b
        end
    end
    for player, b in pairs(linhas) do
        if not player.Parent then
            b:Destroy(); linhas[player] = nil
        else
            local ativo = selecionado ~= "" and string.lower(player.Name) == selecionado
            b.BackgroundColor3 = ativo and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(26, 26, 31)
            b.Nome.TextColor3  = ativo and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(236, 236, 240)
        end
    end
end
Players.PlayerAdded:Connect(function() task.wait(0.5) pcall(atualizar) end)
Players.PlayerRemoving:Connect(function() task.wait() pcall(atualizar) end)
CarregarNomeInput:GetPropertyChangedSignal("Text"):Connect(function() pcall(atualizar) end)
pcall(atualizar)
end  -- fim LISTA DO CARREGAR

do
-- ═══════════════════════════════════════════════════════════════
--   REGENERAR / RENASCER + ANTI-VOID (CODIGO BRUTO)
-- ═══════════════════════════════════════════════════════════════
-- REGENERAR (tecla K): mata o proprio boneco pra renascer no spawn,
--   tentando TODOS os jeitos em sequencia ate um funcionar:
--   0. desliga INVENCIVEL (os hooks dele bloqueiam a morte) e solta
--      costas/braco; reativa o estado Dead
--   1. Health = 0      2. ChangeState(Dead)     3. BreakJoints()
--   4. arranca o pescoco/cabeca                  5. replicatesignal(Kill)
--   Se ainda assim nao morrer (jogo bloqueia), joga voce pro ultimo chao.
-- VOLTAR PRO ULTIMO CHAO (tecla L): a cada 0.5s o script grava a
--   ultima posicao em que voce estava pisando em chao de verdade.
-- ANTI-VOID: se voce cair abaixo do chao salvo (ou perto da altura
--   onde o Roblox destroi as pecas), volta sozinho pro ultimo chao.
-- ═══════════════════════════════════════════════════════════════
local R = {
    ultimoChao = nil,      -- CFrame da ultima posicao segura
    antiVoid   = false,
    morrendo   = false,
    QUEDA_MAX  = 80,       -- studs abaixo do ultimo chao = caiu no void
}

local function _rootEHum()
    local c = LocalPlayer.Character
    return c, c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end

local function voltarProChao()
    local _, root, hum = _rootEHum()
    if not root then return false end
    local destino = R.ultimoChao
    if not destino then
        -- nunca gravou chao: tenta o SpawnLocation
        local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
        if sp then destino = sp.CFrame + Vector3.new(0, 5, 0) end
    end
    if not destino then return false end
    -- garante colisao de volta (senao atravessa o chao de novo)
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name == "HumanoidRootPart" or part.Name == "Torso"
            or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Head") then
            pcall(function() part.CanCollide = true end)
        end
    end
    root.CFrame = destino + Vector3.new(0, 3, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    return true
end

local function regenerar()
    if R.morrendo then return end
    R.morrendo = true
    RegenUI.regenerar.Text = "♻  REGENERANDO..."

    -- 0. tira tudo que segura o boneco vivo/preso
    pcall(function() if ghostAtivado then alternarGhost() end end)
    pcall(function() if GS.limparCarregar then GS.limparCarregar() end end)
    pcall(function() if flyAtivado then alternarFly() end end)
    bypassHealthBlock = true

    local char, root, hum = _rootEHum()
    local personagemAntigo = char
    local metodos = {
        function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) hum.Health = 0 end,
        function() hum:ChangeState(Enum.HumanoidStateType.Dead) end,
        function() char:BreakJoints() end,
        function()
            for _, j in ipairs(char:GetDescendants()) do
                if j:IsA("Motor6D") and (j.Name == "Neck" or j.Name == "Root" or j.Name == "RootJoint") then j:Destroy() end
            end
            local head = char:FindFirstChild("Head")
            if head then head:Destroy() end
        end,
        function() if replicatesignal then replicatesignal(LocalPlayer.Kill) end end,
    }
    task.spawn(function()
        for i, metodo in ipairs(metodos) do
            if not (char and char.Parent and hum) then break end
            pcall(metodo)
            print("[GRINGO REGEN] metodo " .. i .. " executado")
            task.wait(0.4)
            if hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then break end
        end
        bypassHealthBlock = false
        -- espera ate 10s pelo personagem novo (RespawnTime do jogo)
        local t0 = tick()
        while tick() - t0 < 10 and LocalPlayer.Character == personagemAntigo do task.wait(0.2) end
        R.morrendo = false
        if LocalPlayer.Character ~= personagemAntigo then
            RegenUI.regenerar.Text = "♻  REGENERADO!"
        else
            -- jogo bloqueou a morte: pelo menos tira voce do void
            local ok = voltarProChao()
            RegenUI.regenerar.Text = ok and "♻  JOGO BLOQUEOU — VOLTEI PRO CHÃO" or "♻  FALHOU (VEJA F9)"
        end
        task.delay(2, function() pcall(function() RegenUI.regenerar.Text = "♻  REGENERAR / RENASCER (TECLA K)" end) end)
    end)
end

-- Grava o ultimo chao seguro + anti-void
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        pcall(function()
            local _, root, hum = _rootEHum()
            if not (root and hum) or hum.Health <= 0 then return end
            local pisando = hum.FloorMaterial ~= Enum.Material.Air
            if pisando and not hum.Sit and root.AssemblyLinearVelocity.Y > -5 then
                R.ultimoChao = root.CFrame
            end
            if R.antiVoid and R.ultimoChao then
                local limiteRoblox = workspace.FallenPartsDestroyHeight + 40
                local caiuDemais   = root.Position.Y < R.ultimoChao.Position.Y - R.QUEDA_MAX
                if root.Position.Y < limiteRoblox or caiuDemais then
                    voltarProChao()
                end
            end
        end)
        task.wait(R.antiVoid and 0.1 or 0.5)
    end
end)

RegenUI.regenerar.MouseButton1Click:Connect(regenerar)
RegenUI.voltar.MouseButton1Click:Connect(function()
    RegenUI.voltar.Text = voltarProChao() and "⬆ VOLTEI!" or "⬆ SEM CHÃO SALVO"
    task.delay(1.2, function() pcall(function() RegenUI.voltar.Text = "⬆ VOLTAR PRO ÚLTIMO CHÃO (TECLA L)" end) end)
end)
RegenUI.antiVoid.MouseButton1Click:Connect(function()
    R.antiVoid = not R.antiVoid
    RegenUI.antiVoid.Text = R.antiVoid and "ANTI-VOID: ON" or "ANTI-VOID: OFF"
end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or escutandoTecla then return end
    if input.KeyCode == Enum.KeyCode.K then regenerar()
    elseif input.KeyCode == Enum.KeyCode.L then voltarProChao() end
end)
end  -- fim REGENERAR

-- ═══════════════════════════════════
--   EVENTOS DE CLIQUE
-- ═══════════════════════════════════
SpeedUpButton.MouseButton1Click:Connect(function()
    velocidadeCustomizada = math.min(800, velocidadeCustomizada + (velocidadeCustomizada < 100 and 10 or 50))
    SpeedLabel.Text = "VEL: " .. tostring(velocidadeCustomizada)
end)
SpeedDownButton.MouseButton1Click:Connect(function()
    velocidadeCustomizada = math.max(16, velocidadeCustomizada - (velocidadeCustomizada <= 100 and 10 or 50))
    SpeedLabel.Text = "VEL: " .. tostring(velocidadeCustomizada)
end)
FlyUpButton.MouseButton1Click:Connect(function()
    velocidadeVoo = math.min(300, velocidadeVoo + 25)
    FlyLabel.Text = "VOO: " .. tostring(velocidadeVoo)
end)
FlyDownButton.MouseButton1Click:Connect(function()
    velocidadeVoo = math.max(10, velocidadeVoo - 25)
    FlyLabel.Text = "VOO: " .. tostring(velocidadeVoo)
end)

UnloadButton.MouseButton1Click:Connect(function()
    pcall(function() aplicarTamanho(1) end)
    if noclipConnection  then noclipConnection:Disconnect() end
    if GS.noclipConn2    then GS.noclipConn2:Disconnect() end
    for part in pairs(GS.noclipOrig or {}) do pcall(function() if part.Parent then part.CanCollide = true end end) end
    if speedConnection   then speedConnection:Disconnect() end
    if speedBodyVelocity then speedBodyVelocity:Destroy() speedBodyVelocity = nil end
    if flyConnection     then flyConnection:Disconnect() end
    if ghostConnection   then ghostConnection:Disconnect() end
    if ghostHealthConn   then ghostHealthConn:Disconnect() end
    if antiTravaConnection then antiTravaConnection:Disconnect() end
    if antiTravaGyro     then antiTravaGyro:Destroy() antiTravaGyro = nil end
    if puxarConnection   then puxarConnection:Disconnect() end
    _limparPuxar()
    _limparPuxarUm()
    if derrubaXConn      then derrubaXConn:Disconnect() derrubaXConn = nil end
    if bikeAntiQuedaConn    then bikeAntiQuedaConn:Disconnect()    bikeAntiQuedaConn    = nil end
    if bikeAntiQuedaKeyConn then bikeAntiQuedaKeyConn:Disconnect() bikeAntiQuedaKeyConn = nil end
    if bikeGyroAntiQueda and bikeGyroAntiQueda.Parent then pcall(function() bikeGyroAntiQueda:Destroy() end) end
    GS.pararCorGlobal()
    GS.limparCarregar()
    _limparParedePreview()
    for _, p in ipairs(paredesCriadas) do
        if p and p.Parent then pcall(function() p:Destroy() end) end
    end
    paredesCriadas = {}
    GS.limparESP()
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro     then bodyGyro:Destroy() end
    local character = LocalPlayer.Character
    local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.PlatformStand = false
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        for _, estado in ipairs(ESTADOS_QUEDA) do
            humanoid:SetStateEnabled(estado, true)
        end
    end
    Lighting.Ambient = originalAmbient
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.Brightness = originalBrightness
    Lighting.FogEnd = originalFog
    if localLight then localLight:Destroy() end
    ScreenGui:Destroy()
end)

NoclipButton.MouseButton1Click:Connect(alternarNoclip)
BrightnessButton.MouseButton1Click:Connect(alternarBrilho)
SpeedButton.MouseButton1Click:Connect(alternarSpeed)
FlyButton.MouseButton1Click:Connect(alternarFly)
TPButton.MouseButton1Click:Connect(executarTeleporte)
TPNameInput:GetPropertyChangedSignal("Text"):Connect(atualizarListaTP)
GhostButton.MouseButton1Click:Connect(alternarGhost)
EspButton.MouseButton1Click:Connect(GS.alternarEsp)
AntiTravaButton.MouseButton1Click:Connect(alternarAntiTrava)
PuxarButton.MouseButton1Click:Connect(alternarPuxar)
GS.dancaBtn.MouseButton1Click:Connect(GS.alternarDanca)
PuxarUmButton.MouseButton1Click:Connect(alternarPuxarUm)
TamanhoSlider.Changed:Connect(aplicarTamanho)
DerrubaButton.MouseButton1Click:Connect(alternarDerruba)
BikeAntiQuedaButton.MouseButton1Click:Connect(alternarBikeAntiQueda)
ParedeButton.MouseButton1Click:Connect(alternarParede)
CorAplicarButton.MouseButton1Click:Connect(GS.aplicarCorGlobal)
CorGlobalButton.MouseButton1Click:Connect(GS.alternarCorGlobal)

-- ═══════════════════════════════════════════════════════════════
--   ABA COMBATE — CONECTAR + AIMBOT (4 MODOS) + ESP
-- ═══════════════════════════════════════════════════════════════
-- Tudo dentro de uma funcao propria: ela tem os proprios 200
-- registradores, entao nao pesa no limite de locals do arquivo.
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
--   COMPARTILHADO: AMIGOS, DONO DO BONECO E PONTO DA MIRA
-- ═══════════════════════════════════════════════════════════════
-- AMIGOS: aimbot e silent nunca miram em amigo seu do Roblox.
-- IsFriendsWith espera a web, entao o resultado fica em cache; enquanto
-- nao confirmou, a pessoa e tratada como amigo (na duvida, nao atira).
GS.amigos = {}   -- [UserId] = true | false | "?"
GS.ehAmigo = function(plr)
    if not plr or plr == LocalPlayer then return false end
    local v = GS.amigos[plr.UserId]
    if v == nil then
        GS.amigos[plr.UserId] = "?"
        task.spawn(function()
            local ok, sim = pcall(function() return LocalPlayer:IsFriendsWith(plr.UserId) end)
            GS.amigos[plr.UserId] = (ok and sim) and true or false
        end)
        return true
    end
    return v ~= false
end
for _, p in ipairs(Players:GetPlayers()) do GS.ehAmigo(p) end
Players.PlayerAdded:Connect(function(p) GS.ehAmigo(p) end)

-- DONO DO BONECO: personagem normal OU boneco clonado com o nome do player
-- (tem jogo que clona o personagem e GetPlayerFromCharacter devolve nil:
-- antes o jogador virava "bot" e o silent mirava nele)
GS.donoDoModelo = function(m)
    if not m then return nil end
    local plr = Players:GetPlayerFromCharacter(m)
    if plr then return plr end
    local p = Players:FindFirstChild(m.Name)
    if p and p:IsA("Player") then return p end
    for _, p2 in ipairs(Players:GetPlayers()) do
        if p2.DisplayName == m.Name then return p2 end
    end
    return nil
end

-- PONTO DA MIRA: com o FOV travado (padrao) e sempre o centro da tela,
-- entao apertar ESC / soltar a seta do mouse nao arrasta o FOV junto.
GS.fovCentro = true
GS.pontoMira = function(cam)
    cam = cam or workspace.CurrentCamera
    if GS.fovCentro or not UserInputService.MouseEnabled then return cam.ViewportSize / 2 end
    return UserInputService:GetMouseLocation()
end

GS.iniciarCombate = function()
    local U = GS.ui
    local T, tw = U.T, U.tw
    local painel = GS.painelCombate
    local MarketplaceService = game:GetService("MarketplaceService")

    local PEITO  = {"UpperTorso","Torso","HumanoidRootPart"}
    local CABECA = {"Head","UpperTorso","Torso","HumanoidRootPart"}
    -- chanceCabeca: o LEGIT sorteia peito/cabeca de tempos em tempos pra disfarcar
    local MODOS = {
        LEVE      = { fov=90,  suave=0.07, partes=PEITO,  parede=true,  previsao=0,
                      desc="LEVE: bem discreto. FOV pequeno, puxa devagar no peito." },
        LEGIT     = { fov=150, suave=0.16, partes=PEITO,  parede=true,  previsao=0.03, chanceCabeca=0.3,
                      desc="LEGIT: disfarça. Mira no peito e de vez em quando na cabeça, puxando suave." },
        AGRESSIVO = { fov=400, suave=0.75, partes=CABECA, parede=true,  previsao=0.08,
                      desc="AGRESSIVO: puxa brutal pra cabeça do oponente, FOV grande, com previsão de movimento." },
        RAGE      = { fov=0,   suave=1,    partes=CABECA, parede=false, previsao=0.10,
                      desc="RAGE: trava na cabeça na hora, tela toda, através de parede." },
    }
    local ORDEM_MODOS = {"RAGE","AGRESSIVO","LEGIT","LEVE"}

    local C = { conectado=false, conectando=false, aimbot=false, esp=false, modo="LEGIT",
                alvoAtual=nil, conns={}, avisou=false, mirarCabeca=false, proximoSorteio=0 }
    GS.cmb = C

    local alvos = {}   -- [Humanoid] = true
    local esp   = {}   -- [Humanoid] = objetos de desenho
    local camada, circuloFov

    -- ── UI ──────────────────────────────────────────────────────
    U.sec(painel, "CONEXÃO", "🔌", 1)
    local status = U.pequeno(painel, "STATUS: DESCONECTADO", nil, 2)
    status.AutoButtonColor = false; status.TextColor3 = T.dim
    local btnConectar = U.acao(painel, "CONECTAR AO JOGO", "🔌", 3)

    local conteudo = Instance.new("Frame", painel)
    conteudo.Size = UDim2.new(1,0,0,1); conteudo.AutomaticSize = Enum.AutomaticSize.Y
    conteudo.BackgroundTransparency = 1; conteudo.LayoutOrder = 4; conteudo.Visible = false
    do
        local l = Instance.new("UIListLayout", conteudo); l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0,8); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    end

    U.sec(conteudo, "AIMBOT", "🎯", 1)
    local togAim = U.tog(conteudo, "AIMBOT", 2)

    local grade = Instance.new("Frame", conteudo)
    grade.Size = UDim2.new(1,0,0,36); grade.BackgroundTransparency = 1; grade.LayoutOrder = 3
    do
        local gl = Instance.new("UIGridLayout", grade)
        gl.CellSize = UDim2.new(0.25,-6,1,0); gl.CellPadding = UDim2.new(0,8,0,0)
        gl.SortOrder = Enum.SortOrder.LayoutOrder
    end

    local descModo = Instance.new("TextLabel", conteudo)
    descModo.Size = UDim2.new(1,0,0,16); descModo.AutomaticSize = Enum.AutomaticSize.Y
    descModo.BackgroundTransparency = 1; descModo.Font = Enum.Font.Gotham; descModo.TextSize = 11
    descModo.TextColor3 = T.mute; descModo.TextWrapped = true
    descModo.TextXAlignment = Enum.TextXAlignment.Left; descModo.LayoutOrder = 4

    local botoesModo = {}
    local function pintarModos()
        for nome, b in pairs(botoesModo) do
            local sel = nome == C.modo
            tw(b, {BackgroundColor3 = sel and T.on or T.card, TextColor3 = sel and T.knobOn or T.dim}, 0.2)
        end
        descModo.Text = MODOS[C.modo].desc
    end
    for i, nome in ipairs(ORDEM_MODOS) do
        local b = Instance.new("TextButton", grade)
        b.Text = nome; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.AutoButtonColor = false
        b.BackgroundColor3 = T.card; b.TextColor3 = T.dim; b.BorderSizePixel = 0; b.LayoutOrder = i
        U.mkC(9, b); U.mkS(1, T.stroke, b); U.press(b)
        b.MouseButton1Click:Connect(function()
            C.modo = nome; C.alvoAtual = nil
            pintarModos()
            GS.toast("🎯  Modo " .. nome, true)
        end)
        botoesModo[nome] = b
    end
    pintarModos()

    U.sec(conteudo, "ESP", "👁", 5)
    local togEsp = U.tog(conteudo, "ESP (LINHA + CAIXA + VIDA)", 6)
    togAim:SetAttribute("Controlado", true)
    togEsp:SetAttribute("Controlado", true)

    -- ── Alvos ───────────────────────────────────────────────────
    local function registrar(h)
        if h:IsA("Humanoid") then alvos[h] = true end
    end

    local function removerAlvo(h)
        alvos[h] = nil
        local e = esp[h]
        if e then
            for _, o in ipairs(e.todos) do pcall(function() o:Destroy() end) end
            esp[h] = nil
        end
    end

    local function mesmoTime(m)
        if not LocalPlayer.Team then return false end
        local p = GS.donoDoModelo(m)
        return p ~= nil and p.Team == LocalPlayer.Team
    end
    local function ehAmigoModelo(m)
        local p = GS.donoDoModelo(m)
        return p ~= nil and GS.ehAmigo(p)
    end

    local function alvoValido(h, meuChar)
        local m = h.Parent
        return m ~= nil and m:IsA("Model") and m ~= meuChar and h.Health > 0 and not mesmoTime(m)
    end

    local function parteMira(m, partes)
        for _, nome in ipairs(partes) do
            local p = m:FindFirstChild(nome)
            if p and p:IsA("BasePart") then return p end
        end
        return nil
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local function visivel(cam, parte, m, meuChar)
        rayParams.FilterDescendantsInstances = meuChar and {meuChar} or {}
        local origem = cam.CFrame.Position
        local hit = workspace:Raycast(origem, parte.Position - origem, rayParams)
        return hit == nil or hit.Instance:IsDescendantOf(m)
    end

    -- ── ESP ─────────────────────────────────────────────────────
    local function novoFrame(pai, cor, z)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0; f.BackgroundColor3 = cor; f.ZIndex = z or 1; f.Visible = false
        f.Parent = pai
        return f
    end

    local function criarESP(h)
        local e = {}
        e.sombra = novoFrame(camada, Color3.new(0,0,0), 1); e.sombra.BackgroundTransparency = 1
        local s1 = Instance.new("UIStroke", e.sombra); s1.Thickness = 3.5; s1.Color = Color3.new(0,0,0); s1.Transparency = 0.45
        e.box = novoFrame(camada, Color3.new(1,1,1), 2); e.box.BackgroundTransparency = 1
        e.boxStroke = Instance.new("UIStroke", e.box); e.boxStroke.Thickness = 1.5

        e.linha = novoFrame(camada, Color3.new(1,1,1), 2)
        e.linha.AnchorPoint = Vector2.new(0.5,0.5); e.linha.BackgroundTransparency = 0.15

        e.vidaFundo = novoFrame(camada, Color3.new(0,0,0), 2); e.vidaFundo.BackgroundTransparency = 0.35
        e.vida = novoFrame(e.vidaFundo, Color3.new(0,1,0), 3); e.vida.Visible = true
        e.vida.AnchorPoint = Vector2.new(0,1); e.vida.Position = UDim2.new(0,1,1,-1)

        e.nome = Instance.new("TextLabel")
        e.nome.BackgroundTransparency = 1; e.nome.Font = Enum.Font.GothamBold; e.nome.TextSize = 12
        e.nome.TextColor3 = Color3.new(1,1,1); e.nome.TextStrokeTransparency = 0.3
        e.nome.AnchorPoint = Vector2.new(0.5,1); e.nome.Size = UDim2.fromOffset(220,14)
        e.nome.ZIndex = 3; e.nome.Visible = false; e.nome.Parent = camada

        e.todos = {e.sombra, e.box, e.linha, e.vidaFundo, e.nome}
        esp[h] = e
        return e
    end

    local function esconder(e)
        for _, o in ipairs(e.todos) do o.Visible = false end
    end

    local COR_NORMAL = Color3.fromRGB(235,235,240)
    local COR_MIRA   = Color3.fromRGB(255,70,70)
    local COR_AMIGO  = Color3.fromRGB(70,230,120)
    local VIDA_BAIXA = Color3.fromRGB(255,60,60)
    local VIDA_ALTA  = Color3.fromRGB(60,255,110)

    -- ANTI-CRASH: NaN/infinito em camera ou em tamanho de GUI fecha o Roblox
    local function finito(n, lim) return n == n and n > -(lim or 1e7) and n < (lim or 1e7) end
    local function vetorOk(v) return finito(v.X) and finito(v.Y) and finito(v.Z) end

    local function desenharESP(cam, h, m, meuRoot)
        local cf, tam = m:GetBoundingBox()
        if not vetorOk(cf.Position) or not vetorOk(tam) or tam.Magnitude > 2000 then return false end
        local _, naTela = cam:WorldToViewportPoint(cf.Position)
        if not naTela then return false end

        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local hx, hy, hz = tam.X/2, tam.Y/2, tam.Z/2
        for _, sx in ipairs({-1,1}) do
            for _, sy in ipairs({-1,1}) do
                for _, sz in ipairs({-1,1}) do
                    local v = cam:WorldToViewportPoint((cf * CFrame.new(hx*sx, hy*sy, hz*sz)).Position)
                    if v.Z <= 0 then return false end
                    if v.X < minX then minX = v.X end
                    if v.X > maxX then maxX = v.X end
                    if v.Y < minY then minY = v.Y end
                    if v.Y > maxY then maxY = v.Y end
                end
            end
        end

        local w, alt = maxX - minX, maxY - minY
        local vp = cam.ViewportSize
        if not (finito(minX, 1e5) and finito(minY, 1e5) and finito(maxX, 1e5) and finito(maxY, 1e5))
        or w < 1 or alt < 1 or w > vp.X * 2 or alt > vp.Y * 2 then
            return false   -- caixa invalida ou gigante: nao desenha (evita crash)
        end
        local e = esp[h] or criarESP(h)
        local amigo = ehAmigoModelo(m)
        local cor = amigo and COR_AMIGO or ((C.alvoAtual == h) and COR_MIRA or COR_NORMAL)

        e.box.Position = UDim2.fromOffset(minX, minY); e.box.Size = UDim2.fromOffset(w, alt)
        e.sombra.Position = e.box.Position; e.sombra.Size = e.box.Size
        e.boxStroke.Color = cor

        -- linha: do topo-centro da tela ate o topo da caixa
        local a = Vector2.new(cam.ViewportSize.X/2, 0)
        local b = Vector2.new((minX+maxX)/2, minY)
        local d = b - a
        e.linha.Position = UDim2.fromOffset((a.X+b.X)/2, (a.Y+b.Y)/2)
        e.linha.Size = UDim2.fromOffset(d.Magnitude, 1.5)
        e.linha.Rotation = math.deg(math.atan2(d.Y, d.X))
        e.linha.BackgroundColor3 = cor

        -- vida (trata MaxHealth infinito / NaN)
        local pct = 1
        if h.MaxHealth > 0 and h.MaxHealth ~= math.huge then pct = h.Health / h.MaxHealth end
        if pct ~= pct then pct = 1 end
        pct = math.clamp(pct, 0, 1)
        e.vidaFundo.Position = UDim2.fromOffset(minX - 7, minY); e.vidaFundo.Size = UDim2.fromOffset(5, alt)
        e.vida.Size = UDim2.new(1, -2, pct, -2)
        e.vida.BackgroundColor3 = VIDA_BAIXA:Lerp(VIDA_ALTA, pct)

        local p = GS.donoDoModelo(m)
        local dist = meuRoot and math.floor((cf.Position - meuRoot.Position).Magnitude) or 0
        e.nome.Text = (p and p.DisplayName or m.Name) .. (amigo and "  · AMIGO" or "") .. "  [" .. dist .. "m]"
        e.nome.Position = UDim2.fromOffset((minX+maxX)/2, minY - 3)
        e.nome.TextColor3 = cor

        for _, o in ipairs(e.todos) do o.Visible = true end
        return true
    end

    -- ── Aimbot ──────────────────────────────────────────────────
    local function avaliar(cam, h, M, mouse, meuChar, fovMax)
        if not alvoValido(h, meuChar) or ehAmigoModelo(h.Parent) then return nil end   -- amigo: nunca
        local m = h.Parent
        local parte = parteMira(m, (M.chanceCabeca and C.mirarCabeca) and CABECA or M.partes)
        if not parte or not vetorOk(parte.Position) then return nil end
        local v, naTela = cam:WorldToViewportPoint(parte.Position)
        if not naTela then return nil end
        local dist = (Vector2.new(v.X, v.Y) - mouse).Magnitude
        if fovMax > 0 and dist > fovMax then return nil end
        if M.parede and not visivel(cam, parte, m, meuChar) then return nil end
        return parte, dist
    end

    local function mirar(cam, dt, meuChar)
        local M = MODOS[C.modo]
        local mouse = GS.pontoMira(cam)   -- FOV travado no centro (nao segue a seta)

        circuloFov.Visible = C.aimbot and M.fov > 0
        if circuloFov.Visible then
            circuloFov.Position = UDim2.fromOffset(mouse.X, mouse.Y)
            circuloFov.Size = UDim2.fromOffset(M.fov*2, M.fov*2)
        end

        if not C.aimbot then C.alvoAtual = nil return end

        if M.chanceCabeca and os.clock() >= C.proximoSorteio then
            C.mirarCabeca = math.random() < M.chanceCabeca
            C.proximoSorteio = os.clock() + 0.8 + math.random() * 1.7
        end

        -- mantem o alvo atual enquanto valido (evita ficar pulando entre bots)
        local parte
        if C.alvoAtual and alvos[C.alvoAtual] then
            parte = avaliar(cam, C.alvoAtual, M, mouse, meuChar, M.fov * 1.25)
        end
        if not parte then
            C.alvoAtual = nil
            C.proximoSorteio = 0
            local melhor = math.huge
            for h in pairs(alvos) do
                local p, dist = avaliar(cam, h, M, mouse, meuChar, M.fov)
                if p and dist < melhor then melhor = dist; parte = p; C.alvoAtual = h end
            end
        end
        if not parte then return end

        -- ANTI-CRASH: velocidade bugada (ragdoll/arremesso) nao entra na previsao,
        -- e a camera so recebe CFrame valido
        local vel = parte.AssemblyLinearVelocity
        if not vetorOk(vel) or vel.Magnitude > 500 then vel = Vector3.zero end
        local pos = parte.Position + vel * M.previsao
        local origem = cam.CFrame.Position
        if not vetorOk(pos) or (pos - origem).Magnitude < 1 then return end
        local alvoCF = CFrame.lookAt(origem, pos)
        local alpha = M.suave >= 1 and 1 or 1 - (1 - M.suave) ^ (math.clamp(dt, 0, 0.1) * 60)
        local novo = cam.CFrame:Lerp(alvoCF, alpha)
        if vetorOk(novo.Position) and vetorOk(novo.LookVector) then
            cam.CFrame = novo
        end
    end

    -- ── Loop por frame ──────────────────────────────────────────
    local function passo(dt)
        local cam = workspace.CurrentCamera
        if not cam then return end
        local meuChar = LocalPlayer.Character
        local meuRoot = meuChar and meuChar:FindFirstChild("HumanoidRootPart")

        for h in pairs(alvos) do
            if not h.Parent or not h:IsDescendantOf(workspace) then
                removerAlvo(h)
            elseif esp[h] or C.esp then
                local mostrou = C.esp and alvoValido(h, meuChar) and desenharESP(cam, h, h.Parent, meuRoot)
                if not mostrou and esp[h] then esconder(esp[h]) end
            end
        end

        mirar(cam, dt, meuChar)
    end

    local function limpar()
        pcall(function() RunService:UnbindFromRenderStep("GringoCombate") end)
        for _, c in ipairs(C.conns) do pcall(function() c:Disconnect() end) end
        C.conns = {}
        for h in pairs(esp) do removerAlvo(h) end
        alvos = {}
        if camada then pcall(function() camada:Destroy() end) camada = nil end
        C.conectado = false; C.aimbot = false; C.esp = false; C.alvoAtual = nil
    end
    GS.limparCombate = limpar
    ScreenGui.Destroying:Connect(limpar)

    -- ── Conectar ────────────────────────────────────────────────
    local function conectar(nomeJogo)
        C.conectado = true
        status.Text = "✔ CONECTADO: " .. string.upper(nomeJogo)
        status.TextColor3 = T.text
        btnConectar.Visible = false
        conteudo.Visible = true

        camada = Instance.new("Frame")
        camada.Name = "GringoESP"; camada.Size = UDim2.new(1,0,1,0)
        camada.BackgroundTransparency = 1; camada.ZIndex = 0; camada.Parent = ScreenGui

        circuloFov = Instance.new("Frame", camada)
        circuloFov.AnchorPoint = Vector2.new(0.5,0.5); circuloFov.BackgroundTransparency = 1
        circuloFov.Visible = false; U.redondo(circuloFov)
        local st = Instance.new("UIStroke", circuloFov); st.Thickness = 1; st.Color = Color3.new(1,1,1); st.Transparency = 0.4

        for _, d in ipairs(workspace:GetDescendants()) do registrar(d) end
        table.insert(C.conns, workspace.DescendantAdded:Connect(registrar))

        pcall(function() RunService:UnbindFromRenderStep("GringoCombate") end)
        RunService:BindToRenderStep("GringoCombate", Enum.RenderPriority.Camera.Value + 1, function(dt)
            local ok, err = pcall(passo, dt)
            if not ok and not C.avisou then
                C.avisou = true
                warn("[GRINGO COMBATE] " .. tostring(err))
            end
        end)

        GS.toast("🔌  Conectado: " .. nomeJogo, true)
    end

    btnConectar.MouseButton1Click:Connect(function()
        if C.conectado or C.conectando then return end
        C.conectando = true
        status.Text = "STATUS: CONECTANDO..."; status.TextColor3 = T.dim
        task.spawn(function()
            local nome = "JOGO"
            local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
            if ok and type(info) == "table" and type(info.Name) == "string" then nome = info.Name end
            task.wait(0.5)
            if not ScreenGui.Parent then return end
            C.conectando = false
            conectar(nome)
        end)
    end)

    togAim.MouseButton1Click:Connect(function()
        C.aimbot = not C.aimbot
        if not C.aimbot then C.alvoAtual = nil end
        togAim.Text = C.aimbot and "AIMBOT: ON" or "AIMBOT: OFF"
    end)
    togEsp.MouseButton1Click:Connect(function()
        C.esp = not C.esp
        togEsp.Text = C.esp and "ESP: ON" or "ESP: OFF"
    end)
end
GS.rodar("Combate", GS.iniciarCombate, GS.painelCombate)

-- ═══════════════════════════════════════════════════════════════
--   ABA RASTREAR — ESP DE OBJETOS (ARMAS, CHAVES, BAUS, ITENS...)
-- ═══════════════════════════════════════════════════════════════
-- O que ele acha (em qualquer jogo):
--   • Tool largada no mapa (arma/item que da pra pegar)
--   • ProximityPrompt / ClickDetector (tudo que da pra interagir:
--     bau, porta, botao, gerador...) — usa o texto do proprio prompt
--   • Model/Part com nome de item: chave, cartao, fusivel, bau, arma,
--     moeda, lanterna... (portugues e ingles)
-- Mostra nome + distancia atraves da parede, sem limite de distancia.
-- Limite real: em jogo com StreamingEnabled, o que esta longe demais
-- nem existe no seu PC ainda — aparece assim que o jogo carregar.
-- Varredura inicial em pedacos (nao trava o jogo) + deteccao na hora
-- de tudo que aparece depois.
-- ═══════════════════════════════════════════════════════════════
GS.iniciarRastreio = function()
    local U = GS.ui
    local painel = GS.painelRastrear
    if not U or not painel then return end
    local T = U.T

    local CATS = {
        { nome="CHAVE", ico="🔑", cor=Color3.fromRGB(255,215,0),
          palavras={"key","chave","card","cartao","cartão","cracha","crachá","badge","fuse","fusivel","fusível",
                    "battery","bateria","codigo","código","password","senha"} },
        { nome="BAÚ", ico="🧰", cor=Color3.fromRGB(255,140,40),
          palavras={"chest","bau","baú","crate","loot","cofre","locker","armario","armário","treasure","tesouro",
                    "drawer","gaveta","caixa"} },
        { nome="ARMA", ico="🔫", cor=Color3.fromRGB(255,70,70),
          palavras={"gun","arma","weapon","pistol","pistola","rifle","shotgun","knife","faca","sword","espada",
                    "axe","machado","ammo","municao","munição"} },
        { nome="ITEM", ico="📦", cor=Color3.fromRGB(90,200,255),
          palavras={"item","coin","moeda","money","dinheiro","cash","medkit","bandage","curativo","flashlight",
                    "lanterna","note","nota","lever","alavanca","generator","gerador","fuel","gasolina",
                    "collect","pickup","objective","objetivo"} },
    }
    local CAT_INTERAGIR = { nome="INTERAGIR", ico="✋", cor=Color3.fromRGB(150,255,120) }
    local CAT_TOOL      = CATS[4]
    local MAX_VISIVEIS  = 120

    local R = { ativo=false, interagir=false, itens={}, conns={}, gui=nil, t=0, varrendo=false }

    -- ── UI ──
    U.sec(painel, "RASTREAR OBJETOS", "📦", 1)
    local togItens = U.tog(painel, "ESP DE ITENS (ARMAS, CHAVES, BAÚS...)", 2)
    local togInter = U.tog(painel, "MOSTRAR INTERAGÍVEIS (BOTÕES, PORTAS...)", 3)
    togItens:SetAttribute("Controlado", true); togInter:SetAttribute("Controlado", true)
    local filtro = U.inp(painel, "🔎  Filtrar por nome (ex: fusivel, chave)...", 4)
    local status = U.pequeno(painel, "📦 DESLIGADO", nil, 5)
    status.AutoButtonColor = false; status.TextColor3 = T.dim

    -- ── Deteccao ──
    local function catPorNome(nome)
        local n = string.lower(nome)
        for _, c in ipairs(CATS) do
            for _, p in ipairs(c.palavras) do
                if string.find(n, p, 1, true) then return c end
            end
        end
        return nil
    end

    local function dePlayer(obj)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and obj:IsDescendantOf(p.Character) then return true end
        end
        return false
    end

    local function parteDe(alvo)
        if alvo:IsA("BasePart") then return alvo end
        if alvo:IsA("Model") and alvo.PrimaryPart then return alvo.PrimaryPart end
        return alvo:FindFirstChildWhichIsA("BasePart", true)
    end

    local function pequeno(m)
        local ok, tam = pcall(function() return m:GetExtentsSize() end)
        return ok and tam.Magnitude < 40
    end

    -- sobe enquanto o Model pai tambem tiver nome de item (bau inteiro, nao a tampa)
    local function raizComNome(obj)
        local alvo, p = obj, obj.Parent
        while p and p ~= workspace and p:IsA("Model") do
            if catPorNome(p.Name) and pequeno(p) then alvo = p end
            p = p.Parent
        end
        return alvo
    end

    local function jaRastreado(obj)
        local p = obj
        while p and p ~= workspace do
            if R.itens[p] then return true end
            p = p.Parent
        end
        return false
    end

    -- devolve alvo, categoria, rotulo
    local function avaliar(obj)
        if obj:IsA("Tool") then
            return obj, catPorNome(obj.Name) or CAT_TOOL, obj.Name
        end
        if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            local base = obj.Parent
            if base and base:IsA("Attachment") then base = base.Parent end
            if not base or base == workspace then return nil end
            local modelo = base:FindFirstAncestorOfClass("Model")
            local alvo = (modelo and modelo ~= workspace and pequeno(modelo)) and modelo or base
            local nome = alvo.Name
            local acao = ""
            if obj:IsA("ProximityPrompt") then
                if obj.ObjectText ~= "" then nome = obj.ObjectText end
                if obj.ActionText ~= "" then acao = "  [" .. obj.ActionText .. "]" end
            end
            local cat = catPorNome(nome) or catPorNome(alvo.Name) or CAT_INTERAGIR
            return alvo, cat, nome .. acao
        end
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local cat = catPorNome(obj.Name)
            if not cat then return nil end
            local alvo = raizComNome(obj)
            if alvo:IsA("BasePart") and alvo.Size.Magnitude > 60 then return nil end  -- pedaco de mapa
            return alvo, catPorNome(alvo.Name) or cat, alvo.Name
        end
        return nil
    end

    local function criarItem(alvo, cat, rotulo)
        local parte = parteDe(alvo)
        if not parte then return end
        local g = Instance.new("BillboardGui")
        g.AlwaysOnTop = true; g.Size = UDim2.fromOffset(180, 32); g.StudsOffset = Vector3.new(0, 1.5, 0)
        g.MaxDistance = math.huge; g.LightInfluence = 0; g.Adornee = parte; g.Enabled = false
        local bg = Instance.new("Frame", g)
        bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.new(0, 0, 0)
        bg.BackgroundTransparency = 0.45; bg.BorderSizePixel = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)
        local barra = Instance.new("Frame", bg)
        barra.Size = UDim2.new(0, 3, 1, -8); barra.Position = UDim2.new(0, 4, 0, 4)
        barra.BackgroundColor3 = cat.cor; barra.BorderSizePixel = 0
        local function lbl(y, h, fonte, tam, cor)
            local l = Instance.new("TextLabel", bg)
            l.Size = UDim2.new(1, -16, 0, h); l.Position = UDim2.new(0, 12, 0, y)
            l.BackgroundTransparency = 1; l.Font = fonte; l.TextSize = tam; l.TextColor3 = cor
            l.TextStrokeTransparency = 0.4; l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextTruncate = Enum.TextTruncate.AtEnd
            return l
        end
        local nomeL = lbl(2, 16, Enum.Font.GothamBold, 12, Color3.new(1, 1, 1))
        nomeL.Text = cat.ico .. " " .. rotulo
        local distL = lbl(17, 13, Enum.Font.RobotoMono, 11, cat.cor)
        g.Parent = R.gui
        R.itens[alvo] = { alvo=alvo, cat=cat, rotulo=rotulo, busca=string.lower(rotulo .. " " .. alvo.Name),
                          parte=parte, gui=g, distL=distL, dist=math.huge }
    end

    local function adicionar(obj)
        if not R.gui or not obj:IsDescendantOf(workspace) or dePlayer(obj) then return end
        local alvo, cat, rotulo = avaliar(obj)
        if not alvo or jaRastreado(alvo) then return end
        criarItem(alvo, cat, rotulo)
    end

    local function remover(alvo)
        local it = R.itens[alvo]
        if it then pcall(function() it.gui:Destroy() end) R.itens[alvo] = nil end
    end

    -- ── Loop (5x por segundo) ──
    local function atualizar()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local r = (hum and hum.RootPart) or (char and char:FindFirstChild("HumanoidRootPart"))
        local origem = r and r.Position or workspace.CurrentCamera.CFrame.Position
        local busca = string.lower(filtro.Text or "")

        local lista, total = {}, 0
        for alvo, it in pairs(R.itens) do
            if not alvo:IsDescendantOf(workspace) or (alvo:IsA("Tool") and dePlayer(alvo)) then
                remover(alvo)
            else
                if not it.parte:IsDescendantOf(alvo) and it.parte ~= alvo then
                    it.parte = parteDe(alvo)
                    if it.parte then it.gui.Adornee = it.parte end
                end
                if not it.parte then
                    remover(alvo)
                else
                    total = total + 1
                    local mostra = (R.interagir or it.cat ~= CAT_INTERAGIR)
                        and (busca == "" or string.find(it.busca, busca, 1, true) ~= nil)
                    if mostra then
                        it.dist = (it.parte.Position - origem).Magnitude
                        table.insert(lista, it)
                    else
                        it.gui.Enabled = false
                    end
                end
            end
        end
        table.sort(lista, function(a, b) return a.dist < b.dist end)
        for i, it in ipairs(lista) do
            local liga = i <= MAX_VISIVEIS
            it.gui.Enabled = liga
            if liga then it.distL.Text = string.format("◈ %.0f m", it.dist) end
        end

        local txt = "📦 ACHADOS: " .. total .. "   •   MOSTRANDO: " .. math.min(#lista, MAX_VISIVEIS)
        if lista[1] then txt = txt .. "   •   MAIS PERTO: " .. lista[1].rotulo .. string.format(" (%.0f m)", lista[1].dist) end
        if R.varrendo then txt = "📦 PROCURANDO NO MAPA...   " .. txt end
        status.Text = txt
    end

    local function desligar()
        for _, c in ipairs(R.conns) do pcall(function() c:Disconnect() end) end
        R.conns = {}
        R.itens = {}
        if R.gui then pcall(function() R.gui:Destroy() end) R.gui = nil end
        status.Text = "📦 DESLIGADO"
    end

    local function ligar()
        R.gui = Instance.new("ScreenGui")
        R.gui.Name = "GringoItens"; R.gui.ResetOnSpawn = false; R.gui.DisplayOrder = 97
        R.gui.Parent = GS.pai

        table.insert(R.conns, workspace.DescendantAdded:Connect(function(obj)
            task.defer(function() pcall(adicionar, obj) end)
        end))
        table.insert(R.conns, RunService.Heartbeat:Connect(function(dt)
            R.t = R.t + dt
            if R.t < 0.2 then return end
            R.t = 0
            local ok, err = pcall(atualizar)
            if not ok and not R.avisou then R.avisou = true warn("[GRINGO RASTREAR] " .. tostring(err)) end
        end))

        -- varredura inicial em pedacos de 2500 objetos por frame
        local guiAtual = R.gui
        R.varrendo = true
        task.spawn(function()
            local todos = workspace:GetDescendants()
            for i, obj in ipairs(todos) do
                if R.gui ~= guiAtual then return end
                pcall(adicionar, obj)
                if i % 2500 == 0 then task.wait() end
            end
            R.varrendo = false
        end)
    end

    togItens.MouseButton1Click:Connect(function()
        R.ativo = not R.ativo
        togItens.Text = R.ativo and "ESP ITENS: ON" or "ESP ITENS: OFF"
        if R.ativo then ligar() else desligar() end
    end)
    togInter.MouseButton1Click:Connect(function()
        R.interagir = not R.interagir
        togInter.Text = R.interagir and "INTERAGÍVEIS: ON" or "INTERAGÍVEIS: OFF"
    end)
    ScreenGui.Destroying:Connect(desligar)
end
GS.rodar("Rastreio", GS.iniciarRastreio, GS.painelRastrear)

-- ═══════════════════════════════════════════════════════════════
--   ESCUDO ANTI-MONSTRO — NENHUM MONSTRO ENCOSTA EM VOCE
-- ═══════════════════════════════════════════════════════════════
-- Mesma base do PUXAR TODOS (network ownership: monstro solto perto de
-- voce tem a fisica calculada no seu PC, e o que fazemos replica pra
-- todo mundo). Camadas:
--   1) Deteccao universal: qualquer Model com Humanoid OU
--      AnimationController que nao seja de jogador (pega monstro sem
--      Humanoid, comum em jogo de terror). Registro por eventos +
--      varredura inicial em pedacos; monstro recriado e pego na hora.
--   2) Distancia ate o CORPO, nao ate o centro: usa a caixa do modelo
--      inteiro, entao monstro gigante e barrado antes da mao encostar.
--   3) Resposta (voce escolhe):
--        ARREMESSAR — voa em arco girando e cai longe, num chao valido
--                     (raycast: nao joga pra fora do mapa), e fica
--                     atordoado alguns segundos antes de soltar.
--        EMPURRAR   — vira parede: o monstro fica preso na borda.
--        CONGELAR   — trava onde entrou no escudo.
--   4) Trava bruta enquanto barrado: AlignPosition/AlignOrientation
--      rigidos + teleporte antes E depois da fisica + pernas mortas +
--      forcas do jogo desligadas + animacoes paradas.
--   5) Diagnostico: conta os monstros que nenhum cliente segura
--      (ancorados / fisica do servidor).
-- ═══════════════════════════════════════════════════════════════
GS.iniciarEscudo = function()
    local U = GS.ui
    local box = GS.puxarBox
    if not U or not box then return end
    local T = U.T
    local ZERO = Vector3.zero
    local MOVERS = { LinearVelocity=true, AngularVelocity=true, VectorForce=true, LineForce=true,
                     Torque=true, AlignPosition=true, AlignOrientation=true }
    local STUN = 2.5        -- segundos atordoado depois de arremessado
    local VOO  = 0.45       -- duracao do voo do arremesso

    local E = { ativo=false, raio=10, modo="ARREMESSAR", bolhaOn=true, reg={}, alvos={},
                conns={}, regConns=nil, bolha=nil, avisou=false, statusT=0 }

    -- ── UI ──
    U.sec(box, "ESCUDO ANTI-MONSTRO", "🛡", 5)
    local togE = U.tog(box, "🛡 ESCUDO ANTI-MONSTRO", 6)
    local menos, mais, valor = U.ctrl(box, "Raio do escudo (m)", 10, 7)
    local grade = Instance.new("Frame", box)
    grade.Size = UDim2.new(1, 0, 0, 32); grade.BackgroundTransparency = 1; grade.LayoutOrder = 8
    do
        local gl = Instance.new("UIGridLayout", grade)
        gl.CellSize = UDim2.new(1/3, -6, 1, 0); gl.CellPadding = UDim2.new(0, 8, 0, 0)
        gl.SortOrder = Enum.SortOrder.LayoutOrder
    end
    local togBolha = U.tog(box, "MOSTRAR BOLHA DO ESCUDO (SÓ VOCÊ VÊ)", 9)
    local status = U.pequeno(box, "🛡 ESCUDO DESLIGADO", nil, 10)
    status.AutoButtonColor = false; status.TextColor3 = T.dim
    togE:SetAttribute("Controlado", true); togBolha:SetAttribute("Controlado", true)
    togBolha.Text = "BOLHA: ON"

    local botoesModo = {}
    local function pintarModos()
        for nome, b in pairs(botoesModo) do
            local sel = nome == E.modo
            U.tw(b, { BackgroundColor3 = sel and T.on or T.card, TextColor3 = sel and T.knobOn or T.dim }, 0.15)
        end
    end
    for i, nome in ipairs({ "ARREMESSAR", "EMPURRAR", "CONGELAR" }) do
        local b = Instance.new("TextButton", grade)
        b.Text = nome; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.AutoButtonColor = false
        b.BackgroundColor3 = T.card; b.TextColor3 = T.dim; b.BorderSizePixel = 0; b.LayoutOrder = i
        U.mkC(8, b); U.mkS(1, T.stroke, b); U.press(b)
        b.MouseButton1Click:Connect(function()
            E.modo = nome; pintarModos()
            GS.toast("🛡  Escudo: " .. nome, true)
        end)
        botoesModo[nome] = b
    end
    pintarModos()

    local function mostrarRaio() valor.Text = E.raio .. " m" end
    mostrarRaio()
    local function passoRaio(sobe)
        local r = E.raio
        if sobe then r = r + (r < 10 and 1 or (r < 50 and 5 or 10))
        else r = r - (r <= 10 and 1 or (r <= 50 and 5 or 10)) end
        E.raio = math.clamp(r, 2, 200)
        mostrarRaio()
    end
    mais.MouseButton1Click:Connect(function() passoRaio(true) end)
    menos.MouseButton1Click:Connect(function() passoRaio(false) end)

    -- ── Deteccao ──
    local function ehMonstro(m)
        if not m or not m:IsA("Model") or m == workspace or not m:IsDescendantOf(workspace) then return false end
        if Players:GetPlayerFromCharacter(m) then return false end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and m:IsDescendantOf(p.Character) then return false end
        end
        local h = m:FindFirstChildOfClass("Humanoid")
        if h and h.Health <= 0 then return false end
        return true
    end

    local function raizDe(m)
        local h = m:FindFirstChildOfClass("Humanoid")
        local r = (h and h.RootPart) or m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso")
        if r and r:IsA("BasePart") then return r end
        return m:FindFirstChildWhichIsA("BasePart", true)
    end

    local function registrar(d)
        if d:IsA("Humanoid") or d:IsA("AnimationController") then
            local m = d.Parent
            if m and m:IsA("Model") then E.reg[m] = true end
        end
    end

    local function iniciarRegistro()
        if E.regConns then return end
        E.regConns = {}
        table.insert(E.regConns, workspace.DescendantAdded:Connect(registrar))
        task.spawn(function()
            for i, d in ipairs(workspace:GetDescendants()) do
                if not E.regConns then return end
                registrar(d)
                if i % 3000 == 0 then task.wait() end
            end
        end)
    end

    -- distancia de um ponto ate a CAIXA do modelo (monstro gigante conta o corpo todo)
    local function distAoCorpo(m, ponto)
        local ok, cf, tam = pcall(m.GetBoundingBox, m)
        if not ok then return math.huge end
        local loc = cf:PointToObjectSpace(ponto)
        local h = tam / 2
        local perto = Vector3.new(math.clamp(loc.X, -h.X, h.X), math.clamp(loc.Y, -h.Y, h.Y), math.clamp(loc.Z, -h.Z, h.Z))
        return (loc - perto).Magnitude, math.max(tam.X, tam.Z) / 2
    end

    -- ── Trava (igual PUXAR TODOS) ──
    local function neutralizar(st, o)
        if o.Name:sub(1, 6) == "Gringo" then return end
        pcall(function()
            if o:IsA("BodyMover") then
                table.insert(st.movers, { o=o, pai=o.Parent }); o.Parent = nil
            elseif MOVERS[o.ClassName] and o.Enabled then
                table.insert(st.movers, { o=o }); o.Enabled = false
            end
        end)
    end

    local function prender(m, r)
        local st = { m=m, r=r, movers={}, animT=0 }
        local h = m:FindFirstChildOfClass("Humanoid")
        st.h = h
        if h then st.orig = { ws=h.WalkSpeed, jp=h.JumpPower, jh=h.JumpHeight, ar=h.AutoRotate, ps=h.PlatformStand } end
        for _, d in ipairs(m:GetDescendants()) do neutralizar(st, d) end
        st.conn = m.DescendantAdded:Connect(function(d) neutralizar(st, d) end)
        st.att = Instance.new("Attachment"); st.att.Name = "GringoEscudoAtt"; st.att.Parent = r
        st.ap = Instance.new("AlignPosition"); st.ap.Name = "GringoEscudoAP"
        st.ap.Mode = Enum.PositionAlignmentMode.OneAttachment; st.ap.Attachment0 = st.att
        st.ap.RigidityEnabled = true; st.ap.Position = r.Position; st.ap.Parent = r
        st.ao = Instance.new("AlignOrientation"); st.ao.Name = "GringoEscudoAO"
        st.ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; st.ao.Attachment0 = st.att
        st.ao.RigidityEnabled = true; st.ao.CFrame = r.CFrame; st.ao.Parent = r
        E.alvos[m] = st
        return st
    end

    local function soltar(m)
        local st = E.alvos[m]
        if not st then return end
        E.alvos[m] = nil
        if st.conn then st.conn:Disconnect() end
        for _, o in ipairs({ st.ap, st.ao, st.att }) do pcall(function() o:Destroy() end) end
        for _, mv in ipairs(st.movers) do
            pcall(function()
                if mv.pai then if mv.pai.Parent then mv.o.Parent = mv.pai end else mv.o.Enabled = true end
            end)
        end
        if st.h and st.orig then
            pcall(function()
                local h, o = st.h, st.orig
                h.WalkSpeed = o.ws; h.JumpPower = o.jp; h.JumpHeight = o.jh; h.AutoRotate = o.ar; h.PlatformStand = o.ps
            end)
        end
    end

    local function aplicar(st, cf, dt)
        st.cf = cf
        local h, r = st.h, st.r
        if h then
            if h.WalkSpeed ~= 0 then h.WalkSpeed = 0 end
            if h.JumpPower ~= 0 then h.JumpPower = 0 end
            if h.JumpHeight ~= 0 then h.JumpHeight = 0 end
            if h.AutoRotate then h.AutoRotate = false end
            if not h.PlatformStand then h.PlatformStand = true end
        end
        st.animT = st.animT + dt
        if st.animT >= 0.3 then
            st.animT = 0
            local ctrl = h or st.m:FindFirstChildOfClass("AnimationController")
            local animator = ctrl and ctrl:FindFirstChildOfClass("Animator")
            if animator then for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do tr:Stop(0) end end
        end
        st.ap.Position = cf.Position
        st.ao.CFrame = cf
        r.CFrame = cf
        r.AssemblyLinearVelocity = ZERO
        r.AssemblyAngularVelocity = ZERO
    end

    -- ── Arremesso: acha um chao valido longe de voce ──
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local function destinoSeguro(m, r, minhaPos)
        rp.FilterDescendantsInstances = { LocalPlayer.Character, m, E.bolha }
        local de = r.Position
        local dir = Vector3.new(de.X - minhaPos.X, 0, de.Z - minhaPos.Z)
        if dir.Magnitude < 0.1 then dir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) end
        dir = dir.Unit
        local alturaPe = 3
        local baixo = workspace:Raycast(de, Vector3.new(0, -50, 0), rp)
        if baixo then alturaPe = math.clamp(de.Y - baixo.Position.Y, 1, 30) end
        for _, extra in ipairs({ 60, 45, 32, 22, 14, 8 }) do
            local p = minhaPos + dir * (E.raio + extra)
            local chao = workspace:Raycast(Vector3.new(p.X, de.Y + 4, p.Z), Vector3.new(0, -60, 0), rp)
            if chao then return Vector3.new(p.X, chao.Position.Y + alturaPe, p.Z) end
        end
        local p = minhaPos + dir * (E.raio + 4)
        return Vector3.new(p.X, de.Y, p.Z)
    end

    local function olhandoPraMim(pos, minhaPos)
        return CFrame.lookAt(pos, Vector3.new(minhaPos.X, pos.Y, minhaPos.Z))
    end

    -- ── ANTI-TOQUE ──
    -- O toque entre o SEU boneco e o monstro e detectado no SEU PC e
    -- reportado pro servidor. Com CanTouch=false nas pecas do monstro (so
    -- no seu PC), o toque nunca e detectado → ataque/jumpscare que usa
    -- Touched (mao, hitbox escondida, "KillPart") nao dispara em voce.
    -- Vale pra todo monstro do mapa, a qualquer distancia, e e
    -- reaplicado a cada 0.5s (se o jogo religar, desliga de novo).
    E.toque, E.toqueT = {}, 0
    local function antiToque(m)
        local t = E.toque[m]
        if not t then
            t = { lista={} }
            local function pegar(p)
                if p:IsA("BasePart") then
                    table.insert(t.lista, p)
                    if p.CanTouch then p.CanTouch = false end
                end
            end
            for _, d in ipairs(m:GetDescendants()) do pegar(d) end
            t.conn = m.DescendantAdded:Connect(function(d) pcall(pegar, d) end)
            E.toque[m] = t
        else
            for _, p in ipairs(t.lista) do
                if p.Parent and p.CanTouch then p.CanTouch = false end
            end
        end
    end
    local function esquecerToque(m, restaurar)
        local t = E.toque[m]
        if not t then return end
        E.toque[m] = nil
        if t.conn then t.conn:Disconnect() end
        if restaurar then
            for _, p in ipairs(t.lista) do pcall(function() if p.Parent then p.CanTouch = true end end) end
        end
    end

    -- ── Loop ──
    local function passo(dt)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local meuRoot = (hum and hum.RootPart) or (char and char:FindFirstChild("HumanoidRootPart"))
        if not meuRoot then return end
        local minhaPos = meuRoot.Position
        local agora = os.clock()

        if E.bolha then
            E.bolha.Size = Vector3.new(E.raio * 2, E.raio * 2, E.raio * 2)
            E.bolha.CFrame = CFrame.new(minhaPos)
            E.bolha.Transparency = E.bolhaOn and 0.75 or 1
        end

        E.toqueT = E.toqueT + dt
        if E.toqueT >= 0.5 then
            E.toqueT = 0
            for m in pairs(E.reg) do
                if m.Parent and ehMonstro(m) then pcall(antiToque, m) end
            end
        end

        local barrados, impossiveis = 0, 0
        for m in pairs(E.reg) do
            if not m.Parent or not m:IsDescendantOf(workspace) then
                E.reg[m] = nil; soltar(m); esquecerToque(m, false)
            elseif PX.ctrl[m] then
                soltar(m)
            else
                local st = E.alvos[m]
                local r = (st and st.r.Parent and st.r) or raizDe(m)
                if r and (r.Position - minhaPos).Magnitude < E.raio + 150 and ehMonstro(m) then
                    local dist, corpo = distAoCorpo(m, minhaPos)
                    local dentro = dist < E.raio
                    if r.Anchored then
                        if dentro and m:FindFirstChildOfClass("Humanoid") then impossiveis = impossiveis + 1 end
                    else
                        if dentro and isnetworkowner then
                            local ok, meu = pcall(isnetworkowner, r)
                            if ok and meu == false then impossiveis = impossiveis + 1 end
                        end
                        if not st and dentro then
                            st = prender(m, r)
                            st.inicio = agora
                            if E.modo == "ARREMESSAR" then
                                st.estado = "voando"; st.de = r.Position
                                st.para = destinoSeguro(m, r, minhaPos)
                                st.eixo = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit
                            elseif E.modo == "CONGELAR" then
                                st.estado = "congelado"; st.fixo = olhandoPraMim(r.Position, minhaPos)
                            else
                                st.estado = "parede"
                            end
                        end
                        if st then
                            barrados = barrados + 1
                            local dirFora = Vector3.new(r.Position.X - minhaPos.X, 0, r.Position.Z - minhaPos.Z)
                            dirFora = dirFora.Magnitude > 0.1 and dirFora.Unit or Vector3.new(1, 0, 0)
                            local borda = minhaPos + dirFora * (E.raio + corpo + 1.5)
                            borda = Vector3.new(borda.X, r.Position.Y, borda.Z)

                            if st.estado == "voando" then
                                local a = math.clamp((agora - st.inicio) / VOO, 0, 1)
                                local alto = 6 + (st.para - st.de).Magnitude * 0.25
                                local pos = st.de:Lerp(st.para, a) + Vector3.new(0, math.sin(a * math.pi) * alto, 0)
                                pcall(aplicar, st, CFrame.new(pos) * CFrame.fromAxisAngle(st.eixo, a * math.pi * 6), dt)
                                if a >= 1 then
                                    st.estado = "atordoado"; st.ate = agora + STUN
                                    st.fixo = olhandoPraMim(st.para, minhaPos)
                                end
                            elseif st.estado == "atordoado" then
                                -- treme no chao enquanto atordoado
                                local treme = Vector3.new(math.sin(agora * 40) * 0.15, 0, math.cos(agora * 37) * 0.15)
                                pcall(aplicar, st, st.fixo + treme, dt)
                                if agora >= st.ate then
                                    if dentro then
                                        st.estado = "voando"; st.inicio = agora; st.de = r.Position
                                        st.para = destinoSeguro(m, r, minhaPos)
                                    else
                                        soltar(m)
                                    end
                                end
                            elseif st.estado == "congelado" then
                                if dist < E.raio * 0.5 then st.fixo = olhandoPraMim(borda, minhaPos) end
                                pcall(aplicar, st, st.fixo, dt)
                                if dist > E.raio + 6 and agora - st.inicio > 1 then soltar(m) end
                            else -- parede
                                pcall(aplicar, st, olhandoPraMim(borda, minhaPos), dt)
                                if dist > E.raio + 6 and agora - st.inicio > 1 then soltar(m) end
                            end
                        end
                    end
                elseif st then
                    soltar(m)
                end
            end
        end

        E.statusT = E.statusT + dt
        if E.statusT >= 0.25 then
            E.statusT = 0
            local semToque = 0
            for _ in pairs(E.toque) do semToque = semToque + 1 end
            local txt = "🛡 RAIO: " .. E.raio .. " m   •   BARRADOS: " .. barrados .. "   •   🚫 ANTI-TOQUE: " .. semToque
            if impossiveis > 0 then txt = txt .. "   •   ⚓ NÃO SEGURÁVEIS: " .. impossiveis end
            status.Text = txt
        end
    end

    local function desligar()
        for _, c in ipairs(E.conns) do pcall(function() c:Disconnect() end) end
        E.conns = {}
        for m in pairs(E.alvos) do soltar(m) end
        for m in pairs(E.toque) do esquecerToque(m, true) end
        if E.bolha then pcall(function() E.bolha:Destroy() end) E.bolha = nil end
        status.Text = "🛡 ESCUDO DESLIGADO"
    end

    local function ligar()
        iniciarRegistro()
        local b = Instance.new("Part")
        b.Name = "GringoEscudoBolha"; b.Shape = Enum.PartType.Ball; b.Material = Enum.Material.ForceField
        b.Color = Color3.fromRGB(120, 200, 255); b.Anchored = true; b.CanCollide = false
        b.CanQuery = false; b.CanTouch = false; b.CastShadow = false
        b.Parent = workspace.CurrentCamera
        E.bolha = b
        E.avisou = false
        table.insert(E.conns, RunService.Heartbeat:Connect(function(dt)
            local ok, err = pcall(passo, dt)
            if not ok and not E.avisou then E.avisou = true warn("[GRINGO ESCUDO] " .. tostring(err)) end
        end))
        -- re-trava antes da fisica (servidor teleportou → volta no mesmo passo)
        table.insert(E.conns, RunService.Stepped:Connect(function()
            for _, st in pairs(E.alvos) do
                if st.cf and st.r.Parent then
                    pcall(function() st.r.CFrame = st.cf; st.r.AssemblyLinearVelocity = ZERO end)
                end
            end
        end))
    end

    togE.MouseButton1Click:Connect(function()
        E.ativo = not E.ativo
        togE.Text = E.ativo and "ESCUDO: ON" or "ESCUDO: OFF"
        if E.ativo then ligar() else desligar() end
    end)
    togBolha.MouseButton1Click:Connect(function()
        E.bolhaOn = not E.bolhaOn
        togBolha.Text = E.bolhaOn and "BOLHA: ON" or "BOLHA: OFF"
    end)
    ScreenGui.Destroying:Connect(function()
        desligar()
        for _, c in ipairs(E.regConns or {}) do pcall(function() c:Disconnect() end) end
        E.regConns = nil
    end)
end
GS.rodar("Escudo", GS.iniciarEscudo)

-- ═══════════════════════════════════════════════════════════════
--   SUPER PULO — ALTURA ESCOLHIDA (ATE 10.000 STUDS) + POUSO SUAVE
-- ═══════════════════════════════════════════════════════════════
-- Seu boneco e simulado no seu PC, entao o pulo replica: todo mundo ve.
--   • Velocidade calculada pela fisica: v = raiz(2 · gravidade · altura)
--     → sobe EXATAMENTE a altura escolhida, em qualquer gravidade.
--   • Funciona mesmo em jogo que desliga o pulo (JumpPower 0): usa o
--     pedido de pulo (Espaco / botao do celular), nao o pulo do jogo.
--   • So pula se estiver no chao (raycast), nada de pulo duplo bugado.
--   • POUSO SUAVE: caindo rapido perto do chao, freia pra nao tomar dano
--     de queda nem atravessar o piso.
-- ═══════════════════════════════════════════════════════════════
do
    local ALTURAS = { 10, 25, 50, 100, 200, 350, 500, 750, 1000, 2000, 3500, 5000, 10000 }
    local P = { ativo=false, idx=4, conns={}, ultimo=0 }
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude

    local function corpo()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = (hum and hum.RootPart) or (char and char:FindFirstChild("HumanoidRootPart"))
        return char, hum, root
    end

    local function chaoEmbaixo(char, hum, root, extra)
        rp.FilterDescendantsInstances = { char, workspace.CurrentCamera }
        local altura = (hum and hum.HipHeight or 2) + root.Size.Y / 2
        return workspace:Raycast(root.Position, Vector3.new(0, -(altura + extra), 0), rp), altura
    end

    local function mostrar()
        GS.puloLbl.Text = ALTURAS[P.idx] .. " m"
    end

    local function pular()
        if not P.ativo then return end
        local agora = os.clock()
        if agora - P.ultimo < 0.25 then return end
        local char, hum, root = corpo()
        if not root or root.Anchored then return end
        local noChao = (hum and hum.FloorMaterial ~= Enum.Material.Air) or chaoEmbaixo(char, hum, root, 1.5) ~= nil
        if not noChao then return end
        P.ultimo = agora
        local h = ALTURAS[P.idx]
        local v = math.sqrt(2 * workspace.Gravity * h)
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        local vel = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(vel.X, v, vel.Z)
        -- reforco no frame seguinte (alguns jogos zeram a velocidade ao pular)
        task.defer(function()
            pcall(function()
                if root.AssemblyLinearVelocity.Y < v * 0.8 then
                    local v2 = root.AssemblyLinearVelocity
                    root.AssemblyLinearVelocity = Vector3.new(v2.X, v, v2.Z)
                end
            end)
        end)
        GS.toast("🦘  SUPER PULO: " .. h .. " m", true)
    end

    local function pousoSuave()
        local char, hum, root = corpo()
        if not root or root.Anchored then return end
        local vel = root.AssemblyLinearVelocity
        if vel.Y > -60 then return end
        -- olha o chao proporcional a velocidade (quanto mais rapido, mais cedo freia)
        local hit, altura = chaoEmbaixo(char, hum, root, math.clamp(-vel.Y * 0.12, 8, 300))
        if hit then
            root.AssemblyLinearVelocity = Vector3.new(vel.X, -25, vel.Z)
        end
    end

    local function ligar()
        table.insert(P.conns, UserInputService.JumpRequest:Connect(function() pcall(pular) end))
        table.insert(P.conns, RunService.Heartbeat:Connect(function() pcall(pousoSuave) end))
    end
    local function desligar()
        for _, c in ipairs(P.conns) do pcall(function() c:Disconnect() end) end
        P.conns = {}
    end

    if GS.puloBtn then
        GS.puloBtn:SetAttribute("Controlado", true)
        mostrar()
        GS.puloBtn.MouseButton1Click:Connect(function()
            P.ativo = not P.ativo
            GS.puloBtn.Text = P.ativo and "SUPER PULO: ON" or "SUPER PULO: OFF"
            if P.ativo then ligar() else desligar() end
        end)
        GS.puloMais.MouseButton1Click:Connect(function() P.idx = math.min(P.idx + 1, #ALTURAS); mostrar() end)
        GS.puloMenos.MouseButton1Click:Connect(function() P.idx = math.max(P.idx - 1, 1); mostrar() end)
        ScreenGui.Destroying:Connect(desligar)
    end
end

-- ═══════════════════════════════════════════════════════════════
--   🧠 RESOLVER — GUIA AUTOMATICO DE OBJETIVOS
-- ═══════════════════════════════════════════════════════════════
-- Descobre O QUE FAZER no jogo e mostra em texto + marca no ESP.
-- Fontes que ele le (em qualquer jogo, sem saber nada dele antes):
--   1) TEXTO NA TELA: le todos os textos visiveis da interface do jogo
--      e pega os que parecem objetivo ("Encontre...", "Organize os
--      fusiveis 0/3", "Find the key", "Escape"...) com contador X/Y.
--   2) VALORES ESCONDIDOS: StringValue/IntValue/atributos com nome de
--      objetivo/missao/tarefa/etapa/fase/quest/task... (no player,
--      ReplicatedStorage e workspace) — pega objetivo que a tela NAO
--      mostra.
--   3) GUIAS DO PROPRIO JOGO: Beam, Highlight e BillboardGui que o jogo
--      usa pra marcar lugar → "o jogo esta marcando X".
--   4) INTERACOES: todo ProximityPrompt ativo ("[Pegar] Chave").
--   5) PORTAS TRANCADAS (atributo/valor Locked) + chave no mapa.
--   6) SAIDAS: exit/saida/escape/finish/goal/win/extraction...
--   7) DICIONARIO PT/EN: "fusivel" no objetivo → procura fuse/fusivel
--      no mapa; palavra desconhecida ("Amuleto") vira termo de busca.
-- Saida:
--   • Janela RESOLVER na tela (arrastavel) com a lista de tarefas,
--     contador e distancia de cada alvo, atualizada 1x por segundo.
--   • Marcadores no ESP (atraves da parede) nos alvos das tarefas.
--   • Seta guia (Beam) ate o alvo mais importante.
--   • Relatorio completo: copia pra area de transferencia ou F9.
-- ═══════════════════════════════════════════════════════════════
GS.iniciarResolver = function()
    local U = GS.ui
    local painel = GS.painelResolver
    if not U or not painel then return end
    local T = U.T

    -- ─────────────────────────────────────────────────────────────
    --  DICIONARIOS
    -- ─────────────────────────────────────────────────────────────
    local VERBOS = {
        "encontr","ache ","achar","procur","pegu","pegar","colet","junt","reun","abra","abrir","destranc",
        "fuja","fugir","escap","sobreviv","consert","repar","ligu","ligar","ative","ativar","organiz",
        "coloqu","coloc","leve ","levar","entreg","va ate","vá ate","cheg","derrot","mate ","matar","elimin",
        "desliga","use ","usar","resolv","descubr","investig","explor","siga ","seguir","proteg","defend",
        "find","collect","gather","get the","grab","pick up","open","unlock","escape","survive",
        "fix","repair","turn on","activate","power","restore","deliver","bring","place","put ",
        "go to","reach","head to","defeat","kill","destroy","use the","solve","search","explore",
        "follow","protect","defend","insert","return",
    }
    local TITULOS = {
        "objetivo","missao","tarefa","quest","mission","objective","task","goal","etapa","fase",
        "stage","step","proximo","next","dica","hint","capitulo","chapter",
    }
    local RUIDO = {
        "settings","configurac","loja","shop","store","comprar","buy","jogar","play","credits",
        "creditos","volume","graphics","grafico","inventory","inventario","leaderboard","ranking",
        "robux","premium","gamepass","codigo promocional","promo",
    }
    local NOMES_VALOR = {
        "objective","objetivo","quest","mission","missao","task","tarefa","goal","stage","etapa",
        "phase","fase","step","hint","dica","chapter","capitulo",
    }
    local NOMES_NUMERO = { "stage","etapa","fase","phase","step","chapter","capitulo" }
    local SAIDAS = { "exit","saida","escape","finish","goal","win","endzone","end zone","extraction",
                     "evac","fuga","chegada","victory","vitoria","portal" }
    local GENERICOS = {
        part=true, meshpart=true, union=true, unionoperation=true, wedge=true, wedgepart=true,
        model=true, handle=true, base=true, baseplate=true, terrain=true, floor=true, wall=true,
        ["new part"]=true, mesh=true, ["default"]=true, folder=true, cube=true, block=true,
    }
    local STOP = {}
    for _, w in ipairs({
        "para","pelo","pela","pelos","pelas","com","uma","umas","uns","todo","toda","todos","todas",
        "voce","seus","suas","esse","essa","isso","este","esta","aqui","onde","quando","antes","depois",
        "agora","ainda","mais","menos","muito","sala","area","lugar","perto","longe","dentro","fora",
        "the","and","with","your","from","into","that","this","there","before","after","then","more",
        "find","collect","gather","grab","pick","open","unlock","escape","survive","repair","turn",
        "activate","power","restore","deliver","bring","place","reach","head","defeat","kill",
        "destroy","solve","search","explore","follow","protect","defend","insert","return","them",
        "encontre","encontrar","ache","achar","procure","procurar","pegue","pegar","colete","coletar",
        "junte","juntar","reuna","abra","abrir","destranque","destrancar","fuja","fugir","escape",
        "sobreviva","conserte","consertar","repare","ligue","ligar","ative","ativar","organize",
        "organizar","coloque","colocar","leve","levar","entregue","entregar","chegue","chegar",
        "derrote","mate","matar","elimine","desligue","resolva","descubra","investigue","explore",
        "siga","proteja","defenda","objetivo","missao","tarefa","quest","mission","objective","task",
        "goal","etapa","fase","stage","step","proximo","next","dica","hint","capitulo","chapter",
    }) do STOP[w] = true end

    -- termo no texto do objetivo → nomes pra procurar no mapa
    local DICIONARIO = {
        { g={"fusive","fuse"},                       b={"fuse","fusivel"} },
        { g={"chave","key"},                         b={"key","chave"} },
        { g={"cartao","card","cracha"},              b={"card","cartao","keycard","cracha"} },
        { g={"bateria","battery","pilha"},           b={"battery","bateria","pilha"} },
        { g={"gasolin","combustiv","fuel","galao"},  b={"fuel","gas","gasolina","combustivel","jerry","galao","canister"} },
        { g={"gerador","generator"},                 b={"generator","gerador"} },
        { g={"porta","door","portao","gate"},        b={"door","porta","gate","portao"} },
        { g={"saida","exit","fuga","escape"},        b={"exit","saida","escape","door","gate"} },
        { g={"alavanca","lever"},                    b={"lever","alavanca"} },
        { g={"botao","button"},                      b={"button","botao"} },
        { g={"interruptor","switch","disjuntor","breaker","energia","luz"},
                                                     b={"switch","interruptor","breaker","disjuntor","fusebox","power","panel","painel"} },
        { g={"livro","book"},                        b={"book","livro"} },
        { g={"nota","bilhete","note","paper","papel","carta","letter"},
                                                     b={"note","nota","paper","papel","letter","carta","bilhete"} },
        { g={"pagina","page"},                       b={"page","pagina"} },
        { g={"engrenage","gear","peca","part "},     b={"gear","engrenagem","peca","cog"} },
        { g={"moeda","coin","dinheiro","cash"},      b={"coin","moeda","cash","money"} },
        { g={"ovo","egg"},                           b={"egg","ovo"} },
        { g={"osso","bone"},                         b={"bone","osso"} },
        { g={"cristal","crystal","gema","gem","joia"}, b={"crystal","cristal","gem","gema","jewel","joia"} },
        { g={"pocao","potion","frasco"},             b={"potion","pocao","frasco","flask","vial"} },
        { g={"comida","food","lanche"},              b={"food","comida","burger","pizza","snack"} },
        { g={"lanterna","flashlight"},               b={"flashlight","lanterna","torch"} },
        { g={"codigo","code","senha","password"},    b={"code","codigo","keypad","senha","password"} },
        { g={"cofre","safe"},                        b={"safe","cofre","vault"} },
        { g={"valvula","valve"},                     b={"valve","valvula"} },
        { g={"cano","pipe"},                         b={"pipe","cano"} },
        { g={"fio","wire","cabo"},                   b={"wire","fio","cable","cabo"} },
        { g={"ferramenta","tool"},                   b={"tool","ferramenta","toolbox"} },
        { g={"martelo","hammer"},                    b={"hammer","martelo"} },
        { g={"chave de fenda","screwdriver"},        b={"screwdriver","fenda"} },
        { g={"pe de cabra","crowbar"},               b={"crowbar","cabra"} },
        { g={" pa ","shovel"},                       b={"shovel"} },
        { g={"corda","rope"},                        b={"rope","corda"} },
        { g={"mapa","map "},                         b={"map","mapa"} },
        { g={"reliquia","relic","artefato","artifact","amuleto","amulet"},
                                                     b={"relic","reliquia","artifact","artefato","amulet","amuleto"} },
        { g={"boneca","doll"},                       b={"doll","boneca"} },
        { g={"vela","candle"},                       b={"candle","vela"} },
        { g={"cruz","cross","crucifix"},             b={"cross","cruz","crucifix"} },
        { g={"computador","computer","pc ","terminal"}, b={"computer","computador","terminal","pc","laptop"} },
        { g={"radio"},                               b={"radio"} },
        { g={"elevador","elevator"},                 b={"elevator","elevador"} },
        { g={"carro","car ","veiculo","vehicle"},    b={"car","carro","vehicle","veiculo"} },
        { g={"barco","boat"},                        b={"boat","barco"} },
        { g={"helicoptero","helicopter","heli"},     b={"helicopter","helicoptero","heli"} },
    }

    -- ─────────────────────────────────────────────────────────────
    --  UTILIDADES
    -- ─────────────────────────────────────────────────────────────
    local ACENTOS = {
        ["á"]="a",["à"]="a",["â"]="a",["ã"]="a",["ä"]="a",["Á"]="a",["À"]="a",["Â"]="a",["Ã"]="a",
        ["é"]="e",["ê"]="e",["è"]="e",["É"]="e",["Ê"]="e",["í"]="i",["î"]="i",["Í"]="i",
        ["ó"]="o",["ô"]="o",["õ"]="o",["ò"]="o",["Ó"]="o",["Ô"]="o",["Õ"]="o",
        ["ú"]="u",["ü"]="u",["Ú"]="u",["ç"]="c",["Ç"]="c",["ñ"]="n",
    }
    local function norm(s)
        s = string.lower(tostring(s or ""))
        for k, v in pairs(ACENTOS) do
            if string.find(s, k, 1, true) then s = string.gsub(s, k, v) end
        end
        return s
    end
    local function contemAlgum(s, lista)
        for _, p in ipairs(lista) do
            if string.find(s, p, 1, true) then return p end
        end
        return nil
    end
    local function dePlayer(obj)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and obj:IsDescendantOf(p.Character) then return true end
        end
        return false
    end
    local function parteDe(obj)
        if not obj then return nil end
        if obj:IsA("BasePart") then return obj end
        if obj:IsA("Attachment") then return obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or nil end
        if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end
    local function minhaPosicao()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = (hum and hum.RootPart) or (char and char:FindFirstChild("HumanoidRootPart"))
        return root and root.Position or workspace.CurrentCamera.CFrame.Position, root
    end
    local function textoDe(g)
        local ok, t = pcall(function() return g.ContentText end)
        if ok and t and t ~= "" then return t end
        return g.Text or ""
    end
    local function guiVisivel(g)
        local o = g
        while o and not o:IsA("LayerCollector") do
            if o:IsA("GuiObject") and not o.Visible then return false end
            o = o.Parent
        end
        if o and o:IsA("ScreenGui") and not o.Enabled then return false end
        if g.TextTransparency >= 0.95 then return false end
        return true
    end

    -- ─────────────────────────────────────────────────────────────
    --  ESTADO
    -- ─────────────────────────────────────────────────────────────
    local RS = {
        ativo=false, marcar=true, seta=true, conns={}, objs={}, objsSet={}, prompts={}, guias={},
        tarefas={}, relatorio="", ultimoObjetivo="", hud=nil, lista=nil, marcadores={}, beam=nil,
        attEu=nil, attAlvo=nil, varrendo=false, analiseT=99, marcaT=0, busca="",
    }

    -- ─────────────────────────────────────────────────────────────
    --  INDICE DO MAPA (varredura em pedacos + eventos)
    -- ─────────────────────────────────────────────────────────────
    local function indexar(obj)
        if obj.Name:sub(1, 6) == "Gringo" then return end
        if obj:IsA("ProximityPrompt") then
            RS.prompts[obj] = true
        elseif obj:IsA("Beam") or obj:IsA("Highlight") or obj:IsA("BillboardGui") then
            if obj.Name:sub(1, 6) ~= "Gringo" then RS.guias[obj] = true end
        elseif obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("BasePart") then
            local n = norm(obj.Name)
            if #n >= 3 and not GENERICOS[n] and not RS.objsSet[obj] then
                RS.objsSet[obj] = true
                table.insert(RS.objs, { inst=obj, nome=n })
            end
        end
    end

    local function varrer()
        RS.varrendo = true
        local alvo = RS.hud
        task.spawn(function()
            local todos = workspace:GetDescendants()
            for i, obj in ipairs(todos) do
                if RS.hud ~= alvo then return end
                pcall(indexar, obj)
                if i % 3000 == 0 then task.wait() end
            end
            -- guias que o jogo coloca na interface (Highlight/Billboard na PlayerGui)
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if pg then
                for _, g in ipairs(pg:GetDescendants()) do
                    if g:IsA("Highlight") or g:IsA("BillboardGui") then RS.guias[g] = true end
                end
            end
            RS.varrendo = false
        end)
    end

    local function limparIndice()
        local novo, set = {}, {}
        for _, o in ipairs(RS.objs) do
            if o.inst.Parent and o.inst:IsDescendantOf(workspace) then
                table.insert(novo, o); set[o.inst] = true
            end
        end
        RS.objs, RS.objsSet = novo, set
        for p in pairs(RS.prompts) do if not p:IsDescendantOf(workspace) then RS.prompts[p] = nil end end
        for g in pairs(RS.guias) do if not g.Parent then RS.guias[g] = nil end end
    end

    -- ─────────────────────────────────────────────────────────────
    --  FONTE 1: TEXTO NA TELA
    -- ─────────────────────────────────────────────────────────────
    local function objetivosDaTela()
        local achados, vistos = {}, {}
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return achados end
        for _, g in ipairs(pg:GetDescendants()) do
            if (g:IsA("TextLabel") or g:IsA("TextButton")) and guiVisivel(g) then
                local bruto = textoDe(g)
                local n = norm(bruto)
                if #n >= 4 and #n <= 160 and n:find("%a%a%a") and not vistos[n] and not contemAlgum(n, RUIDO) then
                    local pts = 0
                    local temContador = n:find("%d+%s*/%s*%d+") ~= nil
                    if temContador then pts = pts + 2 end
                    if contemAlgum(n, VERBOS) then pts = pts + 2 end
                    if contemAlgum(n, TITULOS) then pts = pts + 3 end
                    if pts >= 2 and (pts >= 3 or temContador) then
                        vistos[n] = true
                        local feito, total = n:match("(%d+)%s*/%s*(%d+)")
                        table.insert(achados, { texto=bruto:gsub("%s+", " "), norm=n, pts=pts,
                                                feito=tonumber(feito), total=tonumber(total), fonte="tela" })
                    end
                end
            end
        end
        table.sort(achados, function(a, b) return a.pts > b.pts end)
        return achados
    end

    -- ─────────────────────────────────────────────────────────────
    --  FONTE 2: VALORES / ATRIBUTOS ESCONDIDOS
    -- ─────────────────────────────────────────────────────────────
    local function nomeDeObjetivo(nome)
        return contemAlgum(norm(nome), NOMES_VALOR) ~= nil
    end
    local function objetivosEscondidos()
        local achados = {}
        local raizes = { LocalPlayer, game:GetService("ReplicatedStorage"), workspace }
        local char = LocalPlayer.Character
        if char then table.insert(raizes, char) end
        local function olharAtributos(inst)
            for k, v in pairs(inst:GetAttributes()) do
                local nk = norm(k)
                local serve = (type(v) == "string" and v ~= "" and contemAlgum(nk, NOMES_VALOR))
                    or (type(v) == "number" and contemAlgum(nk, NOMES_NUMERO))
                if serve then
                    table.insert(achados, { texto=k .. ": " .. tostring(v), norm=norm(tostring(v)), pts=2, fonte="atributo" })
                end
            end
        end
        for _, raiz in ipairs(raizes) do
            pcall(olharAtributos, raiz)
            -- so os 3 primeiros niveis (valores de objetivo ficam perto da raiz)
            local function descer(inst, nivel)
                if nivel > 3 then return end
                for _, c in ipairs(inst:GetChildren()) do
                    if c:IsA("StringValue") and nomeDeObjetivo(c.Name) and c.Value ~= "" then
                        table.insert(achados, { texto=c.Value, norm=norm(c.Value), pts=4, fonte="valor " .. c.Name })
                    elseif (c:IsA("IntValue") or c:IsA("NumberValue")) and contemAlgum(norm(c.Name), NOMES_NUMERO) then
                        table.insert(achados, { texto=c.Name .. ": " .. tostring(c.Value), norm=norm(c.Name), pts=1, fonte="valor" })
                    elseif c:IsA("Folder") or c:IsA("Configuration") or c:IsA("ValueBase") then
                        descer(c, nivel + 1)
                    end
                end
            end
            pcall(descer, raiz, 1)
        end
        return achados
    end

    -- ─────────────────────────────────────────────────────────────
    --  TERMOS DE BUSCA A PARTIR DO OBJETIVO
    -- ─────────────────────────────────────────────────────────────
    local function termosDe(n)
        local termos, vistos = {}, {}
        local function add(t)
            if #t >= 3 and not vistos[t] then vistos[t] = true; table.insert(termos, t) end
        end
        local m = " " .. n .. " "
        for _, grupo in ipairs(DICIONARIO) do
            if contemAlgum(m, grupo.g) then
                for _, t in ipairs(grupo.b) do add(t) end
            end
        end
        for palavra in n:gmatch("%a+") do
            if #palavra >= 4 and not STOP[palavra] then
                add(palavra)
                if palavra:sub(-1) == "s" and #palavra > 4 then add(palavra:sub(1, -2)) end
                if palavra:sub(-2) == "es" and #palavra > 5 then add(palavra:sub(1, -3)) end
            end
        end
        return termos
    end

    local function procurar(termos, origem, limite)
        local res = {}
        if #termos == 0 then return res end
        for _, o in ipairs(RS.objs) do
            local inst = o.inst
            for _, t in ipairs(termos) do
                if string.find(o.nome, t, 1, true) then
                    if inst.Parent and not dePlayer(inst) then
                        local p = parteDe(inst)
                        if p then table.insert(res, { inst=inst, parte=p, nome=inst.Name, dist=(p.Position - origem).Magnitude }) end
                    end
                    break
                end
            end
        end
        table.sort(res, function(a, b) return a.dist < b.dist end)
        -- tira duplicados (peca dentro de modelo que ja entrou)
        local final, usados = {}, {}
        for _, r in ipairs(res) do
            local dup = false
            for u in pairs(usados) do
                if r.inst:IsDescendantOf(u) or u:IsDescendantOf(r.inst) then dup = true break end
            end
            if not dup then
                usados[r.inst] = true
                table.insert(final, r)
                if #final >= (limite or 6) then break end
            end
        end
        return final
    end

    -- ─────────────────────────────────────────────────────────────
    --  FONTES 3-6: GUIAS, INTERACOES, TRANCADOS, SAIDAS
    -- ─────────────────────────────────────────────────────────────
    local function guiasDoJogo(origem)
        local res = {}
        for g in pairs(RS.guias) do
            pcall(function()
                local alvo, nome
                if g:IsA("Beam") and g.Enabled and g.Attachment1 then
                    alvo = parteDe(g.Attachment1); nome = "Linha guia do jogo"
                elseif g:IsA("Highlight") and g.Enabled then
                    alvo = parteDe(g.Adornee or g.Parent); nome = (g.Adornee or g.Parent).Name
                elseif g:IsA("BillboardGui") and g.Enabled and g.AlwaysOnTop then
                    alvo = parteDe(g.Adornee or g.Parent)
                    local lbl = g:FindFirstChildWhichIsA("TextLabel", true)
                    nome = lbl and textoDe(lbl) ~= "" and textoDe(lbl) or (g.Adornee or g.Parent).Name
                end
                if alvo and alvo:IsDescendantOf(workspace) and not dePlayer(alvo) then
                    table.insert(res, { parte=alvo, nome=nome, dist=(alvo.Position - origem).Magnitude })
                end
            end)
        end
        table.sort(res, function(a, b) return a.dist < b.dist end)
        return res
    end

    local function interacoes(origem)
        local res = {}
        for p in pairs(RS.prompts) do
            pcall(function()
                if p.Enabled then
                    local alvo = parteDe(p.Parent)
                    if alvo and not dePlayer(alvo) then
                        local modelo = alvo:FindFirstAncestorOfClass("Model")
                        local nome = p.ObjectText ~= "" and p.ObjectText or (modelo and modelo ~= workspace and modelo.Name or alvo.Name)
                        local acao = p.ActionText ~= "" and p.ActionText or "Interagir"
                        table.insert(res, { parte=alvo, nome=nome, acao=acao, dist=(alvo.Position - origem).Magnitude,
                                            tecla=p.KeyboardKeyCode and p.KeyboardKeyCode.Name or "E" })
                    end
                end
            end)
        end
        table.sort(res, function(a, b) return a.dist < b.dist end)
        return res
    end

    local function trancado(inst)
        for _, k in ipairs({ "Locked","locked","IsLocked","Trancado","trancado","Lock" }) do
            local a = inst:GetAttribute(k)
            if a == true then return true end
            local v = inst:FindFirstChild(k)
            if v and v:IsA("BoolValue") and v.Value then return true end
        end
        return false
    end

    local function portasESaidas(origem)
        local trancadas, saidas = {}, {}
        for _, o in ipairs(RS.objs) do
            local inst = o.inst
            if inst:IsA("Model") or inst:IsA("BasePart") then
                local ehPorta = string.find(o.nome, "door", 1, true) or string.find(o.nome, "porta", 1, true)
                    or string.find(o.nome, "gate", 1, true) or string.find(o.nome, "portao", 1, true)
                if ehPorta and trancado(inst) then
                    local p = parteDe(inst)
                    if p then table.insert(trancadas, { parte=p, nome=inst.Name, dist=(p.Position - origem).Magnitude }) end
                end
                if contemAlgum(o.nome, SAIDAS) then
                    local p = parteDe(inst)
                    if p and p.Size.Magnitude < 200 then
                        table.insert(saidas, { parte=p, nome=inst.Name, dist=(p.Position - origem).Magnitude })
                    end
                end
            end
        end
        table.sort(trancadas, function(a, b) return a.dist < b.dist end)
        table.sort(saidas, function(a, b) return a.dist < b.dist end)
        return trancadas, saidas
    end

    -- ─────────────────────────────────────────────────────────────
    --  ANALISE: junta tudo numa lista de tarefas
    -- ─────────────────────────────────────────────────────────────
    local function m(d) return string.format("%.0f m", d) end

    local function analisar()
        local origem = minhaPosicao()
        local tarefas, rel = {}, {}
        local function tarefa(ico, txt, alvo, prio)
            table.insert(tarefas, { ico=ico, txt=txt, alvo=alvo, prio=prio })
            table.insert(rel, ico .. " " .. txt)
        end

        -- objetivos (tela + escondidos + busca manual)
        local objs = objetivosDaTela()
        for _, o in ipairs(objetivosEscondidos()) do table.insert(objs, o) end
        if RS.busca ~= "" then
            table.insert(objs, { texto="Busca manual: " .. RS.busca, norm=norm(RS.busca), pts=9, fonte="voce" })
        end
        table.sort(objs, function(a, b) return a.pts > b.pts end)

        -- aviso so quando o objetivo muda de verdade (ignora cronometro/numeros)
        local principal = objs[1]
        local chave = principal and principal.norm:gsub("%d", "") or ""
        if principal and chave ~= RS.ultimoObjetivo then
            RS.ultimoObjetivo = chave
            print("[GRINGO RESOLVER] Objetivo: " .. principal.texto)
            GS.toast("🧠  " .. principal.texto, true)
        end

        local usados = 0
        for _, o in ipairs(objs) do
            if usados >= 4 then break end
            usados = usados + 1
            local cont = (o.feito and o.total) and string.format("  [%d/%d]", o.feito, o.total) or ""
            local feito = o.feito and o.total and o.feito >= o.total
            tarefa(feito and "✅" or "📜", o.texto .. cont, nil, 1)
            local achados = procurar(termosDe(o.norm), origem, 5)
            for i, a in ipairs(achados) do
                tarefa("   🎯", a.nome .. "  —  " .. m(a.dist) .. (i == 1 and "  ← mais perto" or ""), a.parte, 2)
            end
            if #achados == 0 and not feito then
                tarefa("   ❔", "Nada com esse nome no mapa ainda (pode estar longe/nao carregado)", nil, 9)
            end
        end
        if #objs == 0 then
            tarefa("💡", "O jogo nao escreveu objetivo — sugestoes pelo que existe no mapa:", nil, 5)
        end

        -- guias do proprio jogo
        local guias = guiasDoJogo(origem)
        for i = 1, math.min(3, #guias) do
            tarefa("📍", "O jogo esta marcando: " .. guias[i].nome .. "  —  " .. m(guias[i].dist), guias[i].parte, 3)
        end

        -- portas trancadas + chave
        local trancadas, saidas = portasESaidas(origem)
        if #trancadas > 0 then
            local chaves = procurar({ "key","chave","card","cartao","keycard" }, origem, 1)
            local extra = chaves[1] and ("  →  tem 🔑 " .. chaves[1].nome .. " a " .. m(chaves[1].dist)) or ""
            tarefa("🔒", "Porta trancada: " .. trancadas[1].nome .. "  —  " .. m(trancadas[1].dist) .. extra, trancadas[1].parte, 4)
            if chaves[1] then tarefa("   🔑", "Pegue: " .. chaves[1].nome .. "  —  " .. m(chaves[1].dist), chaves[1].parte, 2) end
        end

        -- interacoes mais perto
        local inter = interacoes(origem)
        for i = 1, math.min(5, #inter) do
            local it = inter[i]
            tarefa("✋", "[" .. it.acao .. "] " .. it.nome .. "  (" .. it.tecla .. ")  —  " .. m(it.dist), it.parte, 5)
        end

        -- saidas
        for i = 1, math.min(2, #saidas) do
            tarefa("🚪", "Saida provavel: " .. saidas[i].nome .. "  —  " .. m(saidas[i].dist), saidas[i].parte, 6)
        end

        if #tarefas == 0 then tarefa("…", "Procurando... (anda um pouco pro jogo carregar o mapa)", nil, 9) end
        RS.tarefas = tarefas
        RS.relatorio = "=== GRINGO RESOLVER ===\n" .. table.concat(rel, "\n")
    end

    -- ─────────────────────────────────────────────────────────────
    --  JANELA NA TELA
    -- ─────────────────────────────────────────────────────────────
    local function criarHud()
        local sg = Instance.new("ScreenGui")
        sg.Name = "GringoResolver"; sg.ResetOnSpawn = false; sg.DisplayOrder = 96; sg.IgnoreGuiInset = true
        sg.Parent = GS.pai
        local f = Instance.new("Frame", sg)
        f.Size = UDim2.fromOffset(360, 300); f.Position = UDim2.new(0, 16, 0.5, -150)
        f.BackgroundColor3 = T.bg; f.BackgroundTransparency = 0.08; f.BorderSizePixel = 0; f.Active = true
        U.mkC(12, f); U.mkS(1, T.strokeHi, f)
        local topo = Instance.new("TextLabel", f)
        topo.Size = UDim2.new(1, -16, 0, 30); topo.Position = UDim2.new(0, 10, 0, 4)
        topo.BackgroundTransparency = 1; topo.Font = Enum.Font.GothamBlack; topo.TextSize = 14
        topo.TextColor3 = T.text; topo.TextXAlignment = Enum.TextXAlignment.Left; topo.Text = "🧠 RESOLVER"
        local sub = Instance.new("TextLabel", f)
        sub.Size = UDim2.new(1, -16, 0, 14); sub.Position = UDim2.new(0, 10, 0, 30)
        sub.BackgroundTransparency = 1; sub.Font = Enum.Font.Gotham; sub.TextSize = 10
        sub.TextColor3 = T.mute; sub.TextXAlignment = Enum.TextXAlignment.Left; sub.Text = "o que fazer agora"
        local lista = Instance.new("ScrollingFrame", f)
        lista.Size = UDim2.new(1, -16, 1, -54); lista.Position = UDim2.new(0, 8, 0, 48)
        lista.BackgroundTransparency = 1; lista.BorderSizePixel = 0; lista.ScrollBarThickness = 3
        lista.CanvasSize = UDim2.new(); lista.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local ll = Instance.new("UIListLayout", lista); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0, 3)
        -- arrastar pelo topo
        local arr, ini, pos
        f.InputBegan:Connect(function(i)
            if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch)
            and i.Position.Y - f.AbsolutePosition.Y < 46 then
                arr, ini, pos = true, i.Position, f.Position
                i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then arr = false end end)
            end
        end)
        table.insert(RS.conns, UserInputService.InputChanged:Connect(function(i)
            if arr and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ini
                f.Position = UDim2.new(pos.X.Scale, pos.X.Offset + d.X, pos.Y.Scale, pos.Y.Offset + d.Y)
            end
        end))
        RS.hud, RS.lista, RS.sub = sg, lista, sub
    end

    local linhasPool = {}
    local function desenharLista()
        if not RS.lista then return end
        for i, tf in ipairs(RS.tarefas) do
            local l = linhasPool[i]
            if not l or not l.Parent then
                l = Instance.new("TextLabel", RS.lista)
                l.Size = UDim2.new(1, -6, 0, 0); l.AutomaticSize = Enum.AutomaticSize.Y
                l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamMedium; l.TextSize = 12
                l.TextWrapped = true; l.TextXAlignment = Enum.TextXAlignment.Left
                linhasPool[i] = l
            end
            l.LayoutOrder = i; l.Visible = true
            l.Text = tf.ico .. " " .. tf.txt
            l.TextColor3 = tf.prio == 1 and T.text or (tf.prio <= 3 and Color3.fromRGB(255, 215, 90) or T.dim)
        end
        for i = #RS.tarefas + 1, #linhasPool do
            if linhasPool[i] then linhasPool[i].Visible = false end
        end
        RS.sub.Text = (RS.varrendo and "lendo o mapa...  " or "") .. "o que fazer agora  •  " .. #RS.objs .. " objetos lidos"
    end

    -- ─────────────────────────────────────────────────────────────
    --  MARCADORES NO ESP + SETA GUIA
    -- ─────────────────────────────────────────────────────────────
    local function limparMarcadores()
        for p, mk in pairs(RS.marcadores) do pcall(function() mk.gui:Destroy() end) RS.marcadores[p] = nil end
        if RS.beam then pcall(function() RS.beam:Destroy() end) RS.beam = nil end
        if RS.attEu then pcall(function() RS.attEu:Destroy() end) RS.attEu = nil end
        if RS.attAlvo then pcall(function() RS.attAlvo:Destroy() end) RS.attAlvo = nil end
    end

    local function atualizarMarcadores()
        local origem, meuRoot = minhaPosicao()
        local querer, principal = {}, nil
        if RS.marcar or RS.seta then
            local ordenadas = {}
            for _, tf in ipairs(RS.tarefas) do if tf.alvo then table.insert(ordenadas, tf) end end
            table.sort(ordenadas, function(a, b) return a.prio < b.prio end)
            principal = ordenadas[1]
            if RS.marcar then
                for i = 1, math.min(12, #ordenadas) do querer[ordenadas[i].alvo] = ordenadas[i] end
            end
        end
        for p, mk in pairs(RS.marcadores) do
            if not querer[p] or not p:IsDescendantOf(workspace) then
                pcall(function() mk.gui:Destroy() end); RS.marcadores[p] = nil
            end
        end
        for p, tf in pairs(querer) do
            local mk = RS.marcadores[p]
            if not mk then
                local g = Instance.new("BillboardGui")
                g.Name = "GringoResolverMarca"; g.AlwaysOnTop = true; g.Size = UDim2.fromOffset(200, 36)
                g.StudsOffset = Vector3.new(0, 3, 0); g.MaxDistance = math.huge; g.LightInfluence = 0; g.Adornee = p
                local bg = Instance.new("Frame", g)
                bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(40, 30, 0)
                bg.BackgroundTransparency = 0.25; bg.BorderSizePixel = 0
                Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)
                local s = Instance.new("UIStroke", bg); s.Color = Color3.fromRGB(255, 210, 60); s.Thickness = 1.5
                local l = Instance.new("TextLabel", bg)
                l.Size = UDim2.new(1, -8, 1, 0); l.Position = UDim2.new(0, 4, 0, 0); l.BackgroundTransparency = 1
                l.Font = Enum.Font.GothamBold; l.TextSize = 12; l.TextColor3 = Color3.fromRGB(255, 225, 120)
                l.TextWrapped = true; l.TextStrokeTransparency = 0.4
                g.Parent = RS.hud
                mk = { gui=g, lbl=l }
                RS.marcadores[p] = mk
            end
            mk.lbl.Text = "🎯 " .. (tf.txt:match("^(.-)%s+—") or tf.txt) .. "\n" .. m((p.Position - origem).Magnitude)
        end

        -- seta (Beam) do seu boneco ate o alvo principal
        if RS.seta and principal and meuRoot then
            if not RS.attEu or RS.attEu.Parent ~= meuRoot then
                if RS.attEu then RS.attEu:Destroy() end
                RS.attEu = Instance.new("Attachment"); RS.attEu.Name = "GringoResolverEu"; RS.attEu.Parent = meuRoot
            end
            if not RS.attAlvo or RS.attAlvo.Parent ~= principal.alvo then
                if RS.attAlvo then RS.attAlvo:Destroy() end
                RS.attAlvo = Instance.new("Attachment"); RS.attAlvo.Name = "GringoResolverAlvo"; RS.attAlvo.Parent = principal.alvo
            end
            if not RS.beam then
                local b = Instance.new("Beam")
                b.Name = "GringoResolverSeta"; b.FaceCamera = true; b.Width0 = 0.5; b.Width1 = 0.5
                b.Color = ColorSequence.new(Color3.fromRGB(255, 210, 60)); b.LightEmission = 1
                b.Transparency = NumberSequence.new(0.15); b.Segments = 20
                b.Parent = workspace.CurrentCamera
                RS.beam = b
            end
            RS.beam.Attachment0 = RS.attEu; RS.beam.Attachment1 = RS.attAlvo; RS.beam.Enabled = true
        elseif RS.beam then
            RS.beam.Enabled = false
        end
    end

    -- ─────────────────────────────────────────────────────────────
    --  LIGA / DESLIGA
    -- ─────────────────────────────────────────────────────────────
    local status

    local function desligar()
        for _, c in ipairs(RS.conns) do pcall(function() c:Disconnect() end) end
        RS.conns = {}
        limparMarcadores()
        if RS.hud then pcall(function() RS.hud:Destroy() end) end
        RS.hud, RS.lista = nil, nil
        linhasPool = {}
        RS.objs, RS.objsSet, RS.prompts, RS.guias, RS.tarefas = {}, {}, {}, {}, {}
        if status then status.Text = "🧠 DESLIGADO" end
    end

    local function ligar()
        criarHud()
        varrer()
        table.insert(RS.conns, workspace.DescendantAdded:Connect(function(o) pcall(indexar, o) end))
        RS.analiseT, RS.marcaT, RS.limpaT = 99, 0, 0
        table.insert(RS.conns, RunService.Heartbeat:Connect(function(dt)
            RS.analiseT = RS.analiseT + dt
            RS.marcaT = RS.marcaT + dt
            RS.limpaT = RS.limpaT + dt
            if RS.limpaT >= 10 then RS.limpaT = 0; pcall(limparIndice) end
            if RS.analiseT >= 1 then
                RS.analiseT = 0
                local ok, err = pcall(analisar)
                if not ok and not RS.avisou then RS.avisou = true warn("[GRINGO RESOLVER] " .. tostring(err)) end
                pcall(desenharLista)
                if status then
                    status.Text = "🧠 " .. (RS.tarefas[1] and (RS.tarefas[1].ico .. " " .. RS.tarefas[1].txt) or "procurando...")
                end
            end
            if RS.marcaT >= 0.25 then
                RS.marcaT = 0
                pcall(atualizarMarcadores)
            end
        end))
    end

    -- ─────────────────────────────────────────────────────────────
    --  PAINEL (ABA RESOLVER)
    -- ─────────────────────────────────────────────────────────────
    U.sec(painel, "RESOLVER — GUIA DE OBJETIVOS", "🧠", 1)
    local togR = U.tog(painel, "🧠 RESOLVER (MOSTRA O QUE FAZER)", 2)
    local togM = U.tog(painel, "🎯 MARCAR ALVOS NO ESP", 3)
    local togS = U.tog(painel, "➡ SETA GUIA ATÉ O ALVO", 4)
    for _, t in ipairs({ togR, togM, togS }) do t:SetAttribute("Controlado", true) end
    togM.Text = "MARCAR: ON"; togS.Text = "SETA: ON"
    local buscaBox = U.inp(painel, "🔎  Procurar algo específico (ex: chave, fusível)...", 5)
    local copiar = U.pequeno(painel, "📋 COPIAR RELATÓRIO (OU VER NO F9)", nil, 6)
    status = U.pequeno(painel, "🧠 DESLIGADO", nil, 7)
    status.AutoButtonColor = false; status.TextColor3 = T.dim; status.TextTruncate = Enum.TextTruncate.AtEnd

    togR.MouseButton1Click:Connect(function()
        RS.ativo = not RS.ativo
        togR.Text = RS.ativo and "RESOLVER: ON" or "RESOLVER: OFF"
        if RS.ativo then ligar() else desligar() end
    end)
    togM.MouseButton1Click:Connect(function()
        RS.marcar = not RS.marcar
        togM.Text = RS.marcar and "MARCAR: ON" or "MARCAR: OFF"
    end)
    togS.MouseButton1Click:Connect(function()
        RS.seta = not RS.seta
        togS.Text = RS.seta and "SETA: ON" or "SETA: OFF"
    end)
    buscaBox.FocusLost:Connect(function()
        RS.busca = norm(buscaBox.Text or "")
        RS.analiseT = 99
    end)
    copiar.MouseButton1Click:Connect(function()
        if RS.relatorio == "" then GS.toast("🧠  Liga o RESOLVER primeiro", false) return end
        print(RS.relatorio)
        if setclipboard then
            pcall(setclipboard, RS.relatorio)
            GS.toast("📋  Relatório copiado (também está no F9)", true)
        else
            GS.toast("📋  Relatório no F9 (seu executor não copia)", true)
        end
    end)
    ScreenGui.Destroying:Connect(desligar)
end
GS.rodar("Resolver", GS.iniciarResolver, GS.painelResolver)

-- ═══════════════════════════════════════════════════════════════
--   🛡 ANTI-SCRIPTS — PROTECAO CONTRA HACKERS (FLING / DERRUBAR / PUXAR)
-- ═══════════════════════════════════════════════════════════════
-- Seu boneco e simulado no SEU PC, entao da pra defender ele aqui:
--   1) ANTI-COLISAO: o corpo dos outros jogadores vira "fantasma" so
--      pra sua fisica (CanCollide=false local). Fling por colisao
--      (o hacker girando o boneco e encostando em voce) nao te pega.
--   2) ANTI-FLING: velocidade/rotacao absurda no seu boneco que voce
--      nao causou → volta pra ultima posicao segura e zera tudo.
--      Respeita suas funcoes (voo, super pulo, speed).
--   3) ANTI-DERRUBAR: estados de queda/ragdoll desligados; se cair,
--      levanta na hora e endireita o boneco.
--   4) ANTI-GRUDE: solda (Weld) ligando voce ao boneco/ferramenta de
--      outro jogador e destruida; banco de outro jogador te expulsa.
--   5) DETECTOR: jogador com rotacao/velocidade de fling perto de voce
--      ganha marca "⚠ SCRIPT" e aviso na tela.
-- Limite: dano/morte que o hacker causa abusando de eventos do
-- SERVIDOR do jogo nao passa pelo seu PC — isso nenhum cliente bloqueia.
-- ═══════════════════════════════════════════════════════════════
GS.iniciarAntiScript = function()
    local U = GS.ui
    if not U then return end
    local T = U.T
    local ZERO = Vector3.zero
    local ESTADOS = { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Physics }

    local A = { ativo=false, conns={}, mudados={}, seguro=nil, bloqueios=0, suspeitos={}, marcas={},
                detT=0, gruT=0, statusT=0, avisoT={} }

    -- ── UI (fim da aba PLAYER) ──
    U.sec(GS.painelPlayer, "ANTI-SCRIPTS (PROTEÇÃO CONTRA HACKERS)", "🛡", 50)
    local togA = U.tog(GS.painelPlayer, "🛡 ANTI-SCRIPTS (FLING, DERRUBAR, PUXAR)", 51)
    togA:SetAttribute("Controlado", true)
    local status = U.pequeno(GS.painelPlayer, "🛡 DESLIGADO", nil, 52)
    status.AutoButtonColor = false; status.TextColor3 = T.dim; status.TextTruncate = Enum.TextTruncate.AtEnd

    local function eu()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = hum and hum.RootPart
        return char, hum, root
    end

    -- ── 1) ANTI-COLISAO com os outros jogadores ──
    local function semColisaoComOutros()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                        A.mudados[part] = true
                    end
                end
            end
        end
    end

    -- ── 2) ANTI-FLING ──
    local function minhasFuncoesMexendo(hum)
        -- voo ligado, super pulo / queda (eixo Y livre), ou eu mesmo teleportando
        return flyAtivado == true
    end

    local function antiFling()
        local char, hum, root = eu()
        if not root or root.Anchored or flyAtivado or hum.Sit then return end
        local v, w = root.AssemblyLinearVelocity, root.AssemblyAngularVelocity
        local horiz = Vector3.new(v.X, 0, v.Z).Magnitude
        local limiteH = math.max(160, (velocidadeCustomizada or 16) * 2.5)
        local tombando = math.abs(w.X) > 12 or math.abs(w.Z) > 12
        local girando = w.Magnitude > 40
        local voando = horiz > limiteH and not minhasFuncoesMexendo(hum)
        if (tombando or girando or voando) then
            A.bloqueios = A.bloqueios + 1
            root.AssemblyAngularVelocity = ZERO
            root.AssemblyLinearVelocity = Vector3.new(0, math.min(v.Y, 0), 0)
            if A.seguro then
                local pos = A.seguro.Position
                local _, yaw, _ = root.CFrame:ToOrientation()
                root.CFrame = CFrame.new(pos) * CFrame.fromOrientation(0, yaw, 0)
            end
            local agora = os.clock()
            if not A.avisoT.fling or agora - A.avisoT.fling > 3 then
                A.avisoT.fling = agora
                GS.toast("🛡  Tentativa de fling bloqueada", true)
            end
        else
            -- guarda a ultima posicao segura (no chao, parado/andando normal)
            if hum.FloorMaterial ~= Enum.Material.Air and horiz < limiteH and w.Magnitude < 15 then
                A.seguro = root.CFrame
            end
        end
    end

    -- ── 3) ANTI-DERRUBAR ──
    local function antiDerrubar()
        local char, hum, root = eu()
        if not hum then return end
        for _, e in ipairs(ESTADOS) do
            if hum:GetStateEnabled(e) then hum:SetStateEnabled(e, false) end
        end
        if flyAtivado then return end
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Ragdoll
        or st == Enum.HumanoidStateType.Physics then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            A.bloqueios = A.bloqueios + 1
        end
        if hum.PlatformStand and not flyAtivado then hum.PlatformStand = false end
        -- endireita se estiver deitado
        if root and not hum.Sit then
            local up = root.CFrame.UpVector
            if up.Y < 0.6 and not flyAtivado then
                local _, yaw, _ = root.CFrame:ToOrientation()
                root.CFrame = CFrame.new(root.Position) * CFrame.fromOrientation(0, yaw, 0)
                root.AssemblyAngularVelocity = ZERO
            end
        end
    end

    -- ── 4) ANTI-GRUDE ──
    local function deOutroJogador(inst)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and inst:IsDescendantOf(p.Character) then return p end
        end
        return nil
    end
    local function antiGrude()
        local char, hum = eu()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                for _, j in ipairs(part:GetJoints()) do
                    local outro = (j.Part0 and not j.Part0:IsDescendantOf(char) and j.Part0)
                               or (j.Part1 and not j.Part1:IsDescendantOf(char) and j.Part1)
                    if outro and deOutroJogador(outro) then
                        pcall(function() j:Destroy() end)
                        A.bloqueios = A.bloqueios + 1
                        GS.toast("🛡  Solda de outro jogador destruída", true)
                    end
                end
            end
        end
        if hum and hum.Sit and hum.SeatPart and deOutroJogador(hum.SeatPart) then
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            A.bloqueios = A.bloqueios + 1
        end
    end

    -- ── 5) DETECTOR ──
    local function marcar(p)
        local m = A.marcas[p]
        local cab = p.Character and (p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart"))
        if not cab then return end
        if not m or not m.Parent then
            m = Instance.new("BillboardGui")
            m.Name = "GringoAntiScriptMarca"; m.AlwaysOnTop = true; m.Size = UDim2.fromOffset(140, 26)
            m.StudsOffset = Vector3.new(0, 3.5, 0); m.LightInfluence = 0
            local l = Instance.new("TextLabel", m)
            l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundColor3 = Color3.fromRGB(120, 0, 20)
            l.BackgroundTransparency = 0.2; l.Font = Enum.Font.GothamBlack; l.TextSize = 12
            l.TextColor3 = Color3.new(1, 1, 1); l.Text = "⚠ SCRIPT"
            Instance.new("UICorner", l).CornerRadius = UDim.new(0, 6)
            m.Parent = GS.pai
            A.marcas[p] = m
        end
        m.Adornee = cab
    end

    local function detectar()
        local _, _, root = eu()
        local agora = os.clock()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local w = r.AssemblyAngularVelocity.Magnitude
                    local v = r.AssemblyLinearVelocity.Magnitude
                    if w > 60 or v > 400 then
                        local perto = root and (r.Position - root.Position).Magnitude < 60
                        A.suspeitos[p] = agora
                        marcar(p)
                        if perto and (not A.avisoT[p] or agora - A.avisoT[p] > 8) then
                            A.avisoT[p] = agora
                            GS.toast("⚠  " .. p.DisplayName .. " está usando script de fling perto de você", false)
                        end
                    end
                end
            end
        end
        -- marca some 15s depois do ultimo sinal
        for p, t in pairs(A.suspeitos) do
            if agora - t > 15 or not p.Parent then
                A.suspeitos[p] = nil
                if A.marcas[p] then pcall(function() A.marcas[p]:Destroy() end) A.marcas[p] = nil end
            end
        end
    end

    -- ── LIGA / DESLIGA ──
    local function ligar()
        A.bloqueios = 0; A.seguro = nil
        table.insert(A.conns, RunService.Stepped:Connect(function()
            pcall(semColisaoComOutros)
            pcall(antiFling)
        end))
        table.insert(A.conns, RunService.Heartbeat:Connect(function(dt)
            pcall(antiFling)
            pcall(antiDerrubar)
            A.gruT = A.gruT + dt
            if A.gruT >= 0.3 then A.gruT = 0; pcall(antiGrude) end
            A.detT = A.detT + dt
            if A.detT >= 0.2 then A.detT = 0; pcall(detectar) end
            A.statusT = A.statusT + dt
            if A.statusT >= 0.5 then
                A.statusT = 0
                local nomes = {}
                for p in pairs(A.suspeitos) do table.insert(nomes, p.DisplayName) end
                local txt = "🛡 PROTEGIDO   •   BLOQUEIOS: " .. A.bloqueios
                if #nomes > 0 then txt = txt .. "   •   ⚠ SUSPEITOS: " .. table.concat(nomes, ", ") end
                status.Text = txt
            end
        end))
    end

    local function desligar()
        for _, c in ipairs(A.conns) do pcall(function() c:Disconnect() end) end
        A.conns = {}
        for part in pairs(A.mudados) do pcall(function() if part.Parent then part.CanCollide = true end end) end
        A.mudados = {}
        for p, m in pairs(A.marcas) do pcall(function() m:Destroy() end) end
        A.marcas, A.suspeitos = {}, {}
        local _, hum = eu()
        if hum and not ghostAtivado then
            for _, e in ipairs(ESTADOS) do pcall(function() hum:SetStateEnabled(e, true) end) end
        end
        status.Text = "🛡 DESLIGADO"
    end

    togA.MouseButton1Click:Connect(function()
        A.ativo = not A.ativo
        togA.Text = A.ativo and "ANTI-SCRIPTS: ON" or "ANTI-SCRIPTS: OFF"
        if A.ativo then ligar() else desligar() end
    end)
    ScreenGui.Destroying:Connect(desligar)
end
GS.painelPlayer = GS.painelProtecao or GS.painelPlayer  -- visual v6: monta na subaba certa
GS.rodar("AntiScript", GS.iniciarAntiScript)

-- ═══════════════════════════════════════════════════════════════
--   🚫 ANTI-ASSEDIO — PROTECAO CONTRA SCRIPT +18 / GRUDAR / MOSQUITO / TP
-- ═══════════════════════════════════════════════════════════════
-- O que esses scripts fazem: o hacker teleporta o PROPRIO boneco pra
-- colar em voce (atras, em cima, rodando em volta) frame a frame.
-- A posicao do boneco dele e decidida pelo PC dele — nenhum cliente
-- impede ele de ir ate voce. O que da pra fazer (e isto faz):
--   1) DETECTAR na hora, por comportamento:
--        • GRUDANDO: fica a menos de 4 studs de voce por >1.5s
--          (inclusive acompanhando voce andar);
--        • TELEPORTE ATE VOCE: pulou >40 studs num frame e caiu do seu lado;
--        • MOSQUITO: rodando rapido (>50 studs/s) a menos de 10 studs.
--   2) SUMIR COM ELE DA SUA TELA: corpo, roupa, acessorios e nome ficam
--      invisiveis SO pra voce (voce para de ver a nojeira), e o corpo
--      dele atravessa o seu (nao empurra, nao carrega).
--   3) FUGIR AUTOMATICO (opcional): te teleporta pra um chao seguro
--      longe dali — quebra script que gruda no "jogador mais perto".
--   4) BLOQUEAR: abre a tela oficial do Roblox pra bloquear o jogador.
-- Os OUTROS jogadores do servidor continuam vendo o que ele faz —
-- pra isso, alem de bloquear, use o Denunciar do proprio Roblox.
-- ═══════════════════════════════════════════════════════════════
GS.iniciarAntiAssedio = function()
    local U = GS.ui
    if not U or not GS.painelPlayer then return end
    local T = U.T
    local StarterGui = game:GetService("StarterGui")

    local AA = { ativo=false, fugir=false, conns={}, dados={}, ocultos={}, ultimaFuga=0,
                 statusT=0, reaplicaT=0, bloqueioPedido={} }

    -- ── UI (logo abaixo do ANTI-SCRIPTS) ──
    local togAA = U.tog(GS.painelPlayer, "🚫 ANTI-ASSÉDIO (+18, GRUDAR, MOSQUITO, TP)", 53)
    local togF  = U.tog(GS.painelPlayer, "🏃 FUGIR AUTOMÁTICO QUANDO GRUDAREM", 54)
    togAA:SetAttribute("Controlado", true); togF:SetAttribute("Controlado", true)
    local mostrarBtn = U.pequeno(GS.painelPlayer, "👁 MOSTRAR OS ESCONDIDOS DE NOVO", nil, 55)
    local status = U.pequeno(GS.painelPlayer, "🚫 DESLIGADO", nil, 56)
    status.AutoButtonColor = false; status.TextColor3 = T.dim; status.TextTruncate = Enum.TextTruncate.AtEnd

    local function meuRoot()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        return (hum and hum.RootPart) or (char and char:FindFirstChild("HumanoidRootPart")), char
    end

    -- ── Esconder / mostrar (so na sua tela) ──
    local function esconderChar(char, reg)
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then
                d.LocalTransparencyModifier = 1
                if d.CanCollide then d.CanCollide = false end
            elseif (d:IsA("Decal") or d:IsA("Texture")) and reg.decals[d] == nil then
                reg.decals[d] = d.Transparency; d.Transparency = 1
            elseif (d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Trail")
                 or d:IsA("Beam") or d:IsA("Sound")) and reg.outros[d] == nil then
                local prop = d:IsA("Sound") and "Volume" or "Enabled"
                reg.outros[d] = { prop=prop, val=d[prop] }
                d[prop] = d:IsA("Sound") and 0 or false
            end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and reg.nome == nil then
            reg.nome = hum.DisplayDistanceType
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
    end

    local function esconder(p, motivo)
        local reg = AA.ocultos[p]
        if not reg then
            reg = { decals={}, outros={}, motivo=motivo }
            AA.ocultos[p] = reg
            reg.conn = p.CharacterAdded:Connect(function(c)
                reg.decals, reg.outros, reg.nome = {}, {}, nil
                task.wait(0.3)
                pcall(esconderChar, c, reg)
            end)
            GS.toast("🚫  " .. p.DisplayName .. " " .. motivo .. " — sumiu da sua tela", false)
            print("[GRINGO ANTI-ASSEDIO] " .. p.DisplayName .. " (@" .. p.Name .. ", id " .. p.UserId .. "): " .. motivo)
            -- tela oficial de bloquear (1x por jogador)
            if not AA.bloqueioPedido[p] then
                AA.bloqueioPedido[p] = true
                pcall(function() StarterGui:SetCore("PromptBlockPlayer", p) end)
            end
        end
        if p.Character then pcall(esconderChar, p.Character, reg) end
    end

    local function mostrar(p)
        local reg = AA.ocultos[p]
        if not reg then return end
        AA.ocultos[p] = nil
        if reg.conn then reg.conn:Disconnect() end
        local char = p.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then pcall(function() d.LocalTransparencyModifier = 0 end) end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and reg.nome then pcall(function() hum.DisplayDistanceType = reg.nome end) end
        end
        for d, t in pairs(reg.decals) do pcall(function() d.Transparency = t end) end
        for d, o in pairs(reg.outros) do pcall(function() d[o.prop] = o.val end) end
    end

    -- ── Fuga: chao seguro longe dali ──
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local function fugir()
        local agora = os.clock()
        if agora - AA.ultimaFuga < 3 then return end
        local root, char = meuRoot()
        if not root or root.Anchored then return end
        local ignorar = { char, workspace.CurrentCamera }
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignorar, p.Character) end end
        rp.FilterDescendantsInstances = ignorar
        for _ = 1, 12 do
            local ang = math.random() * math.pi * 2
            local dist = 60 + math.random() * 90
            local p = root.Position + Vector3.new(math.cos(ang) * dist, 0, math.sin(ang) * dist)
            local hit = workspace:Raycast(p + Vector3.new(0, 30, 0), Vector3.new(0, -120, 0), rp)
            if hit then
                AA.ultimaFuga = agora
                root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 4, 0)) * (root.CFrame - root.Position)
                root.AssemblyLinearVelocity = Vector3.zero
                GS.toast("🏃  Fugiu pra longe", true)
                return
            end
        end
    end

    -- ── Deteccao por comportamento ──
    local amigos = {}
    local function ehAmigo(p)
        if amigos[p] == nil then
            amigos[p] = false
            task.spawn(function()
                local ok, sim = pcall(function() return p:IsFriendsWith(LocalPlayer.UserId) end)
                amigos[p] = ok and sim or false
            end)
        end
        return amigos[p]
    end

    local function analisar(dt)
        local root = meuRoot()
        if not root then return end
        local minha = root.Position
        local andei = AA.minhaUltima and (minha - AA.minhaUltima).Magnitude or 0
        AA.minhaUltima = minha
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d = AA.dados[p] or { perto=0, mosq=0, seguiu=0 }
                    AA.dados[p] = d
                    if d.root ~= r then d.root, d.ultima, d.nasceu = r, nil, os.clock() end
                    local pos = r.Position
                    local dist = (pos - minha).Magnitude
                    local motivo

                    if d.ultima and os.clock() - d.nasceu > 2 and (pos - d.ultima).Magnitude > 40 and dist < 8 then
                        motivo = "teleportou até você"
                    end
                    if dist < 4 then
                        d.perto = d.perto + dt
                        d.seguiu = d.seguiu + andei          -- quanto voce andou com ele colado
                    else
                        d.perto = math.max(0, d.perto - dt * 0.5)
                        if d.perto == 0 then d.seguiu = 0 end
                    end
                    -- grudar = colado E (te seguiu andando OU dentro do seu corpo); amigo so conta se entrar em voce
                    if d.perto > 1.5 and (d.seguiu > 6 or dist < 1.8) and (not ehAmigo(p) or dist < 1.8) then
                        motivo = motivo or "está grudando em você"
                    end
                    if dist < 10 and r.AssemblyLinearVelocity.Magnitude > 50 then
                        d.mosq = d.mosq + dt
                    else
                        d.mosq = math.max(0, d.mosq - dt * 0.5)
                    end
                    if d.mosq > 1 then motivo = motivo or "está voando em volta de você" end
                    d.ultima = pos

                    if motivo then
                        esconder(p, motivo)
                        if AA.fugir and dist < 10 then fugir() end
                        d.perto, d.mosq, d.seguiu = 0, 0, 0
                    end
                    -- ja escondido e continua colado → foge de novo
                    if AA.ocultos[p] and AA.fugir and dist < 4 then fugir() end
                end
            end
        end
        for p in pairs(AA.dados) do if not p.Parent then AA.dados[p] = nil end end
        for p in pairs(AA.ocultos) do if not p.Parent then mostrar(p) end end
    end

    -- ── Liga / desliga ──
    local function ligar()
        table.insert(AA.conns, RunService.Heartbeat:Connect(function(dt)
            pcall(analisar, dt)
            AA.reaplicaT = AA.reaplicaT + dt
            if AA.reaplicaT >= 0.5 then
                AA.reaplicaT = 0
                for p, reg in pairs(AA.ocultos) do
                    if p.Character then pcall(esconderChar, p.Character, reg) end
                end
            end
            AA.statusT = AA.statusT + dt
            if AA.statusT >= 0.5 then
                AA.statusT = 0
                local nomes = {}
                for p, reg in pairs(AA.ocultos) do table.insert(nomes, p.DisplayName) end
                status.Text = #nomes == 0 and "🚫 VIGIANDO   •   ninguém te incomodando"
                    or ("🚫 ESCONDIDOS: " .. table.concat(nomes, ", "))
            end
        end))
    end
    local function desligar()
        for _, c in ipairs(AA.conns) do pcall(function() c:Disconnect() end) end
        AA.conns = {}
        for p in pairs(AA.ocultos) do mostrar(p) end
        AA.dados = {}
        status.Text = "🚫 DESLIGADO"
    end

    togAA.MouseButton1Click:Connect(function()
        AA.ativo = not AA.ativo
        togAA.Text = AA.ativo and "ANTI-ASSÉDIO: ON" or "ANTI-ASSÉDIO: OFF"
        if AA.ativo then ligar() else desligar() end
    end)
    togF.MouseButton1Click:Connect(function()
        AA.fugir = not AA.fugir
        togF.Text = AA.fugir and "FUGIR: ON" or "FUGIR: OFF"
    end)
    mostrarBtn.MouseButton1Click:Connect(function()
        local n = 0
        for p in pairs(AA.ocultos) do mostrar(p); n = n + 1 end
        AA.dados = {}
        GS.toast("👁  " .. n .. " jogador(es) visível(is) de novo", true)
    end)
    ScreenGui.Destroying:Connect(desligar)
end
GS.painelPlayer = GS.painelProtecao or GS.painelPlayer  -- visual v6: monta na subaba certa
GS.rodar("AntiAssedio", GS.iniciarAntiAssedio)

-- ═══════════════════════════════════════════════════════════════
--   🧱 CHAO INVISIVEL — ANDA NO AR NA ALTURA EM QUE VOCE ESTA
-- ═══════════════════════════════════════════════════════════════
-- Uma plataforma que so existe no SEU PC fica embaixo dos seus pes.
-- Seu boneco e simulado no seu PC, entao ele pisa nela de verdade e a
-- posicao vai pro servidor: todo mundo te ve andando no ar, parado,
-- dancando, usando emote — tudo normal, como se fosse chao.
-- Como a altura funciona:
--   • Chao real MAIS ALTO que o nivel (subindo morro/escada): o nivel
--     acompanha o chao real — nunca te atrapalha.
--   • Chao real MAIS BAIXO (rampa, morro, beira de penhasco, telhado):
--     o nivel fica onde esta → voce continua andando reto no ar.
--     (opcao "DESCER DEGRAUS ANDANDO" libera so degrau de escada)
--   • Pulou: o chao fica, voce cai de volta nele.
--   • DESCER: segure Ctrl esquerdo (ou o botao ⬇ na tela).
--   • SUBIR: segure o botao ⬆ na tela, ou ligue "SUBIR AO PULAR"
--     (cada pulo vira um degrau no ar).
-- Opcoes: tamanho do chao, mostrar o chao (so voce ve), botoes ⬆⬇.
-- ═══════════════════════════════════════════════════════════════
GS.iniciarChao = function()
    local U = GS.ui
    if not U or not GS.painelPlayer then return end
    local T = U.T
    local VEL_SUBIDA = 18          -- studs/s segurando ⬆ / ⬇
    local ESPESSURA = 1

    local CH = { ativo=false, mostrar=false, pulando=false, degrau=false, tamanho=10, nivel=nil,
                 conns={}, plat=nil, sobe=false, desce=false, botoes=nil, statusT=0, picoY=nil }

    -- ── UI ──
    U.sec(GS.painelPlayer, "CHÃO INVISÍVEL (ANDA NO AR)", "🧱", 57)
    local togC = U.tog(GS.painelPlayer, "🧱 CHÃO INVISÍVEL", 58)
    local togD = U.tog(GS.painelPlayer, "⬆ SUBIR AO PULAR (CADA PULO = DEGRAU)", 59)
    local togV = U.tog(GS.painelPlayer, "👁 MOSTRAR O CHÃO (SÓ VOCÊ VÊ)", 60)
    for _, t in ipairs({ togC, togD, togV }) do t:SetAttribute("Controlado", true) end
    local menos, mais, valor = U.ctrl(GS.painelPlayer, "Tamanho do chão", 10, 61)
    local status = U.pequeno(GS.painelPlayer, "🧱 DESLIGADO", nil, 62)
    status.AutoButtonColor = false; status.TextColor3 = T.dim
    local togG = U.tog(GS.painelPlayer, "↘ DESCER DEGRAUS ANDANDO (ESCADA)", 63)
    togG:SetAttribute("Controlado", true)
    togG.MouseButton1Click:Connect(function()
        CH.seguirDegraus = not CH.seguirDegraus
        togG.Text = CH.seguirDegraus and "DEGRAUS: ON" or "DEGRAUS: OFF"
    end)

    local function mostrarTamanho() valor.Text = CH.tamanho .. " m" end
    mostrarTamanho()
    mais.MouseButton1Click:Connect(function() CH.tamanho = math.min(CH.tamanho + 2, 60); mostrarTamanho() end)
    menos.MouseButton1Click:Connect(function() CH.tamanho = math.max(CH.tamanho - 2, 4); mostrarTamanho() end)

    -- ── Utilidades ──
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude

    local function corpo()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = hum and hum.RootPart
        return char, hum, root
    end

    -- distancia do centro do root ate a sola do pe
    local function alturaPe(hum, root)
        if hum.RigType == Enum.HumanoidRigType.R6 then return root.Size.Y / 2 + 2 end
        return hum.HipHeight + root.Size.Y / 2
    end

    -- altura do chao REAL embaixo de voce (ignora o chao invisivel e jogadores)
    local function chaoReal(char, root)
        local ignorar = { char, workspace.CurrentCamera }
        if CH.plat then table.insert(ignorar, CH.plat) end
        rp.FilterDescendantsInstances = ignorar
        local hit = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rp)
        return hit and hit.Position.Y or nil
    end

    local function criarPlataforma()
        local p = Instance.new("Part")
        p.Name = "GringoChaoInvisivel"; p.Anchored = true; p.CanCollide = true; p.CanTouch = false
        p.CastShadow = false; p.Material = Enum.Material.ForceField
        p.Color = Color3.fromRGB(120, 200, 255); p.TopSurface = Enum.SurfaceType.Smooth
        p.Transparency = 1
        p.Parent = workspace
        CH.plat = p
    end

    -- ── Botoes ⬆ ⬇ na tela (PC e celular) ──
    local function criarBotoes()
        local sg = Instance.new("ScreenGui")
        sg.Name = "GringoChaoBotoes"; sg.ResetOnSpawn = false; sg.DisplayOrder = 95; sg.Parent = GS.pai
        local function botao(txt, y, campo)
            local b = Instance.new("TextButton", sg)
            b.Size = UDim2.fromOffset(54, 54); b.Position = UDim2.new(1, -74, 0.5, y)
            b.BackgroundColor3 = T.card; b.BackgroundTransparency = 0.15; b.Text = txt
            b.Font = Enum.Font.GothamBlack; b.TextSize = 22; b.TextColor3 = T.text; b.AutoButtonColor = false
            U.mkC(14, b); U.mkS(1, T.strokeHi, b)
            b.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    CH[campo] = true; b.BackgroundColor3 = T.on; b.TextColor3 = T.knobOn
                end
            end)
            b.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    CH[campo] = false; b.BackgroundColor3 = T.card; b.TextColor3 = T.text
                end
            end)
        end
        botao("⬆", -62, "sobe")
        botao("⬇", 6, "desce")
        CH.botoes = sg
    end

    -- ── Loop ──
    local function passo(dt)
        local char, hum, root = corpo()
        if not root or root.Anchored then
            if CH.plat then CH.plat.CFrame = CFrame.new(0, -1e5, 0) end
            return
        end
        local pe = alturaPe(hum, root)
        local pesY = root.Position.Y - pe
        if CH.nivel == nil then CH.nivel = pesY end

        -- chao real mais alto: o nivel acompanha (subir morro/escada nunca trava)
        local real = chaoReal(char, root)
        if real and real > CH.nivel - 0.05 and pesY >= real - 1 then CH.nivel = real end
        -- padrao: SEGURA A ALTURA sempre (rampa, morro, penhasco: voce nao desce).
        -- com "DESCER DEGRAUS ANDANDO" ligado: degrau de ate 1.5 m em cima do
        -- chao de verdade desce normal (escada); rampa/penhasco continua segurando
        if CH.seguirDegraus and real and real < CH.nivel and CH.nivel - real <= 1.5
        and not CH.picoY and hum.FloorMaterial ~= Enum.Material.Air
        and hum.FloorMaterial ~= Enum.Material.ForceField then   -- pisando no chao de VERDADE, nao no invisivel
            CH.nivel = real
        end

        -- descer / subir segurando
        local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and not UserInputService:GetFocusedTextBox()
        if ctrl or CH.desce then CH.nivel = CH.nivel - VEL_SUBIDA * dt end
        if CH.sobe then
            CH.nivel = CH.nivel + VEL_SUBIDA * dt
            if pesY < CH.nivel then
                root.CFrame = root.CFrame + Vector3.new(0, CH.nivel - pesY, 0)
            end
        end

        -- subir ao pular: no topo do pulo o nivel vira um degrau
        local vy = root.AssemblyLinearVelocity.Y
        if CH.degrau then
            if hum.FloorMaterial == Enum.Material.Air and vy > 2 then
                CH.picoY = math.max(CH.picoY or pesY, pesY)
            elseif CH.picoY and vy <= 0 then
                CH.nivel = math.max(CH.nivel, CH.picoY - 0.5)
                CH.picoY = nil
            end
        end

        -- nunca deixa o nivel abaixo do chao real (nao afunda no mapa)
        if real and CH.nivel < real then CH.nivel = real end

        -- plataforma embaixo dos pes, centrada em voce
        local plat = CH.plat
        plat.Size = Vector3.new(CH.tamanho, ESPESSURA, CH.tamanho)
        local temChaoRealPerto = real and math.abs(real - CH.nivel) < 0.3
        if temChaoRealPerto then
            -- em cima do chao de verdade: plataforma escondida logo abaixo (nao atrapalha nada)
            plat.CFrame = CFrame.new(root.Position.X, CH.nivel - ESPESSURA / 2 - 0.05, root.Position.Z)
        else
            plat.CFrame = CFrame.new(root.Position.X, CH.nivel - ESPESSURA / 2, root.Position.Z)
        end
        plat.Transparency = CH.mostrar and 0.6 or 1

        -- caiu abaixo do nivel sem querer (lag / empurrao): volta pra cima
        if pesY < CH.nivel - 2 and not (ctrl or CH.desce) then
            root.CFrame = root.CFrame + Vector3.new(0, CH.nivel - pesY, 0)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
        end

        CH.statusT = CH.statusT + dt
        if CH.statusT >= 0.25 then
            CH.statusT = 0
            local acima = real and (CH.nivel - real) or nil
            status.Text = acima and acima > 0.5
                and string.format("🧱 ANDANDO NO AR   •   %.0f m acima do chão real   •   Ctrl desce", acima)
                or "🧱 PRONTO   •   anda pra fora da beira que o chão aparece"
        end
    end

    local function desligar()
        for _, c in ipairs(CH.conns) do pcall(function() c:Disconnect() end) end
        CH.conns = {}
        if CH.plat then pcall(function() CH.plat:Destroy() end) CH.plat = nil end
        if CH.botoes then pcall(function() CH.botoes:Destroy() end) CH.botoes = nil end
        CH.nivel, CH.sobe, CH.desce, CH.picoY = nil, false, false, nil
        status.Text = "🧱 DESLIGADO"
    end

    local function ligar()
        criarPlataforma()
        criarBotoes()
        CH.nivel = nil
        table.insert(CH.conns, RunService.Heartbeat:Connect(function(dt)
            local ok, err = pcall(passo, dt)
            if not ok and not CH.avisou then CH.avisou = true warn("[GRINGO CHAO] " .. tostring(err)) end
        end))
        -- renasceu: recomeca na altura nova
        table.insert(CH.conns, LocalPlayer.CharacterAdded:Connect(function() CH.nivel = nil end))
    end

    togC.MouseButton1Click:Connect(function()
        CH.ativo = not CH.ativo
        togC.Text = CH.ativo and "CHÃO: ON" or "CHÃO: OFF"
        if CH.ativo then ligar() else desligar() end
    end)
    togD.MouseButton1Click:Connect(function()
        CH.degrau = not CH.degrau
        togD.Text = CH.degrau and "DEGRAU: ON" or "DEGRAU: OFF"
    end)
    togV.MouseButton1Click:Connect(function()
        CH.mostrar = not CH.mostrar
        togV.Text = CH.mostrar and "MOSTRAR: ON" or "MOSTRAR: OFF"
    end)
    ScreenGui.Destroying:Connect(desligar)
end
GS.painelPlayer = GS.painelMovimento or GS.painelPlayer  -- visual v6: monta na subaba certa
GS.rodar("Chao", GS.iniciarChao)
GS.painelPlayer = GS.painelPersonagem or GS.painelPlayer

-- ═══════════════════════════════════════════════════════════════
--   ⚔ AUTO TOQUE — AUTO PARRY (BOLA DE LAMINA / BLADE BALL E PARECIDOS)
-- ═══════════════════════════════════════════════════════════════
-- Como funciona:
--   1) ACHA A BOLA: pasta "Balls"/"Bolas" do workspace, ou peca com
--      nome de bola. Prioriza a bola de verdade (atributo realBall).
--   2) SABE SE E PRA VOCE: atributo "target" = seu nome, ou destaque
--      (Highlight) no seu boneco, ou a bola vindo direto na sua direcao.
--   3) MEDE A VELOCIDADE pela posicao frame a frame (funciona mesmo com
--      bola ancorada movida pelo servidor) e calcula o TEMPO ATE BATER.
--   4) TOCA na hora certa: tempo ate bater < antecedencia + seu ping.
--      Aperta a tecla do jogo (F) ou clica, igual voce faria.
--   5) MODO CLASH: bola muito perto e muito rapida (troca de toques
--      colada) → toca sem parar ate a bola sair.
-- ═══════════════════════════════════════════════════════════════
GS.iniciarAutoToque = function()
    local U = GS.ui
    local painel = GS.painelCombate
    if not U or not painel then return end
    local T = U.T
    local VIM
    pcall(function() VIM = game:GetService("VirtualInputManager") end)

    local AT = { ativo=false, modo="TECLA F", antecedencia=0.30, clash=true, conns={},
                 ultimoToque=0, rastros={}, statusT=0 }

    -- ── UI ──
    U.sec(painel, "AUTO TOQUE (BOLA DE LÂMINA)", "🔴", 20)
    local togAT = U.tog(painel, "🔴 AUTO TOQUE (PARRY AUTOMÁTICO)", 21)
    local togCl = U.tog(painel, "⚡ MODO CLASH (TOQUE RÁPIDO COLADO)", 22)
    togAT:SetAttribute("Controlado", true); togCl:SetAttribute("Controlado", true)
    togCl.Text = "CLASH: ON"
    local grade = Instance.new("Frame", painel)
    grade.Size = UDim2.new(1, 0, 0, 32); grade.BackgroundTransparency = 1; grade.LayoutOrder = 23
    do
        local gl = Instance.new("UIGridLayout", grade)
        gl.CellSize = UDim2.new(0.5, -4, 1, 0); gl.CellPadding = UDim2.new(0, 8, 0, 0)
        gl.SortOrder = Enum.SortOrder.LayoutOrder
    end
    local menos, mais, valor = U.ctrl(painel, "Antecedência (ms)", 300, 24)
    local status = U.pequeno(painel, "🔴 DESLIGADO", nil, 25)
    status.AutoButtonColor = false; status.TextColor3 = T.dim; status.TextTruncate = Enum.TextTruncate.AtEnd

    local botoesModo = {}
    local function pintar()
        for nome, b in pairs(botoesModo) do
            local sel = nome == AT.modo
            U.tw(b, { BackgroundColor3 = sel and T.on or T.card, TextColor3 = sel and T.knobOn or T.dim }, 0.15)
        end
    end
    for i, nome in ipairs({ "TECLA F", "CLIQUE" }) do
        local b = Instance.new("TextButton", grade)
        b.Text = nome; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.AutoButtonColor = false
        b.BackgroundColor3 = T.card; b.TextColor3 = T.dim; b.BorderSizePixel = 0; b.LayoutOrder = i
        U.mkC(8, b); U.mkS(1, T.stroke, b); U.press(b)
        b.MouseButton1Click:Connect(function() AT.modo = nome; pintar() end)
        botoesModo[nome] = b
    end
    pintar()
    local function mostrarAnt() valor.Text = math.floor(AT.antecedencia * 1000 + 0.5) .. "" end
    mostrarAnt()
    mais.MouseButton1Click:Connect(function() AT.antecedencia = math.min(AT.antecedencia + 0.02, 0.8); mostrarAnt() end)
    menos.MouseButton1Click:Connect(function() AT.antecedencia = math.max(AT.antecedencia - 0.02, 0.08); mostrarAnt() end)

    -- ── Apertar o botao do jogo ──
    local function tocar()
        if AT.modo == "CLIQUE" then
            if mouse1click then
                mouse1click()
            elseif VIM then
                local m = UserInputService:GetMouseLocation()
                VIM:SendMouseButtonEvent(m.X, m.Y, 0, true, game, 0)
                VIM:SendMouseButtonEvent(m.X, m.Y, 0, false, game, 0)
            end
        elseif VIM then
            VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        elseif keypress then
            keypress(0x46); keyrelease(0x46)
        end
    end

    -- ── Achar as bolas ──
    local function ehBola(p)
        if not p:IsA("BasePart") then return false end
        local n = string.lower(p.Name)
        return n:find("ball", 1, true) or n:find("bola", 1, true)
            or (p:IsA("Part") and p.Shape == Enum.PartType.Ball and p.Size.X >= 1.5)
    end
    local function bolas()
        local lista = {}
        local pasta = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("Bolas")
            or workspace:FindFirstChild("TrainingBalls")
        local fonte = pasta and pasta:GetChildren() or workspace:GetChildren()
        for _, o in ipairs(fonte) do
            if o:IsA("BasePart") and ehBola(o) then
                table.insert(lista, o)
            elseif o:IsA("Model") and ehBola(o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart") or o) then
                local p = o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")
                if p then table.insert(lista, p) end
            end
        end
        -- bola "de verdade" primeiro (alguns jogos tem bola visual falsa)
        table.sort(lista, function(a, b)
            return (a:GetAttribute("realBall") and 1 or 0) > (b:GetAttribute("realBall") and 1 or 0)
        end)
        return lista
    end

    local function souAlvo(bola, char, dirParaMim, vel)
        local alvo = bola:GetAttribute("target") or bola:GetAttribute("Target")
        if alvo ~= nil then
            return tostring(alvo) == LocalPlayer.Name or tostring(alvo) == LocalPlayer.DisplayName
        end
        if char:FindFirstChildOfClass("Highlight") then return true end
        -- sem pista do jogo: bola vindo direto em voce
        return vel.Magnitude > 5 and vel.Unit:Dot(dirParaMim) > 0.75
    end

    -- ── Loop ──
    local function passo(dt)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = hum and hum.RootPart
        if not root or hum.Health <= 0 then return end
        local agora = os.clock()
        local ping = 0
        pcall(function() ping = LocalPlayer:GetNetworkPing() end)

        local info = "sem bola"
        for _, bola in ipairs(bolas()) do
            local r = AT.rastros[bola]
            local pos = bola.Position
            local vel = bola.AssemblyLinearVelocity
            if r and dt > 0 then
                local medida = (pos - r.pos) / math.max(agora - r.t, 1e-3)
                if medida.Magnitude > vel.Magnitude then vel = medida end   -- bola ancorada/CFrame
            end
            AT.rastros[bola] = { pos=pos, t=agora }

            local ate = root.Position - pos
            local dist = ate.Magnitude
            local dirParaMim = dist > 0 and ate.Unit or Vector3.zero
            local rapidez = math.max(vel:Dot(dirParaMim), 0)     -- velocidade vindo em voce
            if souAlvo(bola, char, dirParaMim, vel) then
                local tempo = rapidez > 1 and (dist - 3) / rapidez or math.huge
                local limite = AT.antecedencia + ping
                info = string.format("🎯 PRA VOCÊ   •   %.0f st/s   •   %.2fs   •   ping %d ms", rapidez, tempo, ping * 1000)
                local clash = AT.clash and dist < 18 and rapidez > 80
                local podeTocar = agora - AT.ultimoToque > (clash and 0.05 or 0.25)
                if podeTocar and (tempo <= limite or dist < 8 or clash) then
                    AT.ultimoToque = agora
                    pcall(tocar)
                end
                break
            else
                info = string.format("bola em outro jogador   •   %.0f st/s   •   %.0f m", vel.Magnitude, dist)
            end
        end
        for b in pairs(AT.rastros) do if not b.Parent then AT.rastros[b] = nil end end

        AT.statusT = AT.statusT + dt
        if AT.statusT >= 0.15 then AT.statusT = 0; status.Text = "🔴 " .. info end
    end

    local function ligar()
        if not VIM and not mouse1click and not keypress then
            GS.toast("⚠  Seu executor não simula tecla/clique — o auto toque não consegue apertar", false)
        end
        table.insert(AT.conns, RunService.Heartbeat:Connect(function(dt)
            local ok, err = pcall(passo, dt)
            if not ok and not AT.avisou then AT.avisou = true warn("[GRINGO AUTO TOQUE] " .. tostring(err)) end
        end))
    end
    local function desligar()
        for _, c in ipairs(AT.conns) do pcall(function() c:Disconnect() end) end
        AT.conns, AT.rastros = {}, {}
        status.Text = "🔴 DESLIGADO"
    end

    togAT.MouseButton1Click:Connect(function()
        AT.ativo = not AT.ativo
        togAT.Text = AT.ativo and "AUTO TOQUE: ON" or "AUTO TOQUE: OFF"
        if AT.ativo then ligar() else desligar() end
    end)
    togCl.MouseButton1Click:Connect(function()
        AT.clash = not AT.clash
        togCl.Text = AT.clash and "CLASH: ON" or "CLASH: OFF"
    end)
    ScreenGui.Destroying:Connect(desligar)
end
do  -- visual v6: AUTO TOQUE monta na aba DUELO DA BOLA (a funcao le GS.painelCombate)
    local combate = GS.painelCombate
    GS.painelCombate = GS.painelBola or combate
    GS.rodar("Auto Toque", GS.iniciarAutoToque, GS.painelBola)
    GS.painelCombate = combate
end

-- ═══════════════════════════════════════════════════════════════
--   EMOTES — ABRE O PAINEL DE EMOTES (7yd7) PELO BOTAO DA ABA
-- ═══════════════════════════════════════════════════════════════
-- Clicou → baixa e roda o script de emotes (uma vez so). Se ele ja
-- estiver aberto, avisa em vez de abrir outro por cima.
do
    local URL_EMOTES = "https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"
    local carregando = false
    local function status(txt)
        if GS.emotesStatus then pcall(function() GS.emotesStatus.Text = txt end) end
    end
    local function falhou(txt, detalhe)
        carregando = false
        _G.EmotesGUIRunning = nil   -- deixa tentar de novo
        status(txt)
        warn("[Gringo] Emotes: " .. tostring(detalhe))
        GS.toast("Emotes: " .. string.lower(string.gsub(txt, "^STATUS: ", "")), false)
    end
    if GS.emotesBtn then
        GS.emotesBtn.MouseButton1Click:Connect(function()
            if carregando then return end
            if _G.EmotesGUIRunning then
                status("STATUS: JÁ ESTÁ ABERTO")
                GS.toast("Emotes já está aberto", true)
                return
            end
            if type(loadstring) ~= "function" then
                status("STATUS: SEU EXECUTOR NÃO TEM LOADSTRING")
                GS.toast("Seu executor não tem loadstring", false)
                return
            end
            carregando = true
            status("STATUS: BAIXANDO...")
            task.spawn(function()
                local ok, codigo = pcall(function() return game:HttpGet(URL_EMOTES) end)
                if not ok or type(codigo) ~= "string" or codigo == "" then
                    return falhou("STATUS: FALHOU AO BAIXAR (VEJA F9)", codigo)
                end
                local fn, erro = loadstring(codigo)
                if not fn then
                    return falhou("STATUS: ERRO NO SCRIPT (VEJA F9)", erro)
                end
                status("STATUS: ABRINDO...")
                local ok2, erro2 = pcall(fn)
                if not ok2 then
                    return falhou("STATUS: ERRO AO ABRIR (VEJA F9)", erro2)
                end
                carregando = false
                status("STATUS: CARREGADO")
                GS.toast("Emotes carregado", true)
            end)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
--   SILENT AIM v2 (BRUTAL) — ATIRA PRA QUALQUER LADO, A BALA VAI NO BOT
-- ═══════════════════════════════════════════════════════════════
-- Diferente do aimbot (que puxa a camera), aqui a mira NAO se mexe.
-- Pra saber onde a bala bate, a arma do jogo pergunta:
--   • Mouse.Hit / Mouse.Target / Mouse.UnitRay         (armas simples)
--   • Camera:ScreenPointToRay / ViewportPointToRay      (armas que montam o raio)
--   • workspace:Raycast / FindPartOnRay...              (armas com raio)
-- Os hooks respondem TODAS essas perguntas com o alvo, so quando quem
-- pergunta e o script do jogo (checkcaller). Camera e mira nao mudam.
-- MODO BRUTAL:
--   • Atravessa parede: o raio da arma so enxerga o bot alvo.
--   • Previsao: mira onde o bot VAI estar (velocidade x distancia).
--   • Auto atirar: atira sozinho enquanto tem bot no FOV.
--   • Hitbox gigante: cabeca/peito dos bots crescem (so no seu PC).
--   • Destaque + marcador no alvo travado.
-- Alvos:  e bots NPCs em qualquer jogo. JOGADORES 
-- 

-- Precisa do executor ter hookmetamethod + getnamecallmethod.
-- Os hooks so sao instalados na primeira vez que liga.
-- ═══════════════════════════════════════════════════════════════
-- MEUS_JOGOS: PlaceId dos SEUS jogos (os que voce criou/testa). So neles o
-- Silent Aim pode mirar em jogadores; no resto ele mira so em bots/NPCs.
-- (antes essa funcao nao existia e o Silent Aim nem montava)
GS.MEUS_JOGOS = {
    -- 1234567890,
}
GS.jogoLiberado = function()
    for _, id in ipairs(GS.MEUS_JOGOS) do
        if game.PlaceId == id then return true end
    end
    -- jogo criado pela sua propria conta tambem conta
    local ok, meu = pcall(function()
        return game.CreatorType == Enum.CreatorType.User and game.CreatorId == LocalPlayer.UserId
    end)
    return ok and meu == true
end

GS.iniciarSilentAim = function()
    local U = GS.ui
    local painel = GS.painelSilent
    if not U or not painel then
        error("UI nao pronta (GS.ui=" .. tostring(U ~= nil) .. ", GS.painelSilent=" .. tostring(painel ~= nil) .. ")")
    end
    local T = U.T
    local VIM
    pcall(function() VIM = game:GetService("VirtualInputManager") end)
    
    local S = { jogadores=false, liberado=GS.jogoLiberado(), ignorarTime=true,
                ativo=false, mostrarFov=true, fov=200, chance=100, parte="CABEÇA", prioridade="MIRA",
                parede=true, previsao=true, autoAtirar=false, cps=12, hitbox=false, tamHitbox=6,
                destaque=true, alvo=nil, acertar=true, proximoSorteio=0, proximoTiro=0,
                proximaHitbox=0, hooks=false, conns={}, hitboxOrig={},
                -- janela de tiro: so desvia raio enquanto voce atira (antes desviava
                -- TODO raio do jogo: camera e chao iam pro bot e a tela "voava")
                mouseBaixo=false, tiroAte=0, camLook=nil, raizPos=nil }
    GS.silent = S

    -- ── UI ──────────────────────────────────────────────────────
    local function seletor(pai, ord, nomes, campo, aoMudar)
        local grade = Instance.new("Frame", pai)
        grade.Size = UDim2.new(1, 0, 0, 34); grade.BackgroundTransparency = 1; grade.LayoutOrder = ord
        local gl = Instance.new("UIGridLayout", grade)
        gl.CellSize = UDim2.new(1 / #nomes, -math.ceil(10 * (#nomes - 1) / #nomes), 1, 0)
        gl.CellPadding = UDim2.new(0, 10, 0, 0); gl.SortOrder = Enum.SortOrder.LayoutOrder
        local botoes = {}
        local function pintar()
            for valor, b in pairs(botoes) do
                local sel = valor == S[campo]
                U.tw(b, { BackgroundColor3 = sel and T.on or T.card, TextColor3 = sel and T.knobOn or T.dim }, 0.15)
            end
        end
        for i, par in ipairs(nomes) do
            local b = Instance.new("TextButton", grade)
            b.Text = par[2]; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.AutoButtonColor = false
            b.BackgroundColor3 = T.card; b.TextColor3 = T.dim; b.BorderSizePixel = 0; b.LayoutOrder = i
            U.mkC(9, b); U.mkS(1, T.stroke, b); U.press(b)
            b.MouseButton1Click:Connect(function()
                S[campo] = par[1]; S.alvo = nil
                pintar()
                if aoMudar then aoMudar(par[2]) end
            end)
            botoes[par[1]] = b
        end
        pintar()
    end

    local g = U.grupo(painel, "Silent Aim", "Atira pra qualquer lado e a bala vai no bot · a mira não se mexe", "crosshair", 1)
    local togS = U.tog(g, "Silent Aim", 1, "crosshair")
    local togF = U.tog(g, "Mostrar círculo do FOV", 2, "circle-dot")
    local fovMenos, fovMais, fovLbl = U.ctrl(g, "FOV (raio na tela)", "200 px", 3)
    local chMenos, chMais, chLbl = U.ctrl(g, "Chance de acerto", "100%", 4)
    U.sec(g, "PARTE DO CORPO", nil, 5)
    seletor(g, 6, {{"CABEÇA","CABEÇA"}, {"PEITO","PEITO"}}, "parte",
        function(n) GS.toast("Silent Aim: mira no " .. string.lower(n), true) end)
    U.sec(g, "PRIORIDADE DO ALVO", nil, 7)
    seletor(g, 8, {{"MIRA","MAIS PERTO DA MIRA"}, {"PERTO","MAIS PERTO DE VOCÊ"}}, "prioridade",
        function(n) GS.toast("Silent Aim: " .. string.lower(n), true) end)
    U.sec(g, "ALVOS", nil, 9)
    local togJ = U.tog(g, "Mirar em jogadores (só nos seus jogos)", 10, "users")
    local togT = U.tog(g, "Ignorar quem é do seu time", 11, "shield")
    togJ:SetAttribute("Controlado", true)
    togT.Text = "TIME: ON"
    local status = U.pequeno(g, "STATUS: DESLIGADO", nil, 12)
    status.AutoButtonColor = false; status.TextColor3 = T.dim

    local gb = U.grupo(painel, "Modo brutal", "Atravessa parede, prevê movimento, atira sozinho", "flame", 2)
    local togP  = U.tog(gb, "Atravessar parede (wallbang)", 1, "scan-eye")
    local togPv = U.tog(gb, "Previsão de movimento", 2, "move-right")
    local togA  = U.tog(gb, "Auto atirar (bot no FOV = tiro)", 3, "mouse-pointer-click")
    local cpsMenos, cpsMais, cpsLbl = U.ctrl(gb, "Tiros por segundo", "12", 4)
    local togH  = U.tog(gb, "Hitbox gigante nos bots", 5, "maximize")
    local hbMenos, hbMais, hbLbl = U.ctrl(gb, "Tamanho da hitbox", "6", 6)
    local togD  = U.tog(gb, "Destacar alvo travado", 7, "target")
    local togCt = U.tog(gb, "Travar FOV no centro (não segue a seta)", 8, "anchor")
    togS:SetAttribute("Controlado", true)
    togF.Text = "FOV: ON"; togP.Text = "PAREDE: ON"; togPv.Text = "PREVISAO: ON"; togD.Text = "DESTAQUE: ON"
    togCt.Text = GS.fovCentro and "CENTRO: ON" or "CENTRO: OFF"
    -- vale pro FOV do Silent E do aimbot do Combate
    togCt.MouseButton1Click:Connect(function()
        GS.fovCentro = not GS.fovCentro
        togCt.Text = GS.fovCentro and "CENTRO: ON" or "CENTRO: OFF"
    end)

    -- ── Desenhos: circulo do FOV, marcador e destaque do alvo ──
    local circulo = Instance.new("Frame")
    circulo.Name = "GringoSilentFov"; circulo.AnchorPoint = Vector2.new(0.5, 0.5)
    circulo.BackgroundTransparency = 1; circulo.Visible = false; circulo.ZIndex = 0
    U.redondo(circulo)
    local circuloBorda = U.mkS(1.5, T.on, circulo, 0.25)
    circulo.Parent = ScreenGui
    local marcador = Instance.new("Frame")
    marcador.Name = "GringoSilentAlvo"; marcador.AnchorPoint = Vector2.new(0.5, 0.5)
    marcador.Size = UDim2.fromOffset(18, 18); marcador.BackgroundTransparency = 1; marcador.Visible = false
    U.redondo(marcador); U.mkS(2, T.on, marcador, 0)
    do
        local ponto = Instance.new("Frame", marcador)
        ponto.AnchorPoint = Vector2.new(0.5, 0.5); ponto.Position = UDim2.fromScale(0.5, 0.5)
        ponto.Size = UDim2.fromOffset(4, 4); ponto.BackgroundColor3 = T.on; ponto.BorderSizePixel = 0
        U.redondo(ponto)
    end
    marcador.Parent = ScreenGui
    local destaque = Instance.new("Highlight")
    destaque.Name = "GringoSilentDestaque"; destaque.FillColor = T.on; destaque.FillTransparency = 0.55
    destaque.OutlineColor = Color3.new(1, 1, 1); destaque.OutlineTransparency = 0
    destaque.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; destaque.Enabled = false
    destaque.Parent = ScreenGui

    -- ── Bots (Humanoid que NAO e de jogador) ────────────────────
    local bots = {}  -- [Humanoid] = true
    local function registrar(o) if o:IsA("Humanoid") then bots[o] = true end end
    local function ehBot(h)
        local m = h.Parent
        if not m or not m:IsA("Model") or not h:IsDescendantOf(workspace) then return false end
        if h.Health <= 0 or m == LocalPlayer.Character then return false end
        local plr = GS.donoDoModelo(m)   -- pega tambem boneco clonado com o nome do player
        if plr then
            if plr == LocalPlayer or GS.ehAmigo(plr) then return false end   -- amigo: nunca
            -- jogador: so com a opcao ligada E num jogo liberado
            if not (S.jogadores and S.liberado) then return false end
            if S.ignorarTime and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team then return false end
        end
        return true
    end
    local PARTES = {
        ["CABEÇA"] = {"Head", "UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart"},
        ["PEITO"]  = {"UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart", "Head"},
    }
    local function parteDe(m)
        for _, nome in ipairs(PARTES[S.parte]) do
            local p = m:FindFirstChild(nome)
            if p and p:IsA("BasePart") then return p end
        end
        return nil
    end
    local function pontoMira(cam)
        -- FOV travado (padrao): centro da tela. Destravado: segue a seta no PC
        return GS.pontoMira(cam)
    end
    local function minhaRaiz()
        local c = LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function escolherAlvo()
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local mira = pontoMira(cam)
        local raiz = minhaRaiz()
        local melhor, melhorNota = nil, math.huge
        for h in pairs(bots) do
            if not h.Parent then
                bots[h] = nil
            elseif ehBot(h) then
                local p = parteDe(h.Parent)
                if p then
                    local v, naTela = cam:WorldToViewportPoint(p.Position)
                    local dTela = (naTela and v.Z > 0) and (Vector2.new(v.X, v.Y) - mira).Magnitude or math.huge
                    if dTela <= S.fov then
                        local nota = dTela
                        if S.prioridade == "PERTO" and raiz then nota = (raiz.Position - p.Position).Magnitude end
                        if nota < melhorNota then melhor, melhorNota = p, nota end
                    end
                end
            end
        end
        return melhor
    end
    -- onde mirar: com previsao, adianta pela velocidade do bot
    local function posAlvo(origem)
        local p = S.alvo
        local pos = p.Position
        if S.previsao then
            local vel = p.AssemblyLinearVelocity
            local dist = origem and (pos - origem).Magnitude or 50
            pos = pos + vel * math.clamp(dist / 900, 0, 0.35)
        end
        return pos
    end

    -- ── Hitbox gigante (so local; devolve o tamanho original ao desligar) ──
    local function restaurarHitboxes()
        for parte, o in pairs(S.hitboxOrig) do
            pcall(function()
                parte.Size = o.Size; parte.Transparency = o.Transparency
                parte.CanCollide = o.CanCollide; parte.Massless = o.Massless
            end)
        end
        S.hitboxOrig = {}
    end
    local function aplicarHitboxes()
        local tam = Vector3.new(S.tamHitbox, S.tamHitbox, S.tamHitbox)
        for h in pairs(bots) do
            if h.Parent and ehBot(h) then
                local p = parteDe(h.Parent)
                if p then
                    if not S.hitboxOrig[p] then
                        S.hitboxOrig[p] = { Size = p.Size, Transparency = p.Transparency,
                                            CanCollide = p.CanCollide, Massless = p.Massless }
                    end
                    pcall(function()
                        if p.Size ~= tam then p.Size = tam end
                        p.Transparency = 0.6; p.CanCollide = false; p.Massless = true
                    end)
                end
            end
        end
        -- bot que morreu/sumiu: devolve
        for parte, o in pairs(S.hitboxOrig) do
            local m = parte.Parent
            local h = m and m:FindFirstChildOfClass("Humanoid")
            if not h or h.Health <= 0 then
                pcall(function()
                    parte.Size = o.Size; parte.Transparency = o.Transparency
                    parte.CanCollide = o.CanCollide; parte.Massless = o.Massless
                end)
                S.hitboxOrig[parte] = nil
            end
        end
    end

    -- ── Hooks ───────────────────────────────────────────────────
    local nc = newcclosure or function(f) return f end
    local doJogo = function() return not (checkcaller and checkcaller()) end
    local function pronto()
        local p = S.alvo
        return S.ativo and S.acertar and p ~= nil and p.Parent ~= nil
            and (S.mouseBaixo or (GS.relogioReal or os.clock)() < S.tiroAte)   -- so na hora do tiro
            -- (relogio REAL: o hook roda no lugar do jogo, e o relogio turbo da
            -- Velocidade adianta o os.clock pros scripts de arma)
    end
    -- O raio parece de BALA? Raio de chao (curto, pra baixo) e de camera
    -- (da cabeca pra tras, ate a camera) nao passam: eram eles que bugavam.
    local function pareceTiro(origem, dir)
        local mag = dir.Magnitude
        if mag < 8 then return false end
        local u = dir / mag
        -- quase reto pra baixo saindo do seu boneco = checagem de chao, nunca bala
        if u.Y < -0.85 and S.raizPos and (origem - S.raizPos).Magnitude < 8 then return false end
        local look = S.camLook
        if not look then return true end
        local d = u:Dot(look)
        if d > 0.35 then return true end   -- pra frente, pra onde voce olha
        -- jogo de cima (camera olhando pra baixo): sai do seu boneco, quase reto
        if d > -0.2 and u.Y > -0.6 and S.raizPos and (origem - S.raizPos).Magnitude < 15 then return true end
        return false
    end
    local function direcao(origem, tamanhoOriginal)
        local alvoPos = posAlvo(origem)
        local dist = (alvoPos - origem).Magnitude
        return (alvoPos - origem).Unit * math.max(tamanhoOriginal, dist + 5)
    end
    local function paramsSoAlvo()
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Include
        rp.FilterDescendantsInstances = { S.alvo.Parent }
        return rp
    end
    local METODOS_RAY = { FindPartOnRay = true, FindPartOnRayWithIgnoreList = true, FindPartOnRayWithWhitelist = true }
    local METODOS_CAMERA = { ScreenPointToRay = true, ViewportPointToRay = true }
    local velhoNamecall, velhoIndex
    local mouse = LocalPlayer:GetMouse()

    local function instalarHooks()
        if S.hooks then return true end
        if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then return false end
        local ok = pcall(function()
            velhoNamecall = hookmetamethod(game, "__namecall", nc(function(self, ...)
                if pronto() and doJogo() and (self == workspace or self == workspace.CurrentCamera) then
                    local metodo = getnamecallmethod()
                    if self == workspace then
                        if metodo == "Raycast" then
                            local args = table.pack(...)
                            if typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3"
                                and pareceTiro(args[1], args[2]) then
                                args[2] = direcao(args[1], args[2].Magnitude)
                                if S.parede then args[3] = paramsSoAlvo() end
                                return velhoNamecall(self, table.unpack(args, 1, math.max(args.n, 3)))
                            end
                        elseif METODOS_RAY[metodo] then
                            local args = table.pack(...)
                            if typeof(args[1]) == "Ray" and pareceTiro(args[1].Origin, args[1].Direction) then
                                local r = args[1]
                                local raio = Ray.new(r.Origin, direcao(r.Origin, r.Direction.Magnitude))
                                if S.parede then
                                    return workspace.FindPartOnRayWithWhitelist(workspace, raio, { S.alvo.Parent })
                                end
                                args[1] = raio
                                return velhoNamecall(self, table.unpack(args, 1, args.n))
                            end
                        elseif metodo == "Blockcast" then
                            -- Blockcast(cframe, size, direction, params): jogos novos de tiro
                            local args = table.pack(...)
                            if typeof(args[1]) == "CFrame" and typeof(args[3]) == "Vector3"
                                and pareceTiro(args[1].Position, args[3]) then
                                local origem = args[1].Position
                                args[3] = direcao(origem, args[3].Magnitude)
                                if S.parede then args[4] = paramsSoAlvo() end
                                return velhoNamecall(self, table.unpack(args, 1, math.max(args.n, 4)))
                            end
                        elseif metodo == "Spherecast" then
                            -- Spherecast(origin, radius, direction, params)
                            local args = table.pack(...)
                            if typeof(args[1]) == "Vector3" and typeof(args[3]) == "Vector3"
                                and pareceTiro(args[1], args[3]) then
                                args[3] = direcao(args[1], args[3].Magnitude)
                                if S.parede then args[4] = paramsSoAlvo() end
                                return velhoNamecall(self, table.unpack(args, 1, math.max(args.n, 4)))
                            end
                        end
                    elseif METODOS_CAMERA[metodo] then
                        local origem = self.CFrame.Position
                        return Ray.new(origem, (posAlvo(origem) - origem).Unit)
                    end
                end
                return velhoNamecall(self, ...)
            end))
            velhoIndex = hookmetamethod(game, "__index", nc(function(self, chave)
                if self == mouse and (chave == "Hit" or chave == "Target" or chave == "UnitRay")
                    and doJogo() and pronto() then
                    if chave == "Target" then return S.alvo end
                    local cam = workspace.CurrentCamera
                    local origem = cam and cam.CFrame.Position or S.alvo.Position
                    local pos = posAlvo(origem)
                    if chave == "Hit" then return CFrame.new(pos) end
                    return Ray.new(origem, (pos - origem).Unit)
                end
                return velhoIndex(self, chave)
            end))
        end)
        S.hooks = ok and velhoNamecall ~= nil and velhoIndex ~= nil
        return S.hooks
    end
    local function removerHooks()
        if not S.hooks then return end
        pcall(function() hookmetamethod(game, "__namecall", velhoNamecall) end)
        pcall(function() hookmetamethod(game, "__index", velhoIndex) end)
        S.hooks = false
    end

    -- ── Auto atirar ─────────────────────────────────────────────
    local function mouseEmCimaDoPainel(pos)
        if not MainFrame or not MainFrame.Visible then return false end
        local a, t = MainFrame.AbsolutePosition, MainFrame.AbsoluteSize
        local x, y = pos.X, pos.Y   -- ScreenGui ignora o inset: mesma coordenada do mouse
        return x >= a.X and x <= a.X + t.X and y >= a.Y and y <= a.Y + t.Y
    end
    local function atirar(cam)
        local pos = pontoMira(cam)
        -- mouse1press/click clicam onde a SETA esta; o VIM clica no ponto da mira
        local seta = UserInputService.MouseEnabled and UserInputService:GetMouseLocation() or pos
        if UserInputService:GetFocusedTextBox() then return end
        if mouse1press and mouse1release then
            if mouseEmCimaDoPainel(seta) then return end
            S.tiroAte = os.clock() + 0.3
            mouse1press(); task.delay(0.03, function() pcall(mouse1release) end)
        elseif mouse1click then
            if mouseEmCimaDoPainel(seta) then return end
            S.tiroAte = os.clock() + 0.3
            mouse1click()
        elseif VIM then
            if mouseEmCimaDoPainel(pos) then return end
            S.tiroAte = os.clock() + 0.3
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            task.delay(0.03, function() pcall(function() VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0) end) end)
        end
    end

    -- ── Loop (so roda ligado) ───────────────────────────────────
    local ultimoStatus = ""
    local function setStatus(txt)
        if txt ~= ultimoStatus then ultimoStatus = txt; status.Text = txt end
    end
    local function passo()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local agora = os.clock()
        -- guardado aqui pros hooks (dentro do hook nao da pra ficar lendo a camera)
        S.camLook = cam.CFrame.LookVector
        local raiz = minhaRaiz()
        S.raizPos = raiz and raiz.Position or nil
        if S.hitbox and agora >= S.proximaHitbox then
            S.proximaHitbox = agora + 0.5
            aplicarHitboxes()
        end
        S.alvo = escolherAlvo()
        if agora >= S.proximoSorteio then
            S.acertar = math.random(1, 100) <= S.chance
            S.proximoSorteio = agora + 0.25
        end
        local mira = pontoMira(cam)
        if S.mostrarFov and S.fov < 1000 then
            circulo.Position = UDim2.fromOffset(mira.X, mira.Y)
            circulo.Size = UDim2.fromOffset(S.fov * 2, S.fov * 2)
            circuloBorda.Color = S.alvo and T.on or T.mute
            circulo.Visible = true
        else
            circulo.Visible = false
        end
        if S.alvo then
            local v, naTela = cam:WorldToViewportPoint(S.alvo.Position)
            marcador.Visible = S.destaque and naTela and v.Z > 0
            marcador.Position = UDim2.fromOffset(v.X, v.Y)
            destaque.Adornee = S.alvo.Parent
            destaque.Enabled = S.destaque
            local dist = raiz and math.floor((raiz.Position - S.alvo.Position).Magnitude) or 0
            setStatus("STATUS: TRAVADO EM " .. string.upper(S.alvo.Parent.Name) .. " (" .. dist .. " M)")
            if S.autoAtirar and S.acertar and agora >= S.proximoTiro then
                S.proximoTiro = agora + 1 / S.cps
                atirar(cam)
            end
        else
            marcador.Visible = false
            destaque.Enabled = false; destaque.Adornee = nil
            setStatus(S.jogadores and "STATUS: NENHUM ALVO NO FOV" or "STATUS: NENHUM BOT NO FOV")
        end
    end
    local function ligar()
        if not instalarHooks() then
            togS.Text = "EXECUTOR SEM HOOKMETAMETHOD"
            setStatus("STATUS: SEU EXECUTOR NÃO SUPORTA SILENT AIM")
            status.TextColor3 = T.off or Color3.fromRGB(255, 80, 80)
            GS.toast("Executor sem hookmetamethod", false)
            return
        end
        bots = {}
        local nAlvos = 0
        for _, o in ipairs(workspace:GetDescendants()) do
            registrar(o)
            if o:IsA("Humanoid") then nAlvos = nAlvos + 1 end
        end
        table.insert(S.conns, workspace.DescendantAdded:Connect(registrar))
        table.insert(S.conns, RunService.RenderStepped:Connect(function() pcall(passo) end))
        -- janela de tiro: clique (PC) ou toque (celular). Fica aberta um
        -- pouquinho depois de soltar, pra bala que sai no soltar do botao
        local function ehTiro(io)
            local t = io.UserInputType
            return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
        end
        table.insert(S.conns, UserInputService.InputBegan:Connect(function(io)
            if ehTiro(io) then S.mouseBaixo = true; S.tiroAte = os.clock() + 0.4 end
        end))
        table.insert(S.conns, UserInputService.InputEnded:Connect(function(io)
            if ehTiro(io) then S.mouseBaixo = false; S.tiroAte = os.clock() + 0.25 end
        end))
        S.mouseBaixo = false
        S.ativo = true
        togS.Text = "SILENT AIM: ON"
        GS.toast("Silent Aim ON · " .. nAlvos .. " alvos", true)
    end
    local function desligar()
        S.ativo = false; S.alvo = nil
        for _, c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end
        S.conns = {}
        bots = {}
        restaurarHitboxes()
        circulo.Visible = false; marcador.Visible = false
        destaque.Enabled = false; destaque.Adornee = nil
        togS.Text = "SILENT AIM: OFF"
        status.TextColor3 = T.dim
        setStatus("STATUS: DESLIGADO")
        GS.toast("Silent Aim desligado", false)
    end

    -- ── Cliques ─────────────────────────────────────────────────
    local function chave(btn, campo, nome, aoMudar)
        btn.MouseButton1Click:Connect(function()
            S[campo] = not S[campo]
            btn.Text = nome .. (S[campo] and ": ON" or ": OFF")
            if aoMudar then aoMudar(S[campo]) end
        end)
    end
    togS.MouseButton1Click:Connect(function()
        if S.ativo then desligar() else ligar() end
    end)
    togJ.MouseButton1Click:Connect(function()
        if not S.liberado then
            S.jogadores = false
            togJ.Text = "SÓ FUNCIONA NOS SEUS JOGOS (VEJA MEUS_JOGOS)"
            GS.toast("Mirar em jogador: só nos seus jogos", false)
            return
        end
        S.jogadores = not S.jogadores; S.alvo = nil
        togJ.Text = S.jogadores and "JOGADORES: ON" or "JOGADORES: OFF"
        if not S.jogadores then restaurarHitboxes() end
    end)
    chave(togT, "ignorarTime", "TIME")
    chave(togF, "mostrarFov", "FOV", function(v) if not v then circulo.Visible = false end end)
    chave(togP, "parede", "PAREDE")
    chave(togPv, "previsao", "PREVISAO")
    chave(togA, "autoAtirar", "AUTO ATIRAR", function(v)
        if v and not (mouse1press or mouse1click or VIM) then
            GS.toast("Seu executor não simula clique — o auto atirar não funciona", false)
        end
    end)
    chave(togH, "hitbox", "HITBOX", function(v) if not v then restaurarHitboxes() else S.proximaHitbox = 0 end end)
    chave(togD, "destaque", "DESTAQUE", function(v)
        if not v then marcador.Visible = false; destaque.Enabled = false end
    end)

    local function atualizarFov()
        fovLbl.Text = S.fov >= 1000 and "TELA TODA" or (S.fov .. " px")
    end
    fovMenos.MouseButton1Click:Connect(function()
        S.fov = S.fov >= 1000 and 600 or math.max(50, S.fov - 25); atualizarFov()
    end)
    fovMais.MouseButton1Click:Connect(function()
        S.fov = S.fov >= 600 and 1000 or math.min(600, S.fov + 25); atualizarFov()
    end)
    chMenos.MouseButton1Click:Connect(function() S.chance = math.max(10, S.chance - 10); chLbl.Text = S.chance .. "%" end)
    chMais.MouseButton1Click:Connect(function() S.chance = math.min(100, S.chance + 10); chLbl.Text = S.chance .. "%" end)
    cpsMenos.MouseButton1Click:Connect(function() S.cps = math.max(2, S.cps - 2); cpsLbl.Text = tostring(S.cps) end)
    cpsMais.MouseButton1Click:Connect(function() S.cps = math.min(30, S.cps + 2); cpsLbl.Text = tostring(S.cps) end)
    local function atualizarHitbox()
        hbLbl.Text = tostring(S.tamHitbox)
        if S.hitbox then S.proximaHitbox = 0 end
    end
    hbMenos.MouseButton1Click:Connect(function() S.tamHitbox = math.max(3, S.tamHitbox - 1); atualizarHitbox() end)
    hbMais.MouseButton1Click:Connect(function() S.tamHitbox = math.min(20, S.tamHitbox + 1); atualizarHitbox() end)

    ScreenGui.Destroying:Connect(function()
        desligar()
        removerHooks()
        pcall(function() destaque:Destroy() end)
    end)
end
GS.rodar("Silent Aim", GS.iniciarSilentAim, GS.painelSilent)

-- ═══════════════════════════════════════════════════════════════
--   NO RECOIL (BRUTAL) — aba COMBATE > NO RECOIL
-- ═══════════════════════════════════════════════════════════════
--   Tres camadas juntas:
--   1) CAMERA: enquanto voce segura o tiro, todo giro da camera que NAO
--      veio do seu mouse (o coice) e desfeito no mesmo frame. Roda no
--      RenderStepped E no fim do render: pega arma que aplica antes ou depois.
--   2) ARMA: varre a memoria do jogo (getgc) e as Tools (Values e
--      atributos) atras de config de coice (Recoil, CameraShake, Sway...)
--      e zera. Guarda o original e devolve tudo ao desligar.
--   3) SPREAD: mesma varredura pra Spread/Bloom/Inaccuracy (bala reta).
--   Nunca zera tempo/velocidade/massa/recuperacao (divisao por zero no
--   script da arma deixaria a camera NaN) e nunca entra em objeto com
--   metatable (mola/spring) — so em tabela de config pura.
-- ═══════════════════════════════════════════════════════════════
GS.iniciarNoRecoil = function()
    local U = GS.ui
    local painel = GS.painelRecoil
    if not U or not painel then
        error("UI nao pronta (GS.ui=" .. tostring(U ~= nil) .. ", GS.painelRecoil=" .. tostring(painel ~= nil) .. ")")
    end
    local T = U.T

    -- campos sem recoil/shake/spread no nome (a varredura nao pode se achar)
    local R = { ativo=false, camera=true, arma=true, bala=true, forca=100,
                conns={}, backup={}, backupInst={}, nZerados=0, segurados=0,
                pitch=nil, yaw=nil, varrendo=false, geracao=0, loopId=0 }
    GS.norecoil = R
    -- tabelas do proprio script: a varredura nunca mexe nelas
    local nossas = setmetatable({}, { __mode = "k" })
    local cache = {}   -- [nome da chave] = combina? (mesmos nomes repetem muito)
    nossas[nossas] = true; nossas[R] = true; nossas[R.backup] = true
    nossas[R.backupInst] = true; nossas[cache] = true

    -- ── UI ──────────────────────────────────────────────────────
    local g = U.grupo(painel, "No Recoil", "Segura o tiro e a mira não sobe nem treme", "crosshair", 1)
    local togR = U.tog(g, "No Recoil", 1, "crosshair")
    local forMenos, forMais, forLbl = U.ctrl(g, "Força (quanto do coice ele segura)", "100%", 2)
    local status = U.pequeno(g, "STATUS: DESLIGADO", nil, 3)
    status.AutoButtonColor = false; status.TextColor3 = T.dim

    local gb = U.grupo(painel, "Modo brutal", "Câmera + arma + spread juntos", "flame", 2)
    local togC = U.tog(gb, "Segurar a câmera (PC)", 1, "anchor")
    local togA = U.tog(gb, "Zerar coice da arma (config)", 2, "wrench")
    local togB = U.tog(gb, "Zerar spread (bala reta)", 3, "target")
    togR:SetAttribute("Controlado", true)
    togC.Text = "CAMERA: ON"; togA.Text = "ARMA: ON"; togB.Text = "SPREAD: ON"

    local ultimoStatus = ""
    local function setStatus(txt)
        if txt ~= ultimoStatus then ultimoStatus = txt; status.Text = txt end
    end

    -- ── Quais chaves zerar ──────────────────────────────────────
    local COICE  = { "recoil", "camerakick", "camkick", "gunkick", "viewkick", "kickback", "shake", "sway" }
    local EXATAS = { anglex_min=true, anglex_max=true, angley_min=true, angley_max=true,
                     anglez_min=true, anglez_max=true }   -- FE Gun Kit: angulos do coice
    local BALA   = { "spread", "bloom", "inaccura", "deviation" }
    local NUNCA  = { "recover", "return", "time", "speed", "duration", "delay", "damp", "decay",
                     "reset", "cooldown", "reduction", "rate", "fade", "smooth", "freq", "mass",
                     "stiff", "tension", "friction", "weight", "gravity", "constant" }
    nossas[COICE] = true; nossas[EXATAS] = true; nossas[BALA] = true; nossas[NUNCA] = true

    local function proibida(lk)
        for _, p in ipairs(NUNCA) do
            if string.find(lk, p, 1, true) then return true end
        end
        return false
    end
    local function combina(k)
        local c = cache[k]
        if c ~= nil then return c end
        local lk = string.lower(k)
        local sim = false
        if R.arma then
            if EXATAS[lk] then sim = true end
            if not sim then
                for _, p in ipairs(COICE) do
                    if string.find(lk, p, 1, true) then sim = true; break end
                end
            end
        end
        if not sim and R.bala then
            for _, p in ipairs(BALA) do
                if string.find(lk, p, 1, true) then sim = true; break end
            end
        end
        if sim and proibida(lk) then sim = false end
        cache[k] = sim
        return sim
    end
    -- valor "sem coice": numero/vetor vira zero; NoRecoil=true, Recoil/CameraShake=false
    local function valorNovo(k, v)
        local tv = typeof(v)
        if tv == "number" then return 0
        elseif tv == "Vector3" then return Vector3.zero
        elseif tv == "Vector2" then return Vector2.zero
        elseif tv == "NumberRange" then return NumberRange.new(0)
        elseif tv == "boolean" and type(k) == "string" then
            return string.sub(string.lower(k), 1, 2) == "no"
        end
        return nil
    end

    -- ── Escrita com backup ──────────────────────────────────────
    local function escrever(t, k, v)
        if pcall(rawset, t, k, v) then return true end
        if type(setreadonly) == "function" then
            return (pcall(function() setreadonly(t, false); rawset(t, k, v); setreadonly(t, true) end))
        end
        return false
    end
    local function trocar(t, k, v, novo)
        if novo == nil or v == novo then return end
        if not escrever(t, k, novo) then return end
        local b = R.backup[t]
        if not b then b = {}; nossas[b] = true; R.backup[t] = b end
        if b[k] == nil then b[k] = v; R.nZerados = R.nZerados + 1 end
    end
    -- tabela de config pura: sem metatable (objeto/mola) e sem funcao dentro
    local function ehConfig(t)
        if nossas[t] or getmetatable(t) ~= nil then return false end
        local n = 0
        for _, v in next, t do
            n = n + 1
            if n > 64 or type(v) == "function" or typeof(v) == "Instance" then return false end
        end
        return true
    end
    -- forcado = estamos dentro de uma tabela de coice (Recoil = {X=..,Y=..})
    local function aplicar(t, prof, forcado)
        if nossas[t] then return end
        for k, v in next, t do
            local alvo
            if type(k) == "string" then
                if forcado then alvo = not proibida(string.lower(k)) else alvo = combina(k) end
            else
                alvo = forcado
            end
            if alvo then
                if type(v) == "table" then
                    if prof < 3 and ehConfig(v) then aplicar(v, prof + 1, true) end
                elseif type(v) ~= "boolean" or not forcado then
                    trocar(t, k, v, valorNovo(k, v))
                end
            end
        end
    end

    -- ── Camada 2/3: Tools (Values e atributos) ──────────────────
    local function backupInst(o)
        local b = R.backupInst[o]
        if not b then
            b = { attrs = {} }
            nossas[b] = true; nossas[b.attrs] = true
            R.backupInst[o] = b
        end
        return b
    end
    local function mexerInstancia(o)
        if o:IsA("ValueBase") and combina(o.Name) then
            local ok, v = pcall(function() return o.Value end)
            local novo = nil
            if ok then novo = valorNovo(o.Name, v) end
            if novo ~= nil and novo ~= v and pcall(function() o.Value = novo end) then
                local b = backupInst(o)
                if not b.temValor then b.temValor = true; b.valor = v; R.nZerados = R.nZerados + 1 end
            end
        end
        local okA, attrs = pcall(function() return o:GetAttributes() end)
        if okA then
            for nome, v in pairs(attrs) do
                if combina(nome) then
                    local novo = valorNovo(nome, v)
                    if novo ~= nil and novo ~= v and pcall(function() o:SetAttribute(nome, novo) end) then
                        local b = backupInst(o)
                        if b.attrs[nome] == nil then b.attrs[nome] = v; R.nZerados = R.nZerados + 1 end
                    end
                end
            end
        end
    end
    local function varrerFerramentas()
        local char = LocalPlayer.Character
        local mochila = LocalPlayer:FindFirstChildOfClass("Backpack")
        for _, lugar in ipairs({ char or false, mochila or false }) do
            if lugar then
                for _, o in ipairs(lugar:GetChildren()) do
                    if o:IsA("Tool") then
                        pcall(mexerInstancia, o)
                        for _, d in ipairs(o:GetDescendants()) do pcall(mexerInstancia, d) end
                    end
                end
            end
        end
    end

    -- ── Camada 2/3: memoria do jogo (getgc), em pedacos pra nao travar ──
    local function varrerGC()
        if R.varrendo or type(getgc) ~= "function" then return end
        R.varrendo = true
        local minha = R.geracao
        task.spawn(function()
            local ok, lista = pcall(getgc, true)
            if ok and type(lista) == "table" then
                for i = 1, #lista do
                    if not R.ativo or R.geracao ~= minha then break end
                    local o = lista[i]
                    if type(o) == "table" and not nossas[o] then pcall(aplicar, o, 0, false) end
                    if i % 2000 == 0 then task.wait() end
                end
            end
            R.varrendo = false
            -- mudou opcao no meio da varredura: comeca de novo com as regras novas
            if R.ativo and R.geracao ~= minha and (R.arma or R.bala) then varrerGC() end
        end)
    end
    local function aplicarArma()
        if not R.ativo or not (R.arma or R.bala) then return end
        varrerFerramentas()
        varrerGC()
    end
    local function restaurar()
        R.geracao = R.geracao + 1   -- para a varredura em andamento
        for t, b in pairs(R.backup) do
            for k, v in pairs(b) do escrever(t, k, v) end
        end
        table.clear(R.backup)
        for o, b in pairs(R.backupInst) do
            pcall(function()
                if b.temValor then o.Value = b.valor end
                for nome, v in pairs(b.attrs) do o:SetAttribute(nome, v) end
            end)
        end
        table.clear(R.backupInst)
        table.clear(cache)
        R.nZerados = 0
    end

    -- ── Camada 1: camera ────────────────────────────────────────
    local DOIS_PI = math.pi * 2
    local PULO_MAX = math.rad(8)   -- coice por frame e sempre menor que isso

    -- TRAVA: o que ja foi zerado e re-zerado todo frame. Arma que aumenta
    -- o spread a cada tiro (por isso os ultimos tiros eram piores) volta pra 0
    local function manter()
        for t, b in pairs(R.backup) do
            for k, orig in pairs(b) do
                local novo = valorNovo(k, orig)
                if novo ~= nil and rawget(t, k) ~= novo then escrever(t, k, novo) end
            end
        end
        for o, b in pairs(R.backupInst) do
            pcall(function()
                if b.temValor then
                    local novo = valorNovo(o.Name, b.valor)
                    if novo ~= nil and o.Value ~= novo then o.Value = novo end
                end
                for nome, orig in pairs(b.attrs) do
                    local novo = valorNovo(nome, orig)
                    if novo ~= nil and o:GetAttribute(nome) ~= novo then o:SetAttribute(nome, novo) end
                end
            end)
        end
    end

    local function aimbotPuxando()
        local c = GS.cmb
        return c ~= nil and c.aimbot and c.alvoAtual ~= nil
    end
    local function atirando()
        if not UserInputService.MouseEnabled or UserInputService:GetFocusedTextBox() then return false end
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    end
    local function passoCamera()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local cf = cam.CFrame
        local pitch, yaw, roll = cf:ToEulerAnglesYXZ()
        if R.camera and R.pitch and atirando() and not aimbotPuxando() then
            local d = UserInputService:GetMouseDelta()
            local f = R.forca / 100
            local np, ny = pitch, yaw
            -- subiu sem o mouse ter subido = coice
            -- pulo grande (respawn/teleporte/cutscene) nao e coice: nao briga
            local subiu = pitch - R.pitch
            if subiu > 1e-5 and subiu < PULO_MAX and d.Y >= 0 then np = pitch - subiu * f end
            -- girou pro lado sem o mouse ter mexido no X = coice lateral
            local girou = (yaw - R.yaw + math.pi) % DOIS_PI - math.pi
            if math.abs(girou) > 1e-5 and math.abs(girou) < PULO_MAX and math.abs(d.X) < 0.5 then
                ny = yaw - girou * f
            end
            if np ~= pitch or ny ~= yaw then
                cam.CFrame = CFrame.new(cf.Position) * CFrame.fromEulerAnglesYXZ(np, ny, roll * (1 - f))
                pitch, yaw = np, ny
                R.segurados = R.segurados + 1
            end
        end
        R.pitch, R.yaw = pitch, yaw
    end

    -- ── Liga / desliga ──────────────────────────────────────────
    local function ligar()
        R.ativo = true; R.pitch = nil; R.segurados = 0
        R.loopId = R.loopId + 1
        local meuLoop = R.loopId
        table.insert(R.conns, RunService.RenderStepped:Connect(function() pcall(passoCamera) end))
        pcall(function()
            RunService:BindToRenderStep("GringoNoRecoil", Enum.RenderPriority.Last.Value + 1,
                function() pcall(passoCamera) end)
        end)
        table.insert(R.conns, RunService.Heartbeat:Connect(function() pcall(manter) end))
        -- equipou/trocou de arma: varre na hora
        local function aoPersonagem(char)
            table.insert(R.conns, char.ChildAdded:Connect(function(o)
                if o:IsA("Tool") then
                    task.delay(0.35, function() if R.ativo then aplicarArma() end end)
                end
            end))
        end
        if LocalPlayer.Character then aoPersonagem(LocalPlayer.Character) end
        table.insert(R.conns, LocalPlayer.CharacterAdded:Connect(aoPersonagem))
        aplicarArma()
        -- status + revarredura (arma que recria a config ao atirar/recarregar)
        task.spawn(function()
            local proxVarredura = os.clock() + 15
            while R.ativo and R.loopId == meuLoop do
                task.wait(0.5)
                if not (R.ativo and R.loopId == meuLoop) then break end
                setStatus("ON · ARMA: " .. R.nZerados .. " ZERADOS · SEGUROU " .. R.segurados .. "x")
                if os.clock() >= proxVarredura then
                    proxVarredura = os.clock() + (GS.leve and 30 or 15)
                    aplicarArma()
                end
            end
        end)
        togR.Text = "NO RECOIL: ON"
        status.TextColor3 = T.text
        setStatus("ON · PROCURANDO A ARMA...")
        GS.toast("No Recoil ON", true)
        if type(getgc) ~= "function" then
            task.delay(0.6, function() GS.toast("Sem getgc: só câmera + Tools", false) end)
        end
        if not UserInputService.MouseEnabled then
            task.delay(1.2, function() GS.toast("Celular: câmera fica de fora", false) end)
        end
    end
    local function desligar(silencioso)
        R.ativo = false; R.loopId = R.loopId + 1
        for _, c in ipairs(R.conns) do pcall(function() c:Disconnect() end) end
        R.conns = {}
        pcall(function() RunService:UnbindFromRenderStep("GringoNoRecoil") end)
        restaurar()
        R.pitch = nil
        togR.Text = "NO RECOIL: OFF"
        status.TextColor3 = T.dim
        setStatus("STATUS: DESLIGADO")
        if not silencioso then GS.toast("No Recoil desligado", false) end
    end

    -- ── Cliques ─────────────────────────────────────────────────
    togR.MouseButton1Click:Connect(function()
        if R.ativo then desligar() else ligar() end
    end)
    local function reaplicar()
        if not R.ativo then return end
        restaurar()
        aplicarArma()
    end
    togC.MouseButton1Click:Connect(function()
        R.camera = not R.camera; R.pitch = nil
        togC.Text = R.camera and "CAMERA: ON" or "CAMERA: OFF"
    end)
    togA.MouseButton1Click:Connect(function()
        R.arma = not R.arma
        togA.Text = R.arma and "ARMA: ON" or "ARMA: OFF"
        reaplicar()
    end)
    togB.MouseButton1Click:Connect(function()
        R.bala = not R.bala
        togB.Text = R.bala and "SPREAD: ON" or "SPREAD: OFF"
        reaplicar()
    end)
    forMenos.MouseButton1Click:Connect(function() R.forca = math.max(10, R.forca - 10); forLbl.Text = R.forca .. "%" end)
    forMais.MouseButton1Click:Connect(function() R.forca = math.min(100, R.forca + 10); forLbl.Text = R.forca .. "%" end)

    ScreenGui.Destroying:Connect(function()
        if R.ativo then desligar(true) end
    end)
end
GS.rodar("No Recoil", GS.iniciarNoRecoil, GS.painelRecoil)

-- ═══════════════════════════════════════════════════════════════
--   MUNICAO INFINITA + ANTI RECARGA (BRUTAL) — aba COMBATE > MUNICAO
-- ═══════════════════════════════════════════════════════════════
--   • Acha o contador de bala da arma (memoria do jogo via getgc + Values
--     e atributos das Tools) e trava no MAXIMO: o pente nunca esvazia,
--     a arma nunca pede recarga e o ultimo tiro e igual ao primeiro.
--   • Value/atributo volta pro maximo NO MESMO instante em que o jogo tira
--     a bala (sinal de mudanca) — o numero nem chega a cair na tela.
--   • Recarga instantanea: tempo de recarga vira 0.05s (nao 0: evita
--     divisao por zero no script da arma). Destravar: solta a trava de
--     "recarregando", da pra atirar no meio da recarga.
--   • Maximo: MagSize/ClipSize/AmmoPerMag da arma, senao MaxAmmo, senao o
--     maior valor ja visto (recarregou pra mais? sobe junto).
--   • Nome generico (Mag, Clip, Rounds, Bullets) so conta se a tabela tem
--     cara de arma (Reload, Fire, Damage...): nao mexe em contador de rodada.
--   Obs: jogo que conta a bala NO SERVIDOR pode recusar o tiro depois que
--   o pente "de verdade" acaba — isso nao da pra burlar so pelo cliente.
-- ═══════════════════════════════════════════════════════════════
GS.iniciarMunicao = function()
    local U = GS.ui
    local painel = GS.painelMunicao
    if not U or not painel then
        error("UI nao pronta (GS.ui=" .. tostring(U ~= nil) .. ", GS.painelMunicao=" .. tostring(painel ~= nil) .. ")")
    end
    local T = U.T
    local TEMPO_MIN = 0.05

    local M = { ativo=false, recarga=true, destravar=true, conns={}, sinais={},
                pentes={}, tempos={}, travas={}, inst={}, nPentes=0,
                varrendo=false, geracao=0, loopId=0, ligouEm=0 }
    GS.municao = M
    -- tabelas do proprio script: a varredura nunca mexe nelas
    local nossas = setmetatable({}, { __mode = "k" })
    local cacheNome = {}
    for _, t in ipairs({ nossas, M, M.sinais, M.pentes, M.tempos, M.travas, M.inst, cacheNome }) do
        nossas[t] = true
    end

    -- ── UI ──────────────────────────────────────────────────────
    local g = U.grupo(painel, "Munição infinita", "Pente sempre cheio: nunca acaba, nunca pede recarga", "package", 1)
    local togM = U.tog(g, "Munição infinita", 1, "package")
    local status = U.pequeno(g, "STATUS: DESLIGADO", nil, 2)
    status.AutoButtonColor = false; status.TextColor3 = T.dim
    local gb = U.grupo(painel, "Modo brutal", "Recarga instantânea e sem trava de recarregar", "flame", 2)
    local togR = U.tog(gb, "Recarga instantânea", 1, "refresh-cw")
    local togD = U.tog(gb, "Atirar mesmo recarregando", 2, "zap")
    togM:SetAttribute("Controlado", true)
    togR.Text = "RECARGA: ON"; togD.Text = "DESTRAVAR: ON"

    local ultimoStatus = ""
    local function setStatus(txt)
        if txt ~= ultimoStatus then ultimoStatus = txt; status.Text = txt end
    end

    -- ── Quais chaves ────────────────────────────────────────────
    -- "Ammo_Count" -> "ammocount"
    local function normal(k)
        local n = cacheNome[k]
        if n == nil then n = (string.gsub(string.lower(k), "[^%w]", "")); cacheNome[k] = n end
        return n
    end
    local function tem(n, lista)
        for _, p in ipairs(lista) do
            if string.find(n, p, 1, true) then return true end
        end
        return false
    end
    -- contador sem "ammo" no nome: so vale em tabela com cara de arma
    local GENERICO = { mag=true, currentmag=true, magazine=true, currentmagazine=true, clip=true,
                       currentclip=true, bullets=true, bulletsleft=true, currentbullets=true,
                       rounds=true, roundsleft=true, currentrounds=true, roundsinmag=true }
    local NAO_ATUAL = { "max", "type", "name", "per", "size", "cap", "cost", "price", "text", "gui",
                        "label", "display", "sound", "anim", "color", "drop", "pickup", "regen", "use",
                        "consum", "speed", "damage", "enabled", "visible", "time", "delay", "rate",
                        "icon", "image", "reload" }
    local RESERVA  = { "stored", "spare", "reserve", "total", "extra", "pool", "carry" }
    local PENTE    = { "magsize", "magazinesize", "clipsize", "ammopermag", "ammoperclip", "magcapacity",
                       "clipcapacity", "magazinecapacity", "roundspermag", "bulletspermag", "maxmag",
                       "maxclip", "maxammoinmag", "maxammoinclip", "maxmagazine" }
    local MUNI     = { "ammo", "mag", "clip", "bullet", "round" }
    local CONTEXTO = { "ammo", "reload", "fire", "recoil", "spread", "damage", "gun", "weapon", "shoot",
                       "magsize", "clipsize", "firerate" }
    local TEMPO    = { "time", "duration", "delay", "length", "wait", "cooldown" }
    for _, t in ipairs({ GENERICO, NAO_ATUAL, RESERVA, PENTE, MUNI, CONTEXTO, TEMPO }) do nossas[t] = true end

    -- contador de bala? (2o retorno: tem "ammo" no nome = nao precisa de contexto)
    local function ehAtual(n)
        if tem(n, NAO_ATUAL) then return false, false end
        if string.find(n, "ammo", 1, true) then return true, true end
        return GENERICO[n] == true, false
    end
    -- referencia de maximo: "pente" (tamanho do pente) ou "max" (maximo geral)
    local function tipoMax(n)
        if tem(n, PENTE) then return "pente" end
        if string.find(n, "max", 1, true) and tem(n, MUNI) then return "max" end
        if string.find(n, "capacity", 1, true) then return "max" end
        return nil
    end
    local function ehTempoRecarga(n)
        return string.find(n, "reload", 1, true) ~= nil and tem(n, TEMPO)
    end
    local function ehTravaRecarga(n)
        return string.find(n, "reloading", 1, true) ~= nil or n == "inreload" or n == "isreload"
    end
    local function alvoDe(n, v, refPente, refMax)
        if tem(n, RESERVA) then return v end   -- reserva: so nao deixa cair
        return math.max(refPente > 0 and refPente or refMax, v)
    end

    -- ── Escrita ─────────────────────────────────────────────────
    local function escrever(t, k, v)
        if pcall(rawset, t, k, v) then return true end
        if type(setreadonly) == "function" then
            return (pcall(function() setreadonly(t, false); rawset(t, k, v); setreadonly(t, true) end))
        end
        return false
    end
    local function registro(lista, t)
        local p = lista[t]
        if not p then p = {}; nossas[p] = true; lista[t] = p end
        return p
    end

    -- ── Tabelas (memoria do jogo) ───────────────────────────────
    local function analisarTabela(t)
        if nossas[t] then return end
        local refPente, refMax, contexto = 0, 0, false
        local achados = nil
        for k, v in next, t do
            if type(k) == "string" then
                local n = normal(k)
                local tv = type(v)
                if tv == "number" then
                    local atual, ehAmmo = ehAtual(n)
                    if atual then
                        achados = achados or {}
                        achados[k] = true
                        if ehAmmo then contexto = true end
                    else
                        local tipo = tipoMax(n)
                        if tipo == "pente" then
                            if v > refPente then refPente = v end
                            contexto = true
                        elseif tipo == "max" then
                            if v > refMax then refMax = v end
                            contexto = true
                        elseif M.recarga and ehTempoRecarga(n) and v > TEMPO_MIN then
                            local p = registro(M.tempos, t)
                            if p[k] == nil then p[k] = v end   -- original, pra devolver
                            escrever(t, k, TEMPO_MIN)
                        end
                    end
                elseif tv == "boolean" and M.destravar and ehTravaRecarga(n) then
                    registro(M.travas, t)[k] = true
                    if v == true then escrever(t, k, false) end
                end
                if not contexto and not GENERICO[n] and tem(n, CONTEXTO) then contexto = true end
            end
        end
        if not (achados and contexto) then return end
        for k in pairs(achados) do
            local v = rawget(t, k)
            if type(v) == "number" and v == v then
                local alvo = alvoDe(normal(k), v, refPente, refMax)
                if alvo > 0 and alvo < 1e6 then
                    local p = registro(M.pentes, t)
                    if p[k] == nil then M.nPentes = M.nPentes + 1 end
                    if p[k] == nil or alvo > p[k] then p[k] = alvo end
                    if v < p[k] then escrever(t, k, p[k]) end
                end
            end
        end
    end

    -- ── Tools (Values e atributos) ──────────────────────────────
    local function ler(o, attr)
        if attr then return o:GetAttribute(attr) end
        return o.Value
    end
    local function gravar(o, attr, v)
        if attr then o:SetAttribute(attr, v) else o.Value = v end
    end
    -- corrige um Value/atributo registrado (chamado no sinal de mudanca e todo frame)
    local function corrigirInst(o, attr)
        local e = M.inst[o]
        local x = e and e[attr or ""]
        if not x then return end
        local v = ler(o, attr)
        if x.tipo == "pente" then
            if type(v) == "number" then
                if v < x.alvo then gravar(o, attr, x.alvo) elseif v > x.alvo then x.alvo = v end
            end
        elseif x.tipo == "tempo" then
            if M.recarga and type(v) == "number" and v ~= TEMPO_MIN then gravar(o, attr, TEMPO_MIN) end
        elseif x.tipo == "trava" then
            if M.destravar and v == true then gravar(o, attr, false) end
        end
    end
    local function registrarInst(o, attr, tipo, valor)
        local e = M.inst[o]
        if not e then e = {}; nossas[e] = true; M.inst[o] = e end
        local chave = attr or ""
        local x = e[chave]
        if not x then
            x = { tipo = tipo }
            nossas[x] = true
            e[chave] = x
            if tipo == "pente" then x.alvo = valor; M.nPentes = M.nPentes + 1 end
            if tipo == "tempo" then x.orig = valor end
            -- o jogo mexeu? volta NA HORA (nem aparece o numero caindo)
            local sinal = attr and o:GetAttributeChangedSignal(attr) or o:GetPropertyChangedSignal("Value")
            table.insert(M.sinais, sinal:Connect(function()
                if M.ativo then pcall(corrigirInst, o, attr) end
            end))
        elseif tipo == "pente" and valor > x.alvo then
            x.alvo = valor
        end
        pcall(corrigirInst, o, attr)
    end
    local function analisarTool(tool)
        local refPente, refMax = 0, 0
        local atuais = {}
        local function ver(o, nome, v, attr)
            local n = normal(nome)
            if type(v) == "number" then
                if ehAtual(n) then
                    table.insert(atuais, { o = o, attr = attr, n = n, v = v })
                else
                    local tipo = tipoMax(n)
                    if tipo == "pente" then refPente = math.max(refPente, v)
                    elseif tipo == "max" then refMax = math.max(refMax, v)
                    elseif M.recarga and ehTempoRecarga(n) and v > TEMPO_MIN then
                        registrarInst(o, attr, "tempo", v)
                    end
                end
            elseif type(v) == "boolean" and M.destravar and ehTravaRecarga(n) then
                registrarInst(o, attr, "trava")
            end
        end
        local function olhar(o)
            if o:IsA("NumberValue") or o:IsA("IntValue") or o:IsA("BoolValue") then ver(o, o.Name, o.Value, nil) end
            for nome, v in pairs(o:GetAttributes()) do ver(o, nome, v, nome) end
        end
        pcall(olhar, tool)
        for _, d in ipairs(tool:GetDescendants()) do pcall(olhar, d) end
        -- dentro de uma Tool ja tem cara de arma: nao precisa de contexto
        for _, a in ipairs(atuais) do
            local alvo = alvoDe(a.n, a.v, refPente, refMax)
            if alvo > 0 and alvo < 1e6 then pcall(registrarInst, a.o, a.attr, "pente", alvo) end
        end
    end
    local function varrerFerramentas()
        local char = LocalPlayer.Character
        local mochila = LocalPlayer:FindFirstChildOfClass("Backpack")
        for _, lugar in ipairs({ char or false, mochila or false }) do
            if lugar then
                for _, o in ipairs(lugar:GetChildren()) do
                    if o:IsA("Tool") then pcall(analisarTool, o) end
                end
            end
        end
    end

    -- ── Varredura da memoria (getgc), em pedacos pra nao travar ──
    local function varrerGC()
        if M.varrendo or type(getgc) ~= "function" then return end
        M.varrendo = true
        local minha = M.geracao
        task.spawn(function()
            local ok, lista = pcall(getgc, true)
            if ok and type(lista) == "table" then
                for i = 1, #lista do
                    if not M.ativo or M.geracao ~= minha then break end
                    local o = lista[i]
                    if type(o) == "table" and not nossas[o] then pcall(analisarTabela, o) end
                    if i % 2000 == 0 then task.wait() end
                end
            end
            M.varrendo = false
            if M.ativo and M.geracao ~= minha then varrerGC() end
        end)
    end
    local function aplicar()
        if not M.ativo then return end
        varrerFerramentas()
        varrerGC()
    end

    -- ── Trava: todo frame ───────────────────────────────────────
    local function manter()
        for t, p in pairs(M.pentes) do
            for k, alvo in pairs(p) do
                local v = rawget(t, k)
                if type(v) == "number" then
                    if v < alvo then escrever(t, k, alvo) elseif v > alvo then p[k] = v end
                end
            end
        end
        if M.recarga then
            for t, p in pairs(M.tempos) do
                for k in pairs(p) do
                    if rawget(t, k) ~= TEMPO_MIN then escrever(t, k, TEMPO_MIN) end
                end
            end
        end
        if M.destravar then
            for t, p in pairs(M.travas) do
                for k in pairs(p) do
                    if rawget(t, k) == true then escrever(t, k, false) end
                end
            end
        end
        for o, e in pairs(M.inst) do
            if o.Parent == nil then
                M.inst[o] = nil   -- arma destruida
            else
                for chave in pairs(e) do pcall(corrigirInst, o, chave ~= "" and chave or nil) end
            end
        end
    end
    local function restaurar()
        M.geracao = M.geracao + 1   -- para a varredura em andamento
        for _, c in ipairs(M.sinais) do pcall(function() c:Disconnect() end) end
        table.clear(M.sinais)
        -- devolve o tempo de recarga original (a bala que ficou cheia, fica)
        for t, p in pairs(M.tempos) do
            for k, orig in pairs(p) do escrever(t, k, orig) end
        end
        for o, e in pairs(M.inst) do
            for chave, x in pairs(e) do
                if x.tipo == "tempo" and x.orig then
                    pcall(gravar, o, chave ~= "" and chave or nil, x.orig)
                end
            end
        end
        table.clear(M.pentes); table.clear(M.tempos); table.clear(M.travas); table.clear(M.inst)
        table.clear(cacheNome)
        M.nPentes = 0
    end

    -- ── Liga / desliga ──────────────────────────────────────────
    local function ligar()
        M.ativo = true; M.ligouEm = os.clock()
        M.loopId = M.loopId + 1
        local meuLoop = M.loopId
        table.insert(M.conns, RunService.Heartbeat:Connect(function() pcall(manter) end))
        local function aoPersonagem(char)
            table.insert(M.conns, char.ChildAdded:Connect(function(o)
                if o:IsA("Tool") then
                    task.delay(0.35, function() if M.ativo then aplicar() end end)
                end
            end))
        end
        if LocalPlayer.Character then aoPersonagem(LocalPlayer.Character) end
        table.insert(M.conns, LocalPlayer.CharacterAdded:Connect(aoPersonagem))
        aplicar()
        task.spawn(function()
            local proxVarredura = os.clock() + 20
            while M.ativo and M.loopId == meuLoop do
                task.wait(0.5)
                if not (M.ativo and M.loopId == meuLoop) then break end
                if M.nPentes > 0 then
                    setStatus("ON · " .. M.nPentes .. " CONTADOR(ES) DE BALA TRAVADO(S)")
                elseif M.varrendo or os.clock() - M.ligouEm < 3 then
                    setStatus("ON · PROCURANDO A BALA DA ARMA...")
                else
                    setStatus("ON · EQUIPA A ARMA (NÃO ACHEI A BALA)")
                end
                if os.clock() >= proxVarredura then
                    proxVarredura = os.clock() + (GS.leve and 40 or 20)
                    aplicar()
                end
            end
        end)
        togM.Text = "MUNIÇÃO INFINITA: ON"
        status.TextColor3 = T.text
        GS.toast("Munição infinita ON", true)
        if type(getgc) ~= "function" then
            task.delay(0.6, function() GS.toast("Sem getgc: só Values da Tool", false) end)
        end
    end
    local function desligar(silencioso)
        M.ativo = false; M.loopId = M.loopId + 1
        for _, c in ipairs(M.conns) do pcall(function() c:Disconnect() end) end
        M.conns = {}
        restaurar()
        togM.Text = "MUNIÇÃO INFINITA: OFF"
        status.TextColor3 = T.dim
        setStatus("STATUS: DESLIGADO")
        if not silencioso then GS.toast("Munição infinita desligada", false) end
    end

    -- ── Cliques ─────────────────────────────────────────────────
    togM.MouseButton1Click:Connect(function()
        if M.ativo then desligar() else ligar() end
    end)
    local function reaplicar()
        if not M.ativo then return end
        restaurar()
        aplicar()
    end
    togR.MouseButton1Click:Connect(function()
        M.recarga = not M.recarga
        togR.Text = M.recarga and "RECARGA: ON" or "RECARGA: OFF"
        reaplicar()
    end)
    togD.MouseButton1Click:Connect(function()
        M.destravar = not M.destravar
        togD.Text = M.destravar and "DESTRAVAR: ON" or "DESTRAVAR: OFF"
        reaplicar()
    end)

    ScreenGui.Destroying:Connect(function()
        if M.ativo then desligar(true) end
    end)
end
GS.rodar("Munição", GS.iniciarMunicao, GS.painelMunicao)

-- ═══════════════════════════════════════════════════════════════
--   VELOCIDADE DA BALA (BRUTAL) — dentro da aba COMBATE > MUNICAO
-- ═══════════════════════════════════════════════════════════════
--   Camadas (cada uma liga/desliga sozinha):
--   1) CADENCIA: acelera a arma na config. O mesmo nome muda de sentido
--      conforme o kit, entao decide pelo VALOR: FireRate 0.1 (FE Gun Kit =
--      segundos entre tiros) desce; ShootRate 600 (ACS = RPM) sobe;
--      FireDelay/Cooldown/Interval descem.
--   2) AUTOMATICO: Semi/Burst/"Semiautomatico" vira Auto/"Automatico",
--      AutoFire=true, ShootType 1/2 -> 3 (ACS). Segurou = nao para.
--   3) SEM COOLDOWN: CanFire/CanShoot = true, Debounce/Cooldown = false e
--      a Tool equipada fica sempre Enabled (arma simples usa isso de trava).
--   4) RAJADA: enquanto voce segura o tiro, dispara a Tool sozinho na
--      cadencia escolhida (ate 60/s) — funciona mesmo se a config nao achar.
--   5) BALA INSTANTANEA: BulletSpeed/MuzzleVelocity sobem, queda
--      (Gravity/Drop/Acceleration do FastCast) zera, alcance sobe.
--   6) TRAVA: tudo isso e re-aplicado todo frame (arma que reseta ao equipar).
--   Desligou: devolve os valores originais. Junto com MUNICAO INFINITA o
--   pente nunca acaba, entao a rajada nunca para.
--   Obs: jogo que limita a cadencia NO SERVIDOR descarta os tiros extras.
-- ═══════════════════════════════════════════════════════════════
GS.iniciarVelocidade = function()
    local U = GS.ui
    local painel = GS.painelMunicao
    if not U or not painel then
        error("UI nao pronta (GS.ui=" .. tostring(U ~= nil) .. ", GS.painelMunicao=" .. tostring(painel ~= nil) .. ")")
    end
    local T = U.T

    local V = { ativo=false, tps=20, cadencia=true, auto=true, semCd=true, rajada=true, bala=true,
                conns={}, sinais={}, reg={}, flags={}, inst={}, nAcel=0, disparos=0,
                mb1=false, toques={}, acum=0, varrendo=false, geracao=0, loopId=0, ligouEm=0,
                espera=true, relogio=false, universal=false, hooks=false, relogioHooks=false,
                offsetRelogio=0, ultimaVarredura=0 }
    GS.velocidade = V
    local nossas = setmetatable({}, { __mode = "k" })
    local cacheNome = {}
    local velho = {}   -- funcoes originais (antes do hookfunction)
    for _, t in ipairs({ nossas, V, V.sinais, V.reg, V.flags, V.inst, V.toques, cacheNome, velho }) do nossas[t] = true end
    -- relogio de verdade: depois do relogio turbo, os.clock pode estar adiantado
    -- pros scripts de arma; aqui dentro (e no Silent) sempre o original
    local function relogioReal() return (velho.clock or os.clock)() end
    GS.relogioReal = relogioReal

    -- ── UI (mesma aba da municao, embaixo) ──────────────────────
    local g = U.grupo(painel, "Velocidade da bala", "Atira muito rápido e não para nunca", "zap", 3)
    local togV = U.tog(g, "Velocidade da bala", 1, "zap")
    local tpsMenos, tpsMais, tpsLbl = U.ctrl(g, "Tiros por segundo", "20", 2)
    local status = U.pequeno(g, "STATUS: DESLIGADO", nil, 3)
    status.AutoButtonColor = false; status.TextColor3 = T.dim
    local gb = U.grupo(painel, "Velocidade · modo brutal", "Cada camada liga e desliga sozinha", "flame", 4)
    local togC = U.tog(gb, "Acelerar a arma (cadência)", 1, "gauge")
    local togA = U.tog(gb, "Virar automática (segurou, não para)", 2, "refresh-cw")
    local togS = U.tog(gb, "Sem cooldown (destrava o tiro)", 3, "zap")
    local togR = U.tog(gb, "Rajada infinita (dispara sozinho)", 4, "mouse-pointer-click")
    local togB = U.tog(gb, "Bala instantânea (sem queda)", 5, "target")
    togV:SetAttribute("Controlado", true)
    togC.Text = "CADENCIA: ON"; togA.Text = "AUTO: ON"; togS.Text = "SEM COOLDOWN: ON"
    togR.Text = "RAJADA: ON"; togB.Text = "BALA: ON"
    local togE  = U.tog(gb, "Acelerar o tempo da arma (wait/delay)", 6, "rabbit")
    local togRl = U.tog(gb, "Relógio turbo (arma teimosa com tick)", 7, "sliders-horizontal")
    local togU  = U.tog(gb, "Modo universal (qualquer jogo · pode bugar)", 8, "globe")
    togE.Text = "ESPERA: ON"; togRl.Text = "RELOGIO: OFF"; togU.Text = "UNIVERSAL: OFF"

    local ultimoStatus = ""
    local function setStatus(txt)
        if txt ~= ultimoStatus then ultimoStatus = txt; status.Text = txt end
    end

    -- ── Classificacao das chaves ────────────────────────────────
    local function normal(k)
        local n = cacheNome[k]
        if n == nil then n = (string.gsub(string.lower(k), "[^%w]", "")); cacheNome[k] = n end
        return n
    end
    local function tem(n, lista)
        for _, p in ipairs(lista) do
            if string.find(n, p, 1, true) then return true end
        end
        return false
    end
    local TIRO     = { "fire", "shoot", "shot", "attack", "burst", "trigger", "click" }
    local FORA     = { "anim", "sound", "reload", "equip", "aim", "walk", "run", "sprint", "camera",
                       "recoil", "spread", "bullet", "projectile", "muzzle", "swap", "switch", "sway",
                       "effect", "flash", "shell", "particle", "light", "tween", "ui", "gui" }
    local CONTEXTO = { "ammo", "reload", "fire", "shoot", "bullet", "recoil", "spread", "damage", "gun",
                       "weapon", "magsize", "clipsize", "muzzle", "projectile" }
    local AUTO_SIM = { auto=true, automatic=true, isauto=true, isautomatic=true, fullauto=true,
                       autofire=true, automode=true, automatico=true }
    local AUTO_NAO = { semi=true, issemi=true, semiauto=true, semiautomatic=true, boltaction=true,
                       pumpaction=true, singlefire=true, singleshot=true, semiautomatico=true }
    local FLAG_SIM = { canfire=true, canshoot=true, canattack=true, canshot=true, ready=true, isready=true,
                       canclick=true, allowfire=true, allowshoot=true, firingallowed=true, canuse=true }
    local FLAG_NAO = { cooldown=true, oncooldown=true, incooldown=true, iscooldown=true, coolingdown=true,
                       debounce=true, firedebounce=true, shootdebounce=true, attackdebounce=true,
                       shotdebounce=true }
    -- valor do modo (sem simbolo/acento) -> versao automatica
    local MODO_AUTO = { semi="auto", single="auto", burst="auto", semiauto="fullauto",
                        semiautomatic="automatic", semiautomatico="automatico", semiautomtico="automtico",
                        rajada="automatico", tiro="automatico", unico="automatico" }
    for _, t in ipairs({ TIRO, FORA, CONTEXTO, AUTO_SIM, AUTO_NAO, FLAG_SIM, FLAG_NAO, MODO_AUTO }) do nossas[t] = true end

    local function ehBala(n)
        return tem(n, { "bullet", "projectile", "muzzle" }) and tem(n, { "speed", "velocity" })
    end
    local function ehQueda(n)
        return n == "bulletdrop" or n == "bulletgravity" or n == "projectilegravity" or n == "projectiledrop"
            or n == "bulletacceleration" or n == "drop" or n == "gravity" or n == "acceleration"
    end
    local function ehAlcance(n)
        return n == "range" or n == "maxrange" or n == "bulletrange" or n == "maxdistance" or n == "effectiverange"
    end
    local function ehCadencia(n)   -- quanto maior, mais rapido (ou segundos se < 1)
        if tem(n, FORA) then return false end
        if n == "rpm" or n == "roundsperminute" or n == "rateoffire" then return true end
        return tem(n, { "rate", "rpm", "speed" }) and tem(n, TIRO)
    end
    local function ehEspera(n)     -- tempo entre tiros: quanto menor, mais rapido
        if tem(n, FORA) then return false end
        return tem(n, { "delay", "cooldown", "interval", "wait", "between" }) and tem(n, TIRO)
    end
    -- "Semi" -> "Auto" mantendo o estilo (SEMI -> AUTO, semi -> auto)
    local function estilo(modelo, novo)
        if modelo == string.upper(modelo) then return string.upper(novo) end
        if string.sub(modelo, 1, 1) == string.upper(string.sub(modelo, 1, 1)) then
            return string.upper(string.sub(novo, 1, 1)) .. string.sub(novo, 2)
        end
        return novo
    end
    local function modoAuto(v, opcoes)
        local chave = (string.gsub(string.lower(v), "[^%w]", ""))
        if not MODO_AUTO[chave] then return nil end
        -- a arma lista os modos que aceita? usa exatamente o automatico dela
        if opcoes then return opcoes end
        return estilo(v, MODO_AUTO[chave])
    end

    -- valor novo pra cada tipo (calculado na hora: muda junto com os tiros/s)
    local function novoValor(tipo, orig)
        local tps = V.tps
        if tipo == "cadencia" then
            if orig < 1 then return math.min(orig, 1 / tps) end        -- segundos entre tiros
            if orig < 30 then return math.max(orig, tps) end           -- tiros por segundo
            return math.max(orig, tps * 60)                             -- RPM
        elseif tipo == "espera" then
            if orig > 5 then return math.min(orig, 1000 / tps) end      -- milissegundos
            return math.min(orig, 1 / tps)
        elseif tipo == "bala" then
            return math.max(orig, math.min(orig * 5, 3000))
        elseif tipo == "queda" then
            if typeof(orig) == "Vector3" then return Vector3.zero end
            return 0
        elseif tipo == "alcance" then
            return math.max(orig, 3000)
        elseif tipo == "tipo3" then
            return 3
        elseif tipo == "auto_sim" then return true
        elseif tipo == "auto_nao" then return false
        end
        return nil
    end
    local function camadaLigada(tipo)
        if tipo == "cadencia" or tipo == "espera" then return V.cadencia end
        if tipo == "bala" or tipo == "queda" or tipo == "alcance" then return V.bala end
        if tipo == "tipo3" or tipo == "auto_sim" or tipo == "auto_nao" or tipo == "modo" then return V.auto end
        return false
    end
    -- tipo da chave (nil = nao mexe). precisaContexto: so vale em tabela com cara de arma
    local function classe(n, v)
        local tv = typeof(v)
        if tv == "number" then
            if v ~= v then return nil end
            if ehBala(n) then return "bala", false end
            if ehQueda(n) then return "queda", true end
            if ehAlcance(n) then return "alcance", true end
            -- fire/shoot/shot no nome = arma com certeza; attack/click (monstro
            -- tambem tem AttackSpeed) so vale em tabela com cara de arma
            local deArma = tem(n, { "fire", "shoot", "shot", "burst", "trigger" })
            if ehCadencia(n) and v > 0 then return "cadencia", not deArma end
            if ehEspera(n) and v > 0 then return "espera", not deArma end
            if n == "shoottype" and (v == 1 or v == 2) then return "tipo3", true end
        elseif tv == "Vector3" then
            if ehQueda(n) then return "queda", true end
        elseif tv == "boolean" then
            if AUTO_SIM[n] then return "auto_sim", true end
            if AUTO_NAO[n] then return "auto_nao", true end
            if FLAG_SIM[n] then return "flag_sim", true end
            if FLAG_NAO[n] then return "flag_nao", true end
        elseif tv == "string" then
            if tem(n, { "firemode", "shootmode", "firetype", "shoottype", "mode" }) then return "modo", true end
        end
        return nil
    end

    -- ── Escrita ─────────────────────────────────────────────────
    local function escrever(t, k, v)
        if pcall(rawset, t, k, v) then return true end
        if type(setreadonly) == "function" then
            return (pcall(function() setreadonly(t, false); rawset(t, k, v); setreadonly(t, true) end))
        end
        return false
    end
    local function registro(lista, t)
        local p = lista[t]
        if not p then p = {}; nossas[p] = true; lista[t] = p end
        return p
    end

    -- ── Tabelas (memoria do jogo) ───────────────────────────────
    local function analisarTabela(t)
        if nossas[t] then return end
        local contexto, opcaoAuto = false, nil
        local achados = nil
        for k, v in next, t do
            if type(k) == "string" then
                local n = normal(k)
                if not contexto and tem(n, CONTEXTO) then contexto = true end
                if type(v) == "table" and not opcaoAuto and not nossas[v] then
                    -- FireModes = {"Semi","Auto"}: guarda o nome exato do automatico
                    for i = 1, 8 do
                        local s = rawget(v, i)
                        if type(s) ~= "string" then break end
                        local ls = string.lower(s)
                        if string.find(ls, "auto", 1, true) and not string.find(ls, "semi", 1, true) then
                            opcaoAuto = s; break
                        end
                    end
                else
                    local tipo, precisa = classe(n, v)
                    if tipo then
                        achados = achados or {}
                        achados[k] = { tipo = tipo, precisa = precisa }
                    end
                end
            end
        end
        if not achados then return end
        for k, a in pairs(achados) do
            if contexto or not a.precisa then
                local v = rawget(t, k)
                if a.tipo == "flag_sim" or a.tipo == "flag_nao" then
                    if V.semCd then
                        registro(V.flags, t)[k] = (a.tipo == "flag_sim")
                        escrever(t, k, a.tipo == "flag_sim")
                    end
                elseif camadaLigada(a.tipo) then
                    local novo
                    if a.tipo == "modo" then novo = modoAuto(v, opcaoAuto) else novo = novoValor(a.tipo, v) end
                    if novo ~= nil and novo ~= v then
                        local p = registro(V.reg, t)
                        if p[k] == nil then
                            p[k] = { tipo = a.tipo, orig = v, modo = (a.tipo == "modo") and novo or nil }
                            nossas[p[k]] = true
                            V.nAcel = V.nAcel + 1
                        end
                        escrever(t, k, novo)
                    end
                end
            end
        end
    end

    -- ── Quem e script de arma ───────────────────────────────────
    -- Dentro de uma Tool = arma. Fora (framework de FPS em PlayerScripts):
    -- pelo nome do script ou dos pais. Modo universal: qualquer script do jogo.
    local GUNWORDS = { "gun", "weapon", "fire", "shoot", "arma", "blaster", "rifle", "pistol", "sniper",
                       "shotgun", "smg", "firearm", "revolver", "bullet", "ammo", "acs", "fps", "combat", "tool" }
    local cacheArma = setmetatable({}, { __mode = "k" })
    nossas[GUNWORDS] = true; nossas[cacheArma] = true
    local CoreGui = game:GetService("CoreGui")
    local function scriptDeArma(s)
        if typeof(s) ~= "Instance" then return false end
        local agora = relogioReal()
        local c = cacheArma[s]
        if c and agora - c.t < 3 then return c.v end
        local v = false
        if s:FindFirstAncestorOfClass("Tool") then
            v = true
        else
            local o = s
            for _ = 1, 3 do
                if not o or o == game then break end
                if tem(string.lower(o.Name), GUNWORDS) then v = true; break end
                o = o.Parent
            end
            if not v and V.universal then
                local okC, core = pcall(function() return s:IsDescendantOf(CoreGui) end)
                v = not (okC and core)   -- universal: tudo, menos os scripts do Roblox
            end
        end
        c = { v = v, t = agora }
        nossas[c] = true
        cacheArma[s] = c
        return v
    end
    GS.scriptDeArma = scriptDeArma

    -- ── Camada: variaveis do proprio script da arma (getsenv) ───
    -- Arma que guarda FireRate como variavel do script (fora de tabela):
    -- getsenv devolve as variaveis PELO NOME, ai a classificacao pega.
    local function scriptsDeArma()
        local lista = {}
        local function juntar(raiz)
            if not raiz then return end
            for _, d in ipairs(raiz:GetDescendants()) do
                if d:IsA("LocalScript") and scriptDeArma(d) then table.insert(lista, d) end
            end
        end
        juntar(LocalPlayer.Character)
        juntar(LocalPlayer:FindFirstChildOfClass("Backpack"))
        juntar(LocalPlayer:FindFirstChildOfClass("PlayerScripts"))
        juntar(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
        return lista
    end
    local function varrerAmbientes()
        if type(getsenv) ~= "function" then return end
        for _, sc in ipairs(scriptsDeArma()) do
            local ok, env = pcall(getsenv, sc)
            if ok and type(env) == "table" and not nossas[env] then pcall(analisarTabela, env) end
        end
    end

    -- ── Tools (Values e atributos): dentro da Tool ja e arma ────
    local function ler(o, attr)
        if attr then return o:GetAttribute(attr) end
        return o.Value
    end
    local function gravar(o, attr, v)
        if attr then o:SetAttribute(attr, v) else o.Value = v end
    end
    local function valorInst(x)
        if x.tipo == "flag_sim" then return true end
        if x.tipo == "flag_nao" then return false end
        if x.tipo == "modo" then return x.modo end
        return novoValor(x.tipo, x.orig)
    end
    local function corrigirInst(o, attr)
        local e = V.inst[o]
        local x = e and e[attr or ""]
        if not x then return end
        local ligada = (x.tipo == "flag_sim" or x.tipo == "flag_nao") and V.semCd or camadaLigada(x.tipo)
        if not ligada then return end
        local novo = valorInst(x)
        if novo ~= nil and ler(o, attr) ~= novo then gravar(o, attr, novo) end
    end
    local function registrarInst(o, attr, tipo, v)
        local e = V.inst[o]
        if not e then e = {}; nossas[e] = true; V.inst[o] = e end
        local chave = attr or ""
        if e[chave] then return end
        local x = { tipo = tipo, orig = v }
        if tipo == "modo" then x.modo = modoAuto(v, nil); if not x.modo then return end end
        nossas[x] = true
        e[chave] = x
        if tipo ~= "flag_sim" and tipo ~= "flag_nao" then V.nAcel = V.nAcel + 1 end
        local sinal = attr and o:GetAttributeChangedSignal(attr) or o:GetPropertyChangedSignal("Value")
        table.insert(V.sinais, sinal:Connect(function()
            if V.ativo then pcall(corrigirInst, o, attr) end
        end))
        pcall(corrigirInst, o, attr)
    end
    local function analisarTool(tool)
        local function ver(o, nome, v, attr)
            local tipo = classe(normal(nome), v)
            if tipo then registrarInst(o, attr, tipo, v) end
        end
        local function olhar(o)
            if o:IsA("ValueBase") then
                local ok, v = pcall(function() return o.Value end)
                if ok then ver(o, o.Name, v, nil) end
            end
            for nome, v in pairs(o:GetAttributes()) do ver(o, nome, v, nome) end
        end
        pcall(olhar, tool)
        for _, d in ipairs(tool:GetDescendants()) do pcall(olhar, d) end
    end
    local function varrerFerramentas()
        local char = LocalPlayer.Character
        local mochila = LocalPlayer:FindFirstChildOfClass("Backpack")
        for _, lugar in ipairs({ char or false, mochila or false }) do
            if lugar then
                for _, o in ipairs(lugar:GetChildren()) do
                    if o:IsA("Tool") then pcall(analisarTool, o) end
                end
            end
        end
    end

    -- ── Varredura da memoria (getgc), em pedacos ────────────────
    local function varrerGC()
        if V.varrendo or type(getgc) ~= "function" then return end
        V.varrendo = true
        local minha = V.geracao
        task.spawn(function()
            local ok, lista = pcall(getgc, true)
            if ok and type(lista) == "table" then
                for i = 1, #lista do
                    if not V.ativo or V.geracao ~= minha then break end
                    local o = lista[i]
                    if type(o) == "table" and not nossas[o] then pcall(analisarTabela, o) end
                    if i % 2000 == 0 then task.wait() end
                end
            end
            V.varrendo = false
            if V.ativo and V.geracao ~= minha then varrerGC() end
        end)
    end
    local function aplicar()
        if not V.ativo then return end
        V.ultimaVarredura = relogioReal()
        varrerFerramentas()
        pcall(varrerAmbientes)
        varrerGC()
    end

    -- ── Rajada: segurou o tiro = dispara a Tool sozinho ─────────
    local function armaNaMao()
        local c = LocalPlayer.Character
        return c and c:FindFirstChildOfClass("Tool")
    end
    local function segurando()
        if UserInputService:GetFocusedTextBox() then return false end
        return V.mb1 or next(V.toques) ~= nil
    end
    local function passoRajada(dt)
        local tool = armaNaMao()
        if not tool then V.acum = 0; return end
        if V.semCd and not tool.Enabled then tool.Enabled = true end   -- trava de cooldown da Tool
        if not (V.rajada and segurando()) then V.acum = 0; return end
        V.acum = V.acum + dt * V.tps
        local n = 0
        while V.acum >= 1 and n < 8 do
            V.acum = V.acum - 1; n = n + 1
            if V.semCd then tool.Enabled = true end
            -- solta e aperta: arma semi conta um clique novo; arma automatica
            -- reinicia o loop dela em vez de empilhar varios loops juntos
            pcall(tool.Deactivate, tool)
            pcall(tool.Activate, tool)
            V.disparos = V.disparos + 1
        end
        if V.acum > 8 then V.acum = 0 end
    end

    -- ── Camada: acelerar o TEMPO da arma (hookfunction) ─────────
    -- Arma que guarda a cadencia num "local" (nenhuma varredura acha) quase
    -- sempre espera com task.wait/wait/task.delay entre os tiros. Enquanto
    -- voce segura o tiro, a espera dos scripts de arma vira no maximo 1
    -- quadro; acima de 60/s algumas voltas nem esperam (2 tiros por quadro).
    -- Tambem pega a espera da recarga (ate 3s): recarga instantanea.
    local contador = setmetatable({}, { __mode = "k" })
    nossas[contador] = true
    local function deArmaAgora()
        if not V.ativo or not V.espera then return false end
        if checkcaller and checkcaller() then return false end
        if not segurando() then return false end
        local ok, sc = pcall(getcallingscript)
        if not ok or not sc then return false end
        local ok2, sim = pcall(scriptDeArma, sc)
        return ok2 and sim
    end
    local function esperaCurta(t)
        return t == nil or (type(t) == "number" and t <= 3)
    end
    local function pular()   -- true = nao cede o quadro nessa volta
        local th = coroutine.running()
        local c = (contador[th] or 0) + 1
        local k = math.max(1, math.ceil(V.tps / 60))
        if c < k then contador[th] = c; return true end
        contador[th] = 0
        return false
    end
    local function instalarEspera()
        if V.hooks then return true end
        if type(hookfunction) ~= "function" or type(getcallingscript) ~= "function" then return false end
        local nc = newcclosure or function(f) return f end
        pcall(function()
            velho.twait = hookfunction(task.wait, nc(function(t)
                if esperaCurta(t) and deArmaAgora() then
                    if pular() then return 0 end
                    return velho.twait()
                end
                return velho.twait(t)
            end))
        end)
        pcall(function()
            velho.tdelay = hookfunction(task.delay, nc(function(t, f, ...)
                if type(t) == "number" and t <= 3 and deArmaAgora() then return velho.tdelay(0, f, ...) end
                return velho.tdelay(t, f, ...)
            end))
        end)
        if type(wait) == "function" then
            pcall(function()
                velho.wait = hookfunction(wait, nc(function(t)
                    if esperaCurta(t) and deArmaAgora() then
                        if pular() then return 0, relogioReal() end
                        return velho.wait()
                    end
                    return velho.wait(t)
                end))
            end)
        end
        -- AUTOTESTE: tem executor que nao deixa esperar por dentro do hook. Se
        -- quebrar, desfaz NA HORA (senao todo script do jogo que usa wait quebraria)
        if velho.twait and not pcall(function() task.wait() end) then
            pcall(hookfunction, task.wait, velho.twait); velho.twait = nil
        end
        if velho.wait and not pcall(function() wait() end) then
            pcall(hookfunction, wait, velho.wait); velho.wait = nil
        end
        if type(delay) == "function" then
            pcall(function()
                velho.delay = hookfunction(delay, nc(function(t, f)
                    if type(t) == "number" and t <= 3 and deArmaAgora() then return velho.delay(0, f) end
                    return velho.delay(t, f)
                end))
            end)
        end
        V.hooks = velho.twait ~= nil or velho.wait ~= nil
        return V.hooks
    end

    -- ── Camada: relogio turbo (arma que usa tick() no cooldown) ─
    -- "if tick() - ultimoTiro < FireRate then return end": pros scripts de
    -- arma o relogio anda +0.25s a cada leitura enquanto voce atira, entao o
    -- cooldown ja passou sempre. O avanco NUNCA volta: script que recebeu
    -- continua recebendo (senao a arma travaria ate o tempo real alcancar).
    local recebeu = setmetatable({}, { __mode = "k" })
    nossas[recebeu] = true
    local dentro = false
    local function relogioPara(real)
        if dentro or (checkcaller and checkcaller()) then return real end
        if not V.relogio and next(recebeu) == nil then return real end
        dentro = true
        local r = real
        local ok, sc = pcall(getcallingscript)
        if ok and sc then
            if V.ativo and V.relogio and segurando() then
                local ok2, sim = pcall(scriptDeArma, sc)
                if ok2 and sim then
                    recebeu[sc] = true
                    V.offsetRelogio = V.offsetRelogio + 0.25
                end
            end
            if recebeu[sc] then r = real + V.offsetRelogio end
        end
        dentro = false
        return r
    end
    local function instalarRelogio()
        if V.relogioHooks then return true end
        if type(hookfunction) ~= "function" or type(getcallingscript) ~= "function" then return false end
        local nc = newcclosure or function(f) return f end
        pcall(function() velho.tick  = hookfunction(tick,     nc(function() return relogioPara(velho.tick())  end)) end)
        pcall(function() velho.clock = hookfunction(os.clock, nc(function() return relogioPara(velho.clock()) end)) end)
        pcall(function() velho.time  = hookfunction(time,     nc(function() return relogioPara(velho.time())  end)) end)
        V.relogioHooks = velho.tick ~= nil or velho.clock ~= nil
        return V.relogioHooks
    end

    -- ── Trava: todo frame ───────────────────────────────────────
    local function manter()
        for t, p in pairs(V.reg) do
            for k, x in pairs(p) do
                if camadaLigada(x.tipo) then
                    local novo = (x.tipo == "modo") and x.modo or novoValor(x.tipo, x.orig)
                    if novo ~= nil and rawget(t, k) ~= novo then escrever(t, k, novo) end
                end
            end
        end
        if V.semCd then
            for t, p in pairs(V.flags) do
                for k, quer in pairs(p) do
                    if rawget(t, k) ~= quer then escrever(t, k, quer) end
                end
            end
        end
        for o, e in pairs(V.inst) do
            if o.Parent == nil then
                V.inst[o] = nil
            else
                for chave in pairs(e) do pcall(corrigirInst, o, chave ~= "" and chave or nil) end
            end
        end
    end
    local function restaurar()
        V.geracao = V.geracao + 1
        for _, c in ipairs(V.sinais) do pcall(function() c:Disconnect() end) end
        table.clear(V.sinais)
        for t, p in pairs(V.reg) do
            for k, x in pairs(p) do escrever(t, k, x.orig) end
        end
        for o, e in pairs(V.inst) do
            for chave, x in pairs(e) do
                if x.tipo ~= "flag_sim" and x.tipo ~= "flag_nao" then
                    pcall(gravar, o, chave ~= "" and chave or nil, x.orig)
                end
            end
        end
        table.clear(V.reg); table.clear(V.flags); table.clear(V.inst); table.clear(cacheNome)
        V.nAcel = 0
    end

    -- ── Liga / desliga ──────────────────────────────────────────
    -- PC: qualquer clique, menos em cima do menu do script (jogo com mira em
    -- GUI no meio da tela "engole" o clique: gpe vem true mesmo atirando)
    local NUMEROS = {}
    for _, nome in ipairs({ "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }) do
        NUMEROS[Enum.KeyCode[nome]] = true
    end
    nossas[NUMEROS] = true
    local function ehTiroPC(io)
        if io.UserInputType ~= Enum.UserInputType.MouseButton1 then return false end
        if not (MainFrame and MainFrame.Visible) then return true end
        local m = UserInputService:GetMouseLocation()
        local a, t = MainFrame.AbsolutePosition, MainFrame.AbsoluteSize
        return not (m.X >= a.X and m.X <= a.X + t.X and m.Y >= a.Y and m.Y <= a.Y + t.Y)
    end
    local function ligar()
        V.ativo = true; V.ligouEm = os.clock(); V.disparos = 0
        V.mb1 = false; table.clear(V.toques)
        V.loopId = V.loopId + 1
        local meuLoop = V.loopId
        -- PC: clique fora do menu. Celular: toque no BOTAO de tiro (gpe=true);
        -- toque arrastando a camera (gpe=false) nao conta
        table.insert(V.conns, UserInputService.InputBegan:Connect(function(io, gpe)
            local atirou = false
            if ehTiroPC(io) then V.mb1 = true; atirou = true
            elseif io.UserInputType == Enum.UserInputType.Touch and gpe then V.toques[io] = true; atirou = true end
            -- comecou a atirar e a ultima varredura e velha: varre a arma da mao
            if atirou and relogioReal() - V.ultimaVarredura > 4 then task.spawn(aplicar) end
            -- trocou de arma no teclado (1 a 9): varre a arma nova
            if NUMEROS[io.KeyCode] then
                task.delay(0.4, function() if V.ativo then aplicar() end end)
            end
        end))
        table.insert(V.conns, UserInputService.InputEnded:Connect(function(io)
            if io.UserInputType == Enum.UserInputType.MouseButton1 then V.mb1 = false
            elseif io.UserInputType == Enum.UserInputType.Touch then V.toques[io] = nil end
        end))
        table.insert(V.conns, RunService.Heartbeat:Connect(function(dt)
            pcall(manter)
            pcall(passoRajada, dt)
        end))
        local function aoPersonagem(char)
            table.insert(V.conns, char.ChildAdded:Connect(function(o)
                if o:IsA("Tool") then
                    task.delay(0.35, function() if V.ativo then aplicar() end end)
                end
            end))
        end
        if LocalPlayer.Character then aoPersonagem(LocalPlayer.Character) end
        table.insert(V.conns, LocalPlayer.CharacterAdded:Connect(aoPersonagem))
        aplicar()
        task.spawn(function()
            local proxVarredura = os.clock() + 20
            while V.ativo and V.loopId == meuLoop do
                task.wait(0.5)
                if not (V.ativo and V.loopId == meuLoop) then break end
                local txt = "ON · " .. V.tps .. "/s · ARMA: " .. V.nAcel .. " ACELERADOS"
                if V.espera and V.hooks then txt = txt .. " · TEMPO TURBO" end
                if V.rajada then txt = txt .. " · " .. V.disparos .. " DISPAROS" end
                if V.nAcel == 0 and not V.varrendo and os.clock() - V.ligouEm > 3 then
                    txt = "ON · " .. V.tps .. "/s · SÓ RAJADA (CONFIG NÃO ACHADA)"
                end
                setStatus(txt)
                if os.clock() >= proxVarredura then
                    proxVarredura = os.clock() + (GS.leve and 40 or 20)
                    aplicar()
                end
            end
        end)
        if V.espera and not instalarEspera() then
            task.delay(1.2, function() GS.toast("Executor sem hookfunction", false) end)
        end
        if V.relogio then instalarRelogio() end
        togV.Text = "VELOCIDADE DA BALA: ON"
        status.TextColor3 = T.text
        setStatus("ON · PROCURANDO A ARMA...")
        GS.toast("Velocidade da bala ON", true)
        if not (GS.municao and GS.municao.ativo) then
            task.delay(0.6, function() GS.toast("Liga a munição infinita junto", true) end)
        end
    end
    local function desligar(silencioso)
        V.ativo = false; V.loopId = V.loopId + 1
        for _, c in ipairs(V.conns) do pcall(function() c:Disconnect() end) end
        V.conns = {}
        V.mb1 = false; table.clear(V.toques)
        restaurar()
        togV.Text = "VELOCIDADE DA BALA: OFF"
        status.TextColor3 = T.dim
        setStatus("STATUS: DESLIGADO")
        if not silencioso then GS.toast("Velocidade da bala desligada", false) end
    end

    -- ── Cliques ─────────────────────────────────────────────────
    togV.MouseButton1Click:Connect(function()
        if V.ativo then desligar() else ligar() end
    end)
    local function reaplicar()
        if not V.ativo then return end
        restaurar()
        aplicar()
    end
    local function chave(btn, campo, nome, refazer)
        btn.MouseButton1Click:Connect(function()
            V[campo] = not V[campo]
            btn.Text = nome .. (V[campo] and ": ON" or ": OFF")
            if refazer then reaplicar() end
        end)
    end
    chave(togC, "cadencia", "CADENCIA", true)
    chave(togA, "auto", "AUTO", true)
    chave(togS, "semCd", "SEM COOLDOWN", true)
    chave(togR, "rajada", "RAJADA", false)
    chave(togB, "bala", "BALA", true)
    local function atualizarTps()
        tpsLbl.Text = tostring(V.tps)
    end
    -- ate 60: de 5 em 5. Acima: de 10 em 10 ate 120 (2 tiros por quadro).
    -- Nao passa disso: cada tiro e uma mensagem pro servidor, e mais que isso
    -- vira enxurrada (deixa o servidor lento pra todo mundo e da kick).
    tpsMenos.MouseButton1Click:Connect(function()
        V.tps = V.tps > 60 and V.tps - 10 or math.max(5, V.tps - 5); atualizarTps()
    end)
    tpsMais.MouseButton1Click:Connect(function()
        V.tps = V.tps >= 60 and math.min(120, V.tps + 10) or V.tps + 5; atualizarTps()
    end)
    togE.MouseButton1Click:Connect(function()
        V.espera = not V.espera
        togE.Text = V.espera and "ESPERA: ON" or "ESPERA: OFF"
        if V.espera and V.ativo and not instalarEspera() then GS.toast("Executor sem hookfunction", false) end
    end)
    togRl.MouseButton1Click:Connect(function()
        V.relogio = not V.relogio
        togRl.Text = V.relogio and "RELOGIO: ON" or "RELOGIO: OFF"
        if V.relogio and V.ativo and not instalarRelogio() then GS.toast("Executor sem hookfunction", false) end
    end)
    togU.MouseButton1Click:Connect(function()
        V.universal = not V.universal
        togU.Text = V.universal and "UNIVERSAL: ON" or "UNIVERSAL: OFF"
        table.clear(cacheArma)
        reaplicar()
    end)

    ScreenGui.Destroying:Connect(function()
        if V.ativo then desligar(true) end
    end)
end
GS.rodar("Velocidade da bala", GS.iniciarVelocidade, GS.painelMunicao)

-- ═══════════════════════════════════════════════════════════════
--   SE SOLTAR (BRUTAL) — aba LIBERDADE > SE SOLTAR
-- ═══════════════════════════════════════════════════════════════
--   Algema, prender, agarrar, carregar (inclusive item VIP do jogo):
--   por baixo quase sempre e solda/corda no seu corpo, voce ancorado,
--   velocidade/pulo zerados, sentado a forca, controles/mochila
--   desligados e animacao de algemado. Aqui desfaz TUDO isso:
--   • DETECTOR: junta/constraint ligando seu corpo a algo FORA do seu
--     personagem (BasePart:GetJoints pega ate solda que mora na mao de
--     quem te prendeu), ancorado, WalkSpeed 0, sentado no boneco de outro
--     jogador, item/atributo com nome de algema (cuff/arrest/grab...).
--   • SOLTAR: quebra essas juntas, desancora, devolve velocidade/pulo,
--     religa controles/mochila/estados do Humanoid, levanta, para a
--     animacao, marca "Cuffed" etc. como false e pula pra longe de quem
--     prendeu. Segura a liberdade por 2s reaplicando (jogo que prende de
--     novo na hora). Nunca reseta nem mata o personagem.
--   Respeita o proprio script: nada "Gringo..." e mexido, o Voo (que fica
--   deitado de proposito) nao e desfeito e o CARREGAR de amigo nao e solto.
--   Obs: jogo que segura voce NO SERVIDOR (dono da fisica do seu boneco
--   passa pro servidor) pode te puxar de volta — isso o cliente nao manda.
-- ═══════════════════════════════════════════════════════════════
GS.iniciarSoltar = function()
    local U = GS.ui
    local painel = GS.painelSoltar
    if not U or not painel then
        error("UI nao pronta (GS.ui=" .. tostring(U ~= nil) .. ", GS.painelSoltar=" .. tostring(painel ~= nil) .. ")")
    end
    local T = U.T
    local StarterGui = game:GetService("StarterGui")
    local CAS = game:GetService("ContextActionService")
    local TECLA = Enum.KeyCode.Z

    local L = { auto=false, pular=true, ws=16, jp=50, jh=7.2, livreAte=0, ultimoSoltar=0,
                soltou=0, motivo="", captor=nil, conns={} }
    GS.liberdade = L

    -- ── UI ──────────────────────────────────────────────────────
    local g = U.grupo(painel, "Se Soltar", "Te prenderam (algema, agarrar, carregar)? Um clique e você tá livre", "shield-check", 1)
    local botao = U.acao(g, "SE SOLTAR AGORA (TECLA Z)", "zap", 1)
    local status = U.pequeno(g, "STATUS: LIVRE", nil, 2)
    status.AutoButtonColor = false; status.TextColor3 = T.dim
    local gb = U.grupo(painel, "Modo brutal", "Solta sozinho no instante em que te prendem", "flame", 2)
    local togAuto = U.tog(gb, "Soltar sozinho (automático)", 1, "shield")
    local togPulo = U.tog(gb, "Pular pra longe de quem prendeu", 2, "rabbit")
    togPulo.Text = "PULO: ON"

    -- ── Palavras de algema/prisao ───────────────────────────────
    local PALAVRAS = { "cuff", "algema", "arrest", "preso", "prender", "restrain", "detain", "jail",
                       "captur", "grab", "agarr", "carry", "carreg", "ziptie", "tied", "taser", "tased",
                       "stun", "rope", "corda", "hostage", "refem", "kidnap", "sequestr", "drag" }
    local function temPalavra(nome)
        local n = string.lower(nome)
        for _, p in ipairs(PALAVRAS) do
            if string.find(n, p, 1, true) then return true end
        end
        return false
    end
    local function nosso(o) return string.sub(o.Name, 1, 6) == "Gringo" end

    -- ── O que te prende ─────────────────────────────────────────
    -- parte do outro lado de uma junta/constraint (nil se nao tiver)
    local function outroLado(j, minha)
        local a, b
        if j:IsA("JointInstance") or j:IsA("WeldConstraint") or j:IsA("NoCollisionConstraint") then
            a, b = j.Part0, j.Part1
        elseif j:IsA("Constraint") then
            a = j.Attachment0 and j.Attachment0.Parent
            b = j.Attachment1 and j.Attachment1.Parent
        end
        if a == minha then return b end
        if b == minha then return a end
        return a ~= nil and not a:IsDescendantOf(minha.Parent or minha) and a or b
    end
    local function ehPersonagemDeOutro(o)
        local m = o and o:FindFirstAncestorOfClass("Model")
        while m do
            local p = Players:GetPlayerFromCharacter(m)
            if p then return p ~= LocalPlayer end
            m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model")
        end
        return false
    end
    -- junta "de prender": liga voce a algo fora do seu boneco (cadeira normal nao conta)
    local function juntasDePrender(char)
        local lista = {}
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                local ok, juntas = pcall(function() return p:GetJoints() end)
                if ok then
                    for _, j in ipairs(juntas) do
                        if not nosso(j) then
                            local outro = outroLado(j, p)
                            if outro and outro:IsA("BasePart") and not outro:IsDescendantOf(char) then
                                local cadeira = j.Name == "SeatWeld" and outro:IsA("Seat") or outro:IsA("VehicleSeat")
                                if not cadeira or ehPersonagemDeOutro(outro) then
                                    table.insert(lista, { j = j, outro = outro })
                                end
                            end
                        end
                    end
                end
            end
        end
        return lista
    end
    local function marcadores(char)
        local lista = {}
        for _, raiz in ipairs({ char, LocalPlayer }) do
            for _, d in ipairs(raiz:GetDescendants()) do
                if d:IsA("BoolValue") and d.Value and temPalavra(d.Name) and not nosso(d) then
                    table.insert(lista, { o = d })
                end
            end
            for _, o in ipairs({ raiz, char:FindFirstChildOfClass("Humanoid") }) do
                if o then
                    for nome, v in pairs(o:GetAttributes()) do
                        if v == true and temPalavra(nome) then table.insert(lista, { o = o, attr = nome }) end
                    end
                end
            end
        end
        return lista
    end
    local function carregadoPorAmigo()
        -- Carregar do proprio script (amigo te carrega ou voce nas costas dele): nao solta
        local CE = GS.carregarEstado
        return CE ~= nil and (CE.carregadoPor ~= nil or CE.costas == true)
    end

    -- motivo (texto) se voce esta preso, ou nil
    local function preso(char, hum, root)
        if carregadoPorAmigo() then return nil end
        local juntas = juntasDePrender(char)
        if #juntas > 0 then
            L.captor = juntas[1].outro
            local quem = juntas[1].outro:FindFirstAncestorOfClass("Model")
            return "PRESO EM " .. string.upper(quem and quem.Name or juntas[1].outro.Name)
        end
        if root.Anchored then return "ANCORADO" end
        if hum.Sit and hum.SeatPart and ehPersonagemDeOutro(hum.SeatPart) then
            L.captor = hum.SeatPart; return "SENTADO EM OUTRO JOGADOR"
        end
        if not hum.Sit and hum.WalkSpeed == 0 then return "VELOCIDADE ZERADA" end
        if #marcadores(char) > 0 then return "MARCADO COMO PRESO" end
        for _, d in ipairs(char:GetChildren()) do
            if not d:IsA("Tool") and not nosso(d) and temPalavra(d.Name) then return "ITEM DE ALGEMA NO CORPO" end
        end
        return nil
    end

    -- ── Soltar ──────────────────────────────────────────────────
    local MOVERS = { BodyPosition=true, BodyVelocity=true, BodyGyro=true, BodyForce=true, BodyThrust=true,
                     BodyAngularVelocity=true, RocketPropulsion=true, LinearVelocity=true, AngularVelocity=true,
                     VectorForce=true, AlignPosition=true, AlignOrientation=true, LineForce=true, Torque=true }
    local ESTADOS = { Enum.HumanoidStateType.Running, Enum.HumanoidStateType.Jumping,
                      Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Freefall,
                      Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.Landed,
                      Enum.HumanoidStateType.RunningNoPhysics }
    local function soltar(char, hum, root, forte)
        local captorPos = L.captor and L.captor.Parent and L.captor.Position or nil
        -- 1) quebra solda/corda com quem prendeu
        for _, x in ipairs(juntasDePrender(char)) do
            captorPos = captorPos or x.outro.Position
            pcall(function() x.j:Destroy() end)
        end
        -- 2) item de algema e movers estranhos no seu corpo
        for _, d in ipairs(char:GetDescendants()) do
            if not nosso(d) then
                if MOVERS[d.ClassName] and not (flyAtivado and d:IsA("BodyMover")) then
                    pcall(function() d:Destroy() end)
                elseif d:IsA("BasePart") then
                    if d.Anchored then pcall(function() d.Anchored = false end) end
                elseif forte and d.Parent == char and not d:IsA("Tool") and not d:IsA("Humanoid")
                and not d:IsA("BasePart") and temPalavra(d.Name) then
                    pcall(function() d:Destroy() end)
                end
            end
        end
        -- 3) marcadores "Cuffed/Arrested" = false (scripts do seu PC leem isso)
        for _, mk in ipairs(marcadores(char)) do
            pcall(function()
                if mk.attr then mk.o:SetAttribute(mk.attr, false) else mk.o.Value = false end
            end)
        end
        -- 4) pernas de volta
        pcall(function()
            for _, e in ipairs(ESTADOS) do hum:SetStateEnabled(e, true) end
            if hum.WalkSpeed < L.ws then hum.WalkSpeed = L.ws end
            if hum.UseJumpPower then
                if hum.JumpPower < L.jp then hum.JumpPower = L.jp end
            elseif hum.JumpHeight < L.jh then hum.JumpHeight = L.jh end
            if hum.Sit then hum.Sit = false end
            if hum.PlatformStand and not flyAtivado then hum.PlatformStand = false end
            hum.AutoRotate = true
            if not flyAtivado then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end)
        -- 5) animacao de algemado / agarrado para
        pcall(function()
            local animator = hum:FindFirstChildOfClass("Animator")
            for _, tr in ipairs(animator and animator:GetPlayingAnimationTracks() or {}) do
                local nome = (tr.Animation and tr.Animation.Name or "") .. " " .. tr.Name
                if temPalavra(nome) then tr:Stop(0) end
            end
        end)
        -- 6) controles e mochila de volta
        pcall(function()
            local pm = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
            local mod = pm and pm:FindFirstChild("PlayerModule")
            if mod then require(mod):GetControls():Enable() end
        end)
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
        pcall(function()
            for nome in pairs(CAS:GetAllBoundActionInfo()) do
                if temPalavra(nome) then CAS:UnbindAction(nome) end
            end
        end)
        -- 7) pula pra longe de quem prendeu (so no primeiro golpe)
        if forte and L.pular and not flyAtivado then
            pcall(function()
                local de = captorPos or (root.Position - root.CFrame.LookVector * 5)
                local dir = root.Position - de
                dir = Vector3.new(dir.X, 0, dir.Z)
                if dir.Magnitude < 0.1 then dir = -root.CFrame.LookVector end
                local rot = root.CFrame - root.Position
                root.CFrame = CFrame.new(root.Position + dir.Unit * 10 + Vector3.new(0, 3, 0)) * rot
                root.AssemblyLinearVelocity = Vector3.zero
            end)
        end
        L.captor = nil
    end

    -- botao/tecla: solta forte e segura a liberdade por 2s
    local function soltarAgora(manual)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not (hum and root) then return end
        local agora = os.clock()
        if agora - L.ultimoSoltar < 0.25 then return end
        L.ultimoSoltar = agora
        pcall(soltar, char, hum, root, true)
        L.livreAte = agora + 2
        L.soltou = L.soltou + 1
        if manual then GS.toast("Livre!", true) end
    end

    -- ── Loop: guarda velocidade normal, detecta e (auto) solta ──
    local proxCheck = 0
    table.insert(L.conns, RunService.Heartbeat:Connect(function()
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not (hum and root) or hum.Health <= 0 then return end
            local agora = os.clock()
            -- segurando a liberdade logo depois de soltar
            if agora < L.livreAte then pcall(soltar, char, hum, root, false) end
            if agora < proxCheck then return end
            proxCheck = agora + 0.1
            local motivo = preso(char, hum, root)
            if not motivo then
                -- livre: guarda a velocidade/pulo normal desse jogo
                if hum.WalkSpeed > 0 then L.ws = hum.WalkSpeed end
                if hum.JumpPower > 0 then L.jp = hum.JumpPower end
                if hum.JumpHeight > 0 then L.jh = hum.JumpHeight end
                status.Text = "STATUS: LIVRE" .. (L.soltou > 0 and ("  ·  SOLTOU " .. L.soltou .. "x") or "")
                status.TextColor3 = T.dim
            else
                status.Text = "STATUS: " .. motivo .. (L.auto and "  ·  SOLTANDO..." or "  ·  APERTA Z")
                status.TextColor3 = T.text
                if L.auto then soltarAgora(false) end
            end
        end)
    end))

    -- ── Cliques / tecla ─────────────────────────────────────────
    botao.MouseButton1Click:Connect(function() soltarAgora(true) end)
    table.insert(L.conns, UserInputService.InputBegan:Connect(function(io, gpe)
        if gpe or UserInputService:GetFocusedTextBox() then return end
        if io.KeyCode == TECLA then soltarAgora(true) end
    end))
    togAuto.MouseButton1Click:Connect(function()
        L.auto = not L.auto
        togAuto.Text = L.auto and "AUTO: ON" or "AUTO: OFF"
    end)
    togPulo.MouseButton1Click:Connect(function()
        L.pular = not L.pular
        togPulo.Text = L.pular and "PULO: ON" or "PULO: OFF"
    end)

    ScreenGui.Destroying:Connect(function()
        for _, c in ipairs(L.conns) do pcall(function() c:Disconnect() end) end
        L.conns = {}
    end)
end
GS.rodar("Se Soltar", GS.iniciarSoltar, GS.painelSoltar)

-- MODO LEVE (CONFIGURACOES): pra PC fraco / Windows 10 que crasha.
-- Pausa as animacoes em loop (borda girando, brilho do titulo), desliga o
-- efeito de onda dos cliques e deixa a checagem das chaves mais espacada.
do
    if GS.leveBtn then
        GS.leveBtn.MouseButton1Click:Connect(function()
            GS.leve = not GS.leve
            GS.leveBtn.Text = GS.leve and "MODO LEVE: ON" or "MODO LEVE: OFF"
            for _, anim in ipairs(GS.animsInfinitas) do
                pcall(function() if GS.leve then anim:Pause() else anim:Play() end end)
            end
            GS.toast(GS.leve and "🪶  Modo leve ligado" or "🪶  Modo leve desligado", GS.leve)
        end)
    end
end

-- SYNC DAS CHAVES: a cada 0.3s toda chave do painel confere o estado real
-- da funcao (texto ON/OFF) e corrige o desenho se estiver errado.
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        for _, f in ipairs(GS.syncToggles or {}) do pcall(f) end
        task.wait(GS.leve and 0.8 or 0.3)
    end
end)

-- ABERTURA SILENCIOSA: nada liga sozinho (toda funcao principal nasce OFF) e
-- os avisos de "ativado/desativado" so valem depois que tudo carregou e as
-- chaves sincronizaram (o sync roda a cada 0.3s; 2s cobre com folga).
task.delay(2, function() GS.avisosLiberados = true end)
