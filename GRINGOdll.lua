-- GRINGOdll V50.20 · Feito pelo @henrique_system
-- Encerra a execucao anterior quando ela ja possui o registro de recursos.
do
    local ok,ambiente=pcall(function() return type(getgenv)=="function" and getgenv() or _G end)
    if ok and type(ambiente.__GringoEncerrar)=="function" then pcall(ambiente.__GringoEncerrar) end
end
-- Garante que o menu anterior seja limpo antes de rodar o novo
-- (procura no CoreGui e no gethui(), onde o menu pode estar)
do
    local pais = { game.CoreGui }
    pcall(function() if gethui then table.insert(pais, gethui()) end end)
    pcall(function()
        local jogador = game:GetService("Players").LocalPlayer
        local playerGui = jogador and jogador:FindFirstChildOfClass("PlayerGui")
        if playerGui then table.insert(pais, playerGui) end
    end)
    for _, pai in ipairs(pais) do
        for _, velho in ipairs(pai:GetChildren()) do
            if velho.Name == "GringoScripts" or velho.Name == "FarmaMarcadores" then
                velho:Destroy()
            end
        end
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
-- Recursos pertencentes apenas a esta execucao do painel.
GS.recursos={conexoes={},tarefas={},ativos={},instancias={},tweens={},renders={},limpezas={}}
GS.rawTask={spawn=task.spawn,defer=task.defer,delay=task.delay,cancel=task.cancel}
GS.fechando=false
GS.encerrado=false
function GS.tentar(nome,fn,...)
    local ok,erro=pcall(fn,...)
    if not ok then warn("[DEBUG-BOT]: Encerrar:",nome,erro) end
    return ok
end
function GS.conectar(sinal,fn)
    local limpeza
    if GS.tela and sinal==GS.tela.Destroying then
        limpeza={fn=fn,feita=false}
        table.insert(GS.recursos.limpezas,limpeza)
    end
    local conn=sinal:Connect(function(...)
        if limpeza then
            if limpeza.feita then return end
            limpeza.feita=true
        elseif GS.fechando or GS.encerrado then return end
        local th=coroutine.running()
        GS.recursos.ativos[th]=true
        local ok,erro=pcall(fn,...)
        GS.recursos.ativos[th]=nil
        if not ok then warn("[DEBUG-BOT]: Evento do painel:",erro) end
    end)
    GS.recursos.conexoes[conn]=true
    GS.contaConexoes=(GS.contaConexoes or 0)+1
    if GS.contaConexoes%256==0 then
        for c in pairs(GS.recursos.conexoes) do if not c.Connected then GS.recursos.conexoes[c]=nil end end
    end
    return conn
end
function GS.agendar(modo,tempo,fn,...)
    if (GS.fechando or GS.encerrado) and not GS.emLimpeza then return nil end
    local limpeza=GS.emLimpeza
    local th
    if type(fn)=="thread" then
        th=fn
    else
        th=coroutine.create(function(...)
            if GS.fechando and not limpeza then return end
            local ok,erro=pcall(fn,...)
            GS.recursos.tarefas[th]=nil
            if not ok and not GS.fechando then warn("[DEBUG-BOT]: Tarefa do painel:",erro) end
        end)
    end
    -- Restauracoes iniciadas no encerramento precisam terminar seus lotes.
    if not limpeza then GS.recursos.tarefas[th]=true end
    if modo=="delay" then GS.rawTask.delay(tempo,th,...)
    else GS.rawTask[modo](th,...) end
    return th
end
function GS.spawn(fn,...) return GS.agendar("spawn",nil,fn,...) end
function GS.defer(fn,...) return GS.agendar("defer",nil,fn,...) end
function GS.delay(tempo,fn,...) return GS.agendar("delay",tempo,fn,...) end
function GS.guardarInstancia(obj)
    if not GS.emLimpeza and not obj:IsA("JointInstance") and not obj:IsA("Animator") then
        GS.recursos.instancias[obj]=true
        obj.Destroying:Once(function() GS.recursos.instancias[obj]=nil end)
    end
    return obj
end
function GS.novaInstancia(...) return GS.guardarInstancia(Instance.new(...)) end
function GS.clonar(obj,...) return GS.guardarInstancia(obj:Clone(...)) end
function GS.criarTween(servico,...)
    local tw=servico:Create(...)
    GS.recursos.tweens[tw]=true
    tw.Completed:Once(function() GS.recursos.tweens[tw]=nil end)
    return tw
end
function GS.bindRender(servico,nome,...)
    GS.recursos.renders[nome]=servico
    return servico:BindToRenderStep(nome,...)
end
function GS.pararRecursos()
    if GS.encerrado or GS.fechando then return false end
    GS.fechando=true
    local atual=coroutine.running()
    for _,lista in ipairs({GS.recursos.tarefas,GS.recursos.ativos}) do
        for th in pairs(lista) do
            if th~=atual and coroutine.status(th)~="dead" then
                GS.tentar("cancelar tarefa",GS.rawTask.cancel,th)
            end
        end
    end
    GS.emLimpeza=true
    for _,r in ipairs(GS.recursos.limpezas) do
        if not r.feita then r.feita=true; GS.tentar("limpeza de modulo",r.fn) end
    end
    GS.emLimpeza=false
    return true
end
function GS.finalizarRecursos()
    for nome,servico in pairs(GS.recursos.renders) do
        GS.tentar("render",function() servico:UnbindFromRenderStep(nome) end)
    end
    for tw in pairs(GS.recursos.tweens) do GS.tentar("animacao",function() tw:Cancel() end) end
    for conn in pairs(GS.recursos.conexoes) do GS.tentar("evento",function() conn:Disconnect() end) end
    for obj in pairs(GS.recursos.instancias) do
        GS.tentar("objeto local",function() obj:Destroy() end)
    end
    for _,lista in pairs(GS.recursos) do table.clear(lista) end
    GS.encerrado=true
    print("[DEBUG-BOT]: Encerrar tudo: tarefas, eventos e objetos locais removidos")
end

GS.versao = "V50.20"
GS.credito = "Feito pelo @henrique_system"
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
--   VISUAL V50.5 — VIDRO AZUL CLARO, BISEL VERDE-AGUA + ICONES LUCIDE
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
        -- V50.5: vidro claro; tons da borda amostrados da foto de referencia.
        bg        = Color3.fromRGB(185, 219, 230),
        header    = Color3.fromRGB(211, 237, 241),
        side      = Color3.fromRGB(139, 205, 202),
        card      = Color3.fromRGB(191, 231, 231),
        cardHover = Color3.fromRGB(146, 217, 209),
        ctrl      = Color3.fromRGB(169, 218, 218),
        stroke    = Color3.fromRGB(35, 167, 154),
        strokeHi  = Color3.fromRGB(173, 255, 235),
        text      = Color3.fromRGB(5, 28, 31),
        dim       = Color3.fromRGB(7, 34, 37),
        mute      = Color3.fromRGB(9, 39, 42),
        on        = Color3.fromRGB(4, 95, 92),
        onText    = Color3.fromRGB(234, 255, 250),
        off       = Color3.fromRGB(120, 174, 175),
        knobOn    = Color3.fromRGB(234, 255, 250),
        knobOff   = Color3.fromRGB(34, 91, 94),
        perigo    = Color3.fromRGB(132, 43, 66),
        perigoTxt = Color3.fromRGB(255, 237, 240),
        roxoA     = Color3.fromRGB(221, 240, 250),
        roxoB     = Color3.fromRGB(145, 208, 210),
        vidro     = Color3.fromRGB(181, 229, 225),
        bordaFunda= Color3.fromRGB(4, 95, 92),
        bordaLuz  = Color3.fromRGB(99, 229, 215),
    }
    -- Transparencia do vidro (0 = solido, 1 = invisivel).
    -- Quer a janela mais transparente? aumenta "janela" (ex: 0.35).
    local V = {
        janela = 0.30,
        campo  = 0.46,
        linha  = 0.34,
        grupo  = 0.60,
        borda  = 0.48,
        card   = 0.24,
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
        local tween = GS.criarTween(TweenService,o, TweenInfo.new(t or 0.22, estilo or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
        tween:Play()
        return tween
    end
    local function mkC(r,p) GS.novaInstancia("UICorner",p).CornerRadius=UDim.new(0,r) end
    local function mkS(t,c,p,tr) local s=GS.novaInstancia("UIStroke",p); s.Thickness=t; s.Color=c; s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s end
    local function redondo(p) GS.novaInstancia("UICorner",p).CornerRadius=UDim.new(1,0) end

    local function icone(pai, nome, tam, cor)
        local d = nome and ICONES[nome]
        if not d then return nil end
        local im = GS.novaInstancia("ImageLabel")
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
        GS.conectar(o:GetPropertyChangedSignal("BackgroundColor3"),ajustar)
    end
    local function mkCVidro(r, p) mkC(r, p); vidro(p) end

    -- efeito de onda ao clicar
    local function ripple(btn)
        btn.ClipsDescendants=true
        GS.conectar(btn.MouseButton1Down,function()
            if GS.leve then return end
            local m=UserInputService:GetMouseLocation()
            local c=GS.novaInstancia("Frame")
            c.AnchorPoint=Vector2.new(0.5,0.5); c.BackgroundColor3=BRANCO
            c.BackgroundTransparency=0.82; c.BorderSizePixel=0; c.ZIndex=btn.ZIndex+1
            c.Position=UDim2.fromOffset(m.X-btn.AbsolutePosition.X, m.Y-btn.AbsolutePosition.Y)
            c.Size=UDim2.fromOffset(0,0); redondo(c); c.Parent=btn
            local d=math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y)*2.2
            tw(c,{Size=UDim2.fromOffset(d,d), BackgroundTransparency=1},0.6)
            GS.delay(0.65,function() c:Destroy() end)
        end)
    end
    -- aperta (encolhe) e volta com elastico
    local function press(btn)
        local sc=GS.novaInstancia("UIScale",btn)
        GS.conectar(btn.MouseButton1Down,function() tw(sc,{Scale=0.96},0.08) end)
        local function volta() tw(sc,{Scale=1},0.35,Enum.EasingStyle.Back) end
        GS.conectar(btn.MouseButton1Up,volta); GS.conectar(btn.MouseLeave,volta)
    end
    -- vidro clareia no hover (mexe so na transparencia, nao na cor)
    local function hover(btn)
        local base
        GS.conectar(btn.MouseEnter,function()
            base=btn.BackgroundTransparency
            tw(btn,{BackgroundTransparency=math.max(0, base-0.08)},0.15)
        end)
        GS.conectar(btn.MouseLeave,function()
            if base then tw(btn,{BackgroundTransparency=base},0.2) base=nil end
        end)
    end
    local function vidroRoxo(o, rot)
        -- UIGradient multiplica a cor de fundo: branco preserva a paleta exata.
        o.BackgroundColor3 = BRANCO
        local g = GS.novaInstancia("UIGradient", o)
        g.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0,T.roxoA),
            ColorSequenceKeypoint.new(0.52,Color3.fromRGB(187,225,234)),
            ColorSequenceKeypoint.new(1,T.roxoB),
        }
        g.Rotation = rot or 60
        return g
    end

    ScreenGui = GS.novaInstancia("ScreenGui")
    GS.tela=ScreenGui
    ScreenGui.Name = "GringoScripts"; ScreenGui.DisplayOrder = 99
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GS.pai

    -- ── Notificacoes (canto inferior direito) ──
    local ToastBox=GS.novaInstancia("Frame",ScreenGui)
    ToastBox.AnchorPoint=Vector2.new(1,1); ToastBox.Position=UDim2.new(1,-18,1,-18)
    ToastBox.Size=UDim2.new(0,280,0,320); ToastBox.BackgroundTransparency=1
    do
        local l=GS.novaInstancia("UIListLayout",ToastBox); l.VerticalAlignment=Enum.VerticalAlignment.Bottom
        l.HorizontalAlignment=Enum.HorizontalAlignment.Right; l.Padding=UDim.new(0,8); l.SortOrder=Enum.SortOrder.LayoutOrder
    end
    local toastN=0
    GS.toast = function(msg, ligado)
        toastN=toastN+1
        local holder=GS.novaInstancia("Frame",ToastBox); holder.Size=UDim2.new(0,268,0,46)
        holder.BackgroundTransparency=1; holder.LayoutOrder=toastN
        local card=GS.novaInstancia("Frame",holder); card.Size=UDim2.new(1,0,1,0); card.Position=UDim2.new(0,300,0,0)
        card.BackgroundTransparency=0.1; card.BorderSizePixel=0; vidroRoxo(card, 0)
        mkC(18,card); mkS(1,BRANCO,card,0.78)
        local bolha=GS.novaInstancia("Frame",card); bolha.Size=UDim2.fromOffset(26,26); bolha.Position=UDim2.new(0,10,0.5,-13)
        bolha.BackgroundColor3 = ligado==false and T.off or T.on; bolha.BorderSizePixel=0; redondo(bolha)
        icone(bolha, ligado==false and "x" or "check", 14, BRANCO)
        local l=GS.novaInstancia("TextLabel",card); l.Size=UDim2.new(1,-56,1,0); l.Position=UDim2.new(0,46,0,0)
        l.BackgroundTransparency=1; l.Font=Enum.Font.GothamMedium; l.TextSize=12; l.TextColor3=T.text
        l.TextXAlignment=Enum.TextXAlignment.Left; l.TextTruncate=Enum.TextTruncate.AtEnd
        l.Text=semEmoji(tostring(msg))
        tw(card,{Position=UDim2.new(0,0,0,0)},0.45,Enum.EasingStyle.Back)
        GS.delay(2.4,function()
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
                    local lbl = GS.novaInstancia("TextLabel")
                    lbl.Size = UDim2.new(1, -20, 0, 160); lbl.Position = UDim2.fromOffset(10, 10)
                    lbl.BackgroundColor3 = Color3.fromRGB(45, 10, 10); lbl.BackgroundTransparency = 0.1
                    lbl.BorderSizePixel = 0; lbl.TextColor3 = Color3.fromRGB(255, 130, 130)
                    lbl.TextWrapped = true; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
                    lbl.TextYAlignment = Enum.TextYAlignment.Top
                    lbl.Text = nome .. " falhou ao montar:\n\n" .. tostring(err)
                    lbl.ZIndex = 50; lbl.Parent = painelErro
                    local c = GS.novaInstancia("UICorner", lbl); c.CornerRadius = UDim.new(0, 10)
                    local pad = GS.novaInstancia("UIPadding", lbl)
                    pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
                    pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
                end)
            end
        end
        return ok
    end

    -- ═══════════════ JANELA ═══════════════
    local TITULO_H = 44   -- barra do nome, versao e autoria
    local W, H = 860, 570 + TITULO_H
    local HEADER_H = 52
    MainFrame = GS.novaInstancia("Frame")
    MainFrame.Size = UDim2.fromOffset(W, H); MainFrame.Position = UDim2.new(0.5,-W/2,0.5,-H/2)
    MainFrame.BackgroundTransparency = V.janela; MainFrame.BorderSizePixel = 0
    MainFrame.Active = true; MainFrame.Parent = ScreenGui
    MainFrame.ClipsDescendants = true
    vidroRoxo(MainFrame, 60)
    mkC(14, MainFrame)
    -- V50.5: chapa de vidro com espessura, bisel e reflexo em movimento.
    do
        local laminas = {}
        local function lamina(nome,dx,dy,margem,cor,transparencia)
            local f = GS.novaInstancia("Frame")
            f.Name = nome
            f.BorderSizePixel = 0
            f.BackgroundColor3 = cor
            f.BackgroundTransparency = transparencia
            f.ZIndex = 0
            f.Active = false
            f.Parent = ScreenGui
            mkC(14+margem,f)
            local sc = GS.novaInstancia("UIScale",f)
            local item = {obj=f,dx=dx,dy=dy,margem=margem,scale=sc}
            table.insert(laminas,item)
            return f
        end
        -- Sombra deslocada, suave em camadas, abaixo das faces do vidro.
        for i=4,1,-1 do
            lamina("SombraVidro"..i,3,7+i,i*2,Color3.fromRGB(3,39,42),0.94)
        end
        for i=2,1,-1 do
            local f = lamina("EspessuraVidro"..i,i*3,i*4,0,T.bordaFunda,0.80)
            local st = mkS(2,T.bordaFunda,f,0.25)
            local g = GS.novaInstancia("UIGradient",st)
            g.Rotation = 55
            g.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0,T.bordaLuz),
                ColorSequenceKeypoint.new(0.45,T.stroke),
                ColorSequenceKeypoint.new(1,T.bordaFunda),
            }
        end
        local function atualizarLaminas()
            for _,item in ipairs(laminas) do
                local f = item.obj
                f.Position = MainFrame.Position+UDim2.fromOffset(
                    item.dx-item.margem,item.dy-item.margem)
                f.Size = MainFrame.Size+UDim2.fromOffset(item.margem*2,item.margem*2)
                f.Visible = MainFrame.Visible
            end
        end
        local function acompanharEscala(obj)
            if not obj:IsA("UIScale") then return end
            local function copiar()
                for _,item in ipairs(laminas) do item.scale.Scale=obj.Scale end
            end
            GS.conectar(obj:GetPropertyChangedSignal("Scale"),copiar)
            copiar()
        end
        GS.conectar(MainFrame:GetPropertyChangedSignal("Position"),atualizarLaminas)
        GS.conectar(MainFrame:GetPropertyChangedSignal("Size"),atualizarLaminas)
        GS.conectar(MainFrame:GetPropertyChangedSignal("Visible"),atualizarLaminas)
        GS.conectar(MainFrame.ChildAdded,acompanharEscala)
        for _,obj in ipairs(MainFrame:GetChildren()) do acompanharEscala(obj) end
        GS.conectar(MainFrame.Destroying,function()
            for _,item in ipairs(laminas) do item.obj:Destroy() end
        end)
        atualizarLaminas()

        local borda = mkS(4,BRANCO,MainFrame,0.12)
        borda.Name = "BordaVidroPolida"
        local bisel = GS.novaInstancia("UIGradient",borda)
        bisel.Rotation = 55
        bisel.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0,T.bordaLuz),
            ColorSequenceKeypoint.new(0.18,T.stroke),
            ColorSequenceKeypoint.new(0.50,T.bordaFunda),
            ColorSequenceKeypoint.new(0.78,T.stroke),
            ColorSequenceKeypoint.new(1,T.bordaLuz),
        }

        local interior = GS.novaInstancia("Frame",MainFrame)
        interior.Name = "BiselInterno"
        interior.Size = UDim2.new(1,-10,1,-10)
        interior.Position = UDim2.fromOffset(5,5)
        interior.BackgroundTransparency = 1
        interior.BorderSizePixel = 0
        interior.ZIndex = 0
        mkC(10,interior)
        local contorno = mkS(1,Color3.fromRGB(229,255,250),interior,0.25)
        local luzBorda = GS.novaInstancia("UIGradient",contorno)
        luzBorda.Rotation = 55
        luzBorda.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0,0),
            NumberSequenceKeypoint.new(0.35,0.65),
            NumberSequenceKeypoint.new(0.7,0.85),
            NumberSequenceKeypoint.new(1,0.1),
        }

        local reflexo = GS.novaInstancia("Frame",MainFrame)
        reflexo.Name = "ReflexoVidro"
        reflexo.Size = UDim2.fromScale(1,1)
        reflexo.BackgroundColor3 = Color3.fromRGB(221,255,250)
        reflexo.BackgroundTransparency = 0.65
        reflexo.BorderSizePixel = 0
        reflexo.ZIndex = 0
        mkC(14,reflexo)
        local faixa = GS.novaInstancia("UIGradient",reflexo)
        faixa.Rotation = 24
        faixa.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0,1),
            NumberSequenceKeypoint.new(0.40,1),
            NumberSequenceKeypoint.new(0.47,0.6),
            NumberSequenceKeypoint.new(0.50,0.1),
            NumberSequenceKeypoint.new(0.54,0.72),
            NumberSequenceKeypoint.new(0.62,1),
            NumberSequenceKeypoint.new(1,1),
        }
        faixa.Offset = Vector2.new(-1.1,0)
        local deslizar = GS.criarTween(TweenService,faixa,
            TweenInfo.new(11,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
            {Offset=Vector2.new(1.1,0)})
        deslizar:Play()
        table.insert(GS.animsInfinitas,deslizar)
        local respirar = GS.criarTween(TweenService,luzBorda,
            TweenInfo.new(8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
            {Offset=Vector2.new(0.20,0)})
        respirar:Play()
        table.insert(GS.animsInfinitas,respirar)
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
        local fundo = GS.novaInstancia("Frame")
        fundo.Name = "GringoSplash"; fundo.Size = UDim2.fromScale(1, 1)
        fundo.BackgroundColor3 = Color3.fromRGB(0, 0, 0); fundo.BackgroundTransparency = 1
        fundo.BorderSizePixel = 0; fundo.ZIndex = 200; fundo.Parent = ScreenGui
        tw(fundo, {BackgroundTransparency = 0.12}, 0.4)
        -- brilho roxo atras do nome, respirando
        local halo = GS.novaInstancia("Frame", fundo)
        halo.AnchorPoint = Vector2.new(0.5, 0.5); halo.Position = UDim2.new(0.5, 0, 0.5, -40)
        halo.Size = UDim2.fromOffset(120, 120); halo.BackgroundColor3 = T.on; halo.BackgroundTransparency = 1
        halo.BorderSizePixel = 0; halo.ZIndex = 201; redondo(halo)
        local hg = GS.novaInstancia("UIGradient", halo); hg.Rotation = 90
        hg.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }
        tw(halo, {Size = UDim2.fromOffset(560, 560), BackgroundTransparency = 0.62}, 1.1, Enum.EasingStyle.Quint)
        GS.delay(1.1, function()
            if not halo.Parent then return end
            local r = GS.criarTween(TweenService,halo, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { Size = UDim2.fromOffset(640, 640), BackgroundTransparency = 0.72 })
            r:Play(); table.insert(vivos, r)
        end)
        -- GRINGO
        local linha = GS.novaInstancia("Frame", fundo)
        linha.AnchorPoint = Vector2.new(0.5, 0.5); linha.Position = UDim2.new(0.5, 0, 0.5, -54)
        linha.Size = UDim2.fromOffset(0, 84); linha.AutomaticSize = Enum.AutomaticSize.X
        linha.BackgroundTransparency = 1; linha.ZIndex = 202
        do
            local l = GS.novaInstancia("UIListLayout", linha); l.FillDirection = Enum.FillDirection.Horizontal
            l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 4)
            l.VerticalAlignment = Enum.VerticalAlignment.Center
        end
        local letras = {}
        for i = 1, #NOME do
            local caixa = GS.novaInstancia("Frame", linha)
            caixa.BackgroundTransparency = 1; caixa.LayoutOrder = i; caixa.ZIndex = 202
            caixa.Size = UDim2.fromOffset(0, 84); caixa.AutomaticSize = Enum.AutomaticSize.X
            local t = GS.novaInstancia("TextLabel", caixa)
            t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBlack; t.TextSize = 76
            t.Text = string.sub(NOME, i, i); t.TextColor3 = BRANCO; t.TextTransparency = 1
            t.Size = UDim2.fromOffset(0, 84); t.AutomaticSize = Enum.AutomaticSize.X
            t.Position = UDim2.fromOffset(0, 40); t.ZIndex = 203
            local g = GS.novaInstancia("UIGradient", t); g.Rotation = 90
            g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 170))
            local st = GS.novaInstancia("UIStroke", t); st.Color = T.on; st.Thickness = 2; st.Transparency = 1
            letras[i] = { t = t, st = st }
        end
        for i, L in ipairs(letras) do
            GS.delay((i - 1) * 0.08, function()
                tw(L.t, {Position = UDim2.fromOffset(0, 0), TextTransparency = 0}, 0.5, Enum.EasingStyle.Back)
                tw(L.st, {Transparency = 0.45}, 0.5)
            end)
        end
        -- bolinha de carregamento girando (arco: contorno com metade apagada)
        local giraFrame = GS.novaInstancia("Frame", fundo)
        giraFrame.AnchorPoint = Vector2.new(0.5, 0.5); giraFrame.Position = UDim2.new(0.5, 0, 0.5, 34)
        giraFrame.Size = UDim2.fromOffset(34, 34); giraFrame.BackgroundTransparency = 1; giraFrame.ZIndex = 202
        redondo(giraFrame)
        local arco = GS.novaInstancia("UIStroke", giraFrame); arco.Thickness = 3.5; arco.Color = T.strokeHi
        local ag = GS.novaInstancia("UIGradient", arco)
        ag.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.55, 0.15),
                                              NumberSequenceKeypoint.new(0.56, 1), NumberSequenceKeypoint.new(1, 1) }
        local gira = GS.criarTween(TweenService,giraFrame, TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
        gira:Play(); table.insert(vivos, gira)
        -- mensagem + porcentagem
        local msg = GS.novaInstancia("TextLabel", fundo)
        msg.AnchorPoint = Vector2.new(0.5, 0); msg.Position = UDim2.new(0.5, 0, 0.5, 64)
        msg.Size = UDim2.fromOffset(420, 22); msg.BackgroundTransparency = 1
        msg.Font = Enum.Font.GothamMedium; msg.TextSize = 15; msg.Text = ""
        msg.TextColor3 = Color3.fromRGB(225, 225, 225); msg.ZIndex = 202
        local pct = GS.novaInstancia("TextLabel", fundo)
        pct.AnchorPoint = Vector2.new(0.5, 0); pct.Position = UDim2.new(0.5, 0, 0.5, 112)
        pct.Size = UDim2.fromOffset(120, 18); pct.BackgroundTransparency = 1
        pct.Font = Enum.Font.GothamBold; pct.TextSize = 13; pct.Text = "0%"
        pct.TextColor3 = Color3.fromRGB(180, 180, 180); pct.ZIndex = 202
        -- barrinha
        local trilho = GS.novaInstancia("Frame", fundo)
        trilho.AnchorPoint = Vector2.new(0.5, 0); trilho.Position = UDim2.new(0.5, 0, 0.5, 96)
        trilho.Size = UDim2.fromOffset(300, 5); trilho.BackgroundColor3 = BRANCO
        trilho.BackgroundTransparency = 0.85; trilho.BorderSizePixel = 0; trilho.ZIndex = 202; redondo(trilho)
        local enche = GS.novaInstancia("Frame", trilho)
        enche.Size = UDim2.fromScale(0, 1); enche.BackgroundColor3 = T.strokeHi
        enche.BorderSizePixel = 0; enche.ZIndex = 203; redondo(enche)
        do
            local eg = GS.novaInstancia("UIGradient", enche)
            eg.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150), Color3.fromRGB(240, 240, 240))
        end
        -- insta embaixo
        local insta = GS.novaInstancia("TextLabel", fundo)
        insta.AnchorPoint = Vector2.new(0.5, 1); insta.Position = UDim2.new(0.5, 0, 1, -28)
        insta.Size = UDim2.fromOffset(300, 22); insta.BackgroundTransparency = 1
        insta.Font = Enum.Font.GothamBold; insta.TextSize = 16; insta.Text = "insta @henrique_system"
        insta.TextColor3 = Color3.fromRGB(205, 205, 205); insta.TextTransparency = 1; insta.ZIndex = 202
        tw(insta, {TextTransparency = 0.1}, 0.8)
        local brilhoInsta = GS.criarTween(TweenService,insta, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = 0.5 })
        GS.delay(0.8, function() if insta.Parent then brilhoInsta:Play() end end)
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
        GS.delay(0.45, function() fundo:Destroy() end)
        task.wait(0.15)
    end

    -- Janela abre imediatamente; a tela de carregamento foi removida.
    local abrirScale=GS.novaInstancia("UIScale",MainFrame); abrirScale.Scale=escalaBase*0.85
    MainFrame.Position=UDim2.new(0.5,-W/2,0.5,-H/2+40)
    MainFrame.Visible=true
    GS.spawn(function()
        local aberta = false
        local function abrirJanela()
            if aberta then return end
            aberta = true
            MainFrame.Visible = true
            tw(MainFrame,{Position=UDim2.new(0.5,-W/2,0.5,-H/2)},0.55)
            tw(abrirScale,{Scale=escalaBase},0.55,Enum.EasingStyle.Back)
        end
        abrirJanela()
    end)

    -- ── Barra lateral (abas por icone) ──
    local Sidebar=GS.novaInstancia("Frame",MainFrame)
    Sidebar.Position=UDim2.fromOffset(14,14); Sidebar.Size=UDim2.new(0,68,1,-28)
    Sidebar.BackgroundColor3=T.vidro; Sidebar.BackgroundTransparency=V.campo; Sidebar.BorderSizePixel=0
    mkC(12,Sidebar); mkS(1,T.stroke,Sidebar,V.borda)
    -- v9.1.2: sem logo na lateral (o nome fica na barra de titulo)
    -- lista de abas: do topo ate a engrenagem; se um dia tiver aba demais
    -- ela rola em vez de passar por cima da engrenagem
    local ListaAbas=GS.novaInstancia("ScrollingFrame",Sidebar)
    ListaAbas.Position=UDim2.fromOffset(0,16); ListaAbas.Size=UDim2.new(1,0,1,-78)
    ListaAbas.BackgroundTransparency=1; ListaAbas.BorderSizePixel=0
    ListaAbas.ScrollBarThickness=0; ListaAbas.ScrollingDirection=Enum.ScrollingDirection.Y
    ListaAbas.CanvasSize=UDim2.new(0,0,0,0); ListaAbas.AutomaticCanvasSize=Enum.AutomaticSize.Y
    do
        local l=GS.novaInstancia("UIListLayout",ListaAbas); l.SortOrder=Enum.SortOrder.LayoutOrder
        l.Padding=UDim.new(0,3); l.HorizontalAlignment=Enum.HorizontalAlignment.Center
    end

    -- Dica com o nome da aba (aparece no hover)
    local Dica=GS.novaInstancia("TextLabel",MainFrame)
    Dica.AutomaticSize=Enum.AutomaticSize.X; Dica.Size=UDim2.fromOffset(0,28)
    Dica.BackgroundColor3=T.bg; Dica.BackgroundTransparency=0.1; Dica.BorderSizePixel=0
    Dica.Font=Enum.Font.GothamMedium; Dica.TextSize=12; Dica.TextColor3=T.text; Dica.Text=""
    Dica.Visible=false; Dica.ZIndex=20; mkC(10,Dica); mkS(1,BRANCO,Dica,0.8)
    do local p=GS.novaInstancia("UIPadding",Dica); p.PaddingLeft=UDim.new(0,10); p.PaddingRight=UDim.new(0,10) end
    local function dica(btn, txt)
        GS.conectar(btn.MouseEnter,function()
            Dica.Text=txt
            local y = (btn.AbsolutePosition.Y - MainFrame.AbsolutePosition.Y) / math.max(abrirScale.Scale, 0.01)
            Dica.Position=UDim2.fromOffset(80, y + 6)
            Dica.Visible=true
        end)
        GS.conectar(btn.MouseLeave,function() Dica.Visible=false end)
    end

    -- ═══════════ TITULO: GRINGOdll, versao e autoria ═══════════
    local Titulo = GS.novaInstancia("Frame", MainFrame)
    Titulo.Name = "Titulo"; Titulo.Position = UDim2.fromOffset(96, 14)
    Titulo.Size = UDim2.new(1, -110, 0, TITULO_H); Titulo.BackgroundTransparency = 1; Titulo.Active = true
    do
        local l = GS.novaInstancia("UIListLayout", Titulo); l.FillDirection = Enum.FillDirection.Horizontal
        l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 10)
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        local pad = GS.novaInstancia("UIPadding", Titulo); pad.PaddingLeft = UDim.new(0, 10)
        -- Marca em tinta escura: contraste constante sobre a face clara.
        local marca = GS.novaInstancia("TextLabel", Titulo)
        marca.Name = "Marca"; marca.LayoutOrder = 1; marca.BackgroundTransparency = 1
        marca.Size = UDim2.fromOffset(0, TITULO_H); marca.AutomaticSize = Enum.AutomaticSize.X
        marca.Font = Enum.Font.GothamBlack; marca.TextSize = 24; marca.Text = "GRINGOdll"
        marca.TextColor3 = T.text; marca.TextXAlignment = Enum.TextXAlignment.Left
        -- versao numa pilula de vidro
        local pilula = GS.novaInstancia("Frame", Titulo)
        pilula.LayoutOrder = 2; pilula.Size = UDim2.fromOffset(0, 22); pilula.AutomaticSize = Enum.AutomaticSize.X
        pilula.BackgroundColor3 = T.on; pilula.BackgroundTransparency = 0.08; pilula.BorderSizePixel = 0
        redondo(pilula); mkS(1, BRANCO, pilula, 0.7)
        do local pp = GS.novaInstancia("UIPadding", pilula); pp.PaddingLeft = UDim.new(0, 10); pp.PaddingRight = UDim.new(0, 10) end
        local ver = GS.novaInstancia("TextLabel", pilula)
        ver.BackgroundTransparency = 1; ver.Size = UDim2.fromOffset(0, 22); ver.AutomaticSize = Enum.AutomaticSize.X
        ver.Font = Enum.Font.GothamBold; ver.TextSize = 12; ver.Text = GS.versao; ver.TextColor3 = BRANCO
        local credito = GS.novaInstancia("TextLabel", Titulo)
        credito.Name = "CreditoAutor"; credito.LayoutOrder = 4
        credito.BackgroundTransparency = 1
        credito.Size = UDim2.fromOffset(0, 22)
        credito.AutomaticSize = Enum.AutomaticSize.X
        credito.Font = Enum.Font.GothamMedium; credito.TextSize = 12
        credito.TextColor3 = T.dim; credito.Text = GS.credito
        credito.TextXAlignment = Enum.TextXAlignment.Left
        -- bolinha pulsando (onda que abre e some)
        local vivo = GS.novaInstancia("Frame", Titulo)
        vivo.LayoutOrder = 3; vivo.Size = UDim2.fromOffset(18, 18); vivo.BackgroundTransparency = 1
        local onda = GS.novaInstancia("Frame", vivo)
        onda.AnchorPoint = Vector2.new(0.5, 0.5); onda.Position = UDim2.fromScale(0.5, 0.5)
        onda.Size = UDim2.fromOffset(8, 8); onda.BackgroundColor3 = T.on
        onda.BackgroundTransparency = 0.2; onda.BorderSizePixel = 0; redondo(onda)
        local ponto = GS.novaInstancia("Frame", vivo)
        ponto.AnchorPoint = Vector2.new(0.5, 0.5); ponto.Position = UDim2.fromScale(0.5, 0.5)
        ponto.Size = UDim2.fromOffset(8, 8); ponto.BackgroundColor3 = T.on
        ponto.BorderSizePixel = 0; redondo(ponto)
        local pulso = GS.criarTween(TweenService,onda, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), { Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
        pulso:Play(); table.insert(GS.animsInfinitas, pulso)
        -- linha de luz embaixo do titulo, com uma faisca indo e voltando
        local fio = GS.novaInstancia("Frame", MainFrame)
        fio.Name = "FioTitulo"; fio.Position = UDim2.fromOffset(106, 14 + TITULO_H); fio.Size = UDim2.new(1, -128, 0, 1)
        fio.BackgroundColor3 = BRANCO; fio.BackgroundTransparency = 0.82; fio.BorderSizePixel = 0
        local fg = GS.novaInstancia("UIGradient", fio)
        fg.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0),
                                              NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) }
        local faisca = GS.novaInstancia("Frame", fio)
        faisca.AnchorPoint = Vector2.new(0.5, 0.5); faisca.Position = UDim2.new(0, 0, 0.5, 0)
        faisca.Size = UDim2.fromOffset(70, 3); faisca.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
        faisca.BorderSizePixel = 0; redondo(faisca)
        local sg = GS.novaInstancia("UIGradient", faisca)
        sg.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }
        local viaja = GS.criarTween(TweenService,faisca, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.new(1, 0, 0.5, 0) })
        viaja:Play(); table.insert(GS.animsInfinitas, viaja)
    end

    -- ── Topo: subabas + busca + minimizar/fechar + avatar ──
    local Header=GS.novaInstancia("Frame",MainFrame)
    Header.Position=UDim2.fromOffset(96,14+TITULO_H); Header.Size=UDim2.new(1,-110,0,HEADER_H)
    Header.BackgroundTransparency=1; Header.Active=true

    -- Arrastar janela — SO pelo topo (evita conflito com sliders/botoes)
    do
        local dragging, dragInput, dragStart, startPos
        for _, alca in ipairs({ Header, Titulo }) do   -- arrasta pelo topo e pelo titulo
            GS.conectar(alca.InputBegan,function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging=true; dragStart=inp.Position; startPos=MainFrame.Position
                    GS.conectar(inp.Changed,function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
                end
            end)
            GS.conectar(alca.InputChanged,function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end
            end)
        end
        GS.conectar(UserInputService.InputChanged,function(inp)
            if inp==dragInput and dragging then
                local d=inp.Position-dragStart
                MainFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end)
    end

    local SubBar=GS.novaInstancia("Frame",Header)
    SubBar.Size=UDim2.new(1,-330,1,0); SubBar.BackgroundTransparency=1
    do
        local l=GS.novaInstancia("UIListLayout",SubBar); l.FillDirection=Enum.FillDirection.Horizontal
        l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,22)
        l.VerticalAlignment=Enum.VerticalAlignment.Center
        local p=GS.novaInstancia("UIPadding",SubBar); p.PaddingLeft=UDim.new(0,8)
    end

    -- avatar
    do
        local av=GS.novaInstancia("ImageLabel",Header); av.Size=UDim2.fromOffset(38,38); av.Position=UDim2.new(1,-40,0.5,-19)
        av.BackgroundColor3=T.vidro; av.BackgroundTransparency=0.85; av.BorderSizePixel=0; redondo(av)
        mkS(1.5,BRANCO,av,0.6)
        pcall(function() av.Image="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=48&h=48" end)
    end
    local function botaoTopo(nomeIco, x, corHover)
        local b=GS.novaInstancia("TextButton",Header)
        b.Size=UDim2.fromOffset(34,34); b.Position=UDim2.new(1,x,0.5,-17)
        b.BackgroundColor3=T.vidro; b.BackgroundTransparency=V.campo; b.AutoButtonColor=false
        b.Text=""; b.BorderSizePixel=0; redondo(b); mkS(1,BRANCO,b,V.borda); press(b)
        local ic=icone(b,nomeIco,16,T.dim)
        GS.conectar(b.MouseEnter,function()
            tw(b,{BackgroundColor3=corHover or BRANCO,BackgroundTransparency=corHover and 0.1 or 0.75},0.15)
            if ic then tw(ic,{ImageColor3=BRANCO},0.15) end
        end)
        GS.conectar(b.MouseLeave,function()
            tw(b,{BackgroundColor3=T.vidro,BackgroundTransparency=V.campo},0.2)
            if ic then tw(ic,{ImageColor3=T.dim},0.2) end
        end)
        return b
    end
    local XBtn=botaoTopo("x",-82,Color3.fromRGB(200,50,80))
    local MinBtn=botaoTopo("minus",-122)
    GS.conectar(XBtn.MouseButton1Click,function()
        tw(abrirScale,{Scale=escalaBase*0.8},0.25,Enum.EasingStyle.Back,Enum.EasingDirection.In)
        tw(MainFrame,{Position=MainFrame.Position+UDim2.new(0,0,0,40)},0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        task.wait(0.26)
        ScreenGui:Destroy()
    end)
    local mini=false
    GS.conectar(MinBtn.MouseButton1Click,function()
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
        local caixa=GS.novaInstancia("Frame",Header); caixa.Size=UDim2.fromOffset(186,36); caixa.Position=UDim2.new(1,-318,0.5,-18)
        caixa.BackgroundColor3=T.vidro; caixa.BackgroundTransparency=V.campo; caixa.BorderSizePixel=0
        redondo(caixa); local st=mkS(1,BRANCO,caixa,V.borda)
        local ic=icone(caixa,"search",15,T.mute); ic.Position=UDim2.new(0,18,0.5,0)
        Busca=GS.novaInstancia("TextBox",caixa); Busca.Size=UDim2.new(1,-44,1,0); Busca.Position=UDim2.fromOffset(34,0)
        Busca.BackgroundTransparency=1; Busca.Font=Enum.Font.GothamMedium; Busca.TextSize=13
        Busca.PlaceholderText="Buscar"; Busca.PlaceholderColor3=T.mute; Busca.Text=""; Busca.TextColor3=T.text
        Busca.TextXAlignment=Enum.TextXAlignment.Left; Busca.ClearTextOnFocus=false; Busca.TextTruncate=Enum.TextTruncate.AtEnd
        GS.conectar(Busca.Focused,function() tw(st,{Color=T.strokeHi,Transparency=0.3},0.2) tw(caixa,{BackgroundTransparency=0.82},0.2) end)
        GS.conectar(Busca.FocusLost,function() tw(st,{Color=BRANCO,Transparency=V.borda},0.25) tw(caixa,{BackgroundTransparency=V.campo},0.25) end)
    end

    -- ── Area de conteudo ──
    local CA=GS.novaInstancia("ScrollingFrame",MainFrame)
    CA.Position=UDim2.fromOffset(96,TITULO_H+HEADER_H+28); CA.Size=UDim2.new(1,-110,1,-(TITULO_H+HEADER_H+42))
    CA.BackgroundTransparency=1; CA.BorderSizePixel=0
    CA.ScrollBarThickness=3; CA.ScrollBarImageColor3=BRANCO; CA.ScrollBarImageTransparency=0.6
    CA.CanvasSize=UDim2.new(0,0,0,0); CA.AutomaticCanvasSize=Enum.AutomaticSize.Y
    CA.ClipsDescendants=true; CA.ScrollingDirection=Enum.ScrollingDirection.Y
    local cp=GS.novaInstancia("UIPadding",CA); cp.PaddingTop=UDim.new(0,2); cp.PaddingLeft=UDim.new(0,2); cp.PaddingRight=UDim.new(0,10); cp.PaddingBottom=UDim.new(0,12)
    do
        local l=GS.novaInstancia("UIListLayout",CA); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,10)
        l.HorizontalAlignment=Enum.HorizontalAlignment.Center
    end

    local function criarPanel(ord)
        local f=GS.novaInstancia("Frame",CA); f.Size=UDim2.new(1,0,0,1)
        f.AutomaticSize=Enum.AutomaticSize.Y; f.BackgroundTransparency=1
        f.Visible=false; f.LayoutOrder=ord
        local l=GS.novaInstancia("UIListLayout",f); l.SortOrder=Enum.SortOrder.LayoutOrder
        l.Padding=UDim.new(0,10); l.HorizontalAlignment=Enum.HorizontalAlignment.Center
        return f
    end

    -- ═══════════════ COMPONENTES ═══════════════
    -- titulo de secao (pequeno, como o "Actions" da imagem)
    local function sec(pai,titulo,ico,ord)
        local f=GS.novaInstancia("Frame",pai); f.Size=UDim2.new(1,0,0,28)
        f.BackgroundTransparency=1; f.BorderSizePixel=0; f.LayoutOrder=ord
        local x=6
        local ic=icone(f,nomeIcone(ico) or nomeIcone(titulo),14,T.mute)
        if ic then ic.Position=UDim2.new(0,13,0,17); x=26 end
        local lbl=GS.novaInstancia("TextLabel",f); lbl.Size=UDim2.new(1,-x,0,20); lbl.Position=UDim2.new(0,x,0,7)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold
        lbl.Text=semEmoji(titulo); lbl.TextColor3=T.mute; lbl.TextSize=11
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextTruncate=Enum.TextTruncate.AtEnd
    end

    -- card de vidro de uma linha
    local function linhaBase(pai, altura, ord)
        local row=GS.novaInstancia("Frame",pai); row.Size=UDim2.new(1,0,0,altura)
        row.BackgroundColor3=T.vidro; row.BackgroundTransparency=V.linha
        row.BorderSizePixel=0; row.LayoutOrder=ord; mkC(12,row)
        local st=mkS(1,T.stroke,row,V.borda)
        local face=GS.novaInstancia("UIGradient",row)
        face.Color=ColorSequence.new(BRANCO,Color3.fromRGB(176,232,227))
        face.Rotation=70
        return row, st
    end

    -- caixa que agrupa funcoes (como o "Module One" da imagem)
    local function grupo(pai, titulo, subtitulo, ico, ord)
        local f=GS.novaInstancia("Frame",pai); f.Size=UDim2.new(1,0,0,0); f.AutomaticSize=Enum.AutomaticSize.Y
        f.BackgroundColor3=T.vidro; f.BackgroundTransparency=V.grupo; f.BorderSizePixel=0; f.LayoutOrder=ord
        mkC(14,f); mkS(1,T.stroke,f,0.65)
        local p=GS.novaInstancia("UIPadding",f); p.PaddingTop=UDim.new(0,14); p.PaddingBottom=UDim.new(0,14)
        p.PaddingLeft=UDim.new(0,14); p.PaddingRight=UDim.new(0,14)
        local l=GS.novaInstancia("UIListLayout",f); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,8)
        local topo=GS.novaInstancia("Frame",f); topo.Size=UDim2.new(1,0,0,subtitulo and 40 or 24)
        topo.BackgroundTransparency=1; topo.LayoutOrder=0
        local x=2
        if ico and ICONES[ico] then
            local bolha=GS.novaInstancia("Frame",topo); bolha.Size=UDim2.fromOffset(34,34); bolha.Position=UDim2.fromOffset(0,subtitulo and 3 or -5)
            bolha.BackgroundColor3=T.vidro; bolha.BackgroundTransparency=0.86; bolha.BorderSizePixel=0; redondo(bolha)
            icone(bolha,ico,17,T.text)
            x=46
        end
        local t1=GS.novaInstancia("TextLabel",topo); t1.Size=UDim2.new(1,-x,0,20); t1.Position=UDim2.fromOffset(x,subtitulo and 1 or 2)
        t1.BackgroundTransparency=1; t1.Font=Enum.Font.GothamBold; t1.TextSize=15; t1.TextColor3=T.text
        t1.TextXAlignment=Enum.TextXAlignment.Left; t1.Text=titulo
        if subtitulo then
            local t2=GS.novaInstancia("TextLabel",topo); t2.Size=UDim2.new(1,-x,0,16); t2.Position=UDim2.fromOffset(x,22)
            t2.BackgroundTransparency=1; t2.Font=Enum.Font.Gotham; t2.TextSize=11; t2.TextColor3=T.mute
            t2.TextXAlignment=Enum.TextXAlignment.Left; t2.TextTruncate=Enum.TextTruncate.AtEnd; t2.Text=subtitulo
        end
        return f
    end

    -- grade de cards quadrados (como "Thing 1 / Thing 2" da imagem)
    local function grade(pai, ord, colunas, altura)
        local g=GS.novaInstancia("Frame",pai); g.Size=UDim2.new(1,0,0,0); g.AutomaticSize=Enum.AutomaticSize.Y
        g.BackgroundTransparency=1; g.LayoutOrder=ord
        local gl=GS.novaInstancia("UIGridLayout",g); gl.SortOrder=Enum.SortOrder.LayoutOrder
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
        local track=GS.novaInstancia("Frame",pai); track.Size=UDim2.fromOffset(44,24); track.Position=pos
        track.BackgroundColor3=T.off; track.BackgroundTransparency=0.3; track.BorderSizePixel=0; redondo(track)
        local knob=GS.novaInstancia("Frame",track); knob.Size=UDim2.fromOffset(18,18); knob.Position=KNOB_OFF
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
                st    = { Color = on and T.on or T.stroke, Transparency = on and 0.25 or V.borda },
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
            GS.delay(2.8,function()
                if msgId~=meu then return end
                tw(lbl,{Position=o.pos},0.25); tw(sub,{TextTransparency=1},0.25)
            end)
        end
        -- "Controlado": a chave so obedece ao .Text que a logica escreve
        -- (evita a chave mostrar OFF com a funcao ligada)
        GS.conectar(t.MouseButton1Click,function()
            if not t:GetAttribute("Controlado") then setOn(not on) end
            GS.delay(0.1, sync)   -- confere logo depois que a funcao escreveu o texto
        end)
        GS.conectar(t:GetPropertyChangedSignal("Text"),function()
            local txt=t.Text
            if txt=="" then return end
            local v = lerTexto()
            if v ~= nil then setOn(v) else aviso(txt) end
        end)
        GS.conectar(t.MouseEnter,function() tw(row,{BackgroundTransparency=V.linha-0.05},0.15) end)
        GS.conectar(t.MouseLeave,function() tw(row,{BackgroundTransparency=V.linha},0.2) end)
        return t
    end
    local function botaoInvisivel(row)
        local t=GS.novaInstancia("TextButton",row); t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1
        t.Text=""; t.TextTransparency=1; t.AutoButtonColor=false; t.ZIndex=3
        ripple(t)
        return t
    end
    local function bolhaIcone(pai, ico, tam, pos)
        local bolha=GS.novaInstancia("Frame",pai); bolha.Size=UDim2.fromOffset(tam,tam); bolha.Position=pos
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
        local lbl=GS.novaInstancia("TextLabel",row); lbl.Size=UDim2.new(1,-x0-72,1,0); lbl.Position=UDim2.new(0,x0,0,0)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamMedium; lbl.Text=nome
        lbl.TextColor3=T.dim; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.TextTruncate=Enum.TextTruncate.AtEnd
        local sub=GS.novaInstancia("TextLabel",row); sub.Size=UDim2.new(1,-x0-72,0,14); sub.Position=UDim2.new(0,x0,0,29)
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
        local row=GS.novaInstancia("Frame",pai); row.BackgroundColor3=T.vidro; row.BackgroundTransparency=V.linha
        row.BorderSizePixel=0; row.LayoutOrder=ord; mkC(12,row)
        local st=mkS(1,T.stroke,row,V.borda)
        local face=GS.novaInstancia("UIGradient",row)
        face.Color=ColorSequence.new(BRANCO,Color3.fromRGB(176,232,227))
        face.Rotation=70
        local bolha, ic = bolhaIcone(row, nomeIcone(ico), 36, UDim2.fromOffset(12,12))
        local lbl=GS.novaInstancia("TextLabel",row); lbl.Size=UDim2.new(1,-28,0,20); lbl.Position=UDim2.new(0,14,1,-34)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamMedium; lbl.Text=nome
        lbl.TextColor3=T.dim; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.TextTruncate=Enum.TextTruncate.AtEnd
        local sub=GS.novaInstancia("TextLabel",row); sub.Size=UDim2.new(1,-28,0,14); sub.Position=UDim2.new(0,14,1,-18)
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
        local b=GS.novaInstancia("TextButton",pai); b.Size=UDim2.new(1,0,0,altura)
        b.AutoButtonColor=false; b.BorderSizePixel=0; b.LayoutOrder=ord
        b.Font=Enum.Font.GothamBold; b.Text=txt; b.TextSize=tam
        local corBorda, trBorda = BRANCO, V.borda
        if cor=="perigo" then
            b.BackgroundColor3=T.perigo; b.BackgroundTransparency=0.25; b.TextColor3=T.perigoTxt
            corBorda, trBorda = T.perigoTxt, 0.6
        elseif cor=="primario" then
            b.BackgroundColor3=T.on; b.BackgroundTransparency=0.12; b.TextColor3=T.onText
            corBorda, trBorda = T.strokeHi, 0.45
        elseif typeof(cor)=="Color3" then
            b.BackgroundColor3=cor; b.BackgroundTransparency=0; b.TextColor3=BRANCO
        else
            b.BackgroundColor3=T.vidro; b.BackgroundTransparency=0.88; b.TextColor3=T.text
        end
        mkC(12,b); mkS(1,corBorda,b,trBorda)
        -- conteudo centralizado: [icone] texto
        local miolo=GS.novaInstancia("Frame",b); miolo.AnchorPoint=Vector2.new(0.5,0.5); miolo.Position=UDim2.fromScale(0.5,0.5)
        miolo.AutomaticSize=Enum.AutomaticSize.X; miolo.Size=UDim2.fromOffset(0,altura); miolo.BackgroundTransparency=1
        do
            local l=GS.novaInstancia("UIListLayout",miolo); l.FillDirection=Enum.FillDirection.Horizontal
            l.VerticalAlignment=Enum.VerticalAlignment.Center; l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,8)
        end
        local ic=icone(miolo,nomeIcone(ico) or nomeIcone(txt),16,b.TextColor3)
        if ic then ic.AnchorPoint=Vector2.zero; ic.LayoutOrder=1 end
        local lbl=GS.novaInstancia("TextLabel",miolo); lbl.Name="Rotulo"; lbl.BackgroundTransparency=1; lbl.LayoutOrder=2
        lbl.AutomaticSize=Enum.AutomaticSize.X; lbl.Size=UDim2.fromOffset(0,altura)
        lbl.Font=b.Font; lbl.TextSize=tam; lbl.TextTruncate=Enum.TextTruncate.AtEnd
        do local lim=GS.novaInstancia("UISizeConstraint",lbl); lim.MaxSize=Vector2.new(560,altura) end
        b.TextTransparency=1
        local function espelhar()
            lbl.Text=semEmoji(b.Text)
            lbl.TextColor3=b.TextColor3
            lbl.TextStrokeTransparency=b.TextStrokeTransparency
            if ic then ic.ImageColor3=b.TextColor3 end
        end
        espelhar()
        GS.conectar(b:GetPropertyChangedSignal("Text"),espelhar)
        GS.conectar(b:GetPropertyChangedSignal("TextColor3"),espelhar)
        GS.conectar(b:GetPropertyChangedSignal("TextStrokeTransparency"),espelhar)
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
        local lbl=GS.novaInstancia("TextLabel",row); lbl.Size=UDim2.new(1,-190,1,0); lbl.Position=UDim2.new(0,16,0,0)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamMedium; lbl.Text=semEmoji(rotulo)
        lbl.TextColor3=T.dim; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.TextTruncate=Enum.TextTruncate.AtEnd
        local function bt(nomeIco,x)
            local b=GS.novaInstancia("TextButton",row); b.Size=UDim2.fromOffset(32,32); b.Position=UDim2.new(1,x,0.5,-16)
            b.BackgroundColor3=T.vidro; b.BackgroundTransparency=0.84; b.Text=""; b.AutoButtonColor=false
            b.BorderSizePixel=0; redondo(b); mkS(1,BRANCO,b,0.8)
            icone(b,nomeIco,16,T.text)
            hover(b); press(b)
            return b
        end
        local bm=bt("minus",-158)
        local vl=GS.novaInstancia("TextLabel",row); vl.Size=UDim2.fromOffset(78,32); vl.Position=UDim2.new(1,-120,0.5,-16)
        vl.BackgroundColor3=T.bg; vl.BackgroundTransparency=0.45; vl.Font=Enum.Font.GothamBold; vl.Text=tostring(val)
        vl.TextColor3=T.text; vl.TextSize=12; vl.BorderSizePixel=0; redondo(vl); mkS(1,BRANCO,vl,0.85)
        vl.TextScaled=false; vl.TextTruncate=Enum.TextTruncate.AtEnd
        local bp=bt("plus",-38)
        -- valor "pula" quando muda
        local vs=GS.novaInstancia("UIScale",vl)
        GS.conectar(vl:GetPropertyChangedSignal("Text"),function()
            vs.Scale=1.15; tw(vs,{Scale=1},0.3,Enum.EasingStyle.Back)
        end)
        return bm, bp, vl
    end

    -- Slider arrastavel (mouse/touch) — retorna um objeto com :Get(),
    -- :Set(valor) e .Changed (BindableEvent) disparado ao arrastar
    local function slider(pai, rotulo, minV, maxV, valInicial, ord)
        local row=linhaBase(pai,68,ord)
        local lbl=GS.novaInstancia("TextLabel",row); lbl.Size=UDim2.new(1,-32,0,20); lbl.Position=UDim2.new(0,16,0,10)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamMedium
        lbl.Text=rotulo..": "..string.format("%.1f",valInicial).."x"
        lbl.TextColor3=T.text; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left

        local track=GS.novaInstancia("Frame",row); track.Size=UDim2.new(1,-32,0,8); track.Position=UDim2.new(0,16,0,44)
        track.BackgroundColor3=BRANCO; track.BackgroundTransparency=0.75; track.BorderSizePixel=0; redondo(track)
        local fill=GS.novaInstancia("Frame",track); fill.BackgroundColor3=T.on; fill.BorderSizePixel=0
        fill.Size=UDim2.new((valInicial-minV)/(maxV-minV),0,1,0); redondo(fill)
        do
            local g=GS.novaInstancia("UIGradient",fill)
            g.Color=ColorSequence.new(Color3.fromRGB(220,220,220), T.on)
        end
        local knob=GS.novaInstancia("Frame",track); knob.Size=UDim2.new(0,18,0,18)
        knob.AnchorPoint=Vector2.new(0.5,0.5); knob.BackgroundColor3=BRANCO
        knob.BorderSizePixel=0; knob.ZIndex=2
        knob.Position=UDim2.new((valInicial-minV)/(maxV-minV),0,0.5,0); redondo(knob)
        mkS(2,T.on,knob,0.2)

        local valorAtual = valInicial
        local changedEvent = GS.novaInstancia("BindableEvent")

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

        GS.conectar(track.InputBegan,function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                setArrastando(true)
                aplicarValor(posicaoParaValor(inp.Position.X))
                GS.conectar(inp.Changed,function() if inp.UserInputState==Enum.UserInputState.End then setArrastando(false) end end)
            end
        end)
        GS.conectar(knob.InputBegan,function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                setArrastando(true)
                GS.conectar(inp.Changed,function() if inp.UserInputState==Enum.UserInputState.End then setArrastando(false) end end)
            end
        end)
        GS.conectar(UserInputService.InputChanged,function(inp)
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
        local caixa=GS.novaInstancia("Frame",pai); caixa.Size=UDim2.new(1,0,0,44); caixa.LayoutOrder=ord
        caixa.BackgroundColor3=T.vidro; caixa.BackgroundTransparency=V.campo; caixa.BorderSizePixel=0; mkC(22,caixa)
        local st=mkS(1,BRANCO,caixa,V.borda)
        local x = 18
        if lupa then
            local ic=icone(caixa,"search",16,T.mute); ic.Position=UDim2.new(0,22,0.5,0)
            x = 42
        end
        local i=GS.novaInstancia("TextBox",caixa); i.Size=UDim2.new(1,-(x+14),1,0); i.Position=UDim2.fromOffset(x,0)
        i.BackgroundTransparency=1; i.Font=Enum.Font.GothamMedium
        i.PlaceholderText=semEmoji(ph); i.PlaceholderColor3=T.mute; i.ClearTextOnFocus=false
        i.Text=""; i.TextColor3=T.text; i.TextSize=13; i.TextXAlignment=Enum.TextXAlignment.Left
        i.TextTruncate=Enum.TextTruncate.AtEnd; i.BorderSizePixel=0
        GS.conectar(i.Focused,function() tw(st,{Color=T.strokeHi,Transparency=0.3},0.2) tw(caixa,{BackgroundTransparency=0.84},0.2) end)
        GS.conectar(i.FocusLost,function() tw(st,{Color=BRANCO,Transparency=V.borda},0.25) tw(caixa,{BackgroundTransparency=V.campo},0.25) end)
        -- se a logica trocar o placeholder (ex.: "HEX invalido"), tira emoji tambem
        GS.conectar(i:GetPropertyChangedSignal("PlaceholderText"),function()
            local limpo = semEmoji(i.PlaceholderText)
            if limpo ~= i.PlaceholderText then i.PlaceholderText = limpo end
        end)
        return i
    end

    -- Lista rolavel (players). As linhas sao criadas pela logica com cor
    -- cinza fixa → aqui viram vidro roxo automaticamente.
    local CINZA_LINHA, CINZA_SEL = Color3.fromRGB(26,26,31), Color3.fromRGB(70,70,80)
    local function lista(pai,altura,ord)
        local f=GS.novaInstancia("ScrollingFrame",pai)
        f.Size=UDim2.new(1,0,0,altura); f.LayoutOrder=ord
        f.BackgroundColor3=T.bg; f.BackgroundTransparency=0.6; f.BorderSizePixel=0
        f.ScrollBarThickness=3; f.ScrollBarImageColor3=BRANCO; f.ScrollBarImageTransparency=0.6
        f.CanvasSize=UDim2.new(0,0,0,0); f.AutomaticCanvasSize=Enum.AutomaticSize.Y
        mkC(18,f); mkS(1,BRANCO,f,0.88)
        local ll=GS.novaInstancia("UIListLayout",f); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,5)
        local lp=GS.novaInstancia("UIPadding",f); lp.PaddingTop=UDim.new(0,7); lp.PaddingBottom=UDim.new(0,7)
        lp.PaddingLeft=UDim.new(0,7); lp.PaddingRight=UDim.new(0,11)
        GS.conectar(f.ChildAdded,function(ch)
            if not ch:IsA("GuiButton") then return end
            local function ajustar()
                local c = ch.BackgroundColor3
                if perto(c, CINZA_LINHA) then ch.BackgroundColor3 = T.card return end
                if perto(c, CINZA_SEL) then ch.BackgroundColor3 = T.on return end
                ch.BackgroundTransparency = perto(c, T.on) and 0.15 or 0.55
            end
            GS.conectar(ch:GetPropertyChangedSignal("BackgroundColor3"),ajustar)
            GS.defer(ajustar)
            GS.defer(function()
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
        { nome="Farmar Vibes", ico="package", subs={"Farmar Vibes"}, ordem=9.5 },
        { nome="Vale Rush", ico="gauge", subs={"Câmera e FPS"}, ordem=9.6 },
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
            local b=GS.novaInstancia("TextButton",SubBar); b.AutomaticSize=Enum.AutomaticSize.X
            b.Size=UDim2.new(0,0,0,32); b.BackgroundTransparency=1; b.AutoButtonColor=false
            b.Font=Enum.Font.GothamMedium; b.TextSize=15; b.Text=s.nome; b.TextColor3=T.mute; b.LayoutOrder=j
            local ponto=GS.novaInstancia("Frame",b); ponto.Name="Ponto"; ponto.AnchorPoint=Vector2.new(0.5,0)
            ponto.Size=UDim2.fromOffset(16,3); ponto.Position=UDim2.new(0.5,0,1,1)
            ponto.BackgroundColor3=T.strokeHi; ponto.BackgroundTransparency=1; ponto.BorderSizePixel=0; redondo(ponto)
            GS.conectar(b.MouseEnter,function() if j ~= subAtual then tw(b,{TextColor3=T.dim},0.15) end end)
            GS.conectar(b.MouseLeave,function() if j ~= subAtual then tw(b,{TextColor3=T.mute},0.2) end end)
            GS.conectar(b.MouseButton1Click,function() abrir(ai, j) end)
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
        local b=GS.novaInstancia("TextButton",ListaAbas)
        b.Size=UDim2.fromOffset(32,32); b.BackgroundColor3=T.vidro; b.BackgroundTransparency=1
        b.Text=""; b.AutoButtonColor=false; b.BorderSizePixel=0; b.LayoutOrder=math.floor((a.ordem or i)*10); redondo(b)
        a.traco=mkS(1,BRANCO,b,1)
        a.icone=icone(b,a.ico,17,T.mute)
        a.botao=b
        GS.conectar(b.MouseEnter,function()
            if abaAtual ~= i then tw(b,{BackgroundTransparency=0.9},0.15) if a.icone then tw(a.icone,{ImageColor3=T.dim},0.15) end end
        end)
        GS.conectar(b.MouseLeave,function()
            if abaAtual ~= i then tw(b,{BackgroundTransparency=1},0.2) if a.icone then tw(a.icone,{ImageColor3=T.mute},0.2) end end
        end)
        GS.conectar(b.MouseButton1Click,function() abrir(i) end)
        press(b); dica(b, a.nome)
    end

    -- Botao configuracoes (embaixo da barra lateral)
    local cfgBtn=GS.novaInstancia("TextButton",Sidebar)
    cfgBtn.Size=UDim2.fromOffset(38,38); cfgBtn.Position=UDim2.new(0.5,-19,1,-50)
    cfgBtn.BackgroundColor3=T.vidro; cfgBtn.BackgroundTransparency=0.88; cfgBtn.AutoButtonColor=false
    cfgBtn.Text=""; cfgBtn.BorderSizePixel=0; redondo(cfgBtn); mkS(1,BRANCO,cfgBtn,V.borda)
    do
        local ic=icone(cfgBtn,"settings",18,T.dim)
        GS.conectar(cfgBtn.MouseEnter,function() if ic then tw(ic,{ImageColor3=BRANCO,Rotation=60},0.3) end end)
        GS.conectar(cfgBtn.MouseLeave,function() if ic then tw(ic,{ImageColor3=T.dim,Rotation=0},0.3) end end)
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
        RegenUI.regenerar = acao(gs,"REGENERAR / RENASCER","refresh-cw",1)
        RegenUI.voltar    = pequeno(gs,"VOLTAR PRO ÚLTIMO CHÃO (TECLA L)",nil,2,"arrow-up-to-line")
    end

    -- ── JOGADOR › Proteção ── (montada pelos modulos ANTI-SCRIPTS e ANTI-ASSEDIO)
    GS.painelProtecao = painel(1,3)

    -- ── MONSTROS › Puxar ──
    do
        local p = painel(2,1)
        local gx = grupo(p, "Puxar todos", "Trava os monstros em volta de você", "magnet", 1)
        local box=GS.novaInstancia("Frame",gx); box.Size=UDim2.new(1,0,0,1)
        box.AutomaticSize=Enum.AutomaticSize.Y; box.BackgroundTransparency=1; box.LayoutOrder=1
        local bl=GS.novaInstancia("UIListLayout",box); bl.SortOrder=Enum.SortOrder.LayoutOrder; bl.Padding=UDim.new(0,8)
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
        local paletaF=GS.novaInstancia("Frame",gc); paletaF.Size=UDim2.new(1,0,0,44)
        paletaF.BackgroundTransparency=1; paletaF.LayoutOrder=1
        local gl=GS.novaInstancia("UIGridLayout",paletaF); gl.CellSize=UDim2.new(0,38,0,38)
        gl.CellPadding=UDim2.new(0,12,0,0); gl.SortOrder=Enum.SortOrder.LayoutOrder
        gl.HorizontalAlignment=Enum.HorizontalAlignment.Center
        local paleta={
            Color3.fromRGB(255,0,0),   Color3.fromRGB(255,120,0), Color3.fromRGB(255,255,0),
            Color3.fromRGB(0,255,0),   Color3.fromRGB(0,255,255), Color3.fromRGB(0,80,255),
            Color3.fromRGB(170,0,255), Color3.fromRGB(255,0,200),
        }
        for i,c in ipairs(paleta) do
            local b=GS.novaInstancia("TextButton",paletaF); b.Text=""; b.BackgroundColor3=c; b.AutoButtonColor=false
            b.BorderSizePixel=0; b.LayoutOrder=i; redondo(b)
            local st=mkS(2,BRANCO,b,0.7)
            press(b)
            GS.conectar(b.MouseEnter,function() tw(st,{Transparency=0},0.15) end)
            GS.conectar(b.MouseLeave,function() tw(st,{Transparency=0.7},0.2) end)
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
    GS.painelFarma    = painel(12,1)
    GS.painelValeRush = painel(13,1)
    GS.painelCombate  = painel(8,1)
    GS.painelSilent   = painel(8,2)   -- SILENT AIM: montada pelo modulo do fim do arquivo
    GS.painelRecoil   = painel(8,3)   -- NO RECOIL: montada pelo modulo do fim do arquivo
    GS.painelMunicao  = painel(8,4)   -- MUNICAO INFINITA: montada pelo modulo do fim do arquivo
    GS.painelRetorno  = painel(4,1)
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
            local luz=GS.novaInstancia("Frame"); luz.Size=UDim2.new(1,0,1,0); luz.BackgroundColor3=T.on
            luz.BackgroundTransparency=0.45; luz.BorderSizePixel=0; luz.ZIndex=6; mkC(18,luz); luz.Parent=alvo
            tw(luz,{BackgroundTransparency=1},1.2)
            GS.delay(1.3,function() luz:Destroy() end)
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
                            GS.spawn(destacar, alvo)
                            return true
                        end
                    end
                end
            end
            if avisar then GS.toast("Nada encontrado: "..q, false) end
        end
        local buscaId = 0
        GS.conectar(Busca:GetPropertyChangedSignal("Text"),function()
            buscaId = buscaId + 1; local meu = buscaId
            GS.delay(0.5, function() if meu == buscaId then pcall(buscar, Busca.Text, false) end end)
        end)
        GS.conectar(Busca.FocusLost,function(enter) if enter then pcall(buscar, Busca.Text, true) end end)
    end

    -- ═══════════════ CONFIGURACOES ═══════════════
    ConfigFrame=GS.novaInstancia("Frame",ScreenGui)
    ConfigFrame.BackgroundTransparency=0.08; ConfigFrame.BorderSizePixel=0
    ConfigFrame.Position=UDim2.new(0.5,-130,0.5,-134); ConfigFrame.Size=UDim2.new(0,260,0,268)
    ConfigFrame.Visible=false; vidroRoxo(ConfigFrame, 70); mkC(14,ConfigFrame); mkS(3,T.stroke,ConfigFrame,0.2)
    local cfgScale=GS.novaInstancia("UIScale",ConfigFrame)
    do
        local ic=icone(ConfigFrame,"settings",18,T.dim); ic.Position=UDim2.fromOffset(28,28)
    end
    ConfigTitle=GS.novaInstancia("TextLabel",ConfigFrame); ConfigTitle.Size=UDim2.new(1,-60,0,24); ConfigTitle.Position=UDim2.fromOffset(46,16)
    ConfigTitle.BackgroundTransparency=1; ConfigTitle.Font=Enum.Font.GothamBold; ConfigTitle.TextXAlignment=Enum.TextXAlignment.Left
    ConfigTitle.Text="Configurações"; ConfigTitle.TextColor3=T.text; ConfigTitle.TextSize=15
    local function mkCB(txt,posY)
        local b=GS.novaInstancia("TextButton",ConfigFrame); b.Size=UDim2.new(1,-28,0,40); b.Position=UDim2.new(0,14,0,posY)
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
    GS.conectar(cfgBtn.MouseButton1Click,function()
        if ConfigFrame.Visible then
            ConfigFrame.Visible=false
        else
            ConfigFrame.Visible=true
            cfgScale.Scale=0.8*escalaBase; tw(cfgScale,{Scale=escalaBase},0.35,Enum.EasingStyle.Back)
        end
    end)
    GS.conectar(ConfigCloseButton.MouseButton1Click,function() ConfigFrame.Visible=false end)

    -- Botao config invisivel (compatibilidade)
    ConfigTabButton=GS.novaInstancia("TextButton",ScreenGui); ConfigTabButton.Visible=false

    -- Abrir/fechar pela tecla tambem anima
    GS.conectar(MainFrame:GetPropertyChangedSignal("Visible"),function()
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
GS.conectar(KeybindButton.MouseButton1Click,function()
    escutandoTecla=true; KeybindButton.Text="[PRESSIONE UMA TECLA]"
end)
GS.conectar(UserInputService.InputBegan,function(input,_gp)
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
GS.humanoides=setmetatable({}, {__mode="k"})
function GS.salvarHumanoide(char)
    local function salvar(h)
        if not h:IsA("Humanoid") or GS.humanoides[h] then return end
        local r={props={},estados={}}
        for _,p in ipairs({"WalkSpeed","JumpPower","JumpHeight","UseJumpPower","HipHeight",
            "AutoRotate","PlatformStand","Sit","RequiresNeck","BreakJointsOnDeath","MaxHealth"}) do
            pcall(function() r.props[p]=h[p] end)
        end
        for _,estado in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
            pcall(function() r.estados[estado]=h:GetStateEnabled(estado) end)
        end
        GS.humanoides[h]=r
    end
    if not char then return end
    local h=char:FindFirstChildOfClass("Humanoid")
    if h then salvar(h) end
    GS.conectar(char.ChildAdded,salvar)
end
GS.salvarHumanoide(LocalPlayer.Character)
GS.conectar(LocalPlayer.CharacterAdded,GS.salvarHumanoide)
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
        noclipConnection = GS.conectar(RunService.Stepped,atravessar)
        GS.noclipConn2 = GS.conectar(RunService.Heartbeat,function()
            atravessar()
            pcall(nuncaCai)
        end)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local r = hum and hum.RootPart
        if r and r.Anchored then
            GS.delay(0.4, function() NoclipButton.Text = "⚠ O jogo ancorou seu boneco (não dá pra mover)" end)
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
            localLight = GS.novaInstancia("PointLight")
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

GS.conectar(Lighting.Changed,function()
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
        speedConnection = GS.conectar(RunService.Heartbeat,function(dt)
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
        flyConnection = GS.conectar(RunService.RenderStepped,function()
            -- Atualiza referencias todo frame (jogo pode ter resetado o char)
            local c = LocalPlayer.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if not r or not h or h.Health <= 0 then
                if GS.farmaDirecao then GS.farmaDirecao = Vector3.zero end
                if bodyVelocity then bodyVelocity.Velocity = Vector3.zero end
                return
            end

            -- Mantém PlatformStand ligado todo frame
            -- (alguns jogos resetam isso para derrubar o boneco)
            if not h.PlatformStand then
                pcall(function() h.PlatformStand = true end)
            end

            -- Recria BodyVelocity se o jogo destruiu (causa do descida)
            if not bodyVelocity or bodyVelocity.Parent ~= r then
                pcall(function()
                    if bodyVelocity then bodyVelocity:Destroy() end
                    bodyVelocity = GS.novaInstancia("BodyVelocity"); bodyVelocity.Name = "GringoVooVel"
                    bodyVelocity.Velocity   = Vector3.new(0, 0, 0)
                    bodyVelocity.MaxForce   = Vector3.new(math.huge, math.huge, math.huge)
                    bodyVelocity.Parent     = r
                end)
            end

            -- Recria BodyGyro se o jogo destruiu (causa da rotacao bugada)
            if not bodyGyro or bodyGyro.Parent ~= r then
                pcall(function()
                    if bodyGyro then bodyGyro:Destroy() end
                    bodyGyro = GS.novaInstancia("BodyGyro"); bodyGyro.Name = "GringoVooGyro"
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
            if GS.farmaDirecao then
                pcall(function()
                    bodyVelocity.Velocity = GS.farmaDirecao * velocidadeVoo
                end)
                return
            end
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
GS.conectar(LocalPlayer.CharacterAdded,function(novoChar)
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
    local b = GS.novaInstancia("TextButton", TPListaFrame)
    b.Size = UDim2.new(1, 0, 0, 40); b.BackgroundColor3 = Color3.fromRGB(26, 26, 31)
    b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = true
    GS.novaInstancia("UICorner", b).CornerRadius = UDim.new(0, 6)

    local foto = GS.novaInstancia("ImageLabel", b)
    foto.Size = UDim2.new(0, 32, 0, 32); foto.Position = UDim2.new(0, 4, 0.5, -16)
    foto.BackgroundColor3 = Color3.fromRGB(36, 36, 42); foto.BorderSizePixel = 0
    foto.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
    GS.novaInstancia("UICorner", foto).CornerRadius = UDim.new(1, 0)

    local nome = GS.novaInstancia("TextLabel", b)
    nome.Size = UDim2.new(1, -120, 0, 20); nome.Position = UDim2.new(0, 44, 0, 2)
    nome.BackgroundTransparency = 1; nome.Font = Enum.Font.GothamBold; nome.TextSize = 13
    nome.TextColor3 = Color3.fromRGB(236, 236, 240); nome.TextXAlignment = Enum.TextXAlignment.Left
    nome.TextTruncate = Enum.TextTruncate.AtEnd; nome.Text = player.DisplayName

    local user = GS.novaInstancia("TextLabel", b)
    user.Size = UDim2.new(1, -120, 0, 16); user.Position = UDim2.new(0, 44, 0, 21)
    user.BackgroundTransparency = 1; user.Font = Enum.Font.Gotham; user.TextSize = 11
    user.TextColor3 = Color3.fromRGB(130, 130, 140); user.TextXAlignment = Enum.TextXAlignment.Left
    user.TextTruncate = Enum.TextTruncate.AtEnd; user.Text = "@" .. player.Name

    local info = GS.novaInstancia("TextLabel", b)
    info.Size = UDim2.new(0, 70, 1, 0); info.Position = UDim2.new(1, -74, 0, 0)
    info.BackgroundTransparency = 1; info.Font = Enum.Font.GothamBold; info.TextSize = 12
    info.TextColor3 = Color3.fromRGB(236, 236, 240); info.TextXAlignment = Enum.TextXAlignment.Right
    info.Text = "-- m"

    GS.conectar(b.MouseButton1Click,function()
        teleportarParaPlayer(player)
        info.Text = "✔ FOI!"
        GS.delay(0.8, function() pcall(function() info.Text = "-- m" end) end)
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

GS.conectar(Players.PlayerAdded,function() task.wait(0.5) atualizarListaTP() end)
GS.conectar(Players.PlayerRemoving,function(player)
    local linha = tpLinhas[player]
    if linha then linha.botao:Destroy() tpLinhas[player] = nil end
end)
GS.spawn(function()
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
    ghostHealthConn = GS.conectar(hum.HealthChanged,function()
        if not ghostAtivado then return end
        GS.spawn(function()
            local h = char and char:FindFirstChildOfClass("Humanoid")
            if h then aplicarVidaBruta(h) end
        end)
    end)
    ghostDiedConn = GS.conectar(hum.Died,function()
        if not ghostAtivado then return end
        GS.spawn(function()
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
                    local novo = GS.novaInstancia("Motor6D")
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
        ghostConnection = GS.conectar(RunService.Heartbeat,function()
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
        ghostSteppedConn = GS.conectar(RunService.Stepped,function()
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
        GS.conectar(LocalPlayer.CharacterAdded,function(newChar)
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

    local hl = GS.novaInstancia("Highlight")
    hl.FillColor = cor; hl.FillTransparency = 0.55
    hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model; hl.Enabled = false; hl.Parent = ESP.gui

    local bgui = GS.novaInstancia("BillboardGui")
    bgui.AlwaysOnTop = true; bgui.Size = UDim2.new(0, 200, 0, 58)
    bgui.StudsOffset = Vector3.new(0, 4, 0); bgui.Adornee = anc
    bgui.LightInfluence = 0; bgui.Parent = ESP.gui
    local bg = GS.novaInstancia("Frame", bgui)
    bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5; bg.BorderSizePixel = 0
    GS.novaInstancia("UICorner", bg).CornerRadius = UDim.new(0, 4)
    local function lbl(y, h, fonte, tam, c)
        local l = GS.novaInstancia("TextLabel", bgui)
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
        linha = GS.novaInstancia("Frame", ESP.gui)
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

    ESP.gui = GS.novaInstancia("ScreenGui")
    ESP.gui.Name = "GringoESP"; ESP.gui.IgnoreGuiInset = true
    ESP.gui.ResetOnSpawn = false; ESP.gui.DisplayOrder = 98
    ESP.gui.Parent = GS.pai

    ESP.hud = GS.novaInstancia("TextLabel", ESP.gui)
    ESP.hud.Size = UDim2.new(0, 360, 0, 30); ESP.hud.Position = UDim2.new(0.5, -180, 0, 40)
    ESP.hud.BackgroundColor3 = Color3.fromRGB(0, 0, 0); ESP.hud.BackgroundTransparency = 0.35
    ESP.hud.Font = Enum.Font.GothamBold; ESP.hud.TextSize = 15; ESP.hud.BorderSizePixel = 0
    ESP.hud.TextColor3 = Color3.fromRGB(255, 255, 255); ESP.hud.Text = "👹 PROCURANDO MONSTRO..."
    GS.novaInstancia("UICorner", ESP.hud).CornerRadius = UDim.new(0, 8)

    ESP.timer = ESP_CFG.RESCAN   -- varre ja no primeiro frame
    ESP.addConn = GS.conectar(workspace.DescendantAdded,function(obj)
        GS.defer(function()
            pcall(function()
                local m = _candidato(obj)
                if m then _adicionar(m) end
            end)
        end)
    end)

    ESP.conn = GS.conectar(RunService.Heartbeat,function(dt)
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
            antiTravaGyro = GS.novaInstancia("BodyGyro"); antiTravaGyro.Name = "GringoAntiTravaGyro"
            antiTravaGyro.MaxTorque = Vector3.new(math.huge, 0, math.huge)
            antiTravaGyro.P = 9999999  -- rigidez maxima
            antiTravaGyro.D = 1000     -- amortecimento para nao vibrar
            antiTravaGyro.CFrame = CFrame.new(root.Position) -- ereto, sem rotacao X/Z
            antiTravaGyro.Parent = root
        end

        antiTravaConnection = GS.conectar(RunService.Heartbeat,function()
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
                antiTravaGyro = GS.novaInstancia("BodyGyro"); antiTravaGyro.Name = "GringoAntiTravaGyro"
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
                GS.defer(function()
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
        table.insert(PX.regConns, GS.conectar(workspace.DescendantAdded,registrar))
        table.insert(PX.regConns, GS.conectar(workspace.DescendantRemoving,function(d)
            PX.reg[d] = nil; PX.cordasReg[d] = nil
        end))
    end
    GS.conectar(ScreenGui.Destroying,function()
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
        c.conn = GS.conectar(m.DescendantAdded,function(d) neutralizar(c, d) end)
        c.att = GS.novaInstancia("Attachment"); c.att.Name = "GringoPuxarAtt"; c.att.Parent = r
        c.ap = GS.novaInstancia("AlignPosition"); c.ap.Name = "GringoPuxarAP"
        c.ap.Mode = Enum.PositionAlignmentMode.OneAttachment
        c.ap.Attachment0 = c.att; c.ap.RigidityEnabled = true
        c.ap.Position = r.Position; c.ap.Parent = r
        c.ao = GS.novaInstancia("AlignOrientation"); c.ao.Name = "GringoPuxarAO"
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
        local grade = GS.novaInstancia("Frame", GS.puxarBox)
        grade.Size = UDim2.new(1, 0, 0, 0); grade.AutomaticSize = Enum.AutomaticSize.Y
        grade.BackgroundTransparency = 1; grade.LayoutOrder = 4
        local gl = GS.novaInstancia("UIGridLayout", grade)
        gl.CellSize = UDim2.new(1/3, -6, 0, 30); gl.CellPadding = UDim2.new(0, 8, 0, 8)
        gl.SortOrder = Enum.SortOrder.LayoutOrder
        for i, nome in ipairs(PX.DANCAS) do
            local b = GS.novaInstancia("TextButton", grade)
            b.Text = nome; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.AutoButtonColor = false
            b.BackgroundColor3 = U.T.card; b.TextColor3 = U.T.dim; b.BorderSizePixel = 0; b.LayoutOrder = i
            U.mkC(8, b); U.mkS(1, U.T.stroke, b); U.press(b)
            GS.conectar(b.MouseButton1Click,function()
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
        GS.conectar(togFuga.MouseButton1Click,function()
            PX.fuga = not PX.fuga
            togFuga.Text = PX.fuga and "FUGA: ON" or "FUGA: OFF"
        end)
        GS.conectar(togToque.MouseButton1Click,function()
            PX.antiToque = not PX.antiToque
            togToque.Text = PX.antiToque and "ANTI-TOQUE: ON" or "ANTI-TOQUE: OFF"
            if not PX.antiToque then PX.restaurarToque() else PX.ultimoToque = 0 end
        end)
        GS.conectar(fMenos.MouseButton1Click,function() PX.raioFuga = math.max(8, PX.raioFuga - 2); fLbl.Text = tostring(PX.raioFuga) end)
        GS.conectar(fMais.MouseButton1Click,function() PX.raioFuga = math.min(60, PX.raioFuga + 2); fLbl.Text = tostring(PX.raioFuga) end)
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
        puxarConnection = GS.conectar(RunService.Heartbeat,function(dt)
            if not PX.regConns then return end
            local ok, err = pcall(PX.passo, dt)
            if not ok and not PX.avisou then
                PX.avisou = true
                warn("[GRINGO PUXAR] " .. tostring(err))
            end
        end)
        GS.defer(PX.iniciarRegistro)   -- varre o mapa 1 vez so, sem travar o clique
        -- VACINA 2: re-trava ANTES da fisica — se o servidor teleportar o
        -- monstro, ele volta pro lugar no mesmo passo
        if PX.stepConn then PX.stepConn:Disconnect() end
        PX.stepConn = GS.conectar(RunService.Stepped,function()
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
            GS.delay(1.5, function()
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

    puxarUmConn = GS.conectar(RunService.Heartbeat,function()
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
        st.conn = GS.conectar(m.DescendantAdded,function(d) neutralizar(st, d) end)

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

        st.att = GS.novaInstancia("Attachment"); st.att.Name = "GringoDerrubaAtt"; st.att.Parent = r
        st.ap = GS.novaInstancia("AlignPosition"); st.ap.Name = "GringoDerrubaAP"
        st.ap.Mode = Enum.PositionAlignmentMode.OneAttachment; st.ap.Attachment0 = st.att
        st.ap.RigidityEnabled = true; st.ap.Position = de; st.ap.Parent = r
        st.ao = GS.novaInstancia("AlignOrientation"); st.ao.Name = "GringoDerrubaAO"
        st.ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; st.ao.Attachment0 = st.att
        st.ao.RigidityEnabled = true; st.ao.CFrame = r.CFrame; st.ao.Parent = r
        DR.caidos[m] = st

        st.loop = GS.conectar(RunService.Heartbeat,function(dt)
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
    DR.stepConn = GS.conectar(RunService.Stepped,function()
        for _, st in pairs(DR.caidos) do
            if st.cf and st.r.Parent then
                pcall(function() st.r.CFrame = st.cf; st.r.AssemblyLinearVelocity = ZERO end)
            end
        end
    end)

    DR.limpar = function()
        for m in pairs(DR.caidos) do levantar(m) end
    end
    GS.conectar(ScreenGui.Destroying,function()
        DR.limpar()
        if DR.stepConn then DR.stepConn:Disconnect() DR.stepConn = nil end
    end)

    -- botao pra escolher a tecla
    if GS.derrubaTeclaBtn then
        local b = GS.derrubaTeclaBtn
        GS.conectar(b.MouseButton1Click,function()
            DR.escutando = true
            b.Text = "[APERTE A TECLA]"
        end)
        GS.conectar(UserInputService.InputBegan,function(input)
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
        derrubaXConn = GS.conectar(UserInputService.InputBegan,function(input, gp)
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
        bikeAntiQuedaKeyConn = GS.conectar(UserInputService.InputBegan,function(input, _)
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
                    bikeGyroAntiQueda = GS.novaInstancia("BodyGyro"); bikeGyroAntiQueda.Name = "GringoBikeGyro"
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
        bikeAntiQuedaConn = GS.conectar(RunService.Heartbeat,function()
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
                    bikeGyroAntiQueda = GS.novaInstancia("BodyGyro"); bikeGyroAntiQueda.Name = "GringoBikeGyro"
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
GS.conectar(BikeAntiQuedaKeyButton.MouseButton1Click,function()
    if bikeAntiQuedaAtivado then return end
    escutandoAntiQuedaKey = true
    BikeAntiQuedaKeyButton.Text = "[PRESSIONE TECLA]"
    BikeAntiQuedaKeyButton.TextColor3 = Color3.fromRGB(255, 255, 0)
end)

GS.conectar(UserInputService.InputBegan,function(input, _)
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
        paredePreview = GS.novaInstancia("Part")
        paredePreview.Name = "GringoParedePreview"
        paredePreview.Size = PAREDE_TAMANHO
        paredePreview.Anchored = true
        paredePreview.CanCollide = false
        paredePreview.Material = Enum.Material.ForceField
        paredePreview.Color = Color3.fromRGB(255, 60, 60)
        paredePreview.Transparency = 0.5
        paredePreview.Parent = workspace

        local mouse = LocalPlayer:GetMouse()
        paredeRenderConn = GS.conectar(RunService.RenderStepped,function()
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

GS.conectar(ParedeConfirmButton.MouseButton1Click,function()
    if not paredeAtiva or not paredePreview then return end

    -- Cria a parede de verdade: solida (CanCollide) e invisivel (Transparency 1)
    -- OBS: essa parede so bloqueia o SEU proprio personagem. Uma Part criada
    -- por script local nao existe pro servidor nem pros outros clients, entao
    -- e fisicamente impossivel travar outros jogadores com ela — isso nao e
    -- um bug, e uma limitacao de seguranca do proprio Roblox.
    local parede = GS.novaInstancia("Part")
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

GS.conectar(ParedeRemoverButton.MouseButton1Click,function()
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
        GS.spawn(function() pcall(function() remote:InvokeServer(table.unpack(args)) end) end)
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
        GS.spawn(function()
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
    GS.conectar(sw.botao.MouseButton1Click,function() definirCorEscolhida(sw.cor) end)
end
GS.conectar(CorHexInput.FocusLost,function()
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
        local animator = hum and (hum:FindFirstChildOfClass("Animator") or GS.novaInstancia("Animator", hum))
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
    C.colConn = GS.conectar(RunService.Stepped,function()
        _semColisao(LocalPlayer.Character)
    end)
    -- PreSimulation roda ANTES da fisica (1 frame a menos de atraso que o
    -- Heartbeat). Executor/cliente antigo sem ele → Stepped (mesmo momento).
    local sinalFrame = RunService.Stepped
    pcall(function() sinalFrame = RunService.PreSimulation end)
    C.conn = GS.conectar(sinalFrame,function()
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
    C.colConn = GS.conectar(RunService.Stepped,function()
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
    GS.delay(CFG.TIMEOUT, function()
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
    P.frame = GS.novaInstancia("Frame")
    P.frame.Name = "PopupCarregar"
    P.frame.Size = UDim2.new(0, 320, 0, 120); P.frame.Position = UDim2.new(0.5, -160, 0, 80)
    P.frame.BackgroundColor3 = Color3.fromRGB(16, 16, 19); P.frame.BorderSizePixel = 0
    P.frame.Visible = false; P.frame.ZIndex = 50; P.frame.Parent = ScreenGui
    GS.novaInstancia("UICorner", P.frame).CornerRadius = UDim.new(0, 12)
    local st = GS.novaInstancia("UIStroke", P.frame); st.Thickness = 2; st.Color = Color3.fromRGB(200, 200, 210)
    P.texto = GS.novaInstancia("TextLabel", P.frame)
    P.texto.Size = UDim2.new(1, -20, 0, 56); P.texto.Position = UDim2.new(0, 10, 0, 6)
    P.texto.BackgroundTransparency = 1; P.texto.Font = Enum.Font.GothamBold; P.texto.TextWrapped = true
    P.texto.TextColor3 = Color3.fromRGB(255, 255, 255); P.texto.TextSize = 15; P.texto.ZIndex = 51
    local function botao(txt, cor, x)
        local b = GS.novaInstancia("TextButton", P.frame)
        b.Size = UDim2.new(0.5, -15, 0, 40); b.Position = UDim2.new(x, x == 0 and 10 or 5, 1, -50)
        b.BackgroundColor3 = cor; b.Font = Enum.Font.GothamBold; b.Text = txt
        b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 14; b.BorderSizePixel = 0; b.ZIndex = 51
        GS.novaInstancia("UICorner", b).CornerRadius = UDim.new(0, 8)
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
    GS.delay(CFG.TIMEOUT, function()
        if C.recebido == remetente then
            C.recebido = nil
            P.frame.Visible = false
        end
    end)
end

GS.conectar(P.aceitar.MouseButton1Click,function()
    local quem = C.recebido
    C.recebido = nil
    P.frame.Visible = false
    if not quem or not quem.Parent then return end
    if C.carregando then _pararDeCarregar() end
    enviarChat(CFG.PREFIXO .. " aceito " .. quem.Name)
    _comecarSerCarregado(quem)
end)
GS.conectar(P.recusar.MouseButton1Click,function()
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
        table.insert(C.conns, GS.conectar(TextChatService.MessageReceived,function(msg)
            local src = msg.TextSource
            if src then processarMensagemCarregar(Players:GetPlayerByUserId(src.UserId), msg.Text) end
        end))
    else
        local function ouvir(p)
            table.insert(C.conns, GS.conectar(p.Chatted,function(m) processarMensagemCarregar(p, m) end))
        end
        for _, p in ipairs(Players:GetPlayers()) do ouvir(p) end
        table.insert(C.conns, GS.conectar(Players.PlayerAdded,ouvir))
    end
end)

-- ── Recebe pelo SINAL DE ANIMACAO (checa 4x por segundo) ──
local TOLERANCIA_SINAL = 2   -- s sem o sinal do outro antes de soltar
GS.spawn(function()
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
    GS.delay(CFG.SEGURAR, function()
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

table.insert(C.conns, GS.conectar(UserInputService.InputBegan,function(input, gp)
    if gp or escutandoTecla then return end
    if input.KeyCode == CFG.TECLA then _comecarSegurar() end
end))
table.insert(C.conns, GS.conectar(UserInputService.InputEnded,function(input)
    if input.KeyCode == CFG.TECLA then _soltarSegurar() end
end))
GS.conectar(CarregarSegurarButton.MouseButton1Down,_comecarSegurar)
local function _ajustarCostas(campo, delta, lbl)
    CFG[campo] = math.clamp(math.floor((CFG[campo] + delta) * 10 + 0.5) / 10, -2, 5)
    lbl.Text = string.format("%.1f", CFG[campo])
end
GS.conectar(CostasCtrl.atrasMenos.MouseButton1Click,function()  _ajustarCostas("COSTAS_ATRAS", -0.1, CostasCtrl.atrasLbl) end)
GS.conectar(CostasCtrl.atrasMais.MouseButton1Click,function()   _ajustarCostas("COSTAS_ATRAS",  0.1, CostasCtrl.atrasLbl) end)
GS.conectar(CostasCtrl.alturaMenos.MouseButton1Click,function() _ajustarCostas("COSTAS_ALTURA", -0.1, CostasCtrl.alturaLbl) end)
GS.conectar(CostasCtrl.alturaMais.MouseButton1Click,function()  _ajustarCostas("COSTAS_ALTURA",  0.1, CostasCtrl.alturaLbl) end)
local function _ajustarDelay(delta)
    -- AUTO (-1) → 0 → 20 → 40 ... 400; abaixo de 0 volta pro AUTO
    local v = CFG.COSTAS_LEAD_MS
    if v < 0 then v = delta > 0 and 0 or -1 else v = v + delta end
    if v < 0 then v = -1 end
    CFG.COSTAS_LEAD_MS = math.min(v, 400)
    CostasCtrl.delayLbl.Text = CFG.COSTAS_LEAD_MS < 0 and "AUTO" or tostring(CFG.COSTAS_LEAD_MS)
end
GS.conectar(CostasCtrl.delayMenos.MouseButton1Click,function() _ajustarDelay(-20) end)
GS.conectar(CostasCtrl.delayMais.MouseButton1Click,function()  _ajustarDelay(20)  end)
GS.conectar(CostasButton.MouseButton1Click,function()
    if C.carregadoPor and C.costas then _pararDeSerCarregado() return end
    if C.carregando or C.carregadoPor then soltarCarregar() end
    local alvo = localizarJogadorPorNome(CarregarNomeInput.Text) or _maisPerto()
    if not alvo then setStatus("ESCOLHE ELA NA LISTA") return end
    if not (alvo.Character and alvo.Character:FindFirstChild("HumanoidRootPart")) then
        setStatus(alvo.Name:upper() .. " SEM PERSONAGEM") return
    end
    _comecarSerCarregado(alvo, true)
end)
GS.conectar(CarregarSegurarButton.MouseButton1Up,_soltarSegurar)
GS.conectar(CarregarSegurarButton.MouseLeave,_soltarSegurar)

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
            local b = GS.novaInstancia("TextButton", CarregarListaFrame)
            b.Size = UDim2.new(1, 0, 0, 34); b.BorderSizePixel = 0; b.Text = ""
            GS.novaInstancia("UICorner", b).CornerRadius = UDim.new(0, 6)
            local foto = GS.novaInstancia("ImageLabel", b)
            foto.Size = UDim2.new(0, 26, 0, 26); foto.Position = UDim2.new(0, 4, 0.5, -13)
            foto.BackgroundColor3 = Color3.fromRGB(36, 36, 42); foto.BorderSizePixel = 0
            foto.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
            GS.novaInstancia("UICorner", foto).CornerRadius = UDim.new(1, 0)
            local nome = GS.novaInstancia("TextLabel", b)
            nome.Name = "Nome"
            nome.Size = UDim2.new(1, -40, 1, 0); nome.Position = UDim2.new(0, 36, 0, 0)
            nome.BackgroundTransparency = 1; nome.Font = Enum.Font.GothamBold; nome.TextSize = 12
            nome.TextXAlignment = Enum.TextXAlignment.Left; nome.TextTruncate = Enum.TextTruncate.AtEnd
            nome.Text = player.DisplayName .. "  (@" .. player.Name .. ")"
            GS.conectar(b.MouseButton1Click,function()
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
GS.conectar(Players.PlayerAdded,function() task.wait(0.5) pcall(atualizar) end)
GS.conectar(Players.PlayerRemoving,function() task.wait() pcall(atualizar) end)
GS.conectar(CarregarNomeInput:GetPropertyChangedSignal("Text"),function() pcall(atualizar) end)
pcall(atualizar)
end  -- fim LISTA DO CARREGAR

do
-- ═══════════════════════════════════════════════════════════════
--   REGENERAR / RENASCER + ANTI-VOID (CODIGO BRUTO)
-- ═══════════════════════════════════════════════════════════════
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
    local char, root, hum = _rootEHum()
    if not (char and root and hum) then
        GS.toast("Espere seu personagem aparecer", false)
        return
    end
    R.morrendo = true
    local function informar(texto)
        if not ScreenGui.Parent then return end
        RegenUI.regenerar.Text = texto
        if GS.resetStatus then GS.resetStatus.Text = texto end
    end
    informar("RENASCENDO · aguardando o servidor")
    pcall(function() if ghostAtivado then alternarGhost() end end)
    pcall(function() if GS.limparCarregar then GS.limparCarregar() end end)
    pcall(function() if flyAtivado then alternarFly() end end)

    GS.spawn(function()
        bypassHealthBlock = true
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
        pcall(function() hum.BreakJointsOnDeath = true end)
        pcall(function() hum.Health = 0 end)
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
        bypassHealthBlock = false

        task.wait(0.15)
        if LocalPlayer.Character == char and hum.Parent and hum.Health > 0
            and hum:GetState() ~= Enum.HumanoidStateType.Dead then
            pcall(function() char:BreakJoints() end)
        end

        local limite = os.clock() + math.max(15, Players.RespawnTime + 10)
        local novoChar, novoRoot, novoHum
        while ScreenGui.Parent and os.clock() < limite do
            local atual, raiz, humanoide = _rootEHum()
            if atual and atual ~= char and raiz and humanoide and humanoide.Health > 0 then
                novoChar, novoRoot, novoHum = atual, raiz, humanoide
                break
            end
            task.wait(0.05)
        end
        if not ScreenGui.Parent then R.morrendo = false return end
        if not novoChar then
            informar("O servidor não confirmou o renascimento")
            GS.toast("O jogo não confirmou o reset. Tente Redefinir personagem pelo menu Roblox", false)
            R.morrendo = false
            return
        end
        informar("RENASCIDO · no ponto de spawn")
        R.morrendo = false
        GS.delay(2, function()
            if ScreenGui.Parent and not R.morrendo then
                RegenUI.regenerar.Text = "RENASCER"
            end
        end)
    end)
end
GS.renascer = regenerar

-- Grava o ultimo chao seguro + anti-void
GS.spawn(function()
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

GS.conectar(RegenUI.regenerar.MouseButton1Click,regenerar)
GS.conectar(RegenUI.voltar.MouseButton1Click,function()
    RegenUI.voltar.Text = voltarProChao() and "⬆ VOLTEI!" or "⬆ SEM CHÃO SALVO"
    GS.delay(1.2, function() pcall(function() RegenUI.voltar.Text = "⬆ VOLTAR PRO ÚLTIMO CHÃO (TECLA L)" end) end)
end)
GS.conectar(RegenUI.antiVoid.MouseButton1Click,function()
    R.antiVoid = not R.antiVoid
    RegenUI.antiVoid.Text = R.antiVoid and "ANTI-VOID: ON" or "ANTI-VOID: OFF"
end)
GS.conectar(UserInputService.InputBegan,function(input, gp)
    if gp or escutandoTecla or UserInputService:GetFocusedTextBox()
        or (GS.retornoSeguro and GS.retornoSeguro.escolhendo) then return end
    if input.KeyCode == Enum.KeyCode.K then
        if not GS.noclipArquivo then regenerar() end
    elseif input.KeyCode == Enum.KeyCode.L then voltarProChao() end
end)
end  -- fim REGENERAR

-- ═══════════════════════════════════
--   EVENTOS DE CLIQUE
-- ═══════════════════════════════════
GS.conectar(SpeedUpButton.MouseButton1Click,function()
    velocidadeCustomizada = math.min(800, velocidadeCustomizada + (velocidadeCustomizada < 100 and 10 or 50))
    SpeedLabel.Text = "VEL: " .. tostring(velocidadeCustomizada)
end)
GS.conectar(SpeedDownButton.MouseButton1Click,function()
    velocidadeCustomizada = math.max(16, velocidadeCustomizada - (velocidadeCustomizada <= 100 and 10 or 50))
    SpeedLabel.Text = "VEL: " .. tostring(velocidadeCustomizada)
end)
GS.conectar(FlyUpButton.MouseButton1Click,function()
    velocidadeVoo = math.min(300, velocidadeVoo + 25)
    FlyLabel.Text = "VOO: " .. tostring(velocidadeVoo)
end)
GS.conectar(FlyDownButton.MouseButton1Click,function()
    velocidadeVoo = math.max(10, velocidadeVoo - 25)
    FlyLabel.Text = "VOO: " .. tostring(velocidadeVoo)
end)

function GS.encerrar()
    if not GS.pararRecursos() then return end
    -- Cada etapa e isolada: uma funcao ausente nao interrompe as demais.
    GS.emLimpeza=true
    for _,nome in ipairs({"pararFarmaFrascos","pararFarmaLucky","pararFarmaTesouro","pararFarmaNome",
        "pararCorGlobal","limparCarregar","limparESP"}) do
        if type(GS[nome])=="function" then GS.tentar(nome,GS[nome]) end
    end
    GS.tentar("hooks",removerHooks)
    if GS.valeRush then
        GS.tentar("Vale Rush camera",GS.valeRush.visao,false)
        GS.tentar("Vale Rush mapa",GS.valeRush.otimizar,false)
        GS.tentar("Vale Rush box",GS.valeRush.boxes,false)
    end
    GS.tentar("tamanho",function() aplicarTamanho(1) end)
    noclipAtivado=false; speedAtivado=false; flyAtivado=false
    fullbrightAtivado=false; ghostAtivado=false
    GS.farmaDirecao=nil
    GS.tentar("puxar",_limparPuxar)
    GS.tentar("puxar jogador",_limparPuxarUm)
    GS.tentar("parede preview",_limparParedePreview)
    for _,p in ipairs(paredesCriadas) do GS.tentar("parede",function() p:Destroy() end) end
    paredesCriadas={}
    for part,original in pairs(GS.noclipOrig or {}) do
        GS.tentar("colisao",function()
            if part.Parent then part.CanCollide=type(original)=="boolean" and original or true end
        end)
    end
    GS.tentar("personagem",function()
        local char=LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if hum then
            local original=GS.humanoides[hum]
            if original then
                for prop,valor in pairs(original.props) do GS.tentar(prop,function() hum[prop]=valor end) end
                for estado,ativo in pairs(original.estados) do GS.tentar("estado",function() hum:SetStateEnabled(estado,ativo) end) end
            else
                hum.PlatformStand=false
                hum.WalkSpeed=16
            end
        end
        if root then root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end
    end)
    GS.tentar("iluminacao",function()
        Lighting.Ambient=originalAmbient; Lighting.OutdoorAmbient=originalOutdoorAmbient
        Lighting.Brightness=originalBrightness; Lighting.FogEnd=originalFog
    end)
    GS.emLimpeza=false
    GS.finalizarRecursos()
    if GS.ambiente and GS.ambiente.__GringoEncerrar==GS.encerrar then
        GS.ambiente.__GringoEncerrar=nil
    end
end
GS.conectar(UnloadButton.MouseButton1Click,GS.encerrar)
GS.conectar(ScreenGui.Destroying,GS.encerrar)
pcall(function()
    GS.ambiente=type(getgenv)=="function" and getgenv() or _G
    GS.ambiente.__GringoEncerrar=GS.encerrar
end)

GS.conectar(NoclipButton.MouseButton1Click,alternarNoclip)
GS.conectar(BrightnessButton.MouseButton1Click,alternarBrilho)
GS.conectar(SpeedButton.MouseButton1Click,alternarSpeed)
GS.conectar(FlyButton.MouseButton1Click,alternarFly)
GS.conectar(TPButton.MouseButton1Click,executarTeleporte)
GS.conectar(TPNameInput:GetPropertyChangedSignal("Text"),atualizarListaTP)
GS.conectar(GhostButton.MouseButton1Click,alternarGhost)
GS.conectar(EspButton.MouseButton1Click,GS.alternarEsp)
GS.conectar(AntiTravaButton.MouseButton1Click,alternarAntiTrava)
GS.conectar(PuxarButton.MouseButton1Click,alternarPuxar)
GS.conectar(GS.dancaBtn.MouseButton1Click,GS.alternarDanca)
GS.conectar(PuxarUmButton.MouseButton1Click,alternarPuxarUm)
GS.conectar(TamanhoSlider.Changed,aplicarTamanho)
GS.conectar(DerrubaButton.MouseButton1Click,alternarDerruba)
GS.conectar(BikeAntiQuedaButton.MouseButton1Click,alternarBikeAntiQueda)
GS.conectar(ParedeButton.MouseButton1Click,alternarParede)
GS.conectar(CorAplicarButton.MouseButton1Click,GS.aplicarCorGlobal)
GS.conectar(CorGlobalButton.MouseButton1Click,GS.alternarCorGlobal)

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
        GS.spawn(function()
            local ok, sim = pcall(function() return LocalPlayer:IsFriendsWith(plr.UserId) end)
            GS.amigos[plr.UserId] = (ok and sim) and true or false
        end)
        return true
    end
    return v ~= false
end
for _, p in ipairs(Players:GetPlayers()) do GS.ehAmigo(p) end
GS.conectar(Players.PlayerAdded,function(p) GS.ehAmigo(p) end)

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

    local conteudo = GS.novaInstancia("Frame", painel)
    conteudo.Size = UDim2.new(1,0,0,1); conteudo.AutomaticSize = Enum.AutomaticSize.Y
    conteudo.BackgroundTransparency = 1; conteudo.LayoutOrder = 4; conteudo.Visible = false
    do
        local l = GS.novaInstancia("UIListLayout", conteudo); l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0,8); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    end

    U.sec(conteudo, "AIMBOT", "🎯", 1)
    local togAim = U.tog(conteudo, "AIMBOT", 2)

    local grade = GS.novaInstancia("Frame", conteudo)
    grade.Size = UDim2.new(1,0,0,36); grade.BackgroundTransparency = 1; grade.LayoutOrder = 3
    do
        local gl = GS.novaInstancia("UIGridLayout", grade)
        gl.CellSize = UDim2.new(0.25,-6,1,0); gl.CellPadding = UDim2.new(0,8,0,0)
        gl.SortOrder = Enum.SortOrder.LayoutOrder
    end

    local descModo = GS.novaInstancia("TextLabel", conteudo)
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
        local b = GS.novaInstancia("TextButton", grade)
        b.Text = nome; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.AutoButtonColor = false
        b.BackgroundColor3 = T.card; b.TextColor3 = T.dim; b.BorderSizePixel = 0; b.LayoutOrder = i
        U.mkC(9, b); U.mkS(1, T.stroke, b); U.press(b)
        GS.conectar(b.MouseButton1Click,function()
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
        local f = GS.novaInstancia("Frame")
        f.BorderSizePixel = 0; f.BackgroundColor3 = cor; f.ZIndex = z or 1; f.Visible = false
        f.Parent = pai
        return f
    end

    local function criarESP(h)
        local e = {}
        e.sombra = novoFrame(camada, Color3.new(0,0,0), 1); e.sombra.BackgroundTransparency = 1
        local s1 = GS.novaInstancia("UIStroke", e.sombra); s1.Thickness = 3.5; s1.Color = Color3.new(0,0,0); s1.Transparency = 0.45
        e.box = novoFrame(camada, Color3.new(1,1,1), 2); e.box.BackgroundTransparency = 1
        e.boxStroke = GS.novaInstancia("UIStroke", e.box); e.boxStroke.Thickness = 1.5

        e.linha = novoFrame(camada, Color3.new(1,1,1), 2)
        e.linha.AnchorPoint = Vector2.new(0.5,0.5); e.linha.BackgroundTransparency = 0.15

        e.vidaFundo = novoFrame(camada, Color3.new(0,0,0), 2); e.vidaFundo.BackgroundTransparency = 0.35
        e.vida = novoFrame(e.vidaFundo, Color3.new(0,1,0), 3); e.vida.Visible = true
        e.vida.AnchorPoint = Vector2.new(0,1); e.vida.Position = UDim2.new(0,1,1,-1)

        e.nome = GS.novaInstancia("TextLabel")
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
    GS.conectar(ScreenGui.Destroying,limpar)

    -- ── Conectar ────────────────────────────────────────────────
    local function conectar(nomeJogo)
        C.conectado = true
        status.Text = "✔ CONECTADO: " .. string.upper(nomeJogo)
        status.TextColor3 = T.text
        btnConectar.Visible = false
        conteudo.Visible = true

        camada = GS.novaInstancia("Frame")
        camada.Name = "GringoESP"; camada.Size = UDim2.new(1,0,1,0)
        camada.BackgroundTransparency = 1; camada.ZIndex = 0; camada.Parent = ScreenGui

        circuloFov = GS.novaInstancia("Frame", camada)
        circuloFov.AnchorPoint = Vector2.new(0.5,0.5); circuloFov.BackgroundTransparency = 1
        circuloFov.Visible = false; U.redondo(circuloFov)
        local st = GS.novaInstancia("UIStroke", circuloFov); st.Thickness = 1; st.Color = Color3.new(1,1,1); st.Transparency = 0.4

        for _, d in ipairs(workspace:GetDescendants()) do registrar(d) end
        table.insert(C.conns, GS.conectar(workspace.DescendantAdded,registrar))

        pcall(function() RunService:UnbindFromRenderStep("GringoCombate") end)
        GS.bindRender(RunService,"GringoCombate", Enum.RenderPriority.Camera.Value + 1, function(dt)
            local ok, err = pcall(passo, dt)
            if not ok and not C.avisou then
                C.avisou = true
                warn("[GRINGO COMBATE] " .. tostring(err))
            end
        end)

        GS.toast("🔌  Conectado: " .. nomeJogo, true)
    end

    GS.conectar(btnConectar.MouseButton1Click,function()
        if C.conectado or C.conectando then return end
        C.conectando = true
        status.Text = "STATUS: CONECTANDO..."; status.TextColor3 = T.dim
        GS.spawn(function()
            local nome = "JOGO"
            local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
            if ok and type(info) == "table" and type(info.Name) == "string" then nome = info.Name end
            task.wait(0.5)
            if not ScreenGui.Parent then return end
            C.conectando = false
            conectar(nome)
        end)
    end)

    GS.conectar(togAim.MouseButton1Click,function()
        C.aimbot = not C.aimbot
        if not C.aimbot then C.alvoAtual = nil end
        togAim.Text = C.aimbot and "AIMBOT: ON" or "AIMBOT: OFF"
    end)
    GS.conectar(togEsp.MouseButton1Click,function()
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
        local g = GS.novaInstancia("BillboardGui")
        g.AlwaysOnTop = true; g.Size = UDim2.fromOffset(180, 32); g.StudsOffset = Vector3.new(0, 1.5, 0)
        g.MaxDistance = math.huge; g.LightInfluence = 0; g.Adornee = parte; g.Enabled = false
        local bg = GS.novaInstancia("Frame", g)
        bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.new(0, 0, 0)
        bg.BackgroundTransparency = 0.45; bg.BorderSizePixel = 0
        GS.novaInstancia("UICorner", bg).CornerRadius = UDim.new(0, 5)
        local barra = GS.novaInstancia("Frame", bg)
        barra.Size = UDim2.new(0, 3, 1, -8); barra.Position = UDim2.new(0, 4, 0, 4)
        barra.BackgroundColor3 = cat.cor; barra.BorderSizePixel = 0
        local function lbl(y, h, fonte, tam, cor)
            local l = GS.novaInstancia("TextLabel", bg)
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
        R.gui = GS.novaInstancia("ScreenGui")
        R.gui.Name = "GringoItens"; R.gui.ResetOnSpawn = false; R.gui.DisplayOrder = 97
        R.gui.Parent = GS.pai

        table.insert(R.conns, GS.conectar(workspace.DescendantAdded,function(obj)
            GS.defer(function() pcall(adicionar, obj) end)
        end))
        table.insert(R.conns, GS.conectar(RunService.Heartbeat,function(dt)
            R.t = R.t + dt
            if R.t < 0.2 then return end
            R.t = 0
            local ok, err = pcall(atualizar)
            if not ok and not R.avisou then R.avisou = true warn("[GRINGO RASTREAR] " .. tostring(err)) end
        end))

        -- varredura inicial em pedacos de 2500 objetos por frame
        local guiAtual = R.gui
        R.varrendo = true
        GS.spawn(function()
            local todos = workspace:GetDescendants()
            for i, obj in ipairs(todos) do
                if R.gui ~= guiAtual then return end
                pcall(adicionar, obj)
                if i % 2500 == 0 then task.wait() end
            end
            R.varrendo = false
        end)
    end

    GS.conectar(togItens.MouseButton1Click,function()
        R.ativo = not R.ativo
        togItens.Text = R.ativo and "ESP ITENS: ON" or "ESP ITENS: OFF"
        if R.ativo then ligar() else desligar() end
    end)
    GS.conectar(togInter.MouseButton1Click,function()
        R.interagir = not R.interagir
        togInter.Text = R.interagir and "INTERAGÍVEIS: ON" or "INTERAGÍVEIS: OFF"
    end)
    GS.conectar(ScreenGui.Destroying,desligar)
end
GS.rodar("Rastreio", GS.iniciarRastreio, GS.painelRastrear)

-- ═══════════════════════════════════════════════════════════════
--   FARMAR VIBES — coleta local para playtest
-- ═══════════════════════════════════════════════════════════════
-- Vale Rush: controles visuais locais, reversiveis e independentes da coleta.
-- Vale Rush: controles visuais locais, reversiveis e independentes da coleta.
GS.iniciarValeRush = function()
    local U,painel=GS.ui,GS.painelValeRush
    if not U or not painel then return end
    local Lighting=game:GetService("Lighting")
    local Players=game:GetService("Players")
    local Run=game:GetService("RunService")
    local jogador=Players.LocalPlayer
    local V={camera=false,leve=false,fov=95,epoch=0,busy=false,vivo=true,
        salvos=setmetatable({}, {__mode="k"}),cameras=setmetatable({}, {__mode="k"}),
        conns={},fila={},pendentes=setmetatable({}, {__mode="k"}),head=1,mudancas=0,box=false,boxPlayers={},velocidades=setmetatable({}, {__mode="k"})}
    U.sec(painel,"VALE RUSH · HUSS VALLEY","gauge",1)
    local cameraBtn=U.tog(painel,"VISÃO AMPLIADA: OFF",2,"eye")
    local menos,mais,fovLabel=U.ctrl(painel,"Campo de visão (graus)",V.fov,3)
    local leveBtn=U.tog(painel,"MAPA LEVE: OFF",4,"zap")
    local info=U.pequeno(painel,"Modo intenso · gráficos mínimos · velocidade 31",nil,5,"info")
    info.AutoButtonColor=false
    local contador=U.pequeno(painel,"FPS: medindo...",nil,6,"gauge")
    contador.AutoButtonColor=false
    local boxBtn=U.tog(painel,"ESP PROFISSIONAL: OFF",7,"users")
    local focoBtn=U.tog(painel,"FOCAR COM BOTÃO DO MEIO: OFF",8,"crosshair")
    local focoStatus=U.pequeno(painel,"FOCO: DESLIGADO",nil,9,"info")
    focoStatus.AutoButtonColor=false
    local desfocarBtn=U.acao(painel,"DESFOCAR AGORA","x",10)
    local restaurarBtn=U.acao(painel,"RESTAURAR TUDO","refresh-cw",11)

    -- Guarda apenas propriedades que conseguiu alterar; nada e destruido.
    function V.alterar(obj,prop,valor)
        local ok,atual=pcall(function() return obj[prop] end)
        if not ok or atual==valor then return false end
        local props=V.salvos[obj]
        local registro=props and props[prop]
        local mudou=pcall(function() obj[prop]=valor end)
        if not mudou then return false end
        if not props then props={}; V.salvos[obj]=props end
        if not registro then registro={original=atual}; props[prop]=registro end
        registro.aplicado=valor
        V.mudancas=V.mudancas+1
        return true
    end

    function V.protegido(obj)
        local atual=obj
        while atual and atual~=workspace and atual~=Lighting do
            if atual:IsA("Tool") then return true end
            if atual:IsA("Model") and atual:FindFirstChildOfClass("Humanoid") then return true end
            if atual.Name=="PotionTemplate" then return true end
            atual=atual.Parent
        end
        return false
    end

    function V.aplicar(obj)
        if not V.leve or not obj.Parent or V.protegido(obj) then return end
        if obj:IsA("BasePart") then
            -- Materiais tambem definem atrito: conserva a fisica efetiva do piso.
            local podeMaterial=obj.CustomPhysicalProperties~=nil
            if not podeMaterial then
                podeMaterial=V.alterar(obj,"CustomPhysicalProperties",obj.CurrentPhysicalProperties)
            end
            if podeMaterial then
                V.alterar(obj,"Material",Enum.Material.SmoothPlastic)
                V.alterar(obj,"MaterialVariant","")
            end
            V.alterar(obj,"Reflectance",0)
            V.alterar(obj,"CastShadow",false)
            if obj:IsA("MeshPart") then
                V.alterar(obj,"TextureID","")
                V.alterar(obj,"RenderFidelity",Enum.RenderFidelity.Performance)
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            V.alterar(obj,"Transparency",1)
            V.alterar(obj,"Texture","")
        elseif obj:IsA("SpecialMesh") then
            V.alterar(obj,"TextureId","")
        elseif obj:IsA("SurfaceAppearance") then
            for _,prop in ipairs({"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}) do
                V.alterar(obj,prop,"")
            end
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
            or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            V.alterar(obj,"Enabled",false)
        elseif obj:IsA("PostEffect") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect")
            or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") then
            V.alterar(obj,"Enabled",false)
        elseif obj:IsA("Light") then
            V.alterar(obj,"Shadows",false)
        elseif obj:IsA("Atmosphere") then
            V.alterar(obj,"Density",0)
            V.alterar(obj,"Haze",0)
        end
    end

    function V.enfileirar(obj)
        if not V.leve or V.pendentes[obj] then return end
        V.pendentes[obj]=true
        V.fila[#V.fila+1]=obj
    end

    -- A velocidade usa WalkSpeed, sem deslocamentos extras de CFrame.
    function V.velocidade(ativo)
        if ativo then
            local char=jogador.Character
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health>0 then
                if not V.velocidades[hum] then V.velocidades[hum]={original=hum.WalkSpeed} end
                if hum.WalkSpeed~=31 then hum.WalkSpeed=31 end
            end
        else
            for hum,r in pairs(V.velocidades) do
                pcall(function() if hum.WalkSpeed==31 then hum.WalkSpeed=r.original end end)
            end
            V.velocidades=setmetatable({}, {__mode="k"})
            if V.speedAnterior and velocidadeCustomizada==31 then
                velocidadeCustomizada=V.speedAnterior
                if SpeedLabel then SpeedLabel.Text="VEL: "..velocidadeCustomizada end
            end
            V.speedAnterior=nil
        end
    end

    function V.limparBox(player)
        local r=V.boxPlayers[player]
        if not r then return end
        if r.visual then r.visual:Destroy(); r.visual=nil end
        r.ui=nil
    end
    function V.desenharBox(player,char)
        if not V.box or player==jogador then return end
        local r=V.boxPlayers[player]
        if not r then return end
        V.limparBox(player)
        r.char=char
        if not char then return end
        local pasta=GS.novaInstancia("Folder"); pasta.Name="ESP_"..player.Name; pasta.Parent=V.boxFolder
        local cor=Color3.fromRGB(70,235,210)
        local function frame(nome,pai)
            local f=GS.novaInstancia("Frame");f.Name=nome;f.BorderSizePixel=0;f.BackgroundTransparency=1;f.Parent=pai;return f
        end
        local box=frame("Caixa",pasta);box.ZIndex=81
        local contorno=GS.novaInstancia("UIStroke");contorno.Color=Color3.fromRGB(6,12,20);contorno.Thickness=3;contorno.Parent=box
        local interno=frame("Borda",box);interno.Size=UDim2.fromScale(1,1);interno.ZIndex=82
        local stroke=GS.novaInstancia("UIStroke");stroke.Color=cor;stroke.Thickness=1;stroke.Parent=interno
        local function texto(nome,altura)
            local t=GS.novaInstancia("TextLabel");t.Name=nome;t.Size=UDim2.new(1,100,0,altura)
            t.Position=UDim2.new(0,-50,0,-altura-3);t.BackgroundTransparency=1;t.TextColor3=Color3.fromRGB(240,255,255)
            t.TextStrokeColor3=Color3.fromRGB(0,0,0);t.TextStrokeTransparency=0.15
            t.Font=Enum.Font.GothamBold;t.TextSize=12;t.ZIndex=84;t.Parent=box;return t
        end
        local nome=texto("Nome",18);nome.Text=player.DisplayName.." (@"..player.Name..")"
        local distancia=texto("Distancia",16);distancia.Position=UDim2.new(0,-50,1,4)
        local saude=frame("VidaFundo",box);saude.BackgroundTransparency=0;saude.BackgroundColor3=Color3.fromRGB(8,12,18)
        saude.Position=UDim2.fromOffset(-6,0);saude.Size=UDim2.new(0,3,1,0);saude.ZIndex=82
        local barra=frame("Vida",saude);barra.BackgroundTransparency=0;barra.BackgroundColor3=Color3.fromRGB(80,240,130)
        barra.AnchorPoint=Vector2.new(0,1);barra.Position=UDim2.fromScale(0,1);barra.Size=UDim2.fromScale(1,1);barra.ZIndex=83
        local linha=frame("Linha",pasta);linha.BackgroundTransparency=0.25;linha.BackgroundColor3=cor;linha.AnchorPoint=Vector2.new(0.5,0.5);linha.ZIndex=80
        local seta=GS.novaInstancia("TextLabel");seta.Name="ForaDaTela";seta.Size=UDim2.fromOffset(22,22)
        seta.AnchorPoint=Vector2.new(0.5,0.5);seta.BackgroundTransparency=1;seta.Text="▲";seta.TextSize=19
        seta.TextColor3=cor;seta.TextStrokeTransparency=0.1;seta.ZIndex=83;seta.Parent=pasta
        box.Visible=false;linha.Visible=false;seta.Visible=false
        r.visual=pasta;r.ui={box=box,stroke=stroke,distancia=distancia,barra=barra,linha=linha,seta=seta}
        r.proximoTamanho=0;r.tamanho=Vector3.new(4,6,3)
    end
    function V.atualizarBoxes()
        if not V.box or not V.vivo then return end
        local camera=workspace.CurrentCamera
        if not camera then return end
        local viewport=camera.ViewportSize
        if viewport.X<1 or viewport.Y<1 then return end
        local minhaRaiz=V.raizPersonagem(jogador.Character)
        local origem=minhaRaiz and minhaRaiz.Position or camera.CFrame.Position
        for player,r in pairs(V.boxPlayers) do
            local ui=r.ui
            if ui then
                ui.box.Visible=false;ui.linha.Visible=false;ui.seta.Visible=false
                local char=player.Character
                local root,hum=V.raizPersonagem(char)
                if char and root and hum and hum.Health>0 and char:IsDescendantOf(workspace) then
                    local cor=char==V.alvoFoco and Color3.fromRGB(255,200,70) or Color3.fromRGB(70,235,210)
                    local pos,visivel=camera:WorldToViewportPoint(root.Position)
                    if visivel and pos.Z>0 then
                        if os.clock()>r.proximoTamanho then
                            r.proximoTamanho=os.clock()+1
                            local ok,tam=pcall(function() return char:GetExtentsSize() end)
                            if ok then r.tamanho=Vector3.new(math.clamp(tam.X,3,8),math.clamp(tam.Y,5,10),3) end
                        end
                        local metade=camera.CFrame.UpVector*(r.tamanho.Y*0.5)
                        local topo=camera:WorldToViewportPoint(root.Position+metade)
                        local base=camera:WorldToViewportPoint(root.Position-metade)
                        local h=math.clamp(math.abs(base.Y-topo.Y),6,viewport.Y*2)
                        local w=math.clamp(h*r.tamanho.X/r.tamanho.Y,4,viewport.X)
                        local x,y=pos.X-w*0.5,pos.Y-h*0.5
                        ui.box.Position=UDim2.fromOffset(x,y);ui.box.Size=UDim2.fromOffset(w,h);ui.box.Visible=true
                        ui.stroke.Color=cor;ui.linha.BackgroundColor3=cor
                        local vida=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                        ui.barra.Size=UDim2.fromScale(1,vida);ui.barra.BackgroundColor3=Color3.fromRGB(255*(1-vida),210*vida,70)
                        ui.distancia.Text=string.format("%.0f studs · %d%%",(root.Position-origem).Magnitude,math.floor(vida*100+0.5))
                        local a=Vector2.new(viewport.X*0.5,viewport.Y-35)
                        local b=Vector2.new(pos.X,math.clamp(y+h,0,viewport.Y))
                        local delta=b-a
                        ui.linha.Position=UDim2.fromOffset((a.X+b.X)*0.5,(a.Y+b.Y)*0.5)
                        ui.linha.Size=UDim2.fromOffset(delta.Magnitude,1)
                        ui.linha.Rotation=math.deg(math.atan2(delta.Y,delta.X));ui.linha.Visible=true
                    else
                        local dx,dy=pos.X-viewport.X*0.5,pos.Y-viewport.Y*0.5
                        if pos.Z<0 then dx,dy=-dx,-dy end
                        local t=math.min(math.max(1,viewport.X*0.5-28)/math.max(math.abs(dx),0.01),math.max(1,viewport.Y*0.5-50)/math.max(math.abs(dy),0.01))
                        ui.seta.Position=UDim2.fromOffset(viewport.X*0.5+dx*t,viewport.Y*0.5+dy*t)
                        ui.seta.Rotation=math.deg(math.atan2(dy,dx))+90;ui.seta.TextColor3=cor;ui.seta.Visible=true
                    end
                end
            end
        end
    end
    function V.seguirPlayer(player)
        if player==jogador or V.boxPlayers[player] then return end
        local r={};V.boxPlayers[player]=r
        r.add=GS.conectar(player.CharacterAdded,function(char) V.desenharBox(player,char) end)
        r.remove=GS.conectar(player.CharacterRemoving,function() V.limparBox(player);r.char=nil end)
        V.desenharBox(player,player.Character)
    end
    function V.removerPlayer(player)
        local r=V.boxPlayers[player]
        if not r then return end
        V.limparBox(player)
        if r.add then r.add:Disconnect() end
        if r.remove then r.remove:Disconnect() end
        V.boxPlayers[player]=nil
    end
    function V.boxes(ativo)
        if V.box==ativo then return end
        V.box=ativo
        if ativo then
            V.boxFolder=GS.novaInstancia("Frame");V.boxFolder.Name="ValeRushESP"
            V.boxFolder.BackgroundTransparency=1;V.boxFolder.Size=UDim2.fromScale(1,1);V.boxFolder.Parent=ScreenGui
            V.playerAdd=GS.conectar(Players.PlayerAdded,V.seguirPlayer)
            V.playerRemove=GS.conectar(Players.PlayerRemoving,V.removerPlayer)
            for _,p in ipairs(Players:GetPlayers()) do V.seguirPlayer(p) end
            local tempo=0
            GS.bindRender(Run,"GringoValeRushESP",Enum.RenderPriority.Last.Value+2,function(dt)
                tempo=tempo+dt;if tempo<1/40 then return end;tempo=0
                local ok,erro=pcall(V.atualizarBoxes)
                if not ok and os.clock()>(V.proximoErroESP or 0) then
                    V.proximoErroESP=os.clock()+5;warn("[DEBUG-BOT]: ESP:",erro)
                end
            end)
        else
            Run:UnbindFromRenderStep("GringoValeRushESP")
            if GS.recursos then GS.recursos.renders.GringoValeRushESP=nil end
            if V.playerAdd then V.playerAdd:Disconnect();V.playerAdd=nil end
            if V.playerRemove then V.playerRemove:Disconnect();V.playerRemove=nil end
            local lista={};for p in pairs(V.boxPlayers) do table.insert(lista,p) end
            for _,p in ipairs(lista) do V.removerPlayer(p) end
            if V.boxFolder then V.boxFolder:Destroy();V.boxFolder=nil end
        end
        boxBtn.Text=ativo and "ESP PROFISSIONAL: ON" or "ESP PROFISSIONAL: OFF"
    end

    function V.otimizar(ativo)
        if V.busy or V.leve==ativo then return end
        V.leve=ativo
        V.epoch=V.epoch+1
        for _,c in ipairs(V.conns) do c:Disconnect() end
        V.conns={}
        V.fila={}; V.head=1
        V.pendentes=setmetatable({}, {__mode="k"})
        if not ativo then
            V.velocidade(false)
            local salvos=V.salvos
            V.salvos=setmetatable({}, {__mode="k"})
            V.busy=true
            leveBtn.Text="MAPA LEVE: RESTAURANDO..."
            GS.spawn(function()
                local n=0
                for obj,props in pairs(salvos) do
                    for prop,r in pairs(props) do
                        pcall(function()
                            -- Respeita alteracoes feitas por outro controle apos este modo.
                            if obj[prop]==r.aplicado then obj[prop]=r.original end
                        end)
                    end
                    n=n+1
                    if n%100==0 then task.wait() end
                end
                V.busy=false; V.mudancas=0
                if V.vivo then leveBtn.Text="MAPA LEVE: OFF" end
                print("[DEBUG-BOT]: Vale Rush: visual restaurado")
            end)
            return
        end
        leveBtn.Text="MAPA LEVE INTENSO: ON · VEL 31"
        if speedAtivado then
            V.speedAnterior=velocidadeCustomizada
            velocidadeCustomizada=31
            if SpeedLabel then SpeedLabel.Text="VEL: 31" end
        end
        V.velocidade(true)
        V.mudancas=0
        V.alterar(Lighting,"GlobalShadows",false)
        pcall(function()
            local graficos=UserSettings():GetService("UserGameSettings")
            V.alterar(graficos,"SavedQualityLevel",Enum.SavedQualitySetting.QualityLevel1)
        end)
        local terreno=workspace:FindFirstChildOfClass("Terrain")
        if terreno then
            V.alterar(terreno,"Decoration",false)
            V.alterar(terreno,"WaterWaveSize",0)
            V.alterar(terreno,"WaterWaveSpeed",0)
            V.alterar(terreno,"WaterReflectance",0)
        end
        table.insert(V.conns,GS.conectar(workspace.DescendantAdded,V.enfileirar))
        table.insert(V.conns,GS.conectar(Lighting.DescendantAdded,V.enfileirar))
        local epoch=V.epoch
        GS.spawn(function()
            for _,raiz in ipairs({workspace,Lighting}) do
                for i,obj in ipairs(raiz:GetDescendants()) do
                    if not V.leve or V.epoch~=epoch or not V.vivo then return end
                    V.enfileirar(obj)
                    if i%500==0 then task.wait() end
                end
            end
            while V.leve and V.vivo and V.epoch==epoch do
                local inicio,feitos=os.clock(),0
                while V.head<=#V.fila and feitos<100 do
                    local obj=V.fila[V.head]
                    V.pendentes[obj]=nil
                    local ok,erro=pcall(V.aplicar,obj)
                    if not ok then warn("[DEBUG-BOT]: Vale Rush:",erro) end
                    V.head=V.head+1; feitos=feitos+1
                    if os.clock()-inicio>=0.002 then break end
                end
                if V.head>#V.fila then
                    V.fila={}; V.head=1
                    task.wait(0.1)
                else
                    task.wait()
                end
            end
        end)
        print("[DEBUG-BOT]: Vale Rush: otimizacao visual ativa")
    end

    V.focoAtivo=false
    V.alvoFoco=nil
    V.focoCameras=setmetatable({}, {__mode="k"})
    local entrada=game:GetService("UserInputService")
    local mouse=jogador:GetMouse()
    local nomeRender="GringoValeRushFoco"

    function V.raizPersonagem(char)
        if not char then return nil end
        local hum=char:FindFirstChildOfClass("Humanoid")
        local raiz=char:FindFirstChild("HumanoidRootPart") or (hum and hum.RootPart)
            or char.PrimaryPart or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
        if raiz and raiz:IsA("BasePart") then return raiz,hum end
    end
    function V.personagemClicado(parte)
        local atual=parte
        while atual and atual~=workspace do
            if atual:IsA("Model") and atual~=jogador.Character then
                local root,hum=V.raizPersonagem(atual)
                if root and hum and hum.Health>0 then return atual end
            end
            atual=atual.Parent
        end
    end
    function V.proximoCursor()
        local camera=workspace.CurrentCamera
        if not camera then return nil end
        local cursor=entrada:GetMouseLocation()
        local melhor,menor=nil,220*220
        for _,p in ipairs(Players:GetPlayers()) do
            local char=p.Character
            local root,hum=V.raizPersonagem(char)
            if p~=jogador and char and root and hum and hum.Health>0 and char:IsDescendantOf(workspace) then
                local tela,visivel=camera:WorldToScreenPoint(root.Position)
                if visivel and tela.Z>0 then
                    local dx,dy=tela.X-cursor.X,tela.Y-cursor.Y
                    local d=dx*dx+dy*dy
                    if d<menor then menor=d; melhor=char end
                end
            end
        end
        return melhor
    end
    function V.limparFoco()
        V.alvoFoco=nil
        V.ultimaRaizFoco=nil
        Run:UnbindFromRenderStep(nomeRender)
        if GS.recursos then GS.recursos.renders[nomeRender]=nil end
        for camera,r in pairs(V.focoCameras) do
            pcall(function()
                if camera.CameraType==Enum.CameraType.Scriptable then camera.CameraType=r.tipo end
                if camera.Focus==r.aplicado then camera.Focus=r.original end
            end)
        end
        V.focoCameras=setmetatable({}, {__mode="k"})
        focoStatus.Text=V.focoAtivo and "Botão do meio perto de alguém: focar · mesmo alvo: soltar" or "FOCO: DESLIGADO"
    end
    function V.passoFoco()
        if not V.vivo or not V.focoAtivo or GS.fechando then V.limparFoco(); return end
        local char=V.alvoFoco
        local root,hum=V.raizPersonagem(char)
        if not char or char==jogador.Character or not char:IsDescendantOf(workspace)
            or not hum or hum.Health<=0 or not root then V.limparFoco(); return end
        local camera=workspace.CurrentCamera
        if not camera then return end
        if not V.focoCameras[camera] then
            V.focoCameras[camera]={original=camera.Focus,tipo=camera.CameraType}
        end
        local minhaRaiz=V.raizPersonagem(jogador.Character)
        local pos=minhaRaiz and minhaRaiz.Position
        local delta=(pos and V.ultimaRaizFoco) and pos-V.ultimaRaizFoco or Vector3.zero
        V.ultimaRaizFoco=pos
        local head=char:FindFirstChild("Head")
        local ponto=(head and head:IsA("BasePart")) and head.Position or root.Position
        local origem=camera.CFrame.Position+delta
        if (ponto-origem).Magnitude<0.1 then return end
        camera.CameraType=Enum.CameraType.Scriptable
        local foco=CFrame.new(ponto)
        V.focoCameras[camera].aplicado=foco
        camera.CFrame=CFrame.lookAt(origem,ponto)
        camera.Focus=foco
    end
    function V.selecionarFoco(char)
        if not V.focoAtivo or not V.vivo then return end
        if not char or char==V.alvoFoco then V.limparFoco(); return end
        V.limparFoco()
        V.alvoFoco=char
        focoStatus.Text="FOCADO: "..char.Name.." · meio em outro para trocar"
        GS.bindRender(Run,nomeRender,Enum.RenderPriority.Last.Value+1,function()
            local ok,erro=pcall(V.passoFoco)
            if not ok then warn("[DEBUG-BOT]: Foco:",erro); V.limparFoco() end
        end)
        V.passoFoco()
        print("[DEBUG-BOT]: Vale Rush: foco travado",char.Name)
    end
    function V.focar(ativo)
        V.focoAtivo=ativo
        V.limparFoco()
        if V.focoEntrada then V.focoEntrada:Disconnect(); V.focoEntrada=nil end
        if ativo then
            V.focoEntrada=GS.conectar(entrada.InputBegan,function(input)
                if input.UserInputType~=Enum.UserInputType.MouseButton3 or entrada:GetFocusedTextBox() then return end
                -- MouseButton3 pode chegar marcado como processado pelo controle da camera.
                V.selecionarFoco(V.personagemClicado(mouse.Target) or V.proximoCursor())
            end)
        end
        focoBtn.Text=ativo and "FOCAR COM BOTÃO DO MEIO: ON" or "FOCAR COM BOTÃO DO MEIO: OFF"
    end
    GS.conectar(focoBtn.MouseButton1Click,function() V.focar(not V.focoAtivo) end)
    GS.conectar(desfocarBtn.MouseButton1Click,V.limparFoco)

    function V.ligarCamera()
        if V.fovConn then V.fovConn:Disconnect(); V.fovConn=nil end
        local camera=workspace.CurrentCamera
        if not V.camera or not camera then return end
        if not V.cameras[camera] then V.cameras[camera]={original=camera.FieldOfView} end
        V.cameras[camera].aplicado=V.fov
        camera.FieldOfView=V.fov
        V.fovConn=GS.conectar(camera:GetPropertyChangedSignal("FieldOfView"),function()
            if V.camera and camera.FieldOfView~=V.fov then camera.FieldOfView=V.fov end
        end)
    end
    function V.visao(ativo)
        V.camera=ativo
        if ativo then
            V.ligarCamera()
        else
            if V.fovConn then V.fovConn:Disconnect(); V.fovConn=nil end
            for camera,r in pairs(V.cameras) do
                pcall(function() if camera.FieldOfView==r.aplicado then camera.FieldOfView=r.original end end)
            end
            V.cameras=setmetatable({}, {__mode="k"})
        end
        cameraBtn.Text=ativo and "VISÃO AMPLIADA: ON" or "VISÃO AMPLIADA: OFF"
    end
    function V.ajustar(delta)
        V.fov=math.clamp(V.fov+delta,70,110)
        fovLabel.Text=tostring(V.fov)
        if V.camera then V.ligarCamera() end
    end
    GS.conectar(cameraBtn.MouseButton1Click,function() V.visao(not V.camera) end)
    GS.conectar(menos.MouseButton1Click,function() V.ajustar(-5) end)
    GS.conectar(mais.MouseButton1Click,function() V.ajustar(5) end)
    GS.conectar(leveBtn.MouseButton1Click,function() V.otimizar(not V.leve) end)
    GS.conectar(boxBtn.MouseButton1Click,function() V.boxes(not V.box) end)
    GS.conectar(restaurarBtn.MouseButton1Click,function() V.visao(false); V.otimizar(false); V.boxes(false); V.focar(false) end)
    local cameraConn=GS.conectar(workspace:GetPropertyChangedSignal("CurrentCamera"),function()
        V.ligarCamera()
        if V.leve and workspace.CurrentCamera then
            for _,obj in ipairs(workspace.CurrentCamera:GetDescendants()) do V.enfileirar(obj) end
        end
    end)
    local tempo,frames=0,0
    local fpsConn=GS.conectar(Run.RenderStepped,function(dt)
        tempo=tempo+dt; frames=frames+1
        if tempo>=0.5 then
            if V.leve then V.velocidade(true) end
            contador.Text=string.format("FPS: %.0f · Alterações visuais: %d",frames/tempo,V.mudancas)
            tempo=0; frames=0
        end
    end)
    GS.conectar(ScreenGui.Destroying,function()
        V.focar(false)
        V.vivo=false
        cameraConn:Disconnect(); fpsConn:Disconnect()
        V.visao(false)
        V.otimizar(false)
        V.boxes(false)
    end)
    GS.valeRush=V
    print("[DEBUG-BOT]: Vale Rush: painel pronto")
end
GS.rodar("Vale Rush",GS.iniciarValeRush,GS.painelValeRush)

GS.prepararTelaFarma = function()
    local U,painel=GS.ui,GS.painelFarma
    if not U or not painel then return end
    local layout=painel:FindFirstChildOfClass("UIListLayout")
    if layout then layout.Padding=UDim.new(0,6) end
    local barra=GS.novaInstancia("Frame")
    barra.Name="ModosFarma"
    barra.Size=UDim2.new(1,0,0,36)
    barra.LayoutOrder=-1
    barra.BackgroundTransparency=1
    barra.Parent=painel
    local botoes,telas={},{}
    local nomes={"Frascos","Lucky Blocks","Por nome","Tesouro"}
    local function selecionar(indice)
        for i,tela in ipairs(telas) do
            tela.Visible=i==indice
            botoes[i].BackgroundTransparency=i==indice and 0.2 or 0.8
            botoes[i].TextColor3=i==indice and U.T.onText or U.T.mute
        end
        local scroll=painel.Parent
        if scroll and scroll:IsA("ScrollingFrame") then scroll.CanvasPosition=Vector2.zero end
    end
    for i,nome in ipairs(nomes) do
        local tela=GS.novaInstancia("Frame")
        tela.Name="Farma"..i
        tela.BackgroundTransparency=1
        tela.Size=UDim2.new(1,0,0,0)
        tela.AutomaticSize=Enum.AutomaticSize.Y
        tela.LayoutOrder=i
        tela.Parent=painel
        local lista=GS.novaInstancia("UIListLayout",tela)
        lista.Padding=UDim.new(0,6)
        lista.SortOrder=Enum.SortOrder.LayoutOrder
        local botao=GS.novaInstancia("TextButton")
        botao.Size=UDim2.new(1/#nomes,-4,1,0)
        botao.Position=UDim2.new((i-1)/#nomes,2,0,0)
        botao.BackgroundColor3=U.T.on
        botao.BorderSizePixel=0
        botao.Font=Enum.Font.GothamBold
        botao.TextSize=13
        botao.Text=nome
        botao.Parent=barra
        U.mkC(10,botao)
        telas[i]=tela
        botoes[i]=botao
        GS.conectar(botao.MouseButton1Click,function() selecionar(i) end)
    end
    GS.painelFarmaFrascos=telas[1]
    GS.painelFarmaLucky=telas[2]
    GS.painelFarmaNome=telas[3]
    GS.painelFarmaTesouro=telas[4]
    selecionar(1)
end
GS.rodar("Layout Farma",GS.prepararTelaFarma,GS.painelFarma)
GS.iniciarNoclipArquivo = function()
    local guiPainel=ScreenGui
    local ModuloAtivo=true
    local Conexoes={}
    local CapturarPersonagem
    -- Conteudo de s.lua; as conexoes e o loop recebem controle de ciclo de vida.
--[[ 
    NOCLIP SYSTEM (ATRAVESSAR PAREDES)
    Funcionalidades:
    - Desativa colisões do personagem
    - Painel de controle simples (GUI)
    - Toggle via Tecla K
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Settings = {
    Enabled = false,
    AntiVoid = true,
    VoidY = -100,
    RecoveryOffset = Vector3.new(0, 5, 0),
    ToggleKey = Enum.KeyCode.K
}

local LastSafeCFrame

-- Criação do Painel Simples
local ScreenGui = GS.novaInstancia("ScreenGui")
local MainFrame = GS.novaInstancia("Frame")
local ToggleButton = GS.novaInstancia("TextButton")

ScreenGui.Name = "NoclipPanel"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
MainFrame.Size = UDim2.new(0, 150, 0, 50)
MainFrame.Active = true
MainFrame.Draggable = true

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = MainFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleButton.Position = UDim2.new(0.1, 0, 0.2, 0)
ToggleButton.Size = UDim2.new(0.8, 0, 0.6, 0)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Noclip: OFF"
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.TextSize = 18

local function UpdateUI()
    ToggleButton.Text = "Noclip: " .. (Settings.Enabled and "ON" or "OFF")
    ToggleButton.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
end

local function ToggleNoclip()
    Settings.Enabled = not Settings.Enabled
    UpdateUI()
end

local function GetRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function SaveSafePosition(character)
    local root = GetRoot(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return end

    if root.Position.Y > Settings.VoidY + 20 then
        LastSafeCFrame = root.CFrame
    end
end

local function RecoverFromVoid(character)
    if not Settings.AntiVoid then return end

    local root = GetRoot(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return end

    if root.Position.Y <= Settings.VoidY then
        if LastSafeCFrame then
            root.CFrame = LastSafeCFrame + Settings.RecoveryOffset
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            warn("[DEBUG-BOT]: Void recovery activated")
        else
            warn("[DEBUG-BOT]: No safe position available for recovery")
        end
    end
end

local function ApplyNoCollision(character)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function BindCharacter(character)
    LastSafeCFrame = nil
    if CapturarPersonagem then CapturarPersonagem(character) end
    print("[DEBUG-BOT]: Character bound")

    GS.spawn(function()
        while ModuloAtivo and character.Parent and LocalPlayer.Character == character do
            SaveSafePosition(character)
            RecoverFromVoid(character)

            if Settings.Enabled then
                ApplyNoCollision(character)
            end

            task.wait(0.05)
        end
    end)
end

table.insert(Conexoes, GS.conectar(ToggleButton.MouseButton1Click,ToggleNoclip))

local conexaoTecla = GS.conectar(UserInputService.InputBegan,function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.ToggleKey then
        ToggleNoclip()
    end
end)

if LocalPlayer.Character then
    BindCharacter(LocalPlayer.Character)
end

table.insert(Conexoes, GS.conectar(LocalPlayer.CharacterAdded,BindCharacter))

print("[DEBUG-BOT]: Anti-void controller active")
    table.insert(Conexoes,conexaoTecla)
    local donos={}
    local anteriores=setmetatable({}, {__mode="k"})
    local observados=setmetatable({}, {__mode="k"})
    local eraManual=false
    local function guardarParte(obj)
        if obj:IsA("BasePart") and anteriores[obj]==nil then anteriores[obj]=obj.CanCollide end
    end
    local function guardarPersonagem(char)
        for _,obj in ipairs(char:GetDescendants()) do guardarParte(obj) end
        if observados[char] then return end
        observados[char]=true
        table.insert(Conexoes,GS.conectar(char.DescendantAdded,function(obj)
            if next(donos) then guardarParte(obj) end
        end))
    end
    CapturarPersonagem=function(char)
        if next(donos) then guardarPersonagem(char) end
    end
    local function restaurarColisoes()
        if Settings.Enabled or noclipAtivado then return end
        for obj,valor in pairs(anteriores) do
            if obj.Parent then obj.CanCollide=valor end
        end
        table.clear(anteriores)
    end
    GS.noclipArquivo={
        ativar=function(dono)
            if not ModuloAtivo or donos[dono] then return end
            if not next(donos) then
                eraManual=Settings.Enabled
                table.clear(anteriores)
                if LocalPlayer.Character then guardarPersonagem(LocalPlayer.Character) end
            end
            donos[dono]=true
            Settings.Enabled=true
            UpdateUI()
            print("[DEBUG-BOT]: Noclip do arquivo ativado pela farma",dono)
        end,
        liberar=function(dono)
            if not donos[dono] then return end
            donos[dono]=nil
            if not next(donos) then
                Settings.Enabled=eraManual
                UpdateUI()
                restaurarColisoes()
            end
        end,
    }
    table.insert(Conexoes,GS.conectar(LocalPlayer.CharacterAdded,function(char)
        if next(donos) then guardarPersonagem(char) end
    end))
    -- Reaproveita o mesmo botao do arquivo dentro da tela Farma.
    MainFrame.Parent=GS.painelFarma
    MainFrame.LayoutOrder=-0.5
    MainFrame.Draggable=false
    -- O controle importado recebe o mesmo material; seu comportamento permanece.
    MainFrame.Size=UDim2.new(1,0,0,44)
    MainFrame.BackgroundColor3=GS.ui.T.vidro
    MainFrame.BackgroundTransparency=0.34
    GS.ui.mkC(12,MainFrame)
    GS.ui.mkS(1,GS.ui.T.stroke,MainFrame,0.48)
    ToggleButton.Size=UDim2.fromOffset(146,30)
    ToggleButton.Position=UDim2.new(1,-158,0.5,-15)
    ToggleButton.Font=Enum.Font.GothamBold
    ToggleButton.TextSize=12
    GS.ui.mkC(9,ToggleButton)
    local legenda=GS.novaInstancia("TextLabel",MainFrame)
    legenda.Size=UDim2.new(1,-180,1,0)
    legenda.Position=UDim2.fromOffset(14,0)
    legenda.BackgroundTransparency=1
    legenda.Font=Enum.Font.GothamMedium
    legenda.TextSize=13
    legenda.TextColor3=GS.ui.T.text
    legenda.TextXAlignment=Enum.TextXAlignment.Left
    legenda.Text="Atravessar obstáculos · tecla K"
    local atualizarOriginal=UpdateUI
    UpdateUI=function()
        atualizarOriginal()
        ToggleButton.BackgroundColor3=Settings.Enabled and GS.ui.T.on or GS.ui.T.ctrl
        ToggleButton.BackgroundTransparency=Settings.Enabled and 0.08 or 0.20
        ToggleButton.TextColor3=Settings.Enabled and GS.ui.T.onText or GS.ui.T.text
    end
    UpdateUI()
    ScreenGui:Destroy()
    GS.conectar(guiPainel.Destroying,function()
        ModuloAtivo=false
        Settings.Enabled=false
        Settings.AntiVoid=false
        for _,conn in ipairs(Conexoes) do conn:Disconnect() end
        table.clear(donos)
        restaurarColisoes()
        GS.noclipArquivo=nil
    end)
end
GS.rodar("Noclip s.lua",GS.iniciarNoclipArquivo,GS.painelFarma)


GS.iniciarFarma = function()
    local U = GS.ui
    local painel = GS.painelFarmaFrascos or GS.painelFarma
    if not U or not painel then return end

    -- Configuracao exclusiva dos frascos; nenhum filtro por cor ou brilho.
    local CFG = {
        nome = "PotionTemplate",
        voo = 500,
        caminhada = 16,
        aproxima = 12,
        toque = 4,
        alcance = 8,
        limiteVoo = 20,
        limiteColeta = 18,
        pausaErro = 12,
        correlacao = 8,
        intervaloScan = 2,
        intervaloUI = 0.15,
        maxHistorico = 60,
        maxMarcadores = 10,
    }
    local PathfindingService = game:GetService("PathfindingService")
    local R = {
        monitor = false,
        auto = false,
        geracao = 0,
        cicloAuto = 0,
        itens = {},
        conns = {},
        log = {},
        pendentes = {},
        vistos = setmetatable({}, {__mode="k"}),
        personagens = setmetatable({}, {__mode="k"}),
        ferramentas = setmetatable({}, {__mode="k"}),
        alvo = nil,
        gui = nil,
        sujo = true,
        inicial = true,
        fase = "DESLIGADO",
        nascimentos = 0,
        carregados = 0,
        coletados = 0,
        retirados = 0,
        perto = 0,
        depois = 0,
        ultimaColeta = -math.huge,
        ultimaPos = nil,
        movimento = 0,
        salvo = nil,
        destruindo = false,
    }

    -- Controles e diagnostico visivel no painel.
    U.sec(painel, "FARMA · FRASCOS V5 · AUTO ADAPTATIVO", "package", 1)
    local monitorBtn = U.tog(painel, "DETECTAR E MOSTRAR FRASCOS", 2)
    monitorBtn:SetAttribute("Controlado", true)
    monitorBtn.Text = "DETECÇÃO: OFF"
    local autoBtn = U.tog(painel, "AUTOMÁTICO · MODO LIVRE 500", 3)
    autoBtn:SetAttribute("Controlado", true)
    autoBtn.Text = "AUTOMÁTICO: OFF"
    local status = U.pequeno(painel, "DESLIGADO", nil, 4, "radar")
    status.AutoButtonColor = false

    local function texto(nome, altura, ordem)
        local label = GS.novaInstancia("TextLabel")
        label.Name = nome
        label.Size = UDim2.new(1,-16,0,altura)
        label.LayoutOrder = ordem
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextColor3 = U.T.text
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.Parent = painel
        return label
    end

    local resumo = texto("ResumoFarma", 60, 5)
    local locais = texto("LocaisFarma", 76, 6)
    local historico = texto("HistoricoFarma", 140, 7)
    historico.Visible=false
    local detalhes=U.pequeno(painel,"MOSTRAR HISTÓRICO",nil,6.5,"info")
    GS.conectar(detalhes.MouseButton1Click,function()
        historico.Visible=not historico.Visible
        detalhes.Text=historico.Visible and "OCULTAR HISTÓRICO" or "MOSTRAR HISTÓRICO"
    end)
    resumo.Text = "Um automático: patrulha, voo 500, chegada por cima, laterais e pulos."
    locais.Text = "Filtro exclusivo: PotionTemplate."
    historico.Text = "Histórico: aguardando ativação."

    local function registrar(tipo, mensagem)
        local linha = string.format("[%s] %s · %s", os.date("%H:%M:%S"), tipo, mensagem)
        table.insert(R.log,1,linha)
        while #R.log > CFG.maxHistorico do table.remove(R.log) end
        print("[DEBUG-BOT]: " .. linha)
    end

    local function personagem()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then return end
        return char,hum,root
    end

    local function parte(obj)
        if obj:IsA("BasePart") then return obj end
        if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
        if obj:IsA("Tool") then
            local handle = obj:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then return handle end
        end
        return obj:FindFirstChildWhichIsA("BasePart",true)
    end

    local function dePersonagem(obj)
        local pai = obj
        while pai and pai ~= workspace do
            if pai:IsA("Model") and pai:FindFirstChildOfClass("Humanoid") then return true end
            pai = pai.Parent
        end
        return false
    end

    local function avaliar(obj)
        if obj.Name ~= CFG.nome then return end
        if not (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Tool")) then return end
        if not obj:IsDescendantOf(workspace) or dePersonagem(obj) then return end
        local alvo = obj
        local pai = obj.Parent
        while pai and pai ~= workspace do
            if pai.Name == CFG.nome and (pai:IsA("Model") or pai:IsA("Tool")) then alvo = pai end
            pai = pai.Parent
        end
        local p = parte(alvo)
        if not p then return end
        return alvo,p
    end

    local function mesmoCiclo(g)
        return R.monitor and R.geracao == g and not R.destruindo
    end

    local function autoVivo(g,a)
        return mesmoCiclo(g) and R.auto and R.cicloAuto == a
    end

    local function valido(obj)
        return obj and obj.Name == CFG.nome and obj:IsDescendantOf(workspace)
            and not dePersonagem(obj)
    end

    local function marcar(obj,p)
        local gui = GS.novaInstancia("BillboardGui")
        gui.Name = "FarmaFrascoV4"
        gui.Adornee = p
        gui.Size = UDim2.fromOffset(168,36)
        gui.StudsOffsetWorldSpace = Vector3.new(0,2.5,0)
        gui.AlwaysOnTop = true
        gui.MaxDistance = 0
        gui.LightInfluence = 0
        gui.Enabled = false
        gui.Parent = R.gui
        local label = GS.novaInstancia("TextLabel")
        label.Size = UDim2.fromScale(1,1)
        label.BackgroundColor3 = Color3.fromRGB(4,24,18)
        label.BackgroundTransparency = 0.18
        label.TextColor3 = U.T.strokeHi
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextWrapped = true
        label.Parent = gui
        GS.novaInstancia("UICorner",label).CornerRadius = UDim.new(0,8)
        return gui,label
    end

    local function adicionar(obj,inicial)
        local alvo,p = avaliar(obj)
        if not alvo or R.itens[alvo] then return end
        for outro,it in pairs(R.itens) do
            if outro:IsDescendantOf(alvo) then
                it.gui:Destroy()
                R.itens[outro] = nil
            elseif alvo:IsDescendantOf(outro) then
                return
            end
        end
        local gui,label = marcar(alvo,p)
        R.itens[alvo] = {
            parte=p, gui=gui, label=label,
            pos=p.Position, distancia=math.huge,
            tentarEm=0, detectado=os.clock(),
        }
        local conhecido = R.vistos[alvo]
        R.vistos[alvo] = true
        if conhecido then return end
        local _,_,root = personagem()
        local distancia = root and (root.Position-p.Position).Magnitude or 0
        if inicial then
            R.carregados = R.carregados+1
            return
        end
        R.nascimentos = R.nascimentos+1
        local detalhe = string.format("%s a %.0f studs",alvo.Name,distancia)
        if workspace.StreamingEnabled then detalhe = detalhe .. " (spawn ou carregamento)" end
        registrar("APARECEU",detalhe)
        if os.clock()-R.ultimaColeta <= CFG.correlacao then
            R.depois = R.depois+1
            registrar("OBSERVAÇÃO","Apareceu até " .. CFG.correlacao .. "s após coleta; relação não confirmada.")
        end
        if R.movimento > 0.5 and distancia < 100 then
            R.perto = R.perto+1
            registrar("OBSERVAÇÃO","Detectado durante deslocamento perto do personagem.")
        end
    end

    local function inventario(obj)
        if not obj:IsA("Tool") or obj.Name ~= CFG.nome then return end
        if R.ferramentas[obj] then return end
        R.ferramentas[obj] = true
        R.coletados = R.coletados+1
        R.ultimaColeta = os.clock()
        registrar("COLETA CONFIRMADA","PotionTemplate recebido no inventário.")
    end

    local function ligarInventario(char)
        if R.personagens[char] then return end
        R.personagens[char] = true
        -- Ferramentas existentes sao base inicial, nao uma nova coleta.
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") then R.ferramentas[obj] = true end
        end
        table.insert(R.conns,GS.conectar(char.ChildAdded,inventario))
    end

    local function retirar(obj,it)
        if it.gui then it.gui:Destroy() end
        R.itens[obj] = nil
        R.retirados = R.retirados+1
        if obj == R.alvo then
            registrar("ALVO RETIRADO","Saiu do mapa; aguardando confirmação no inventário.")
        end
    end

    local function examinar(obj,g,inicial)
        if not mesmoCiclo(g) then return end
        local atual = obj
        while atual and atual ~= workspace do
            if atual.Name == CFG.nome then adicionar(atual,inicial); return end
            atual = atual.Parent
        end
    end

    local function varrer(g)
        R.sujo = false
        local inicial = R.inicial
        for i,obj in ipairs(workspace:GetDescendants()) do
            if not mesmoCiclo(g) then return end
            if R.observarMapa then R.observarMapa(obj) end
            if obj.Name == CFG.nome then adicionar(obj,inicial) end
            if i % 300 == 0 then task.wait() end
        end
        if mesmoCiclo(g) and inicial then
            R.inicial = false
            registrar("VARREDURA",R.carregados .. " frascos já carregados; não contam como spawn novo.")
        end
    end

    local function listar(root)
        local achados = {}
        for obj,it in pairs(R.itens) do
            if not valido(obj) then
                retirar(obj,it)
            else
                local p = parte(obj)
                if p and p:IsDescendantOf(workspace) then
                    it.parte = p
                    it.pos = p.Position
                    it.gui.Adornee = p
                    it.distancia = (root.Position-it.pos).Magnitude
                    table.insert(achados,{obj=obj,it=it})
                else
                    it.gui.Enabled = false
                end
            end
        end
        table.sort(achados,function(a,b) return a.it.distancia < b.it.distancia end)
        return achados
    end

    local function desenhar(achados)
        local camera = workspace.CurrentCamera
        local ocupados = {}
        local linhas = {}
        for i,e in ipairs(achados) do
            local it = e.it
            it.label.Text = string.format("FRASCO · %.0f studs",it.distancia)
            local mostrar = false
            if camera and #ocupados < CFG.maxMarcadores then
                local tela,visivel = camera:WorldToViewportPoint(it.pos+Vector3.new(0,2.5,0))
                if visivel and tela.Z > 0 then
                    mostrar = true
                    for _,usado in ipairs(ocupados) do
                        if math.abs(tela.X-usado.X)<178 and math.abs(tela.Y-usado.Y)<42 then
                            mostrar = false
                            break
                        end
                    end
                    if mostrar then table.insert(ocupados,tela) end
                end
            end
            it.gui.Enabled = mostrar
            if i <= 3 then
                linhas[i] = string.format("%d. %.0f studs · X %.0f Y %.0f Z %.0f",
                    i,it.distancia,it.pos.X,it.pos.Y,it.pos.Z)
            end
        end
        locais.Text = #linhas>0 and table.concat(linhas,"\n") or "Nenhum PotionTemplate carregado."
    end

    local function atualizarResumo(total)
        status.Text = "V50.20 · " .. R.fase .. " · LOCALIZADOS: " .. total
        local limite = workspace.StreamingEnabled
            and "Streaming ativo: aparição no cliente não prova spawn no servidor."
            or "Streaming desligado: novas aparições são observações locais."
        resumo.Text = string.format(
            "Iniciais: %d | Aparições: %d | Recebidos: %d | Retirados: %d\nApós coleta: %d | Durante movimento: %d\n%s",
            R.carregados,R.nascimentos,R.coletados,R.retirados,R.depois,R.perto,
            limite .. " | " .. (R.atividadeTexto or "Atividade: OFF"))
        local linhas = {}
        for i=1,math.min(6,#R.log) do linhas[i] = R.log[i] end
        historico.Text = table.concat(linhas,"\n")
    end

    local function salvarMovimento()
        if R.salvo then return end
        local _,hum = personagem()
        R.salvo = {
            fly=flyAtivado, velocidadeVoo=velocidadeVoo,
            speed=speedAtivado, velocidade=velocidadeCustomizada,
            caminhada=hum and hum.WalkSpeed or 16,
        }
        if speedAtivado then alternarSpeed() end
        velocidadeVoo = CFG.voo
        if FlyLabel then FlyLabel.Text = "VOO: " .. CFG.voo end
    end

    local function setVoo(ativo)
        GS.farmaDirecao = nil
        if GS.noclipArquivo then
            if ativo then GS.noclipArquivo.ativar("frascos")
            else GS.noclipArquivo.liberar("frascos") end
        end
        if not ativo then
            local _,_,root = personagem()
            if root then root.AssemblyLinearVelocity = Vector3.zero end
        end
        if flyAtivado ~= ativo then alternarFly() end
        if ativo then
            velocidadeVoo = CFG.voo
            if FlyLabel then FlyLabel.Text = "VOO: " .. CFG.voo end
            GS.farmaDirecao = Vector3.zero
        end
    end

    local function restaurarMovimento()
        GS.farmaDirecao = nil
        local salvo = R.salvo
        if not salvo then return end
        if flyAtivado then alternarFly() end
        velocidadeVoo = salvo.velocidadeVoo
        velocidadeCustomizada = salvo.velocidade
        if FlyLabel then FlyLabel.Text = "VOO: " .. velocidadeVoo end
        if SpeedLabel then SpeedLabel.Text = "VEL: " .. velocidadeCustomizada end
        if speedAtivado ~= salvo.speed then alternarSpeed() end
        if salvo.fly then alternarFly() end
        local _,hum,root = personagem()
        if hum then
            hum.WalkSpeed = salvo.caminhada
            hum:MoveTo(root.Position)
        end
        R.salvo = nil
    end

    -- Um unico controlador decide a rota, a chegada e a patrulha.
    local Nav = {}
    Nav.cfg = {
        velocidade = 500,
        velocidadePerto = 110,
        freioSegundos = 0.08,
        intervalo = 0.02,
        saltoRapido = true,
        passoRapido = 180,
        limiteRapido = 2400,
        pausaRapida = 0.04,
        verificarRapido = 0.12,
        bloquearRapidoAte = 0,
        chegada = 1.5,
        raioVertical = 1.5,
        alturaElevada = 5,
        alturaSobrevoo = 8,
        alturaExtra = 8,
        alturaPatrulha = 18,
        distanciaPouso = 2.5,
        margemBorda = 0.6,
        raioSuporte = 5,
        raioSonda = 3,
        normalMinima = 0.48,
        limiteTrecho = 12,
        limiteAlvo = 72,
        limitePouso = 3,
        limitePe = 4,
        limitePatrulha = 5,
        semProgresso = 2.5,
        margemProgresso = 0.6,
        progressoPe = 0.2,
        distanciaReplanejar = 3,
        alturaSalto = 6,
        raioToque = 1.8,
        cooldownBase = 3,
        cooldownMaximo = 45,
        orcamentoComAlternativa = 12,
        orcamentoSozinho = 20,
        pausaConfirmacao = 0.18,
        limiteMemoria = 64,
        idadeMemoria = 180,
        raioCelula = 30,
        maxHistorico = 60,
        raioPatrulha = 90,
        maxAnel = 8,
        alturaMaxPatrulha = 180,
        setores = 12,
        tempoRevisita = 25,
        maxTentativasPatrulha = 5,
        limiteRotaPe = 8,
        recuo = 5,
        minAltura = 20,
    }
    Nav.estado = {
        ancora = nil,
        seguro = nil,
        memoria = {},
        falhas = setmetatable({}, {__mode = "k"}),
        visita = {},
        passos = 0,
        anel = 1,
        setor = 0,
        alvo = nil,
        rota = nil,
        prompt = nil,
        tokenPrompt = nil,
        voo = false,
        patrulhas = 0,
        recuperacoes = 0,
        ultimaFase = "",
        ultimoLog = 0,
        ultimaPos = nil,
        ultimoDestino = nil,
        ultimamente = {},
    }

    -- Atividade periodica limitada ao mesmo ciclo da coleta automatica.
    Nav.atividade = {
        intervalo = 2,
        media = 2,
        desvio = 0.085,
        minimo = 1.7,
        maximo = 2.3,
        gaussReserva = nil,
        ultimoPonto = nil,
        ativo = false,
        conn = nil,
        servico = nil,
        proxima = 0,
        ultimaTentativa = -math.huge,
        enviados = 0,
        erros = 0,
        seguidos = 0,
        ultimoSucesso = 0,
        proximaBusca = 0,
        avisou = false,
        token = 0,
        g = 0,
        a = 0,
    }

    function Nav.pararAtividade()
        local s = Nav.atividade
        s.ativo = false
        s.token = s.token+1
        if s.conn then
            s.conn:Disconnect()
            s.conn = nil
        end
        if s.vigiaConn then s.vigiaConn:Disconnect(); s.vigiaConn=nil end
        if Nav.liberarAtividade then Nav.liberarAtividade() end
        R.atividadeTexto = "Autoclique: OFF"
    end

    -- Box-Muller: duas uniformes geram duas amostras normais independentes.
    -- Os limites impedem rajadas acidentais e esperas excessivas.
    function Nav.intervaloAtividade()
        local s = Nav.atividade
        local z = s.gaussReserva
        if z then
            s.gaussReserva = nil
        else
            local u1 = math.max(0.0000001,math.random())
            local u2 = math.random()
            local raio = math.sqrt(-2*math.log(u1))
            local angulo = 2*math.pi*u2
            z = raio*math.cos(angulo)
            s.gaussReserva = raio*math.sin(angulo)
        end
        return math.clamp(s.media+s.desvio*z,s.minimo,s.maximo)
    end

    function Nav.deslocarClique(base,tamanho)
        if tamanho.X<40 or tamanho.Y<40 then return nil end
        local centroX = math.clamp(base.X,16,tamanho.X-16)
        local centroY = math.clamp(base.Y,16,tamanho.Y-16)
        for _=1,10 do
            local angulo = math.random()*math.pi*2
            local raio = math.sqrt(25+math.random()*200)
            local x = math.floor(centroX+math.cos(angulo)*raio+0.5)
            local y = math.floor(centroY+math.sin(angulo)*raio+0.5)
            local d2 = (x-centroX)^2+(y-centroY)^2
            local ultimo = Nav.atividade.ultimoPonto
            local repetiu = ultimo and ultimo.X==x and ultimo.Y==y
            if d2>=25 and d2<=225 and not repetiu
                and x>=1 and y>=1 and x<tamanho.X and y<tamanho.Y then
                return Vector2.new(x,y)
            end
        end
        return nil
    end

    function Nav.pixelLivre(ponto,superficies)
        local janelas={}
        if MainFrame then table.insert(janelas,MainFrame) end
        if ConfigFrame then table.insert(janelas,ConfigFrame) end
        for _,janela in ipairs(janelas) do
            if janela and janela.Visible then
                local pos,tam = janela.AbsolutePosition,janela.AbsoluteSize
                if ponto.X>=pos.X and ponto.X<=pos.X+tam.X
                    and ponto.Y>=pos.Y and ponto.Y<=pos.Y+tam.Y then
                    return false
                end
            end
        end
        for _,superficie in ipairs(superficies) do
            local sucesso,objetos = pcall(function()
                return superficie:GetGuiObjectsAtPosition(ponto.X,ponto.Y)
            end)
            -- Nao injeta clique se nao for possivel consultar a interface.
            if not sucesso then return false end
            for _,obj in ipairs(objetos) do
                if obj.Visible and (obj:IsA("GuiButton") or obj:IsA("TextBox") or obj.Active) then
                    return false
                end
            end
        end
        return true
    end

    function Nav.pontoClique(camera)
        local tamanho = camera.ViewportSize
        local candidatos = {
            Vector2.new(tamanho.X*0.98,tamanho.Y*0.85),
            Vector2.new(tamanho.X*0.02,tamanho.Y*0.5),
            Vector2.new(tamanho.X*0.5,tamanho.Y*0.98),
            Vector2.new(tamanho.X*0.98,tamanho.Y*0.25),
            Vector2.new(tamanho.X*0.12,tamanho.Y*0.76),
            Vector2.new(tamanho.X*0.88,tamanho.Y*0.76),
            Vector2.new(tamanho.X*0.34,tamanho.Y*0.88),
            Vector2.new(tamanho.X*0.66,tamanho.Y*0.88),
            Vector2.new(tamanho.X*0.12,tamanho.Y*0.32),
            Vector2.new(tamanho.X*0.88,tamanho.Y*0.32),
        }
        local superficies = {}
        local ok,playerGui = pcall(function()
            return LocalPlayer:FindFirstChildOfClass("PlayerGui")
        end)
        if not ok then return nil end
        if playerGui then table.insert(superficies,playerGui) end
        if GS.pai and GS.pai~=playerGui then table.insert(superficies,GS.pai) end
        for _,base in ipairs(candidatos) do
            for _=1,4 do
                local ponto = Nav.deslocarClique(base,tamanho)
                if ponto and Nav.pixelLivre(ponto,superficies) then
                    return ponto
                end
            end
        end
        return nil
    end

    function Nav.liberarAtividade()
        local s=Nav.atividade
        local preso=s.pressionado
        if not preso then return true end
        local ok=pcall(function()
            if preso.tipo=="VirtualUser" then
                preso.vi:Button1Up(preso.ponto,preso.camera)
            else
                preso.vi:SendMouseButton(preso.ponto,Enum.UserInputType.MouseButton1,false,0)
            end
        end)
        if ok then s.pressionado=nil end
        return ok
    end

    function Nav.estadoAtividade(motivo)
        local s=Nav.atividade
        local agora=os.clock()
        s.ultimoMotivo=motivo
        if s.motivoAnterior~=motivo then
            s.motivoAnterior=motivo
            s.pausaDesde=agora
        end
        if agora<(s.proximaUI or 0) then return end
        s.proximaUI=agora+1
        local semEnvio=math.max(0,agora-(s.ultimoSucesso or s.inicio))
        if motivo~="enviado" then
            R.atividadeTexto=string.format("Atividade: %s · %.0fs sem envio local",motivo,semEnvio)
        elseif s.idleObservado then
            R.atividadeTexto=string.format("ALERTA: motor sinalizou AFK · %d envios locais · roda %d",s.enviados,s.rodas)
        else
            R.atividadeTexto=string.format("Envio local: %s · %d cliques · roda %d%s",
                s.canal or "nenhum",s.enviados,s.rodas,s.rodaIndisponivel and " (indisponivel)" or "")
        end
        if semEnvio>=60 and agora>=(s.proximoAviso or 0) then
            s.proximoAviso=agora+60
            warn("[DEBUG-BOT]: Atividade sem envio local ha",math.floor(semEnvio),"s. Motivo:",motivo)
        end
    end

    function Nav.buscarEntradaModerna()
        local s=Nav.atividade
        if s.virtual then return s.virtual end
        if os.clock()<(s.proximaVI or 0) then return nil end
        s.proximaVI=os.clock()+60
        local ok,vi=pcall(function() return UserInputService:CreateVirtualInput() end)
        if ok and vi then s.virtual=vi end
        return s.virtual
    end

    function Nav.enviarClique(ponto,camera)
        local s=Nav.atividade
        if not Nav.liberarAtividade() then return false,"botao_pendente" end
        local vi=Nav.buscarEntradaModerna()
        if vi then
            local segurou
            local ok,erro=pcall(function()
                vi:SendMousePosition(ponto)
                vi:SendMouseButton(ponto,Enum.UserInputType.MouseButton1,true,0)
                segurou={vi=vi,ponto=ponto}
                s.pressionado=segurou
                task.wait(0.04)
            end)
            local soltou=s.pressionado~=segurou or Nav.liberarAtividade()
            if ok and soltou then
                s.canal="VirtualInput"
                return true
            end
            s.virtual=nil
            s.proximaVI=os.clock()+60
            s.erroCanal=tostring(erro or "Nao foi possivel soltar o botao")
            return false,soltou and "entrada_moderna_recusada" or "botao_pendente"
        end
        local agora=os.clock()
        if not s.servico and agora>=(s.proximaBusca or 0) then
            s.proximaBusca=agora+math.min(30,2^(math.min(s.seguidos,4)))
            local ok,servico=pcall(function() return game:GetService("VirtualUser") end)
            s.servico=ok and servico or nil
        end
        local pareado=false
        local ok,erro=pcall(function()
            if not s.servico then error("VirtualUser indisponivel neste ambiente") end
            s.servico:CaptureController()
            pareado=type(s.servico.Button1Down)=="function" and type(s.servico.Button1Up)=="function"
            if pareado then
                s.servico:Button1Down(ponto,camera.CFrame)
                local segurou={vi=s.servico,ponto=ponto,camera=camera.CFrame,tipo="VirtualUser"}
                s.pressionado=segurou
                task.wait(0.04)
                if s.pressionado==segurou and not Nav.liberarAtividade() then
                    error("Nao foi possivel soltar o botao legado")
                end
            else
                s.servico:ClickButton1(ponto,camera.CFrame)
            end
        end)
        if ok then
            s.canal=pareado and "VirtualUser pareado" or "VirtualUser legado"
            return true
        end
        s.servico=nil
        s.erroCanal=tostring(erro)
        return false,"entrada_legada_recusada"
    end

    function Nav.rolarAtividade(ponto)
        local s=Nav.atividade
        if os.clock()<(s.proximaRoda or 0) then return false,"intervalo" end
        s.proximaRoda=os.clock()+30
        local ok,erro=pcall(function()
            if s.virtual then
                s.virtual:SendPointerAction(ponto,{Wheel=s.sentidoRoda})
            else
                if not s.gerenciador then s.gerenciador=game:GetService("VirtualInputManager") end
                s.gerenciador:SendMouseWheelEvent(ponto.X,ponto.Y,s.sentidoRoda>0,game)
            end
        end)
        if ok then
            s.rodas=s.rodas+1
            s.sentidoRoda=-s.sentidoRoda
            s.rodaIndisponivel=false
            return true,"enviado"
        end
        s.proximaRoda=os.clock()+60
        s.rodaIndisponivel=true
        s.gerenciador=nil
        if not s.avisouRoda then
            s.avisouRoda=true
            warn("[DEBUG-BOT]: Rolagem indisponivel; cliques continuam:",erro)
        end
        return false,"indisponivel"
    end

    function Nav.executarPulso(g,a,motivo)
        local s=Nav.atividade
        if not s.ativo or s.g~=g or s.a~=a then return false,"desligado" end
        if not autoVivo(g,a) then return false,"cancelado" end
        if Nav.estado.prompt then return false,"interagindo" end
        if UserInputService:GetFocusedTextBox() then return false,"digitando" end
        local okMenu,menu=pcall(function() return game:GetService("GuiService").MenuIsOpen end)
        if not okMenu then return false,"menu_indisponivel" end
        if menu then return false,"menu" end
        local agora=os.clock()
        if agora-s.ultimaTentativa<s.intervalo then return false,"intervalo" end
        local camera=workspace.CurrentCamera
        if not camera then return false,"sem_camera" end
        if camera.ViewportSize.X<40 or camera.ViewportSize.Y<40 then return false,"janela_sem_area" end
        local ponto=Nav.pontoClique(camera)
        if not ponto then return false,"tela_ocupada" end
        s.ultimaTentativa=agora
        s.intervalo=Nav.intervaloAtividade()
        s.proxima=agora+s.intervalo
        local token=s.token
        local ok,erro=Nav.enviarClique(ponto,camera)
        if s.token~=token or not s.ativo or not autoVivo(g,a) then return false,"cancelado" end
        if ok then
            s.enviados=s.enviados+1
            s.ultimoPonto=ponto
            s.seguidos=0
            s.ultimoSucesso=os.clock()
            s.avisou=false
            -- Revalida o estado apos o pequeno tempo de pressionar o botao.
            local seguro=not Nav.estado.prompt and not UserInputService:GetFocusedTextBox()
            local menuOK,aberto=pcall(function() return game:GetService("GuiService").MenuIsOpen end)
            if seguro and menuOK and not aberto and os.clock()>=(s.proximaRoda or 0) then
                local atual=Nav.pontoClique(camera)
                if atual then Nav.rolarAtividade(atual) end
            end
            return true,"enviado"
        end
        s.erros=s.erros+1
        s.seguidos=s.seguidos+1
        if not s.avisou then
            s.avisou=true
            s.proximoAviso=os.clock()+60
            warn("[DEBUG-BOT]: Entrada recusada:",s.erroCanal or erro,"Motivo:",motivo)
        end
        return false,erro
    end

    function Nav.pulsoAtividade(g,a,motivo)
        local s=Nav.atividade
        if s.emPulso then return false,"entrada_pendente" end
        local operacao={}
        s.emPulso=operacao
        local ok,enviou,estado=pcall(Nav.executarPulso,g,a,motivo)
        if s.emPulso==operacao then s.emPulso=nil end
        if not ok then
            s.erros=s.erros+1
            s.proxima=os.clock()+s.intervalo
            s.erroCanal=tostring(enviou)
            Nav.liberarAtividade()
            Nav.estadoAtividade("erro_no_agendador")
            return false,"erro"
        end
        if estado~="intervalo" and estado~="cancelado" and estado~="desligado" then
            Nav.estadoAtividade(estado)
            if not enviou then s.proxima=os.clock()+0.5 end
        end
        return enviou,estado
    end

    function Nav.loopAtividade(g,a,token,worker)
        local s=Nav.atividade
        while s.ativo and s.token==token and s.worker==worker and autoVivo(g,a) do
            s.batida=os.clock()
            if os.clock()>=s.proxima then
                Nav.pulsoAtividade(g,a,"periodico")
            end
            task.wait(0.05)
        end
    end
    function Nav.criarWorkerAtividade(g,a)
        local s=Nav.atividade
        s.worker=(s.worker or 0)+1
        local worker,token=s.worker,s.token
        s.batida=os.clock()
        s.workerPendente=true
        GS.spawn(function()
            if s.worker==worker and s.token==token then s.workerPendente=false end
            Nav.loopAtividade(g,a,token,worker)
        end)
    end
    function Nav.vigiarAtividade(g,a,token)
        local s=Nav.atividade
        if not s.ativo or s.token~=token then return end
        if not autoVivo(g,a) then Nav.pararAtividade(); return end
        local agora=os.clock()
        if agora>=(s.proximaVigia or 0) then
            s.proximaVigia=agora+1
            if agora-(s.batida or agora)>10 then
                if s.workerPendente then
                    Nav.estadoAtividade("agendador_sem_execucao")
                elseif s.emPulso then
                    Nav.estadoAtividade("entrada_pendente")
                else
                    s.reinicios=s.reinicios+1
                    s.proxima=agora
                    Nav.criarWorkerAtividade(g,a)
                    registrar("ATIVIDADE","Agendador retomado; periodo sem executar nao conta como atividade.")
                end
            end
            if agora-(s.ultimoSucesso or s.inicio)>60 then
                Nav.estadoAtividade(s.ultimoMotivo or "sem_envio")
            end
        end
    end

    function Nav.iniciarAtividade(g,a)
        Nav.pararAtividade()
        local s=Nav.atividade
        s.ativo=true
        s.g=g
        s.a=a
        s.avisou=false
        s.avisouRoda=false
        s.ultimaTentativa=-math.huge
        s.seguidos=0
        s.proximaBusca=0
        s.gaussReserva=nil
        s.intervalo=Nav.intervaloAtividade()
        s.ultimoPonto=nil
        s.proxima=os.clock()+s.intervalo
        s.inicio=os.clock()
        s.ultimoSucesso=s.inicio
        s.proximaUI=0
        s.proximoAviso=0
        s.proximaVigia=0
        s.proximaRoda=os.clock()+30
        s.sentidoRoda=1
        s.rodas=0
        s.reinicios=0
        s.idleObservado=false
        s.idleEventos=0
        s.ultimoIdle=nil
        s.proximoLogIdle=0
        s.emPulso=nil
        s.ultimoMotivo="iniciando"
        local token=s.token
        local ok,servico=pcall(function() return game:GetService("VirtualUser") end)
        s.servico=ok and servico or nil
        R.atividadeTexto="Entrada local iniciada · nao confirma aceitacao pelo motor"
        s.conn=GS.conectar(LocalPlayer.Idled,function(tempo)
            if not s.ativo or s.token~=token then return end
            s.idleEventos=s.idleEventos+1
            s.ultimoIdle=os.clock()
            s.idleSegundos=type(tempo)=="number" and tempo or 0
            s.idleObservado=true
            s.proximaUI=0
            if os.clock()>=s.proximoLogIdle then
                s.proximoLogIdle=os.clock()+60
                registrar("AFK","Motor ainda informa inatividade; envios locais nao confirmam aceitacao. Tempo: "..tostring(s.idleSegundos).."s")
            end
            Nav.estadoAtividade("motor_sinalizou_AFK")
            Nav.pulsoAtividade(g,a,"Idled")
        end)
        s.vigiaConn=GS.conectar(RunService.Heartbeat,function()
            local ok,erro=pcall(Nav.vigiarAtividade,g,a,token)
            if not ok then
                s.erroCanal=tostring(erro)
                if os.clock()>=(s.proximoAviso or 0) then
                    s.proximoAviso=os.clock()+60
                    warn("[DEBUG-BOT]: Monitor de atividade:",erro)
                end
            end
        end)
        Nav.criarWorkerAtividade(g,a)
        registrar("ATIVIDADE","Clique ~2s; rolagem alternada 30s se permitida; monitor de envios e sinal AFK.")
    end

    function Nav.fase(nome)
        R.fase = nome
        local mudou = Nav.estado.ultimaFase ~= nome
        local tempo = os.clock() - Nav.estado.ultimoLog
        if mudou and tempo > 0.4 then
            Nav.estado.ultimaFase = nome
            Nav.estado.ultimoLog = os.clock()
            registrar("NAVEGAÇÃO", nome)
        end
    end

    function Nav.finito(numero)
        return numero == numero
            and numero > -math.huge
            and numero < math.huge
    end

    function Nav.vetorValido(vetor)
        return vetor
            and Nav.finito(vetor.X)
            and Nav.finito(vetor.Y)
            and Nav.finito(vetor.Z)
    end

    function Nav.distanciaHorizontal(a,b)
        local dx = a.X - b.X
        local dz = a.Z - b.Z
        return math.sqrt(dx*dx + dz*dz)
    end

    function Nav.chave(pos)
        local celula = Nav.cfg.raioCelula
        return string.format("%d:%d",
            math.floor(pos.X/celula),
            math.floor(pos.Z/celula))
    end

    function Nav.contexto(g,a)
        local char,hum,root = personagem()
        if not char then return end
        if not autoVivo(g,a) then return end
        if Nav.estado.personagem ~= char then
            Nav.parar()
            Nav.reset()
            Nav.estado.personagem = char
            GS.farmaDirecao = Vector3.zero
            registrar("PERSONAGEM","Nova vida: direcao, rota e pontos antigos descartados.")
        end
        return {
            g = g,
            a = a,
            char = char,
            hum = hum,
            root = root,
            recebido = R.coletados,
            inicio = os.clock(),
        }
    end

    function Nav.vivo(ctx)
        if not ctx then return false end
        if not autoVivo(ctx.g,ctx.a) then return false end
        if LocalPlayer.Character ~= ctx.char then return false end
        if not ctx.root:IsDescendantOf(ctx.char) then return false end
        if not ctx.hum:IsDescendantOf(ctx.char) then return false end
        if ctx.hum.Health <= 0 then return false end
        return true
    end

    function Nav.alvoValido(e)
        if not e or not valido(e.obj) then return false end
        local p = parte(e.obj)
        if not p or not p:IsDescendantOf(workspace) then return false end
        if not Nav.vetorValido(p.Position) then return false end
        e.it.parte = p
        e.it.pos = p.Position
        return true
    end

    function Nav.posAlvo(e)
        if not Nav.alvoValido(e) then return end
        return e.it.parte.Position
    end

    function Nav.terminou(ctx,e)
        if not Nav.vivo(ctx) then return "cancelado" end
        if R.coletados > ctx.recebido then return "inventario" end
        if not Nav.alvoValido(e) then return "retirado" end
        if ctx.prazo and os.clock()>ctx.prazo then return "reagendar" end
        return nil
    end

    function Nav.esperar(ctx,duracao)
        local fim = os.clock() + duracao
        while Nav.vivo(ctx) and os.clock() < fim do
            task.wait(math.min(0.05,math.max(0,fim-os.clock())))
        end
        return Nav.vivo(ctx)
    end

    function Nav.parametros(ctx,e)
        local parametros = RaycastParams.new()
        parametros.FilterType = Enum.RaycastFilterType.Exclude
        local ignorados = {}
        if ctx and ctx.char then
            table.insert(ignorados,ctx.char)
        elseif LocalPlayer.Character then
            table.insert(ignorados,LocalPlayer.Character)
        end
        if e and e.obj and e.obj.Parent then
            table.insert(ignorados,e.obj)
        end
        parametros.FilterDescendantsInstances = ignorados
        parametros.IgnoreWater = true
        parametros.RespectCanCollide = true
        return parametros
    end

    function Nav.raio(origem,direcao,ctx,e)
        if not Nav.vetorValido(origem) then return end
        if not Nav.vetorValido(direcao) then return end
        if direcao.Magnitude < 0.01 then return end
        return workspace:Raycast(origem,direcao,Nav.parametros(ctx,e))
    end

    function Nav.alturaRoot(ctx)
        local h = math.max(0,ctx.hum.HipHeight)
        return math.max(2,h+ctx.root.Size.Y*0.5)
    end

    function Nav.superficie(pos,ctx,e,profundidade)
        local cima = pos + Vector3.new(0,2,0)
        local baixo = Vector3.new(0,-(profundidade or 24),0)
        local hit = Nav.raio(cima,baixo,ctx,e)
        if not hit then return end
        if hit.Normal.Y < Nav.cfg.normalMinima then return end
        if not Nav.vetorValido(hit.Position) then return end
        return {
            pos = hit.Position,
            normal = hit.Normal,
            objeto = hit.Instance,
            altura = hit.Position.Y,
        }
    end

    function Nav.suporte(pos,ctx,e)
        local melhor
        local dist
        local deslocamentos = {
            Vector3.zero,
            Vector3.new(0.8,0,0),
            Vector3.new(-0.8,0,0),
            Vector3.new(0,0,0.8),
            Vector3.new(0,0,-0.8),
        }
        for _,delta in ipairs(deslocamentos) do
            local s = Nav.superficie(pos+delta,ctx,e,16)
            if s then
                local d = math.abs(pos.Y-s.altura)
                if d <= 12 and (not dist or d < dist) then
                    melhor = s
                    dist = d
                end
            end
        end
        return melhor
    end

    function Nav.cabecaLivre(pouso,ctx,e)
        local altura = Nav.alturaRoot(ctx) + 2
        local origem = pouso.pos + Vector3.new(0,0.25,0)
        local hit = Nav.raio(origem,Vector3.new(0,altura,0),ctx,e)
        return hit == nil
    end

    function Nav.analise(ctx,e)
        local pos = Nav.posAlvo(e)
        if not pos then return end
        local suporte = Nav.suporte(pos,ctx,e)
        local alturaRoot = Nav.alturaRoot(ctx)
        local destino
        if suporte then
            destino = suporte.pos + Vector3.new(0,alturaRoot+0.2,0)
        else
            destino = pos + Vector3.new(0,0.5,0)
        end
        local deltaY = pos.Y - ctx.root.Position.Y
        local origem = ctx.root.Position
        local bloqueio = Nav.raio(origem,destino-origem,ctx,e)
        return {
            pos = pos,
            suporte = suporte,
            destino = destino,
            elevado = deltaY > Nav.cfg.alturaElevada,
            deltaY = deltaY,
            bloqueio = bloqueio,
            alturaRoot = alturaRoot,
            cabeca = suporte and Nav.cabecaLivre(suporte,ctx,e) or false,
        }
    end

    function Nav.salvarSeguro(ctx)
        if not Nav.vivo(ctx) then return end
        local pos = ctx.root.Position
        local piso = Nav.superficie(pos,ctx,nil,12)
        if not piso then return end
        if pos.Y <= workspace.FallenPartsDestroyHeight+20 then return end
        Nav.estado.seguro = piso.pos + Vector3.new(0,Nav.alturaRoot(ctx)+1,0)
    end

    function Nav.reset()
        Nav.mundoNovo()
        R.sujo = true
        Nav.estado.ancora = nil
        Nav.estado.seguro = nil
        Nav.estado.alvo = nil
        Nav.estado.anel = 1
        Nav.estado.setor = 0
        Nav.estado.passos = 0
        Nav.estado.ultimaPos = nil
        Nav.estado.ultimoDestino = nil
        Nav.estado.prompt = nil
        Nav.estado.tokenPrompt = nil
        Nav.estado.ultimaFase = ""
        Nav.estado.ultimoLog = 0
        Nav.estado.voo = false
        Nav.estado.visita = {}
    end

    function Nav.liberarPrompt()
        local prompt = Nav.estado.prompt
        Nav.estado.tokenPrompt = nil
        Nav.estado.prompt = nil
        if prompt then
            pcall(function()
                prompt:InputHoldEnd()
            end)
        end
    end

    function Nav.parar()
        Nav.liberarPrompt()
        Nav.estado.alvo = nil
        Nav.estado.rota = nil
        GS.farmaDirecao = nil
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity.Velocity = Vector3.zero
        end
    end

    function Nav.voo(ctx)
        if not Nav.vivo(ctx) then return false end
        if ctx.root.Anchored then return false end
        if not flyAtivado then
            setVoo(true)
        else
            if GS.noclipArquivo then
                GS.noclipArquivo.ativar("frascos")
            end
            velocidadeVoo = Nav.cfg.velocidade
            GS.farmaDirecao = Vector3.zero
        end
        Nav.estado.voo = true
        return true
    end

    function Nav.zerar(ctx)
        GS.farmaDirecao = Vector3.zero
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity.Velocity = Vector3.zero
        end
        if ctx and Nav.vivo(ctx) then
            ctx.root.AssemblyLinearVelocity = Vector3.zero
            ctx.root.AssemblyAngularVelocity = Vector3.zero
        end
    end

    function Nav.velocidadePara(delta,preciso)
        local distancia = delta.Magnitude
        if distancia < 0.01 then return Vector3.zero end
        local teto = preciso and Nav.cfg.velocidadePerto or Nav.cfg.velocidade
        local velocidade = math.min(teto,distancia/Nav.cfg.freioSegundos)
        return delta.Unit*(velocidade/Nav.cfg.velocidade)
    end

    function Nav.moverVoo(ctx,destino,opcoes)
        opcoes = opcoes or {}
        if not Nav.vetorValido(destino) then return "destino_invalido" end
        if destino.Y<=workspace.FallenPartsDestroyHeight+Nav.cfg.minAltura then
            return "destino_inseguro"
        end
        if not Nav.voo(ctx) then return "sem_movimento" end
        local inicio = os.clock()
        local limite = opcoes.limite or Nav.cfg.limiteTrecho
        local tolerancia = opcoes.tolerancia or Nav.cfg.chegada
        local ultimaDistancia = math.huge
        local progresso = os.clock()
        local ultimaPos = ctx.root.Position
        local parado = os.clock()
        Nav.estado.ultimoDestino = destino
        while Nav.vivo(ctx) do
            if opcoes.alvo then
                local fim = Nav.terminou(ctx,opcoes.alvo)
                if fim then
                    Nav.zerar(ctx)
                    return fim
                end
                if os.clock()-ctx.inicio > Nav.cfg.limiteAlvo then
                    Nav.zerar(ctx)
                    return "limite_do_alvo"
                end
            end
            if ctx.root.Anchored then
                Nav.zerar(ctx)
                return "ancorado"
            end
            if os.clock()-inicio > limite then
                Nav.zerar(ctx)
                return "tempo"
            end
            local delta = destino-ctx.root.Position
            local distancia = delta.Magnitude
            if distancia <= tolerancia then
                Nav.zerar(ctx)
                return "chegou"
            end
            if distancia < ultimaDistancia-Nav.cfg.margemProgresso then
                ultimaDistancia = distancia
                progresso = os.clock()
            elseif os.clock()-progresso > Nav.cfg.semProgresso then
                Nav.zerar(ctx)
                return "bloqueado"
            end
            local avancou = (ctx.root.Position-ultimaPos).Magnitude
            if avancou > 0.15 then
                ultimaPos = ctx.root.Position
                parado = os.clock()
            elseif os.clock()-parado > Nav.cfg.semProgresso then
                Nav.zerar(ctx)
                return "parado"
            end
            local limiteY = workspace.FallenPartsDestroyHeight+Nav.cfg.minAltura
            if ctx.root.Position.Y < limiteY and not opcoes.recuperacao then
                Nav.zerar(ctx)
                return "void"
            end
            if opcoes.patrulha then
                local e = Nav.escolher(ctx)
                if e then
                    Nav.zerar(ctx)
                    return "alvo_detectado"
                end
            end
            if opcoes.alvo and opcoes.posOriginal then
                local pos = Nav.posAlvo(opcoes.alvo)
                if pos and (pos-opcoes.posOriginal).Magnitude > Nav.cfg.distanciaReplanejar then
                    Nav.zerar(ctx)
                    return "replanejar"
                end
            end
            GS.farmaDirecao = Nav.velocidadePara(delta,opcoes.preciso)
            task.wait(Nav.cfg.intervalo)
        end
        if autoVivo(ctx.g,ctx.a) then Nav.zerar(ctx) end
        return "cancelado"
    end

    function Nav.observarItens()
        local agora = os.clock()
        for obj,it in pairs(R.itens) do
            if valido(obj) and it.parte and it.parte.Parent then
                local pos = it.parte.Position
                local chave = Nav.chave(pos)
                Nav.estado.memoria[chave] = {
                    pos = pos,
                    hora = agora,
                    objeto = obj,
                }
            end
        end
        local chaves = {}
        for chave,memoria in pairs(Nav.estado.memoria) do
            if agora-memoria.hora > Nav.cfg.idadeMemoria then
                Nav.estado.memoria[chave] = nil
            else
                table.insert(chaves,{chave=chave,hora=memoria.hora})
            end
        end
        if #chaves > Nav.cfg.limiteMemoria then
            table.sort(chaves,function(a,b)
                return a.hora < b.hora
            end)
            for i=1,#chaves-Nav.cfg.limiteMemoria do
                Nav.estado.memoria[chaves[i].chave] = nil
            end
        end
    end

    function Nav.escolher(ctx)
        if not Nav.vivo(ctx) then return end
        Nav.observarItens()
        local escolhido
        local menor
        local agora = os.clock()
        for obj,it in pairs(R.itens) do
            if valido(obj) and (it.tentarEm or 0) <= agora then
                local p = parte(obj)
                if p then
                    local distancia = (p.Position-ctx.root.Position).Magnitude
                    local erros = Nav.estado.falhas[obj] or 0
                    local custo = distancia + erros*25
                    local idade = agora-(it.detectado or agora)
                    custo = custo-math.min(40,idade*0.1)
                    if not menor or custo < menor then
                        menor = custo
                        escolhido = {obj=obj,it=it}
                    end
                end
            end
        end
        return escolhido
    end

    function Nav.pontoLateral(analise,indice)
        local angulo = (indice-1)*math.pi/2
        local raio = Nav.cfg.raioSuporte
        return analise.destino + Vector3.new(
            math.cos(angulo)*raio,
            0,
            math.sin(angulo)*raio)
    end

    function Nav.teto(ctx,e,analise)
        local origem = ctx.root.Position
        local pos = analise.destino
        local cima = math.max(origem.Y,pos.Y)+Nav.cfg.alturaSobrevoo
        local hit = Nav.raio(pos+Vector3.new(0,1,0),
            Vector3.new(0,Nav.cfg.alturaSobrevoo*3,0),ctx,e)
        if hit then
            cima = math.max(cima,hit.Position.Y+Nav.cfg.alturaExtra)
        end
        return cima
    end

    function Nav.rotas(ctx,e,analise)
        local teto = Nav.teto(ctx,e,analise)
        local origem = ctx.root.Position
        local centro = analise.destino
        local rotas = {}
        local direto = {
            nome = "APROXIMAÇÃO DIRETA",
            pontos = {centro},
        }
        local porCima = {
            nome = "SUBINDO POR CIMA DO OBSTÁCULO",
            pontos = {
                Vector3.new(origem.X,teto,origem.Z),
                Vector3.new(centro.X,teto,centro.Z),
                centro,
            },
        }
        if analise.elevado or analise.bloqueio then
            table.insert(rotas,porCima)
            table.insert(rotas,direto)
        else
            table.insert(rotas,direto)
            table.insert(rotas,porCima)
        end
        for i=1,4 do
            local lateral = Nav.pontoLateral(analise,i)
            table.insert(rotas,{
                nome = "TENTANDO LATERAL " .. i,
                pontos = {
                    Vector3.new(origem.X,teto+4,origem.Z),
                    Vector3.new(lateral.X,teto+4,lateral.Z),
                    lateral+Vector3.new(0,3,0),
                    centro,
                },
            })
        end
        table.insert(rotas,{
            nome = "RECUANDO E TENTANDO POR BAIXO",
            pontos = {
                centro+Vector3.new(Nav.cfg.recuo,0,Nav.cfg.recuo),
                centro,
            },
        })
        return rotas
    end

    function Nav.executarRota(ctx,e,rota,analise)
        Nav.fase(rota.nome)
        Nav.estado.rota = rota.nome
        for i,ponto in ipairs(rota.pontos) do
            if not Nav.vivo(ctx) then return "cancelado" end
            local fim = Nav.terminou(ctx,e)
            if fim then return fim end
            local resultado = Nav.moverVoo(ctx,ponto,{
                alvo = e,
                posOriginal = analise.pos,
                preciso = i == #rota.pontos,
                tolerancia = i == #rota.pontos and 1.1 or 2,
                limite = Nav.cfg.limiteTrecho,
            })
            if resultado ~= "chegou" then return resultado end
        end
        return "chegou"
    end

    function Nav.pousar(ctx,e,analise)
        if not Nav.vivo(ctx) then return "cancelado" end
        local suporte = analise.suporte
        if not suporte or not analise.cabeca then
            Nav.fase("COLETA EM VOO · SEM APOIO SEGURO")
            return "sem_suporte"
        end
        local acima = suporte.pos + Vector3.new(0,Nav.alturaRoot(ctx)+0.5,0)
        local resultado = Nav.moverVoo(ctx,acima,{
            alvo = e,
            preciso = true,
            tolerancia = 1,
            limite = 4,
        })
        if resultado ~= "chegou" then return resultado end
        if not Nav.vivo(ctx) then return "cancelado" end
        local p = Nav.posAlvo(e)
        if not p then return "retirado" end
        if math.abs(ctx.root.Position.Y-acima.Y) > 2 then
            return "altura_errada"
        end
        Nav.fase("POUSANDO NA SUPERFÍCIE")
        Nav.zerar(ctx)
        setVoo(false)
        Nav.estado.voo = false
        ctx.hum.PlatformStand = false
        ctx.hum.WalkSpeed = CFG.caminhada
        local inicio = os.clock()
        while Nav.vivo(ctx) and os.clock()-inicio < Nav.cfg.limitePouso do
            local fim = Nav.terminou(ctx,e)
            if fim then return fim end
            local y = ctx.root.Position.Y
            if y < suporte.altura-3 then
                Nav.voo(ctx)
                return "caiu"
            end
            if ctx.hum.FloorMaterial ~= Enum.Material.Air then
                Nav.salvarSeguro(ctx)
                return "pousou"
            end
            task.wait(0.05)
        end
        if Nav.vivo(ctx) then Nav.voo(ctx) end
        return "sem_chao"
    end

    function Nav.posPrompt(prompt,e)
        local pai = prompt and prompt.Parent
        if pai and pai:IsA("Attachment") then
            return pai.WorldPosition
        end
        if pai and pai:IsA("BasePart") then
            return pai.Position
        end
        if pai and pai:IsA("Model") then
            return pai:GetPivot().Position
        end
        return Nav.posAlvo(e)
    end

    function Nav.linhaVisao(ctx,e,destino)
        local origem = ctx.root.Position + Vector3.new(0,1,0)
        local delta = destino-origem
        if delta.Magnitude < 0.05 then return true end
        local hit = Nav.raio(origem,delta,ctx,e)
        return hit == nil
    end

    function Nav.segurar(ctx,e,prompt)
        if not Nav.vivo(ctx) then return "cancelado" end
        if not prompt.Enabled then return "prompt_desligado" end
        local pos = Nav.posPrompt(prompt,e)
        if not pos then return "retirado" end
        local distancia = (ctx.root.Position-pos).Magnitude
        if distancia > prompt.MaxActivationDistance then
            return "longe"
        end
        if prompt.RequiresLineOfSight and not Nav.linhaVisao(ctx,e,pos) then
            return "sem_visao"
        end
        local token = {}
        local disparou = false
        Nav.estado.prompt = prompt
        Nav.estado.tokenPrompt = token
        local conn = GS.conectar(prompt.Triggered,function(player)
            if player == LocalPlayer and Nav.vivo(ctx) then
                disparou = true
            end
        end)
        local ok,erro = pcall(function()
            Nav.fase("SEGURANDO INTERAÇÃO DO FRASCO")
            ctx.hum:MoveTo(ctx.root.Position)
            prompt:InputHoldBegin()
            local fim = os.clock()+prompt.HoldDuration+0.25
            while Nav.vivo(ctx) and prompt.Parent and prompt.Enabled do
                if Nav.terminou(ctx,e) then break end
                local atual = Nav.posPrompt(prompt,e)
                if not atual then break end
                if (ctx.root.Position-atual).Magnitude > prompt.MaxActivationDistance then break end
                if disparou or os.clock() >= fim then break end
                task.wait(0.05)
            end
        end)
        if Nav.estado.tokenPrompt == token then
            Nav.liberarPrompt()
        end
        conn:Disconnect()
        if not ok then
            registrar("INTERAÇÃO",tostring(erro))
            return "erro_interacao"
        end
        if disparou then return "interacao" end
        return Nav.terminou(ctx,e) or "sem_confirmacao"
    end

    function Nav.interagir(ctx,e)
        local fim = Nav.terminou(ctx,e)
        if fim then return fim end
        local prompt = e.obj:FindFirstChildWhichIsA("ProximityPrompt",true)
        if prompt then
            return Nav.segurar(ctx,e,prompt)
        end
        local click = e.obj:FindFirstChildWhichIsA("ClickDetector",true)
        local pos = Nav.posAlvo(e)
        if not pos then return "retirado" end
        local distancia = (ctx.root.Position-pos).Magnitude
        if click and distancia <= click.MaxActivationDistance then
            if type(fireclickdetector) == "function" then
                local ok,erro = pcall(fireclickdetector,click)
                if not ok then registrar("INTERAÇÃO",tostring(erro)) end
            end
        end
        return Nav.terminou(ctx,e) or "aguardando_toque"
    end

    function Nav.confirmar(ctx,e)
        local fim = os.clock()+Nav.cfg.pausaConfirmacao
        while Nav.vivo(ctx) and os.clock()<fim do
            local resultado = Nav.terminou(ctx,e)
            if resultado then return resultado end
            task.wait(0.05)
        end
        return Nav.terminou(ctx,e) or "sem_confirmacao"
    end

    function Nav.pontoPe(ctx,e,deslocamento)
        local pos = Nav.posAlvo(e)
        if not pos then return end
        local alvo = pos+deslocamento
        local suporte = Nav.superficie(alvo,ctx,e,10)
        if not suporte then return end
        if math.abs(suporte.altura-pos.Y) > 6 then return end
        local alto = suporte.pos+Vector3.new(0,Nav.alturaRoot(ctx),0)
        local apoio = {
            pos = suporte.pos,
            normal = suporte.normal,
            altura = suporte.altura,
        }
        if not Nav.cabecaLivre(apoio,ctx,e) then return end
        return {
            chao = suporte.pos,
            root = alto,
            suporte = suporte,
        }
    end

    function Nav.andar(ctx,e,destino,pular,limite)
        if not Nav.vivo(ctx) then return "cancelado" end
        if flyAtivado then return "ainda_voando" end
        if ctx.root.Anchored then return "ancorado" end
        ctx.hum.PlatformStand = false
        ctx.hum.WalkSpeed = CFG.caminhada
        if pular then ctx.hum.Jump = true end
        ctx.hum:MoveTo(destino)
        local inicio = os.clock()
        local ultimo = ctx.root.Position
        local progresso = os.clock()
        while Nav.vivo(ctx) and os.clock()-inicio < (limite or Nav.cfg.limitePe) do
            local fim = Nav.terminou(ctx,e)
            if fim then return fim end
            if Nav.distanciaHorizontal(ctx.root.Position,destino) < 1 then
                return "chegou"
            end
            local deslocamento = (ctx.root.Position-ultimo).Magnitude
            if deslocamento > Nav.cfg.progressoPe then
                ultimo = ctx.root.Position
                progresso = os.clock()
            elseif os.clock()-progresso > 0.8 then
                ctx.hum.Jump = true
                progresso = os.clock()
                ctx.hum:MoveTo(destino)
            end
            local pos = Nav.posAlvo(e)
            if pos and ctx.root.Position.Y < pos.Y-8 then
                Nav.voo(ctx)
                return "caiu"
            end
            task.wait(0.08)
        end
        return Nav.terminou(ctx,e) or "tempo_pe"
    end

    function Nav.rotaPe(ctx,e)
        local pos = Nav.posAlvo(e)
        if not pos or not Nav.vivo(ctx) then return "cancelado" end
        local path = PathfindingService:CreatePath({
            AgentRadius = 1.6,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentCanClimb = true,
            WaypointSpacing = 3,
        })
        local ok,erro = pcall(function()
            path:ComputeAsync(ctx.root.Position,pos)
        end)
        if not Nav.vivo(ctx) then
            path:Destroy()
            return "cancelado"
        end
        if not ok or path.Status ~= Enum.PathStatus.Success then
            path:Destroy()
            if not ok then registrar("ROTA",tostring(erro)) end
            return "sem_rota"
        end
        local fim = os.clock()+Nav.cfg.limiteRotaPe
        local resultado = "tempo_rota"
        for _,ponto in ipairs(path:GetWaypoints()) do
            if not Nav.vivo(ctx) or os.clock()>fim then break end
            local saiu = Nav.terminou(ctx,e)
            if saiu then
                resultado = saiu
                break
            end
            resultado = Nav.andar(ctx,e,ponto.Position,
                ponto.Action == Enum.PathWaypointAction.Jump,1.2)
            if resultado ~= "chegou" then break end
            local atual = Nav.posAlvo(e)
            if atual and (ctx.root.Position-atual).Magnitude < CFG.alcance then
                resultado = "chegou"
                break
            end
        end
        path:Destroy()
        return resultado
    end

    function Nav.toques(ctx,e)
        local deslocamentos = {
            Vector3.zero,
            Vector3.new(1.2,0,0),
            Vector3.new(-1.2,0,0),
            Vector3.new(0,0,1.2),
            Vector3.new(0,0,-1.2),
            Vector3.new(0.8,0,0.8),
            Vector3.new(-0.8,0,-0.8),
        }
        for i,delta in ipairs(deslocamentos) do
            if not Nav.vivo(ctx) then return "cancelado" end
            local fim = Nav.terminou(ctx,e)
            if fim then return fim end
            local ponto = Nav.pontoPe(ctx,e,delta)
            if ponto then
                Nav.fase("APROXIMAÇÃO A PÉ · TENTATIVA " .. i)
                local pos = Nav.posAlvo(e)
                local alto = pos and pos.Y-ctx.root.Position.Y > 2
                local andou = Nav.andar(ctx,e,ponto.chao,alto or i%3==0,1)
                if andou == "caiu" or andou == "cancelado" then
                    return andou
                end
                local resultado = Nav.interagir(ctx,e)
                if resultado == "inventario" or resultado == "retirado" then
                    return resultado
                end
                local confirmado = Nav.confirmar(ctx,e)
                if confirmado ~= "sem_confirmacao" then
                    return confirmado
                end
            end
        end
        return "sem_confirmacao"
    end

    function Nav.toqueAereo(ctx,e)
        local pos = Nav.posAlvo(e)
        if not pos then return "retirado" end
        local pontos = {
            Vector3.new(0,1,0),
            Vector3.new(0,0,0),
            Vector3.new(1.3,0,0),
            Vector3.new(-1.3,0,0),
            Vector3.new(0,0,1.3),
            Vector3.new(0,0,-1.3),
        }
        for i,delta in ipairs(pontos) do
            if not Nav.vivo(ctx) then return "cancelado" end
            local atual = Nav.posAlvo(e)
            if not atual then return "retirado" end
            Nav.fase("AJUSTE AÉREO DE PRECISÃO · " .. i)
            local resultado = Nav.moverVoo(ctx,atual+delta,{
                alvo = e,
                preciso = true,
                tolerancia = 0.7,
                limite = 3,
            })
            if resultado == "inventario" or resultado == "retirado" then
                return resultado
            end
            if resultado == "chegou" then
                Nav.interagir(ctx,e)
                local confirmado = Nav.confirmar(ctx,e)
                if confirmado ~= "sem_confirmacao" then return confirmado end
            end
        end
        return "sem_confirmacao"
    end

    function Nav.toqueRapido(ctx,e)
        if not Nav.vivo(ctx) then return "cancelado" end
        -- Prompts seguem o tempo de segurar definido pelo proprio jogo.
        if e.obj:FindFirstChildWhichIsA("ProximityPrompt",true) then
            return "sem_confirmacao"
        end
        Nav.fase("COLETA RÁPIDA · AJUSTE DE TOQUE")
        local pontos = {
            Vector3.new(0,0.4,0),
            Vector3.new(0.7,0,0),
            Vector3.new(-0.7,0,0),
        }
        local inicio = os.clock()
        for _,delta in ipairs(pontos) do
            local fim = Nav.terminou(ctx,e)
            if fim then return fim end
            if os.clock()-inicio > 2.8 then break end
            local pos = Nav.posAlvo(e)
            if not pos then return "retirado" end
            local resultado = Nav.moverVoo(ctx,pos+delta,{
                alvo = e,
                preciso = true,
                tolerancia = 0.45,
                limite = 0.8,
            })
            if resultado == "inventario" or resultado == "retirado" or resultado == "cancelado" then
                return resultado
            end
            local confirmado = Nav.confirmar(ctx,e)
            if confirmado ~= "sem_confirmacao" then return confirmado end
        end
        return "sem_confirmacao"
    end

    -- O deslocamento rapido nunca e contabilizado como coleta.
    -- Caso o servidor corrija a posicao, volta ao navegador com pouso/pulos.
    function Nav.encadearRapido(ctx,e)
        if not Nav.cfg.saltoRapido then return "desativado" end
        if os.clock() < Nav.cfg.bloquearRapidoAte then return "aguardando" end
        if not Nav.vivo(ctx) or ctx.root.Anchored then return "cancelado" end
        if not ctx.root.CFrame then return "sem_raiz" end
        local destino = Nav.posAlvo(e)
        if not destino then return "retirado" end
        if destino.Y <= workspace.FallenPartsDestroyHeight+Nav.cfg.minAltura then
            return "destino_inseguro"
        end
        if (destino-ctx.root.Position).Magnitude > Nav.cfg.limiteRapido then
            return "fora_do_limite"
        end
        if not Nav.voo(ctx) then return "sem_movimento" end
        Nav.fase("ENCADEANDO FRASCOS · DESLOCAMENTO RÁPIDO")
        local inicio = os.clock()
        for _=1,24 do
            local fim = Nav.terminou(ctx,e)
            if fim then return fim end
            destino = Nav.posAlvo(e)
            if not destino then return "retirado" end
            local delta = destino-ctx.root.Position
            if delta.Magnitude < 1.4 then break end
            if os.clock()-inicio > 1.5 then return "tempo_rapido" end
            local passo = math.min(delta.Magnitude,Nav.cfg.passoRapido)
            local ponto = ctx.root.Position+delta.Unit*passo
            if ponto.Y <= workspace.FallenPartsDestroyHeight+Nav.cfg.minAltura then
                return "destino_inseguro"
            end
            Nav.zerar(ctx)
            local ok = pcall(function()
                ctx.root.CFrame = ctx.root.CFrame+(ponto-ctx.root.Position)
            end)
            if not ok then return "movimento_recusado" end
            Nav.esperar(ctx,Nav.cfg.pausaRapida)
            if not Nav.vivo(ctx) then return "cancelado" end
            if (ctx.root.Position-ponto).Magnitude > 24 then
                Nav.cfg.bloquearRapidoAte = os.clock()+15
                registrar("AJUSTE","Servidor corrigiu o deslocamento; usando voo e pouso.")
                return "corrigido"
            end
        end
        Nav.interagir(ctx,e)
        local prazo = os.clock()+Nav.cfg.verificarRapido
        while Nav.vivo(ctx) and os.clock()<prazo do
            local resultado = Nav.terminou(ctx,e)
            if resultado then return resultado end
            task.wait(0.02)
        end
        return Nav.terminou(ctx,e) or "sem_confirmacao"
    end

    function Nav.coletarChegada(ctx,e,analise)
        local fim = Nav.terminou(ctx,e)
        if fim then return fim end
        local rapido = Nav.toqueRapido(ctx,e)
        if rapido == "inventario" or rapido == "retirado" or rapido == "cancelado" then
            return rapido
        end
        local resultado = Nav.interagir(ctx,e)
        if resultado == "inventario" or resultado == "retirado" then
            return resultado
        end
        local pouso = Nav.pousar(ctx,e,analise)
        if pouso == "pousou" then
            resultado = Nav.toques(ctx,e)
            if resultado == "inventario" or resultado == "retirado" then
                return resultado
            end
            if resultado == "sem_confirmacao" and Nav.vivo(ctx) then
                Nav.fase("TENTANDO ROTA COM PULOS")
                Nav.rotaPe(ctx,e)
                resultado = Nav.toques(ctx,e)
                if resultado == "inventario" or resultado == "retirado" then
                    return resultado
                end
            end
        elseif pouso == "inventario" or pouso == "retirado" or pouso == "cancelado" then
            return pouso
        end
        if not Nav.vivo(ctx) then return "cancelado" end
        return Nav.toqueAereo(ctx,e)
    end

    function Nav.recuar(ctx,e)
        if not Nav.vivo(ctx) then return "cancelado" end
        local pos = Nav.posAlvo(e)
        if not pos then return "retirado" end
        Nav.estado.recuperacoes = Nav.estado.recuperacoes+1
        Nav.fase("RECUANDO PARA REPLANEJAR")
        local destino = ctx.root.Position+Vector3.new(0,Nav.cfg.alturaExtra,0)
        local resultado = Nav.moverVoo(ctx,destino,{
            alvo = e,
            limite = 4,
            tolerancia = 2,
        })
        return resultado
    end

    function Nav.falhou(e,motivo)
        if not e or not e.it then return end
        local contagem = (Nav.estado.falhas[e.obj] or 0)+1
        Nav.estado.falhas[e.obj] = contagem
        local pausa = math.min(Nav.cfg.cooldownMaximo,
            Nav.cfg.cooldownBase*(1.6^(contagem-1)))
        e.it.tentarEm = os.clock()+pausa
        registrar("REAGENDADO",string.format(
            "%s: %s. Nova tentativa em %.0fs.",
            e.obj.Name,motivo,pausa))
    end

    function Nav.concluir(ctx,e,resultado)
        if not Nav.vivo(ctx) then return end
        Nav.liberarPrompt()
        Nav.zerar(ctx)
        if resultado == "inventario" then
            Nav.estado.falhas[e.obj] = nil
            registrar("FINALIZADO","Frasco confirmado no inventário.")
        elseif resultado == "retirado" then
            registrar("FINALIZADO","Frasco saiu do mapa; pode ter sido coletado ou descarregado.")
        else
            Nav.falhou(e,resultado or "sem_confirmacao")
        end
        Nav.estado.alvo = nil
        Nav.estado.rota = nil
    end

    function Nav.temAlternativa(ctx,e)
        for obj,it in pairs(R.itens) do
            if obj~=e.obj and (it.tentarEm or 0)<=os.clock() then
                if Nav.alvoValido({obj=obj,it=it}) then return true end
            end
        end
        return false
    end

    function Nav.buscar(e,g,a)
        local ctx = Nav.contexto(g,a)
        if not ctx then return end
        local haOutro = Nav.temAlternativa(ctx,e)
        ctx.prazo = os.clock()+(haOutro and Nav.cfg.orcamentoComAlternativa or Nav.cfg.orcamentoSozinho)
        Nav.estado.alvo = e.obj
        Nav.salvarSeguro(ctx)
        local rapido = Nav.encadearRapido(ctx,e)
        if rapido == "inventario" or rapido == "retirado" or rapido == "cancelado" then
            Nav.concluir(ctx,e,rapido)
            return
        end
        local inicial = Nav.analise(ctx,e)
        if not inicial then return end
        local nomeSuporte = inicial.suporte and inicial.suporte.objeto.Name or "sem apoio"
        registrar("ALVO",string.format(
            "%s | diferença vertical %.1f | apoio %s",
            e.obj.Name,inicial.deltaY,nomeSuporte))
        local resultado = "sem_confirmacao"
        local plano = Nav.rotas(ctx,e,inicial)
        local indice = 1
        local replanejamentos = 0
        while Nav.vivo(ctx) and indice <= #plano do
            local saiu = Nav.terminou(ctx,e)
            if saiu then
                resultado = saiu
                break
            end
            if os.clock()-ctx.inicio > Nav.cfg.limiteAlvo then
                resultado = "limite_do_alvo"
                break
            end
            local analise = Nav.analise(ctx,e)
            if not analise then
                resultado = "retirado"
                break
            end
            if (analise.pos-inicial.pos).Magnitude > Nav.cfg.distanciaReplanejar then
                inicial = analise
                plano = Nav.rotas(ctx,e,analise)
                indice = 1
                replanejamentos = replanejamentos+1
                if replanejamentos > 3 then
                    resultado = "alvo_movel"
                    break
                end
            end
            resultado = Nav.executarRota(ctx,e,plano[indice],analise)
            if resultado == "chegou" then
                local atual = Nav.analise(ctx,e)
                if atual then
                    resultado = Nav.coletarChegada(ctx,e,atual)
                else
                    resultado = "retirado"
                end
            end
            if resultado == "inventario" or resultado == "retirado" then break end
            if resultado == "cancelado" then break end
            if resultado == "reagendar" or os.clock()>ctx.prazo then
                resultado = "reagendar"
                break
            end
            if (resultado=="bloqueado" or resultado=="parado" or resultado=="ancorado")
                and Nav.temAlternativa(ctx,e) then
                registrar("TROCANDO ALVO","Frasco travado; tentando outro sem insistir no mesmo obstaculo.")
                resultado = "reagendar"
                break
            end
            if resultado == "void" then
                Nav.recuperar(ctx)
            elseif resultado ~= "replanejar" then
                Nav.recuar(ctx,e)
            end
            indice = indice+1
        end
        Nav.concluir(ctx,e,resultado)
    end

    function Nav.recuperar(ctx)
        if not Nav.vivo(ctx) then return false end
        Nav.liberarPrompt()
        Nav.estado.recuperacoes = Nav.estado.recuperacoes+1
        Nav.fase("RECUPERANDO ALTURA SEGURA")
        if not Nav.voo(ctx) then return false end
        local seguro = Nav.estado.seguro or Nav.estado.ancora
        if not seguro then
            seguro = ctx.root.Position+Vector3.new(0,20,0)
        end
        seguro = Vector3.new(seguro.X,
            math.max(seguro.Y,workspace.FallenPartsDestroyHeight+30),
            seguro.Z)
        local resultado = Nav.moverVoo(ctx,seguro,{
            limite = 6,
            tolerancia = 3,
            recuperacao = true,
        })
        return resultado == "chegou"
    end

    -- Cobertura global: limites observados, bordas, grade e fronteira expansiva.
    -- Sem reiniciar a busca no raio local de oito aneis.
    Nav.mundoCfg = {
        celula=80, trecho=280, maxRaio=32768,
        maxVisitados=2048, revisita=8, pausaFalha=25,
        intervaloCarga=2, timeoutCarga=1.5, intervaloCantos=20,
        candidatosPorPasso=24, margem=12, teleporte=true, pausaTeleporte=0.15,
    }
    function Nav.mundoNovo()
        Nav.mundo = {
            limites=nil, origem=nil, alvo=nil, versao=0, fila={},
            cantosVersao=-1, ultCantos=-math.huge, visitados={}, total=0,
            ix=nil, iz=nil, sentido=1, voltas=0, planos=0,
            espiral={x=0,z=0,dx=1,dz=0,tamanho=1,andou=0,viradas=0},
            carregando=false, proximaCarga=0, cargas=0, errosCarga=0,
            token={}, ultimaLimpeza=0, proximaFronteira=0, fonte="exploracao",
        }
        return Nav.mundo
    end
    function Nav.mundoEstado()
        return Nav.mundo or Nav.mundoNovo()
    end
    function Nav.mundoLimites(minimo,maximo,fonte)
        if not Nav.vetorValido(minimo) or not Nav.vetorValido(maximo) then return false end
        if minimo.X>maximo.X or minimo.Y>maximo.Y or minimo.Z>maximo.Z then return false end
        if maximo.X-minimo.X>Nav.mundoCfg.maxRaio*2
            or maximo.Z-minimo.Z>Nav.mundoCfg.maxRaio*2 then return false end
        local m = Nav.mundoEstado()
        local b = m.limites
        if b and b.explicito and fonte~="atributos" then return false end
        if b and b.explicito and fonte=="atributos"
            and b.minX==minimo.X and b.maxX==maximo.X
            and b.minY==minimo.Y and b.maxY==maximo.Y
            and b.minZ==minimo.Z and b.maxZ==maximo.Z then return true end
        if not b or fonte=="atributos" then
            b={minX=minimo.X,maxX=maximo.X,minZ=minimo.Z,maxZ=maximo.Z,
                minY=minimo.Y,maxY=maximo.Y,explicito=fonte=="atributos"}
            m.limites=b
            m.versao=m.versao+1
        else
            local x1,x2,z1,z2=b.minX,b.maxX,b.minZ,b.maxZ
            b.minX=math.min(b.minX,minimo.X)
            b.maxX=math.max(b.maxX,maximo.X)
            b.minZ=math.min(b.minZ,minimo.Z)
            b.maxZ=math.max(b.maxZ,maximo.Z)
            b.minY=math.min(b.minY,minimo.Y)
            b.maxY=math.max(b.maxY,maximo.Y)
            if x1~=b.minX or x2~=b.maxX or z1~=b.minZ or z2~=b.maxZ then
                m.versao=m.versao+1
            end
        end
        m.fonte=fonte or "geometria carregada"
        return true
    end
    function Nav.mundoObservar(obj)
        local ok = pcall(function()
            if not obj:IsA("BasePart") or not obj.Anchored or not obj.CanCollide then return end
            if not obj:IsDescendantOf(workspace) then return end
            local modelo = obj:FindFirstAncestorOfClass("Model")
            while modelo do
                if modelo:FindFirstChildOfClass("Humanoid") then return end
                modelo = modelo:FindFirstAncestorOfClass("Model")
            end
            local pos,tam = obj.Position,obj.Size
            if not Nav.vetorValido(pos) or not Nav.vetorValido(tam) then return end
            if tam.Magnitude<4 or tam.Magnitude>Nav.mundoCfg.maxRaio*2 then return end
            if pos.Y<=workspace.FallenPartsDestroyHeight+20 then return end
            local cf = obj.CFrame
            local rx,uy,lz = cf.RightVector,cf.UpVector,cf.LookVector
            local ext
            if rx and uy and lz then
                ext=Vector3.new(
                    (math.abs(rx.X)*tam.X+math.abs(uy.X)*tam.Y+math.abs(lz.X)*tam.Z)/2,
                    (math.abs(rx.Y)*tam.X+math.abs(uy.Y)*tam.Y+math.abs(lz.Y)*tam.Z)/2,
                    (math.abs(rx.Z)*tam.X+math.abs(uy.Z)*tam.Y+math.abs(lz.Z)*tam.Z)/2)
            else
                ext=tam*0.5
            end
            Nav.mundoLimites(pos-ext,pos+ext,"geometria carregada")
        end)
        return ok
    end
    function Nav.mundoAtributos()
        local ok,mi,ma = pcall(function()
            return workspace:GetAttribute("FarmMapMin"),workspace:GetAttribute("FarmMapMax")
        end)
        if ok and mi and ma then return Nav.mundoLimites(mi,ma,"atributos") end
        return false
    end
    function Nav.mundoChave(pos)
        -- Cantos diferentes nao devem compartilhar o bloqueio de um setor inteiro.
        local c=16
        return math.floor(pos.X/c)..":"..math.floor(pos.Z/c)
    end
    function Nav.mundoRegistrar(pos,falha)
        local m=Nav.mundoEstado()
        local chave=Nav.mundoChave(pos)
        if not m.visitados[chave] then m.total=m.total+1 end
        m.visitados[chave]={hora=os.clock(),falha=falha==true,pos=pos}
        if m.total>Nav.mundoCfg.maxVisitados then
            local lista={}
            for k,v in pairs(m.visitados) do table.insert(lista,{chave=k,hora=v.hora}) end
            table.sort(lista,function(a,b) return a.hora<b.hora end)
            for i=1,#lista-Nav.mundoCfg.maxVisitados do
                m.visitados[lista[i].chave]=nil
                m.total=m.total-1
            end
        end
    end
    function Nav.mundoDisponivel(pos)
        if not Nav.vetorValido(pos) then return false end
        local m=Nav.mundoEstado()
        local antigo=m.visitados[Nav.mundoChave(pos)]
        if not antigo then return true end
        local prazo=antigo.falha and Nav.mundoCfg.pausaFalha or Nav.mundoCfg.revisita
        return os.clock()-antigo.hora>=prazo
    end
    function Nav.mundoCantos()
        local m=Nav.mundoEstado()
        local b=m.limites
        if not b then return end
        if m.cantosVersao==m.versao then return end
        if os.clock()-m.ultCantos<Nav.mundoCfg.intervaloCantos then return end
        m.cantosVersao=m.versao
        m.ultCantos=os.clock()
        local margem=Nav.mundoCfg.margem
        local x1=math.min(b.minX+margem,(b.minX+b.maxX)/2)
        local x2=math.max(b.maxX-margem,(b.minX+b.maxX)/2)
        local z1=math.min(b.minZ+margem,(b.minZ+b.maxZ)/2)
        local z2=math.max(b.maxZ-margem,(b.minZ+b.maxZ)/2)
        local cx,cz=(x1+x2)/2,(z1+z2)/2
        local y=m.origem.Y+Nav.cfg.alturaPatrulha
        m.fila={
            Vector3.new(x2,y,z2),Vector3.new(x1,y,z1),
            Vector3.new(x2,y,z1),Vector3.new(x1,y,z2),
            Vector3.new(cx,y,z2),Vector3.new(cx,y,z1),
            Vector3.new(x2,y,cz),Vector3.new(x1,y,cz),
        }
    end
    function Nav.mundoGrade()
        local m=Nav.mundoEstado()
        local b=m.limites
        if not b then return nil end
        local c=Nav.mundoCfg.celula
        local x1,x2=math.floor(b.minX/c),math.ceil(b.maxX/c)
        local z1,z2=math.floor(b.minZ/c),math.ceil(b.maxZ/c)
        if not m.ix or not m.iz or m.iz<z1 or m.iz>z2 or m.ix<x1 or m.ix>x2 then
            m.ix=x1
            m.iz=z1
            m.sentido=1
        end
        local ix,iz=m.ix,m.iz
        m.ix=m.ix+m.sentido
        if m.ix>x2 or m.ix<x1 then
            m.iz=m.iz+1
            m.sentido=-m.sentido
            m.ix=m.sentido>0 and x1 or x2
            if m.iz>z2 then
                m.iz=z1
                m.ix=x1
                m.sentido=1
                m.voltas=m.voltas+1
            end
        end
        return Vector3.new(
            math.clamp(ix*c,b.minX+math.min(12,(b.maxX-b.minX)/2),b.maxX-math.min(12,(b.maxX-b.minX)/2)),
            m.origem.Y+Nav.cfg.alturaPatrulha,
            math.clamp(iz*c,b.minZ+math.min(12,(b.maxZ-b.minZ)/2),b.maxZ-math.min(12,(b.maxZ-b.minZ)/2)))
    end
    function Nav.mundoFronteira()
        local m=Nav.mundoEstado()
        local e=m.espiral
        local pos=m.origem+Vector3.new(e.x*Nav.mundoCfg.celula,Nav.cfg.alturaPatrulha,e.z*Nav.mundoCfg.celula)
        e.x=e.x+e.dx
        e.z=e.z+e.dz
        e.andou=e.andou+1
        if e.andou>=e.tamanho then
            e.andou=0
            e.dx,e.dz=-e.dz,e.dx
            e.viradas=e.viradas+1
            if e.viradas%2==0 then e.tamanho=e.tamanho+1 end
        end
        if math.max(math.abs(e.x),math.abs(e.z))*Nav.mundoCfg.celula>Nav.mundoCfg.maxRaio then
            -- Limite numerico configuravel, nao o antigo limite local de 720.
            m.espiral={x=0,z=0,dx=1,dz=0,tamanho=1,andou=0,viradas=0}
        end
        return pos
    end
    -- Se a grade estiver em cooldown, continua a ronda pelos pontos ja confirmados.
    -- Falhas mantem sua pausa: nunca recicla um destino rejeitado como se fosse seguro.
    -- Busca local funciona mesmo quando Terrain/streaming ainda nao gerou limites.
    -- Os candidatos usam o mesmo teste de piso e os limites X/Z explicitos.
    function Nav.mundoExplorarPerto(ctx)
        local m=Nav.mundoEstado()
        local origem=ctx.root.Position
        local melhor,custo
        local agora=os.clock()
        local setor=m.setorLocal or 0
        local raio=32+32*((m.anelLocal or 0)%3)
        m.setorLocal=(setor+1)%12
        m.anelLocal=(m.anelLocal or 0)+1
        for i=0,11 do
            local angulo=(i+setor)*math.pi/6
            local ponto=origem+Vector3.new(math.cos(angulo)*raio,0,math.sin(angulo)*raio)
            local antigo=m.visitados[Nav.mundoChave(ponto)]
            if not antigo or (not antigo.falha and agora-antigo.hora>=0.25)
                or (antigo.falha and agora-antigo.hora>=Nav.mundoCfg.pausaFalha) then
                local seguro=Nav.destinoPatrulha(ctx,ponto)
                if seguro and Nav.distanciaHorizontal(origem,seguro)>=12 then
                    local v=m.visitados[Nav.mundoChave(seguro)]
                    if not v or not v.falha or agora-v.hora>=Nav.mundoCfg.pausaFalha then
                        local nota=v and v.hora or -math.huge
                        if not melhor or nota<custo then
                            melhor,custo=seguro,nota
                        end
                    end
                end
            end
        end
        if melhor then
            m.alvo=melhor
            R.motivoPatrulha="BUSCA LOCAL ATIVA"
            return melhor
        end
        return nil
    end

    function Nav.mundoRevisitar(ctx)
        local m=Nav.mundoEstado()
        local candidatos={}
        local agora=os.clock()
        for _,v in pairs(m.visitados) do
            if not v.falha and Nav.vetorValido(v.pos)
                and agora-v.hora>=0.75
                and Nav.distanciaHorizontal(ctx.root.Position,v.pos)>=12 then
                table.insert(candidatos,v)
            end
        end
        table.sort(candidatos,function(a,b) return a.hora<b.hora end)
        for i=1,math.min(8,#candidatos) do
            local v=candidatos[i]
            local seguro=Nav.destinoPatrulha(ctx,v.pos)
            if seguro then
                m.alvo=seguro
                return seguro
            end
            Nav.mundoPedirCarga(ctx,v.pos)
            Nav.mundoRegistrar(v.pos,true)
        end
        return nil
    end

    function Nav.mundoEscolher(ctx)
        local m=Nav.mundoEstado()
        if m.alvo then return m.alvo end
        m.origem=m.origem or Nav.estado.ancora or ctx.root.Position
        Nav.mundoCantos()
        for _=1,Nav.mundoCfg.candidatosPorPasso do
            local pos
            if #m.fila>0 then
                pos=table.remove(m.fila,1)
            else
                m.planos=m.planos+1
                -- Geometria conhecida define candidatos, nunca autoriza voar no vazio.
                -- Streaming pendente e consultado sem mover o personagem.
                pos=Nav.mundoGrade()
            end
            if pos and Nav.mundoDisponivel(pos) then
                local seguro=Nav.destinoPatrulha(ctx,pos)
                if not seguro then
                    Nav.mundoPedirCarga(ctx,pos)
                    Nav.mundoRegistrar(pos,true)
                elseif Nav.distanciaHorizontal(ctx.root.Position,seguro)<12 then
                    Nav.mundoRegistrar(seguro,false)
                else
                    m.alvo=seguro
                    return seguro
                end
            end
        end
        return Nav.mundoExplorarPerto(ctx) or Nav.mundoRevisitar(ctx)
    end
    function Nav.mundoPedirCarga(ctx,pos)
        if not workspace.StreamingEnabled then return false end
        local m=Nav.mundoEstado()
        if m.carregando or os.clock()<m.proximaCarga then return false end
        if not Nav.vetorValido(pos) or not Nav.vivo(ctx) then return false end
        m.proximaCarga=os.clock()+Nav.mundoCfg.intervaloCarga
        m.carregando=true
        local token=m.token
        GS.spawn(function()
            if Nav.mundo~=m or m.token~=token or not Nav.vivo(ctx) then
                m.carregando=false
                return
            end
            local ok,erro=pcall(function()
                LocalPlayer:RequestStreamAroundAsync(pos,Nav.mundoCfg.timeoutCarga)
            end)
            m.carregando=false
            if Nav.mundo~=m or m.token~=token or not Nav.vivo(ctx) then return end
            if ok then
                m.cargas=m.cargas+1
                R.sujo=true
            else
                m.errosCarga=m.errosCarga+1
                if m.errosCarga==1 then
                    registrar("CARREGAMENTO","Pedido indisponivel; patrulha continua pelo carregamento normal: "..tostring(erro))
                end
            end
        end)
        return true
    end
    -- A altura de voo nao e um limite do mapa. Valida X/Z e o piso no destino.
    function Nav.destinoPatrulha(ctx,ponto)
        if not Nav.vetorValido(ponto) then return nil end
        local b=Nav.mundoEstado().limites
        if b and b.explicito and (ponto.X<b.minX or ponto.X>b.maxX
            or ponto.Z<b.minZ or ponto.Z>b.maxZ) then return nil end
        return Nav.sondarPatrulha(ctx,ponto)
    end

    function Nav.mundoTrecho(ctx,meta)
        if Nav.mundoCfg.teleporte and os.clock()>=Nav.cfg.bloquearRapidoAte then
            local seguro=Nav.destinoPatrulha(ctx,meta)
            if not seguro then
                Nav.mundoPedirCarga(ctx,meta)
                Nav.mundoRegistrar(meta,true)
                Nav.mundoEstado().alvo=nil
            end
            return seguro
        end
        local delta=meta-ctx.root.Position
        if delta.Magnitude<0.01 then return Nav.destinoPatrulha(ctx,meta) end
        local bruto=ctx.root.Position+delta.Unit*math.min(delta.Magnitude,Nav.mundoCfg.trecho)
        -- Sem piso confirmado: aguarda streaming, sem fabricar destino no vazio.
        local sondado=Nav.destinoPatrulha(ctx,bruto)
        if not sondado then
            Nav.mundoPedirCarga(ctx,bruto)
            Nav.mundoRegistrar(meta,true)
            Nav.mundoEstado().alvo=nil
        end
        return sondado
    end

    function Nav.teleportarPatrulha(ctx,destino)
        if not Nav.mundoCfg.teleporte or os.clock()<Nav.cfg.bloquearRapidoAte then
            return "indisponivel"
        end
        if not Nav.vivo(ctx) or ctx.root.Anchored then return "cancelado" end
        local seguro=Nav.destinoPatrulha(ctx,destino)
        if not seguro then return "sem_suporte" end
        if not Nav.voo(ctx) then return "sem_movimento" end
        Nav.zerar(ctx)
        local ok=pcall(function()
            ctx.root.CFrame=ctx.root.CFrame+(seguro-ctx.root.Position)
        end)
        if not ok then
            Nav.cfg.bloquearRapidoAte=os.clock()+15
            return "indisponivel"
        end
        if not Nav.esperar(ctx,Nav.mundoCfg.pausaTeleporte) then return "cancelado" end
        if (ctx.root.Position-seguro).Magnitude>24 then
            Nav.cfg.bloquearRapidoAte=os.clock()+15
            registrar("PATRULHA","Deslocamento corrigido pelo servidor; retomando voo.")
            return "corrigido"
        end
        Nav.zerar(ctx)
        Nav.salvarSeguro(ctx)
        return "chegou"
    end

    function Nav.mundoConcluir(ctx,resultado)
        local m=Nav.mundoEstado()
        if not m.alvo or resultado=="alvo_detectado" or resultado=="cancelado" then return end
        if resultado=="chegou" then
            if Nav.distanciaHorizontal(ctx.root.Position,m.alvo)<=16 then
                Nav.mundoRegistrar(m.alvo,false)
                m.alvo=nil
            end
        else
            Nav.mundoRegistrar(m.alvo,true)
            m.alvo=nil
        end
    end
    function Nav.mundoInspecionar()
        local m=Nav.mundoEstado()
        return {alvo=m.alvo,limites=m.limites,fonte=m.fonte,
            visitados=m.total,voltas=m.voltas,cargas=m.cargas,
            errosCarga=m.errosCarga,carregando=m.carregando,
            fronteiraX=m.espiral.x,fronteiraZ=m.espiral.z}
    end
    R.observarMapa=Nav.mundoObservar
    function Nav.inicializarPatrulha(ctx)
        if Nav.estado.ancora then return end
        Nav.estado.ancora = ctx.root.Position
        Nav.estado.seguro = ctx.root.Position
        Nav.estado.setor = 0
        Nav.estado.anel = 1
        Nav.salvarSeguro(ctx)
        Nav.mundoEstado().origem = ctx.root.Position
        Nav.mundoAtributos()
    end

    function Nav.proximoAnel()
        Nav.estado.setor = Nav.estado.setor+1
        if Nav.estado.setor >= Nav.cfg.setores then
            Nav.estado.setor = 0
            Nav.estado.anel = Nav.estado.anel+1
            if Nav.estado.anel > Nav.cfg.maxAnel then
                Nav.estado.anel = 1
            end
        end
        Nav.estado.passos = Nav.estado.passos+1
    end

    function Nav.pontoAnel()
        local ancora = Nav.estado.ancora
        if not ancora then return end
        local raio = Nav.cfg.raioPatrulha*Nav.estado.anel
        local angulo = Nav.estado.setor*math.pi*2/Nav.cfg.setores
        local deslocamento = Vector3.new(
            math.cos(angulo)*raio,
            Nav.cfg.alturaPatrulha,
            math.sin(angulo)*raio)
        local ponto = ancora+deslocamento
        Nav.proximoAnel()
        return ponto
    end

    function Nav.pontoConhecido(ctx)
        local melhor
        local custo
        local agora = os.clock()
        for chave,m in pairs(Nav.estado.memoria) do
            local ultima = Nav.estado.visita[chave] or -math.huge
            if agora-ultima >= Nav.cfg.tempoRevisita then
                local d = (ctx.root.Position-m.pos).Magnitude
                if not custo or d < custo then
                    custo = d
                    melhor = m.pos
                end
            end
        end
        return melhor
    end

    function Nav.sondarPatrulha(ctx,ponto)
        if not Nav.vetorValido(ponto) then return end
        -- Primeiro sonda perto da altura atual; cenarios muito altos nao devem
        -- esconder o terreno local nem obrigar a aguardar a grade global.
        local localOrigem=Vector3.new(ponto.X,math.max(ponto.Y,ctx.root.Position.Y)+32,ponto.Z)
        local localHit=Nav.raio(localOrigem,Vector3.new(0,-512,0),ctx,nil)
        if localHit and localHit.Normal.Y>=Nav.cfg.normalMinima
            and localHit.Position.Y>workspace.FallenPartsDestroyHeight+20 then
            return localHit.Position+Vector3.new(0,Nav.cfg.alturaPatrulha,0)
        end
        local altura = math.max(ponto.Y,ctx.root.Position.Y)+100
        local limites = Nav.mundoEstado().limites
        if limites then altura=math.max(altura,limites.maxY+64) end
        local origem = Vector3.new(ponto.X,altura,ponto.Z)
        local profundidade = limites and math.clamp(altura-limites.minY+128,500,8192) or 500
        local hit = Nav.raio(origem,Vector3.new(0,-profundidade,0),ctx,nil)
        if not hit then return end
        if hit.Normal.Y < Nav.cfg.normalMinima then return end
        if hit.Position.Y <= workspace.FallenPartsDestroyHeight+20 then return end
        local destino = hit.Position+Vector3.new(0,Nav.cfg.alturaPatrulha,0)
        return destino
    end

    function Nav.planoPatrulha(ctx)
        Nav.inicializarPatrulha(ctx)
        Nav.observarItens()
        local mundo=Nav.mundoEstado()
        if os.clock()>=(mundo.proximoAtributo or 0) then
            mundo.proximoAtributo=os.clock()+10
            Nav.mundoAtributos()
        end
        local meta=Nav.mundoEscolher(ctx)
        if not meta then return nil end
        return Nav.mundoTrecho(ctx,meta)
    end

    function Nav.patrulhar(g,a)
        local ctx = Nav.contexto(g,a)
        if not ctx then return end
        Nav.inicializarPatrulha(ctx)
        local e = Nav.escolher(ctx)
        if e then return end
        Nav.fase("VARRENDO MAPA · TELEPORTE ENTRE SETORES SEGUROS")
        local destino = Nav.planoPatrulha(ctx)
        if not destino then
            if Nav.voo(ctx) then Nav.zerar(ctx) end
            R.motivoPatrulha="SEM PISO: GRADE, BUSCA LOCAL E REVISITAS"
            Nav.fase(R.motivoPatrulha)
            Nav.esperar(ctx,0.05)
            return
        end
        Nav.mundoPedirCarga(ctx,destino)
        local chave = Nav.chave(destino)
        local resultado = Nav.teleportarPatrulha(ctx,destino)
        if resultado=="indisponivel" then
            resultado=Nav.moverVoo(ctx,destino,{
                patrulha = true,
                limite = Nav.cfg.limitePatrulha,
                tolerancia = 4,
            })
        end
        if not Nav.vivo(ctx) then return end
        if resultado == "alvo_detectado" then
            Nav.fase("FRASCO DETECTADO · INTERROMPENDO PATRULHA")
            return
        end
        Nav.mundoConcluir(ctx,resultado)
        Nav.estado.visita[chave] = os.clock()
        Nav.estado.patrulhas = Nav.estado.patrulhas+1
        if resultado == "void" then
            Nav.recuperar(ctx)
        elseif resultado ~= "chegou" then
            Nav.estado.recuperacoes = Nav.estado.recuperacoes+1
            local acima = ctx.root.Position+Vector3.new(0,8,0)
            Nav.moverVoo(ctx,acima,{
                patrulha = true,
                limite = 3,
                tolerancia = 2,
            })
        end
        if Nav.vivo(ctx) then
            R.sujo = true
            Nav.esperar(ctx,0.05)
        end
    end

    function Nav.passo(g,a)
        local ctx = Nav.contexto(g,a)
        if not ctx then
            Nav.parar()
            GS.farmaDirecao = Vector3.zero
            Nav.fase("AGUARDANDO PERSONAGEM")
            return
        end
        if ctx.root.Anchored then
            Nav.fase("AGUARDANDO PERSONAGEM DESANCORAR")
            return
        end
        local e = Nav.escolher(ctx)
        if e then
            R.alvo = e.obj
            Nav.buscar(e,g,a)
        else
            R.alvo = nil
            Nav.patrulhar(g,a)
        end
    end

    local function desligarAuto()
        if not R.auto and not R.salvo then return end
        R.auto = false
        R.cicloAuto = R.cicloAuto+1
        R.alvo = nil
        Nav.pararAtividade()
        Nav.parar()
        restaurarMovimento()
        if GS.noclipArquivo then GS.noclipArquivo.liberar("frascos") end
        autoBtn.Text = "AUTOMÁTICO: OFF"
        R.fase = R.monitor and "MONITORANDO" or "DESLIGADO"
    end

    local function iniciarAuto()
        if R.auto then return end
        if GS.pararFarmaLucky then GS.pararFarmaLucky() end
        if GS.pararFarmaNome then GS.pararFarmaNome() end
        if GS.pararFarmaTesouro then GS.pararFarmaTesouro() end
        R.auto = true
        R.cicloAuto = R.cicloAuto+1
        local g,a = R.geracao,R.cicloAuto
        Nav.reset()
        Nav.iniciarAtividade(g,a)
        salvarMovimento()
        if GS.noclipArquivo then GS.noclipArquivo.ativar("frascos") end
        autoBtn.Text = "AUTOMÁTICO: ON · VOO 500"
        registrar("AUTO","Patrulha em voo 500; rotas por altura, laterais, pouso e pulos.")
        GS.spawn(function()
            while autoVivo(g,a) do
                local ok,err = pcall(function()
                    Nav.passo(g,a)
                end)
                if not autoVivo(g,a) then break end
                R.alvo = nil
                if not ok then
                    warn("[DEBUG-BOT]: Farma:",err)
                    Nav.liberarPrompt()
                    GS.farmaDirecao = Vector3.zero
                    local ctx = Nav.contexto(g,a)
                    if ctx then
                        local recuperou,erro = pcall(Nav.recuperar,ctx)
                        if not recuperou then warn("[DEBUG-BOT]: Recuperação:",erro) end
                    end
                    R.fase = "ERRO AUTO: " .. tostring(err):sub(1,140)
                end
                task.wait(0.02)
            end
        end)
    end

    local function iniciarMonitor()
        if R.monitor then return end
        R.monitor = true
        R.geracao = R.geracao+1
        R.inicial = true
        R.sujo = true
        R.ultimaPos = nil
        R.gui = GS.novaInstancia("Folder")
        R.gui.Name = "FarmaMarcadores"
        R.gui.Parent = ScreenGui
        local g = R.geracao
        monitorBtn.Text = "DETECÇÃO: ON · FILTRO EXATO V5"
        R.fase = "MONITORANDO"
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _,obj in ipairs(backpack:GetChildren()) do
                if obj:IsA("Tool") then R.ferramentas[obj]=true end
            end
            table.insert(R.conns,GS.conectar(backpack.ChildAdded,inventario))
        end
        if LocalPlayer.Character then ligarInventario(LocalPlayer.Character) end
        table.insert(R.conns,GS.conectar(LocalPlayer.CharacterAdded,function(char)
            if mesmoCiclo(g) then ligarInventario(char) end
        end))
        table.insert(R.conns,GS.conectar(workspace.DescendantAdded,function(obj)
            if not mesmoCiclo(g) then return end
            if R.observarMapa then R.observarMapa(obj) end
            R.sujo = true
            R.pendentes[obj] = os.clock()+1
            GS.defer(function()
                if mesmoCiclo(g) then
                    local ok,err=pcall(examinar,obj,g,R.inicial)
                    if not ok then warn("[DEBUG-BOT]: Registro:",err) end
                end
            end)
        end))
        registrar("MONITOR","Ativo; somente PotionTemplate. Histórico não determina a regra do servidor.")
        GS.spawn(function()
            local ultima = 0
            while mesmoCiclo(g) do
                local ok,err = pcall(function()
                    for obj,prazo in pairs(R.pendentes) do
                        if os.clock() >= prazo then
                            R.pendentes[obj]=nil
                            examinar(obj,g,R.inicial)
                        end
                    end
                    if (R.sujo and os.clock()-ultima>=0.75) or os.clock()-ultima >= CFG.intervaloScan then
                        varrer(g)
                        ultima = os.clock()
                    end
                    if not mesmoCiclo(g) then return end
                    local _,_,root = personagem()
                    if root then
                        R.movimento = R.ultimaPos and (root.Position-R.ultimaPos).Magnitude or 0
                        R.ultimaPos = root.Position
                        local achados = listar(root)
                        desenhar(achados)
                        atualizarResumo(#achados)
                    else
                        R.fase = "AGUARDANDO PERSONAGEM"
                        atualizarResumo(0)
                    end
                end)
                if not ok then warn("[DEBUG-BOT]: Monitor:",err) end
                task.wait(CFG.intervaloUI)
            end
        end)
    end

    local function pararMonitor()
        desligarAuto()
        R.monitor = false
        R.geracao = R.geracao+1
        for _,conn in ipairs(R.conns) do conn:Disconnect() end
        table.clear(R.conns)
        table.clear(R.itens)
        table.clear(R.pendentes)
        table.clear(R.personagens)
        if R.gui then R.gui:Destroy(); R.gui=nil end
        monitorBtn.Text = "DETECÇÃO: OFF"
        status.Text = "DESLIGADO"
        locais.Text = "Monitoramento desligado."
    end

    GS.pararFarmaFrascos = desligarAuto
    GS.conectar(monitorBtn.MouseButton1Click,function()
        if R.monitor then pararMonitor() else iniciarMonitor() end
    end)
    GS.conectar(autoBtn.MouseButton1Click,function()
        if R.auto then
            desligarAuto()
        else
            iniciarMonitor()
            iniciarAuto()
        end
    end)
    GS.conectar(ScreenGui.Destroying,function()
        R.destruindo = true
        pararMonitor()
    end)
end
GS.rodar("Farmar Vibes", GS.iniciarFarma, GS.painelFarma)

-- Lucky Blocks: busca independente na mesma tela da farma de frascos.
GS.iniciarFarmaLucky = function()
    local U,painel = GS.ui,GS.painelFarmaLucky or GS.painelFarma
    if not U or not painel then return end
    local Chat = game:GetService("TextChatService")
    local L = {
        ligado=false, auto=false, geracao=0, ciclo=0, itens={}, conns={},
        espera=setmetatable({}, {__mode="k"}), salvo=nil, gui=nil,
        aviso="Nenhum aviso observado.", candidatos={}, examinados=0,
        scanEm=0, alvo=nil, fase="DESLIGADO", segurando=nil,
        tentativas=0, interacoes=0, sinais=setmetatable({}, {__mode="k"}),
    }
    U.sec(painel,"FARMA · FIRE LUCKY BLOCK · V2","package",20)
    local detectar = U.tog(painel,"PROCURAR LUCKY BLOCKS",21)
    detectar:SetAttribute("Controlado",true)
    detectar.Text="LUCKY BLOCKS: OFF"
    local automatico = U.tog(painel,"IR ATÉ O LUCKY BLOCK · TELEPORTE",22)
    automatico:SetAttribute("Controlado",true)
    automatico.Text="AUTO LUCKY: OFF"
    local busca = U.acao(painel,"REFAZER BUSCA COMPLETA","scan-search",23)
    local info = GS.novaInstancia("TextLabel")
    info.Size=UDim2.new(1,-16,0,130)
    info.LayoutOrder=24
    info.BackgroundTransparency=1
    info.TextColor3=U.T.text
    info.Font=Enum.Font.GothamMedium
    info.TextSize=12
    info.TextWrapped=true
    info.TextXAlignment=Enum.TextXAlignment.Left
    info.TextYAlignment=Enum.TextYAlignment.Top
    info.Text="Busca separada dos frascos. Avisos do chat iniciam nova varredura."
    info.Parent=painel

    local function normalizar(s)
        return string.lower(s):gsub("[^%w]","")
    end
    local function nomeLucky(s)
        local n=normalizar(s)
        return n:find("luckyblock",1,true)~=nil
            or n:find("luckblock",1,true)~=nil
            or n:find("lockblock",1,true)~=nil
    end
    local function promptDe(obj)
        for _,desc in ipairs(obj:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and nomeLucky(desc.ObjectText) then return desc end
        end
    end
    local function posPrompt(prompt,base)
        local pai=prompt and prompt.Parent
        if pai and pai:IsA("Attachment") then return pai.WorldPosition end
        if pai and pai:IsA("BasePart") then return pai.Position end
        if pai and pai:IsA("Model") then return pai:GetPivot().Position end
        return base.Position
    end
    local function personagem()
        local char=LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health>0 then return char,hum,root end
    end
    local function parte(obj)
        if obj:IsA("BasePart") then return obj end
        return obj:FindFirstChildWhichIsA("BasePart",true)
    end
    local function dePersonagem(obj)
        local p=obj
        while p and p~=workspace do
            if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") then return true end
            p=p.Parent
        end
        return false
    end
    local function vivo(g)
        return L.ligado and L.geracao==g and ScreenGui.Parent~=nil
    end
    local function autoVivo(g,c)
        return vivo(g) and L.auto and L.ciclo==c
    end
    local function avaliar(obj)
        local alvo=obj
        local prompt
        local corresponde=nomeLucky(obj.Name)
        if obj:IsA("ProximityPrompt") then
            prompt=obj
            corresponde=corresponde or nomeLucky(obj.ObjectText)
            alvo=obj.Parent
            if alvo and alvo:IsA("Attachment") then alvo=alvo.Parent end
        elseif obj:IsA("ClickDetector") then
            alvo=obj.Parent
            corresponde=corresponde or (alvo and nomeLucky(alvo.Name))
        elseif not (obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Tool")) then
            return
        end
        if not corresponde or not alvo or alvo==workspace then return end
        if dePersonagem(alvo) then return end
        local p=alvo.Parent
        while p and p~=workspace do
            if (p:IsA("Model") or p:IsA("Tool")) and nomeLucky(p.Name) then alvo=p end
            p=p.Parent
        end
        if not (alvo:IsA("Model") or alvo:IsA("Tool") or alvo:IsA("BasePart")) then return end
        local n=normalizar(alvo.Name)
        -- Spawners e pastas de templates nao sao o bloco coletavel.
        if n:find("spawner",1,true) or n:find("spawnpoint",1,true) then return end
        local base=parte(alvo)
        if not base then return end
        if alvo:IsA("Model") and alvo:GetExtentsSize().Magnitude>60 then return end
        prompt=prompt or promptDe(alvo)
        return alvo,base,prompt
    end
    local function adicionar(obj,base,prompt)
        if L.itens[obj] then
            if prompt then L.itens[obj].prompt=prompt end
            return
        end
        for outro,it in pairs(L.itens) do
            if obj:IsDescendantOf(outro) then return end
            if outro:IsDescendantOf(obj) then it.gui:Destroy(); L.itens[outro]=nil end
        end
        local gui=GS.novaInstancia("BillboardGui")
        gui.Name="LuckyLocal"
        gui.Adornee=base
        gui.Size=UDim2.fromOffset(174,38)
        gui.StudsOffsetWorldSpace=Vector3.new(0,3,0)
        gui.AlwaysOnTop=true
        gui.MaxDistance=0
        gui.Enabled=false
        gui.Parent=L.gui
        local label=GS.novaInstancia("TextLabel")
        label.Size=UDim2.fromScale(1,1)
        label.BackgroundColor3=Color3.fromRGB(35,22,8)
        label.BackgroundTransparency=0.2
        label.TextColor3=Color3.fromRGB(255,211,118)
        label.TextSize=12
        label.Font=Enum.Font.GothamBold
        label.TextWrapped=true
        label.Parent=gui
        GS.novaInstancia("UICorner",label).CornerRadius=UDim.new(0,8)
        L.itens[obj]={base=base,gui=gui,label=label,prompt=prompt}
        print("[DEBUG-LUCKY]: Encontrado",obj:GetFullName())
    end
    local function varrer(g)
        L.examinados=0
        L.candidatos={}
        L.scanEm=os.clock()+5
        local nomes={}
        for i,obj in ipairs(workspace:GetDescendants()) do
            if not vivo(g) then return end
            L.examinados=i
            local ok,alvo,base,prompt=pcall(avaliar,obj)
            if ok and alvo then adicionar(alvo,base,prompt) end
            local n=normalizar(obj.Name)
            if #L.candidatos<5 and (n:find("redfire",1,true) or n:find("lucky",1,true))
                and not nomes[obj.Name] and (obj:IsA("Model") or obj:IsA("BasePart")) then
                nomes[obj.Name]=true
                table.insert(L.candidatos,obj:GetFullName())
            end
            if i%300==0 then task.wait() end
        end
        print("[DEBUG-LUCKY]: Busca completa:",L.examinados,"objetos examinados")
        if vivo(g) then L.scanEm=os.clock()+5 end
    end
    local function listar()
        local _,_,root=personagem()
        local lista={}
        for obj,it in pairs(L.itens) do
            if not obj:IsDescendantOf(workspace) or dePersonagem(obj) then
                it.gui:Destroy()
                L.itens[obj]=nil
            else
                local base=parte(obj)
                if base then
                    it.base=base
                    it.gui.Adornee=base
                    if not it.prompt or not it.prompt:IsDescendantOf(obj) then it.prompt=promptDe(obj) end
                    it.nome=it.prompt and it.prompt.ObjectText~="" and it.prompt.ObjectText or obj.Name
                    it.pos=posPrompt(it.prompt,base)
                    table.insert(lista,{obj=obj,it=it,d=root and (root.Position-it.pos).Magnitude or math.huge})
                end
            end
        end
        table.sort(lista,function(a,b) return a.d<b.d end)
        local linhas={L.fase.." | Examinados: "..L.examinados.." | Blocos: "..#lista,
            "Tentativas: "..L.tentativas.." | Interações observadas: "..L.interacoes,L.aviso}
        local camera=workspace.CurrentCamera
        local ocupados={}
        for i,e in ipairs(lista) do
            e.it.label.Text=string.format("%s\n%.0f studs",e.it.nome,e.d)
            local mostrar=false
            if camera and #ocupados<6 then
                local tela,visivel=camera:WorldToViewportPoint(e.it.base.Position+Vector3.new(0,3,0))
                mostrar=visivel and tela.Z>0
                if mostrar then
                    for _,p in ipairs(ocupados) do
                        if math.abs(tela.X-p.X)<184 and math.abs(tela.Y-p.Y)<44 then mostrar=false; break end
                    end
                    if mostrar then table.insert(ocupados,tela) end
                end
            end
            e.it.gui.Enabled=mostrar
            if i<=4 then table.insert(linhas,string.format("%s · %.0f studs",e.it.nome,e.d)) end
        end
        if #lista==0 then
            table.insert(linhas,"Nenhum bloco identificado entre os objetos carregados.")
            if #L.candidatos>0 then
                table.insert(linhas,"Nomes para diagnóstico (não são alvos confirmados):")
                for _,s in ipairs(L.candidatos) do table.insert(linhas,s) end
            end
            if workspace.StreamingEnabled then table.insert(linhas,"Streaming: objetos distantes podem estar ausentes.") end
        end
        info.Text=table.concat(linhas,"\n")
        return lista
    end
    local function restaurar()
        if not L.salvo then return end
        if L.segurando then
            pcall(function() L.segurando:InputHoldEnd() end)
            L.segurando=nil
        end
        L.holdToken=nil
        GS.farmaDirecao=nil
        if flyAtivado then alternarFly() end
        local salvo=L.salvo
        velocidadeVoo=salvo.voo
        if FlyLabel then FlyLabel.Text="VOO: "..velocidadeVoo end
        if speedAtivado~=salvo.speed then alternarSpeed() end
        if salvo.fly then alternarFly() end
        local _,hum,root=personagem()
        if hum then hum.WalkSpeed=salvo.walk; hum:MoveTo(root.Position) end
        L.salvo=nil
    end
    local function pararAuto()
        if not L.auto and not L.salvo then return end
        L.auto=false
        L.ciclo=L.ciclo+1
        L.alvo=nil
        restaurar()
        if GS.noclipArquivo then GS.noclipArquivo.liberar("lucky") end
        automatico.Text="AUTO LUCKY: OFF"
        L.fase="MONITORANDO LUCKY"
    end
    local function segurarPrompt(e,prompt,g,c)
        local _,hum,root=personagem()
        if not hum or not prompt.Enabled then return false end
        if (root.Position-posPrompt(prompt,e.it.base)).Magnitude>prompt.MaxActivationDistance then return false end
        local disparou=false
        local conn=GS.conectar(prompt.Triggered,function(player)
            if player==LocalPlayer and autoVivo(g,c) then
                disparou=true
                L.interacoes=L.interacoes+1
                print("[DEBUG-LUCKY]: Interação observada:",prompt.ObjectText)
            end
        end)
        L.tentativas=L.tentativas+1
        local token={}
        L.holdToken=token
        L.segurando=prompt
        hum:MoveTo(root.Position)
        local ok,err=pcall(function()
            prompt:InputHoldBegin()
            local duracao=prompt.HoldDuration
            local inicio=os.clock()
            while autoVivo(g,c) and prompt.Parent and prompt.Enabled do
                local _,atual,raiz=personagem()
                if atual~=hum then break end
                if (raiz.Position-posPrompt(prompt,e.it.base)).Magnitude>prompt.MaxActivationDistance then break end
                L.fase=string.format("ABRINDO %s · %.0f%%",prompt.ObjectText,
                    math.min(100,100*(os.clock()-inicio)/math.max(duracao,0.05)))
                if disparou or os.clock()-inicio>=duracao+0.3 then break end
                task.wait(0.05)
            end
        end)
        if L.holdToken==token then
            pcall(function() prompt:InputHoldEnd() end)
            L.segurando=nil
            L.holdToken=nil
        end
        if ok and autoVivo(g,c) then
            local fim=os.clock()+1
            while autoVivo(g,c) and not disparou and prompt.Parent and os.clock()<fim do task.wait(0.05) end
        end
        conn:Disconnect()
        if not ok then warn("[DEBUG-LUCKY]: Interação:",err) end
        return disparou
    end
    -- Chegada direta ao Lucky Block; nao substitui o tempo de abrir do prompt.
    local function teleportarLucky(e,g,c)
        local char,hum,root=personagem()
        if not char or not hum or not root or hum.Health<=0 then return false,"sem_personagem" end
        if root.Anchored then return false,"ancorado" end
        local function finito(v)
            return v and v.X==v.X and v.Y==v.Y and v.Z==v.Z
                and math.abs(v.X)<10000000 and math.abs(v.Y)<10000000 and math.abs(v.Z)<10000000
        end
        local parametros=RaycastParams.new()
        parametros.FilterType=Enum.RaycastFilterType.Exclude
        parametros.FilterDescendantsInstances={char,e.obj}
        parametros.IgnoreWater=true
        parametros.RespectCanCollide=true
        for tentativa=1,3 do
            if not autoVivo(g,c) or LocalPlayer.Character~=char then return false,"cancelado" end
            if not e.obj:IsDescendantOf(workspace) then return false,"retirado" end
            local base=parte(e.obj)
            if not base then return false,"sem_base" end
            local pos=posPrompt(e.it.prompt,base)
            if not finito(pos) or pos.Y<=workspace.FallenPartsDestroyHeight+20 then
                return false,"destino_invalido"
            end
            local alcance=e.it.prompt and e.it.prompt.MaxActivationDistance or 8
            if type(alcance)~="number" or alcance<=0 then return false,"sem_alcance" end
            local afastamento=math.min(3,math.max(0.5,alcance*0.4))
            local cf=base.CFrame
            local frente=cf and cf.LookVector or Vector3.new(0,0,-1)
            local direita=cf and cf.RightVector or Vector3.new(1,0,0)
            local direcao=tentativa==1 and frente or (tentativa==2 and direita or direita*-1)
            direcao=Vector3.new(direcao.X,0,direcao.Z)
            if direcao.Magnitude<0.01 then direcao=Vector3.new(0,0,-1) end
            local destino=pos+direcao.Unit*afastamento
            local hit=workspace:Raycast(destino+Vector3.new(0,12,0),Vector3.new(0,-64,0),parametros)
            if hit and hit.Normal.Y>0.45 then
                local altura=math.max(3,hum.HipHeight+root.Size.Y*0.5)
                local apoiado=Vector3.new(destino.X,hit.Position.Y+altura,destino.Z)
                -- Um piso muito abaixo do bloco nao e uma chegada utilizavel.
                if (apoiado-pos).Magnitude<=alcance*0.9 then destino=apoiado end
            end
            if (destino-pos).Magnitude>=alcance then return false,"fora_do_alcance" end
            L.fase="TELEPORTANDO ATÉ "..(e.it.nome or e.obj.Name)
            GS.farmaDirecao=Vector3.zero
            local ok,erro=pcall(function()
                hum.Sit=false
                hum.PlatformStand=false
                root.AssemblyLinearVelocity=Vector3.zero
                root.AssemblyAngularVelocity=Vector3.zero
                root.CFrame=root.CFrame+(destino-root.Position)
            end)
            if not ok then return false,tostring(erro) end
            task.wait(0.15)
            if not autoVivo(g,c) or LocalPlayer.Character~=char then return false,"cancelado" end
            if not e.obj:IsDescendantOf(workspace) then return false,"retirado" end
            local atual,humAtual,raiz=personagem()
            if atual~=char or humAtual~=hum or raiz~=root or hum.Health<=0 then return false,"personagem_mudou" end
            local atualBase=parte(e.obj)
            if not atualBase then return false,"retirado" end
            local atualPos=posPrompt(e.it.prompt,atualBase)
            if finito(atualPos) and (raiz.Position-atualPos).Magnitude<alcance
                and (raiz.Position-destino).Magnitude<5 then
                raiz.AssemblyLinearVelocity=Vector3.zero
                raiz.AssemblyAngularVelocity=Vector3.zero
                return true,"chegou"
            end
        end
        return false,"servidor_corrigiu_posicao"
    end

    local function buscarAlvo(e,g,c)
        local _,hum,root=personagem()
        if not hum then return end
        if GS.noclipArquivo then GS.noclipArquivo.ativar("lucky") end
        GS.farmaDirecao=Vector3.zero
        if not flyAtivado then alternarFly() end
        local chegou,motivo=teleportarLucky(e,g,c)
        GS.farmaDirecao=nil
        if flyAtivado then alternarFly() end
        if GS.noclipArquivo then GS.noclipArquivo.liberar("lucky") end
        if not autoVivo(g,c) then return end
        if not chegou then
            L.espera[e.obj]=os.clock()+15
            L.fase="TELEPORTE NÃO CONFIRMADO · PRÓXIMO BLOCO"
            print("[DEBUG-LUCKY]: Teleporte:",motivo)
            return
        end
        root.AssemblyLinearVelocity=Vector3.zero
        hum.WalkSpeed=16
        local inicio=os.clock()
        local confirmou=false
        while autoVivo(g,c) and e.obj:IsDescendantOf(workspace) and os.clock()-inicio<12 do
            local _,atual,raiz=personagem()
            local base=parte(e.obj)
            if atual~=hum or not base then return end
            local prompt=e.it.prompt
            if not prompt or not prompt.Parent then
                prompt=promptDe(e.obj)
                e.it.prompt=prompt
            end
            local pos=posPrompt(prompt,base)
            local d=(raiz.Position-pos).Magnitude
            -- Pequenas mudanças de lado ajudam quando o personagem encosta no bloco.
            local angulo=(os.clock()-inicio)*1.2
            local deslocamento=Vector3.new(math.cos(angulo),0,math.sin(angulo))*1.5
            hum:MoveTo(pos+deslocamento)
            if d<=8 then
                if prompt and prompt.Enabled and d<=prompt.MaxActivationDistance then
                    confirmou=segurarPrompt(e,prompt,g,c)
                    if confirmou then break end
                end
                if not autoVivo(g,c) then return end
                local click=e.obj:FindFirstChildWhichIsA("ClickDetector",true)
                if click and d<=click.MaxActivationDistance
                    and type(fireclickdetector)=="function" then pcall(fireclickdetector,click) end
            end
            task.wait(0.5)
        end
        if autoVivo(g,c) then
            L.espera[e.obj]=os.clock()+(confirmou and 45 or 15)
            L.fase=confirmou and "INTERAÇÃO OBSERVADA · PRÓXIMO BLOCO" or "AGUARDANDO NOVA TENTATIVA"
            print("[DEBUG-LUCKY]: Visita encerrada. Interação observada:",confirmou)
        end
    end
    local function ligar()
        if L.ligado then return end
        L.ligado=true
        L.geracao=L.geracao+1
        L.scanEm=0
        local g=L.geracao
        L.gui=GS.novaInstancia("Folder")
        L.gui.Name="FarmaLuckyMarcadores"
        L.gui.Parent=ScreenGui
        detectar.Text="LUCKY BLOCKS: ON"
        L.fase="BUSCA COMPLETA"
        table.insert(L.conns,GS.conectar(workspace.DescendantAdded,function(obj)
            if nomeLucky(obj.Name) or obj:IsA("ProximityPrompt") then
                L.scanEm=0
                GS.defer(function()
                    if not vivo(g) then return end
                    local ok,alvo,base,prompt=pcall(avaliar,obj)
                    if ok and alvo then adicionar(alvo,base,prompt) end
                end)
            end
        end))
        table.insert(L.conns,GS.conectar(Chat.MessageReceived,function(msg)
            if nomeLucky(msg.Text) then
                L.aviso="Chat: "..msg.Text:sub(1,160)
                L.scanEm=0
                print("[DEBUG-LUCKY]: Aviso observado; refazendo busca:",msg.Text)
            end
        end))
        GS.spawn(function()
            while vivo(g) do
                local ok,err=pcall(function()
                    if os.clock()>=L.scanEm then varrer(g) end
                    if vivo(g) then listar() end
                end)
                if not ok then warn("[DEBUG-LUCKY]: Busca:",err) end
                task.wait(0.5)
            end
        end)
    end
    local function iniciarAuto()
        if L.auto then return end
        if GS.pararFarmaFrascos then GS.pararFarmaFrascos() end
        if GS.pararFarmaNome then GS.pararFarmaNome() end
        if GS.pararFarmaTesouro then GS.pararFarmaTesouro() end
        ligar()
        local _,hum=personagem()
        L.salvo={fly=flyAtivado,voo=velocidadeVoo,speed=speedAtivado,walk=hum and hum.WalkSpeed or 16}
        if speedAtivado then alternarSpeed() end
        L.auto=true
        if GS.noclipArquivo then GS.noclipArquivo.ativar("lucky") end
        L.ciclo=L.ciclo+1
        local g,c=L.geracao,L.ciclo
        automatico.Text="AUTO LUCKY: ON · TELEPORTE"
        GS.spawn(function()
            while autoVivo(g,c) do
                local ok,err=pcall(function()
                    local alvo
                    for _,e in ipairs(listar()) do
                        if (L.espera[e.obj] or 0)<=os.clock() then alvo=e; break end
                    end
                    if alvo then
                        L.alvo=alvo.obj
                        buscarAlvo(alvo,g,c)
                    else L.fase="AGUARDANDO LUCKY BLOCK" end
                end)
                if not autoVivo(g,c) then break end
                L.alvo=nil
                if not ok then
                    warn("[DEBUG-LUCKY]: Movimento:",err)
                    GS.farmaDirecao=nil
                    if flyAtivado then alternarFly() end
                end
                task.wait(0.5)
            end
        end)
    end
    local function desligar()
        pararAuto()
        L.ligado=false
        L.geracao=L.geracao+1
        for _,conn in ipairs(L.conns) do conn:Disconnect() end
        table.clear(L.conns)
        table.clear(L.itens)
        if L.gui then L.gui:Destroy(); L.gui=nil end
        detectar.Text="LUCKY BLOCKS: OFF"
        L.fase="DESLIGADO"
        info.Text="Busca Lucky Block desligada."
    end
    GS.pararFarmaLucky=pararAuto
    GS.conectar(detectar.MouseButton1Click,function()
        if L.ligado then desligar() else ligar() end
    end)
    GS.conectar(automatico.MouseButton1Click,function()
        if L.auto then pararAuto() else iniciarAuto() end
    end)
    GS.conectar(busca.MouseButton1Click,function()
        ligar()
        L.scanEm=0
        L.fase="REFAZENDO BUSCA COMPLETA"
    end)
    GS.conectar(ScreenGui.Destroying,desligar)
end
GS.rodar("Farma Lucky Block",GS.iniciarFarmaLucky,GS.painelFarma)

GS.iniciarFarmaTesouro = function()
    local U,painel = GS.ui,GS.painelFarmaTesouro or GS.painelFarma
    if not U or not painel then return end
    local Chat = game:GetService("TextChatService")
    local L = {
        ligado=false, auto=false, geracao=0, ciclo=0, itens={}, conns={},
        espera=setmetatable({}, {__mode="k"}), salvo=nil, gui=nil,
        aviso="Nenhum aviso observado.", candidatos={}, examinados=0,
        scanEm=0, alvo=nil, fase="DESLIGADO", segurando=nil,
        tentativas=0, interacoes=0, sinais=setmetatable({}, {__mode="k"}),
    }
    U.sec(painel,"FARMA · TREASURE CHEST","package",20)
    local detectar = U.tog(painel,"PROCURAR BAÚ DO TESOURO",21)
    detectar:SetAttribute("Controlado",true)
    detectar.Text="TESOURO: OFF"
    local automatico = U.tog(painel,"IR ATÉ O TESOURO · VOO 90",22)
    automatico:SetAttribute("Controlado",true)
    automatico.Text="AUTO TESOURO: OFF"
    local busca = U.acao(painel,"REFAZER BUSCA COMPLETA","scan-search",23)
    local info = GS.novaInstancia("TextLabel")
    info.Size=UDim2.new(1,-16,0,130)
    info.LayoutOrder=24
    info.BackgroundTransparency=1
    info.TextColor3=U.T.text
    info.Font=Enum.Font.GothamMedium
    info.TextSize=12
    info.TextWrapped=true
    info.TextXAlignment=Enum.TextXAlignment.Left
    info.TextYAlignment=Enum.TextYAlignment.Top
    info.Text="Procura Treasure Chest e prompts de abrir baú; aviso do chat refaz a busca."
    info.Parent=painel

    local function normalizar(s)
        return string.lower(s):gsub("ú","u"):gsub("Ú","u"):gsub("ã","a"):gsub("[^%w]","")
    end
    local function nomeTesouro(s)
        local n=normalizar(s)
        return n:find("treasurechest",1,true)~=nil
            or n:find("chesttreasure",1,true)~=nil
            or n:find("baudotesouro",1,true)~=nil
            or n:find("bautesouro",1,true)~=nil
    end
    local function promptTesouro(prompt)
        if not prompt:IsA("ProximityPrompt") then return false end
        if nomeTesouro(prompt.ObjectText) then return true end
        local nome=normalizar(prompt.ObjectText)
        local acao=normalizar(prompt.ActionText)
        local generico=nome=="chest" or nome=="treasure" or nome=="bau"
        local abrir=acao:find("open",1,true)~=nil or acao:find("abrir",1,true)~=nil
        return generico and abrir
    end
    local function promptDe(obj)
        for _,desc in ipairs(obj:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and promptTesouro(desc) then return desc end
        end
    end
    local function posPrompt(prompt,base)
        local pai=prompt and prompt.Parent
        if pai and pai:IsA("Attachment") then return pai.WorldPosition end
        if pai and pai:IsA("BasePart") then return pai.Position end
        if pai and pai:IsA("Model") then return pai:GetPivot().Position end
        return base.Position
    end
    local function personagem()
        local char=LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health>0 then return char,hum,root end
    end
    local function parte(obj)
        if obj:IsA("BasePart") then return obj end
        return obj:FindFirstChildWhichIsA("BasePart",true)
    end
    local function dePersonagem(obj)
        local p=obj
        while p and p~=workspace do
            if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") then return true end
            p=p.Parent
        end
        return false
    end
    local function vivo(g)
        return L.ligado and L.geracao==g and ScreenGui.Parent~=nil
    end
    local function autoVivo(g,c)
        return vivo(g) and L.auto and L.ciclo==c
    end
    local function avaliar(obj)
        local alvo=obj
        local prompt
        local corresponde=nomeTesouro(obj.Name)
        if obj:IsA("ProximityPrompt") then
            prompt=obj
            corresponde=corresponde or promptTesouro(obj)
            alvo=obj.Parent
            if alvo and alvo:IsA("Attachment") then alvo=alvo.Parent end
        elseif obj:IsA("ClickDetector") then
            alvo=obj.Parent
            corresponde=corresponde or (alvo and nomeTesouro(alvo.Name))
        elseif not (obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Tool")) then
            return
        end
        if not corresponde or not alvo or alvo==workspace then return end
        if dePersonagem(alvo) then return end
        local p=alvo.Parent
        while p and p~=workspace do
            if (p:IsA("Model") or p:IsA("Tool")) and nomeTesouro(p.Name) then alvo=p end
            p=p.Parent
        end
        if not (alvo:IsA("Model") or alvo:IsA("Tool") or alvo:IsA("BasePart")) then return end
        local n=normalizar(alvo.Name)
        -- Spawners e pastas de templates nao sao o bloco coletavel.
        if n:find("spawner",1,true) or n:find("spawnpoint",1,true) then return end
        local base=parte(alvo)
        if not base then return end
        if alvo:IsA("Model") and alvo:GetExtentsSize().Magnitude>60 then return end
        prompt=prompt or promptDe(alvo)
        return alvo,base,prompt
    end
    local function adicionar(obj,base,prompt)
        if L.itens[obj] then
            if prompt then L.itens[obj].prompt=prompt end
            return
        end
        for outro,it in pairs(L.itens) do
            if obj:IsDescendantOf(outro) then return end
            if outro:IsDescendantOf(obj) then it.gui:Destroy(); L.itens[outro]=nil end
        end
        local gui=GS.novaInstancia("BillboardGui")
        gui.Name="TesouroLocal"
        gui.Adornee=base
        gui.Size=UDim2.fromOffset(174,38)
        gui.StudsOffsetWorldSpace=Vector3.new(0,3,0)
        gui.AlwaysOnTop=true
        gui.MaxDistance=0
        gui.Enabled=false
        gui.Parent=L.gui
        local label=GS.novaInstancia("TextLabel")
        label.Size=UDim2.fromScale(1,1)
        label.BackgroundColor3=Color3.fromRGB(35,22,8)
        label.BackgroundTransparency=0.2
        label.TextColor3=Color3.fromRGB(255,211,118)
        label.TextSize=12
        label.Font=Enum.Font.GothamBold
        label.TextWrapped=true
        label.Parent=gui
        GS.novaInstancia("UICorner",label).CornerRadius=UDim.new(0,8)
        L.itens[obj]={base=base,gui=gui,label=label,prompt=prompt}
        print("[DEBUG-TESOURO]: Encontrado",obj:GetFullName())
    end
    local function varrer(g)
        L.examinados=0
        L.candidatos={}
        L.scanEm=os.clock()+5
        local nomes={}
        for i,obj in ipairs(workspace:GetDescendants()) do
            if not vivo(g) then return end
            L.examinados=i
            local ok,alvo,base,prompt=pcall(avaliar,obj)
            if ok and alvo then adicionar(alvo,base,prompt) end
            local n=normalizar(obj.Name)
            if #L.candidatos<5 and (n:find("treasure",1,true) or n:find("chest",1,true) or n:find("tesouro",1,true))
                and not nomes[obj.Name] and (obj:IsA("Model") or obj:IsA("BasePart")) then
                nomes[obj.Name]=true
                table.insert(L.candidatos,obj:GetFullName())
            end
            if i%300==0 then task.wait() end
        end
        print("[DEBUG-TESOURO]: Busca completa:",L.examinados,"objetos examinados")
        if vivo(g) then L.scanEm=os.clock()+5 end
    end
    local function listar()
        local _,_,root=personagem()
        local lista={}
        for obj,it in pairs(L.itens) do
            if not obj:IsDescendantOf(workspace) or dePersonagem(obj) then
                it.gui:Destroy()
                L.itens[obj]=nil
            else
                local base=parte(obj)
                if base then
                    it.base=base
                    it.gui.Adornee=base
                    if not it.prompt or not it.prompt:IsDescendantOf(obj) then it.prompt=promptDe(obj) end
                    it.nome=it.prompt and it.prompt.ObjectText~="" and it.prompt.ObjectText or obj.Name
                    it.pos=posPrompt(it.prompt,base)
                    table.insert(lista,{obj=obj,it=it,d=root and (root.Position-it.pos).Magnitude or math.huge})
                end
            end
        end
        table.sort(lista,function(a,b) return a.d<b.d end)
        local linhas={L.fase.." | Examinados: "..L.examinados.." | Blocos: "..#lista,
            "Tentativas: "..L.tentativas.." | Interações observadas: "..L.interacoes,L.aviso}
        local camera=workspace.CurrentCamera
        local ocupados={}
        for i,e in ipairs(lista) do
            e.it.label.Text=string.format("%s\n%.0f studs",e.it.nome,e.d)
            local mostrar=false
            if camera and #ocupados<6 then
                local tela,visivel=camera:WorldToViewportPoint(e.it.base.Position+Vector3.new(0,3,0))
                mostrar=visivel and tela.Z>0
                if mostrar then
                    for _,p in ipairs(ocupados) do
                        if math.abs(tela.X-p.X)<184 and math.abs(tela.Y-p.Y)<44 then mostrar=false; break end
                    end
                    if mostrar then table.insert(ocupados,tela) end
                end
            end
            e.it.gui.Enabled=mostrar
            if i<=4 then table.insert(linhas,string.format("%s · %.0f studs",e.it.nome,e.d)) end
        end
        if #lista==0 then
            table.insert(linhas,"Nenhum bloco identificado entre os objetos carregados.")
            if #L.candidatos>0 then
                table.insert(linhas,"Nomes para diagnóstico (não são alvos confirmados):")
                for _,s in ipairs(L.candidatos) do table.insert(linhas,s) end
            end
            if workspace.StreamingEnabled then table.insert(linhas,"Streaming: objetos distantes podem estar ausentes.") end
        end
        info.Text=table.concat(linhas,"\n")
        return lista
    end
    local function restaurar()
        if not L.salvo then return end
        if L.segurando then
            pcall(function() L.segurando:InputHoldEnd() end)
            L.segurando=nil
        end
        L.holdToken=nil
        GS.farmaDirecao=nil
        if flyAtivado then alternarFly() end
        local salvo=L.salvo
        velocidadeVoo=salvo.voo
        if FlyLabel then FlyLabel.Text="VOO: "..velocidadeVoo end
        if speedAtivado~=salvo.speed then alternarSpeed() end
        if salvo.fly then alternarFly() end
        local _,hum,root=personagem()
        if hum then hum.WalkSpeed=salvo.walk; hum:MoveTo(root.Position) end
        L.salvo=nil
    end
    local function pararAuto()
        if not L.auto and not L.salvo then return end
        L.auto=false
        L.ciclo=L.ciclo+1
        L.alvo=nil
        restaurar()
        if GS.noclipArquivo then GS.noclipArquivo.liberar("tesouro") end
        automatico.Text="AUTO TESOURO: OFF"
        L.fase="MONITORANDO TESOURO"
    end
    local function segurarPrompt(e,prompt,g,c)
        local _,hum,root=personagem()
        if not hum or not prompt.Enabled then return false end
        if (root.Position-posPrompt(prompt,e.it.base)).Magnitude>prompt.MaxActivationDistance then return false end
        local disparou=false
        local conn=GS.conectar(prompt.Triggered,function(player)
            if player==LocalPlayer and autoVivo(g,c) then
                disparou=true
                L.interacoes=L.interacoes+1
                print("[DEBUG-TESOURO]: Interação observada:",prompt.ObjectText)
            end
        end)
        L.tentativas=L.tentativas+1
        local token={}
        L.holdToken=token
        L.segurando=prompt
        hum:MoveTo(root.Position)
        local ok,err=pcall(function()
            prompt:InputHoldBegin()
            local duracao=prompt.HoldDuration
            local inicio=os.clock()
            while autoVivo(g,c) and prompt.Parent and prompt.Enabled do
                local _,atual,raiz=personagem()
                if atual~=hum then break end
                if (raiz.Position-posPrompt(prompt,e.it.base)).Magnitude>prompt.MaxActivationDistance then break end
                L.fase=string.format("ABRINDO %s · %.0f%%",prompt.ObjectText,
                    math.min(100,100*(os.clock()-inicio)/math.max(duracao,0.05)))
                if disparou or os.clock()-inicio>=duracao+0.3 then break end
                task.wait(0.05)
            end
        end)
        if L.holdToken==token then
            pcall(function() prompt:InputHoldEnd() end)
            L.segurando=nil
            L.holdToken=nil
        end
        if ok and autoVivo(g,c) then
            local fim=os.clock()+1
            while autoVivo(g,c) and not disparou and prompt.Parent and os.clock()<fim do task.wait(0.05) end
        end
        conn:Disconnect()
        if not ok then warn("[DEBUG-TESOURO]: Interação:",err) end
        return disparou
    end
    local function aproximar(e,g,c)
        local _,hum,root=personagem()
        if not hum then return end
        local destino=posPrompt(e.it.prompt,e.it.base)
        if (root.Position-destino).Magnitude<=8 then return end
        local path=game:GetService("PathfindingService"):CreatePath({
            AgentRadius=2,AgentHeight=5,AgentCanJump=true,
        })
        local ok=pcall(function() path:ComputeAsync(root.Position,destino) end)
        local fim=os.clock()+12
        if ok and autoVivo(g,c) and path.Status==Enum.PathStatus.Success then
            for _,ponto in ipairs(path:GetWaypoints()) do
                if not autoVivo(g,c) or not e.obj:IsDescendantOf(workspace) or os.clock()>fim then break end
                if (root.Position-destino).Magnitude<6 then break end
                if ponto.Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
                hum:MoveTo(ponto.Position)
                local prazo=os.clock()+1.5
                while autoVivo(g,c) and root.Parent and os.clock()<math.min(prazo,fim) do
                    if hum.Health<=0 or (root.Position-ponto.Position).Magnitude<3 then break end
                    task.wait(0.08)
                end
                if not root.Parent or hum.Health<=0 then break end
            end
        end
        path:Destroy()
    end
    local function buscarAlvo(e,g,c)
        local _,hum,root=personagem()
        if not hum then return end
        if GS.noclipArquivo then GS.noclipArquivo.ativar("tesouro") end
        L.fase="INDO ATÉ "..(e.it.nome or e.obj.Name)
        velocidadeVoo=90
        FlyLabel.Text="VOO: 90"
        GS.farmaDirecao=Vector3.zero
        if not flyAtivado then alternarFly() end
        local inicio=os.clock()
        local ultimaDist=math.huge
        local progresso=os.clock()
        while autoVivo(g,c) and e.obj:IsDescendantOf(workspace) and os.clock()-inicio<20 do
            local _,atual,raiz=personagem()
            local base=parte(e.obj)
            if atual~=hum or not base or raiz.Anchored then break end
            local delta=posPrompt(e.it.prompt,base)+Vector3.new(0,2,0)-raiz.Position
            if delta.Magnitude<10 then break end
            if delta.Magnitude<ultimaDist-1 then
                ultimaDist=delta.Magnitude
                progresso=os.clock()
            elseif os.clock()-progresso>3 then
                print("[DEBUG-TESOURO]: Obstáculo no voo; tentando rota a pé.")
                break
            end
            GS.farmaDirecao=delta.Unit*math.clamp(delta.Magnitude/10,0,1)
            task.wait(0.05)
        end
        if not autoVivo(g,c) then return end
        GS.farmaDirecao=nil
        if flyAtivado then alternarFly() end
        root.AssemblyLinearVelocity=Vector3.zero
        if GS.noclipArquivo then GS.noclipArquivo.liberar("tesouro") end
        hum.WalkSpeed=16
        aproximar(e,g,c)
        if not autoVivo(g,c) then return end
        inicio=os.clock()
        local confirmou=false
        while autoVivo(g,c) and e.obj:IsDescendantOf(workspace) and os.clock()-inicio<12 do
            local _,atual,raiz=personagem()
            local base=parte(e.obj)
            if atual~=hum or not base then return end
            local prompt=e.it.prompt
            if not prompt or not prompt.Parent then
                prompt=promptDe(e.obj)
                e.it.prompt=prompt
            end
            local pos=posPrompt(prompt,base)
            local d=(raiz.Position-pos).Magnitude
            -- Pequenas mudanças de lado ajudam quando o personagem encosta no bloco.
            local angulo=(os.clock()-inicio)*1.2
            local deslocamento=Vector3.new(math.cos(angulo),0,math.sin(angulo))*1.5
            hum:MoveTo(pos+deslocamento)
            if d<=8 then
                if prompt and prompt.Enabled and d<=prompt.MaxActivationDistance then
                    confirmou=segurarPrompt(e,prompt,g,c)
                    if confirmou then break end
                end
                if not autoVivo(g,c) then return end
                local click=e.obj:FindFirstChildWhichIsA("ClickDetector",true)
                if click and d<=click.MaxActivationDistance
                    and type(fireclickdetector)=="function" then pcall(fireclickdetector,click) end
            end
            task.wait(0.5)
        end
        if autoVivo(g,c) then
            L.espera[e.obj]=os.clock()+(confirmou and 45 or 15)
            L.fase=confirmou and "INTERAÇÃO OBSERVADA · PRÓXIMO BLOCO" or "AGUARDANDO NOVA TENTATIVA"
            print("[DEBUG-TESOURO]: Visita encerrada. Interação observada:",confirmou)
        end
    end
    local function ligar()
        if L.ligado then return end
        L.ligado=true
        L.geracao=L.geracao+1
        L.scanEm=0
        local g=L.geracao
        L.gui=GS.novaInstancia("Folder")
        L.gui.Name="FarmaTesouroMarcadores"
        L.gui.Parent=ScreenGui
        detectar.Text="TESOURO: ON"
        L.fase="BUSCA COMPLETA"
        table.insert(L.conns,GS.conectar(workspace.DescendantAdded,function(obj)
            if nomeTesouro(obj.Name) or obj:IsA("ProximityPrompt") then
                L.scanEm=0
                GS.defer(function()
                    if not vivo(g) then return end
                    local ok,alvo,base,prompt=pcall(avaliar,obj)
                    if ok and alvo then adicionar(alvo,base,prompt) end
                end)
            end
        end))
        table.insert(L.conns,GS.conectar(Chat.MessageReceived,function(msg)
            if nomeTesouro(msg.Text) then
                L.aviso="Chat: "..msg.Text:sub(1,160)
                L.scanEm=0
                print("[DEBUG-TESOURO]: Aviso observado; refazendo busca:",msg.Text)
            end
        end))
        GS.spawn(function()
            while vivo(g) do
                local ok,err=pcall(function()
                    if os.clock()>=L.scanEm then varrer(g) end
                    if vivo(g) then listar() end
                end)
                if not ok then warn("[DEBUG-TESOURO]: Busca:",err) end
                task.wait(0.5)
            end
        end)
    end
    local function iniciarAuto()
        if L.auto then return end
        if GS.pararFarmaLucky then GS.pararFarmaLucky() end
        if GS.pararFarmaFrascos then GS.pararFarmaFrascos() end
        if GS.pararFarmaNome then GS.pararFarmaNome() end
        ligar()
        local _,hum=personagem()
        L.salvo={fly=flyAtivado,voo=velocidadeVoo,speed=speedAtivado,walk=hum and hum.WalkSpeed or 16}
        if speedAtivado then alternarSpeed() end
        L.auto=true
        if GS.noclipArquivo then GS.noclipArquivo.ativar("tesouro") end
        L.ciclo=L.ciclo+1
        local g,c=L.geracao,L.ciclo
        automatico.Text="AUTO TESOURO: ON · 90"
        GS.spawn(function()
            while autoVivo(g,c) do
                local ok,err=pcall(function()
                    local alvo
                    for _,e in ipairs(listar()) do
                        if (L.espera[e.obj] or 0)<=os.clock() then alvo=e; break end
                    end
                    if alvo then
                        L.alvo=alvo.obj
                        buscarAlvo(alvo,g,c)
                    else L.fase="AGUARDANDO BAÚ DO TESOURO" end
                end)
                if not autoVivo(g,c) then break end
                L.alvo=nil
                if not ok then
                    warn("[DEBUG-TESOURO]: Movimento:",err)
                    GS.farmaDirecao=nil
                    if flyAtivado then alternarFly() end
                end
                task.wait(0.5)
            end
        end)
    end
    local function desligar()
        pararAuto()
        L.ligado=false
        L.geracao=L.geracao+1
        for _,conn in ipairs(L.conns) do conn:Disconnect() end
        table.clear(L.conns)
        table.clear(L.itens)
        if L.gui then L.gui:Destroy(); L.gui=nil end
        detectar.Text="TESOURO: OFF"
        L.fase="DESLIGADO"
        info.Text="Busca do tesouro desligada."
    end
    GS.pararFarmaTesouro=pararAuto
    GS.conectar(detectar.MouseButton1Click,function()
        if L.ligado then desligar() else ligar() end
    end)
    GS.conectar(automatico.MouseButton1Click,function()
        if L.auto then pararAuto() else iniciarAuto() end
    end)
    GS.conectar(busca.MouseButton1Click,function()
        ligar()
        L.scanEm=0
        L.fase="REFAZENDO BUSCA COMPLETA"
    end)
    GS.conectar(ScreenGui.Destroying,desligar)
end
GS.rodar("Farma Treasure Chest",GS.iniciarFarmaTesouro,GS.painelFarmaTesouro)

-- Navegacao por nome interno exato, independente das duas farmas.
GS.iniciarFarmaNome=function()
    local U,painel=GS.ui,GS.painelFarmaNome
    if not U or not painel then return end
    local N={mostrar=false,auto=false,geracao=0,ciclo=0,reg={},conns={},marcas={},salvo=nil,
        alvo=nil,proxima=0,ultimoScan=0,sujo=true,segurando=nil,pagina=1,paginas=1,
        espera=setmetatable({}, {__mode="k"})}
    U.sec(painel,"EXPLORAR MODELOS E PEÇAS","scan-search",1)
    local mostrar=U.tog(painel,"MOSTRAR NOMES NO MAPA",2)
    mostrar:SetAttribute("Controlado",true)
    mostrar.Text="NOMES: OFF"
    local campo=U.inp(painel,"Nome interno exato · ex.: PotionTemplate",3)
    local ir=U.tog(painel,"IR ATRÁS DO NOME EXATO",4)
    ir:SetAttribute("Controlado",true)
    ir.Text="SEGUIR NOME: OFF"
    local estado=U.pequeno(painel,"Ative os nomes e clique em um resultado.",nil,5,"info")
    estado.AutoButtonColor=false
    local lista=GS.novaInstancia("ScrollingFrame")
    lista.Name="ListaNomes"
    lista.Size=UDim2.new(1,0,0,128)
    lista.BackgroundColor3=U.T.bg
    lista.BackgroundTransparency=0.35
    lista.BorderSizePixel=0
    lista.ScrollBarThickness=4
    lista.ScrollBarImageColor3=U.T.strokeHi
    lista.CanvasSize=UDim2.fromOffset(0,0)
    lista.AutomaticCanvasSize=Enum.AutomaticSize.Y
    lista.LayoutOrder=6
    lista.Parent=painel
    U.mkC(10,lista)
    local layout=GS.novaInstancia("UIListLayout",lista)
    layout.Padding=UDim.new(0,4)
    layout.SortOrder=Enum.SortOrder.LayoutOrder
    local linhas={}
    local paginador=GS.novaInstancia("Frame")
    paginador.Size=UDim2.new(1,0,0,30)
    paginador.LayoutOrder=7
    paginador.BackgroundTransparency=1
    paginador.Parent=painel
    for i,titulo in ipairs({"Anterior","Próxima"}) do
        local b=GS.novaInstancia("TextButton")
        b.Size=UDim2.new(0.5,-3,1,0)
        b.Position=UDim2.new((i-1)*0.5,0,0,0)
        b.BackgroundColor3=U.T.card
        b.BackgroundTransparency=0.3
        b.Font=Enum.Font.GothamMedium
        b.TextSize=12
        b.TextColor3=U.T.text
        b.Text=titulo
        b.Parent=paginador
        U.mkC(6,b)
        GS.conectar(b.MouseButton1Click,function()
            N.pagina=math.clamp(N.pagina+(i==1 and -1 or 1),1,N.paginas)
        end)
    end
    for i=1,30 do
        local b=GS.novaInstancia("TextButton")
        b.Size=UDim2.new(1,-8,0,28)
        b.BackgroundColor3=U.T.card
        b.BackgroundTransparency=0.3
        b.Font=Enum.Font.GothamMedium
        b.TextSize=12
        b.TextColor3=U.T.text
        b.TextXAlignment=Enum.TextXAlignment.Left
        b.TextTruncate=Enum.TextTruncate.AtEnd
        b.LayoutOrder=i
        b.Visible=false
        b.Parent=lista
        U.mkC(6,b)
        GS.conectar(b.MouseButton1Click,function()
            if b:GetAttribute("NomeExato") then campo.Text=b:GetAttribute("NomeExato") end
        end)
        linhas[i]=b
    end
    local function personagem()
        local char=LocalPlayer.Character
        local h=char and char:FindFirstChildOfClass("Humanoid")
        local r=char and char:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health>0 then return char,h,r end
    end
    local function parte(obj)
        if obj:IsA("BasePart") then return obj end
        if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart",true)
    end
    local function jogador(obj)
        local pai=obj
        while pai and pai~=workspace do
            if pai:IsA("Model") and pai:FindFirstChildOfClass("Humanoid") then return true end
            pai=pai.Parent
        end
        return false
    end
    local function vivo(g)
        return N.mostrar and N.geracao==g and ScreenGui.Parent~=nil
    end
    local function ativo(g,c)
        return vivo(g) and N.auto and N.ciclo==c
    end
    local function scan(g)
        N.sujo=false
        N.ultimoScan=os.clock()
        local atual={}
        for i,obj in ipairs(workspace:GetDescendants()) do
            if not vivo(g) then return end
            if (obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("BasePart")) and not jogador(obj) then
                local p=parte(obj)
                if p then atual[obj]={parte=p,nome=obj.Name} end
            end
            if i%300==0 then task.wait() end
        end
        if vivo(g) then N.reg=atual end
    end
    local function resultados()
        local _,_,root=personagem()
        local busca=string.lower(campo.Text)
        local nomes,proximos={},{}
        for obj,it in pairs(N.reg) do
            if obj.Parent and obj:IsDescendantOf(workspace) and it.parte:IsDescendantOf(workspace)
                and not jogador(obj) then
                it.nome=obj.Name
                if busca=="" or string.find(string.lower(it.nome),busca,1,true) then
                    local d=root and (root.Position-it.parte.Position).Magnitude or math.huge
                    local atual=nomes[it.nome]
                    if not atual then nomes[it.nome]={nome=it.nome,n=1,d=d}
                    else atual.n=atual.n+1; atual.d=math.min(atual.d,d) end
                    if #proximos<10 or d<proximos[#proximos].d then
                        table.insert(proximos,{obj=obj,it=it,d=d})
                        table.sort(proximos,function(a,b) return a.d<b.d end)
                        if #proximos>10 then table.remove(proximos) end
                    end
                end
            end
        end
        local unicos={}
        for _,nome in pairs(nomes) do table.insert(unicos,nome) end
        table.sort(unicos,function(a,b)
            if a.d==b.d then return a.nome<b.nome end
            return a.d<b.d
        end)
        return unicos,proximos
    end
    local function marcador(e)
        local m=N.marcas[e.obj]
        if m then return m end
        local gui=GS.novaInstancia("BillboardGui")
        gui.Name="NomeModelo"
        gui.Size=UDim2.fromOffset(186,34)
        gui.StudsOffsetWorldSpace=Vector3.new(0,2.5,0)
        gui.MaxDistance=0
        gui.AlwaysOnTop=true
        gui.Parent=ScreenGui
        local l=GS.novaInstancia("TextLabel",gui)
        l.Size=UDim2.fromScale(1,1)
        l.BackgroundColor3=U.T.bg
        l.BackgroundTransparency=0.2
        l.Font=Enum.Font.GothamBold
        l.TextSize=12
        l.TextColor3=U.T.strokeHi
        l.TextWrapped=true
        U.mkC(8,l)
        m={gui=gui,label=l}
        N.marcas[e.obj]=m
        return m
    end
    local function atualizar()
        local nomes,proximos=resultados()
        N.paginas=math.max(1,math.ceil(#nomes/30))
        N.pagina=math.clamp(N.pagina,1,N.paginas)
        for i,b in ipairs(linhas) do
            local e=nomes[(N.pagina-1)*30+i]
            b.Visible=e~=nil
            if e then
                b.Text=string.format("  %s · %d objetos · %.0f st",e.nome,e.n,e.d)
                b:SetAttribute("NomeExato",e.nome)
            end
        end
        local usados,ocupados={},{}
        local cam=workspace.CurrentCamera
        for _,e in ipairs(proximos) do
            if cam then
                local p,visivel=cam:WorldToViewportPoint(e.it.parte.Position+Vector3.new(0,2.5,0))
                if visivel and p.Z>0 then
                    for _,v in ipairs(ocupados) do
                        if math.abs(p.X-v.X)<196 and math.abs(p.Y-v.Y)<40 then visivel=false; break end
                    end
                    if visivel then
                        local m=marcador(e)
                        m.gui.Adornee=e.it.parte
                        m.label.Text=string.format("%s\n%.0f studs",e.obj.Name,e.d)
                        usados[e.obj]=true
                        table.insert(ocupados,p)
                    end
                end
            end
        end
        for obj,m in pairs(N.marcas) do
            if not usados[obj] then m.gui:Destroy(); N.marcas[obj]=nil end
        end
        if not N.auto then
            estado.Text=string.format("%d nomes · página %d/%d. Digite para filtrar; clique para selecionar.",
                #nomes,N.pagina,N.paginas)
        end
    end
    local function pararAuto()
        if not N.auto and not N.salvo then return end
        N.auto=false
        N.ciclo=N.ciclo+1
        N.alvo=nil
        if N.segurando then pcall(function() N.segurando:InputHoldEnd() end); N.segurando=nil end
        GS.farmaDirecao=nil
        if flyAtivado then alternarFly() end
        if N.salvo then
            velocidadeVoo=N.salvo.voo
            FlyLabel.Text="VOO: "..velocidadeVoo
            if speedAtivado~=N.salvo.speed then alternarSpeed() end
            if N.salvo.fly then alternarFly() end
            local _,h,r=personagem()
            if h then h.WalkSpeed=N.salvo.walk; h:MoveTo(r.Position) end
        end
        N.salvo=nil
        ir.Text="SEGUIR NOME: OFF"
    end
    local function ligar()
        if N.mostrar then return end
        N.mostrar=true
        N.geracao=N.geracao+1
        N.sujo=true
        local g=N.geracao
        mostrar.Text="NOMES: ON"
        table.insert(N.conns,GS.conectar(workspace.DescendantAdded,function() N.sujo=true end))
        GS.spawn(function()
            while vivo(g) do
                local ok,err=pcall(function()
                    if os.clock()-N.ultimoScan>4 or (N.sujo and os.clock()-N.ultimoScan>1) then scan(g) end
                    if vivo(g) then atualizar() end
                end)
                if not ok then warn("[DEBUG-NOMES]:",err) end
                task.wait(0.5)
            end
        end)
    end
    local function selecionar(nome)
        local _,_,root=personagem()
        if not root then return end
        local escolhido,distancia
        for obj,it in pairs(N.reg) do
            if obj.Name==nome and obj:IsDescendantOf(workspace) and not jogador(obj)
                and it.parte:IsDescendantOf(workspace) and (N.espera[obj] or 0)<=os.clock() then
                local d=(it.parte.Position-root.Position).Magnitude
                if not distancia or d<distancia then escolhido={obj=obj,parte=it.parte}; distancia=d end
            end
        end
        return escolhido
    end
    local function perseguir(e,g,c)
        local _,hum,root=personagem()
        if not hum then return end
        velocidadeVoo=90
        FlyLabel.Text="VOO: 90"
        GS.farmaDirecao=Vector3.zero
        if not flyAtivado then alternarFly() end
        local inicio=os.clock()
        while ativo(g,c) and e.obj:IsDescendantOf(workspace) and e.parte.Parent and os.clock()-inicio<20 do
            local _,atual,raiz=personagem()
            if atual~=hum or raiz.Anchored then break end
            local delta=e.parte.Position+Vector3.new(0,2,0)-raiz.Position
            if delta.Magnitude<9 then break end
            estado.Text="INDO ATÉ "..e.obj.Name
            GS.farmaDirecao=delta.Unit*math.clamp(delta.Magnitude/10,0,1)
            task.wait(0.05)
        end
        if not ativo(g,c) then return end
        GS.farmaDirecao=nil
        if flyAtivado then alternarFly() end
        local _,h,r=personagem()
        if h~=hum then return end
        r.AssemblyLinearVelocity=Vector3.zero
        h.WalkSpeed=16
        inicio=os.clock()
        while ativo(g,c) and e.obj:IsDescendantOf(workspace) and e.parte.Parent and os.clock()-inicio<8 do
            local _,atual,raiz=personagem()
            if atual~=hum then return end
            estado.Text="APROXIMANDO: "..e.obj.Name
            hum:MoveTo(e.parte.Position)
            local prompt=e.obj:FindFirstChildWhichIsA("ProximityPrompt",true)
            if prompt and prompt.Enabled then
                local p=prompt.Parent
                local pos=p:IsA("Attachment") and p.WorldPosition or (p:IsA("BasePart") and p.Position or e.parte.Position)
                if (raiz.Position-pos).Magnitude<=prompt.MaxActivationDistance then
                    hum:MoveTo(raiz.Position)
                    local ok,err=pcall(function()
                        N.segurando=prompt
                        prompt:InputHoldBegin()
                        local fim=os.clock()+prompt.HoldDuration+0.2
                        while ativo(g,c) and prompt.Parent and os.clock()<fim do task.wait(0.05) end
                    end)
                    if ativo(g,c) and N.segurando==prompt then
                        pcall(function() prompt:InputHoldEnd() end)
                        N.segurando=nil
                    end
                    if not ok then warn("[DEBUG-NOMES]: Interação:",err) end
                    break
                end
            elseif (raiz.Position-e.parte.Position).Magnitude<4 then
                break
            end
            task.wait(0.15)
        end
        if ativo(g,c) then N.espera[e.obj]=os.clock()+15 end
    end
    local function iniciarAuto()
        local nome=campo.Text
        if nome=="" then estado.Text="Digite ou selecione um nome exato antes de seguir."; return end
        if N.auto then return end
        if GS.pararFarmaFrascos then GS.pararFarmaFrascos() end
        if GS.pararFarmaLucky then GS.pararFarmaLucky() end
        if GS.pararFarmaTesouro then GS.pararFarmaTesouro() end
        ligar()
        local _,h=personagem()
        N.salvo={fly=flyAtivado,voo=velocidadeVoo,speed=speedAtivado,walk=h and h.WalkSpeed or 16}
        if speedAtivado then alternarSpeed() end
        N.auto=true
        N.ciclo=N.ciclo+1
        local g,c=N.geracao,N.ciclo
        ir.Text="SEGUIR NOME: ON"
        print("[DEBUG-NOMES]: Alvo exato:",nome)
        GS.spawn(function()
            while ativo(g,c) do
                local ok,err=pcall(function()
                    local e=selecionar(nome)
                    if e then
                        N.alvo=e.obj
                        perseguir(e,g,c)
                    else estado.Text="AGUARDANDO NOME EXATO: "..nome end
                end)
                if not ativo(g,c) then break end
                N.alvo=nil
                if not ok then
                    warn("[DEBUG-NOMES]: Movimento:",err)
                    GS.farmaDirecao=nil
                    if flyAtivado then alternarFly() end
                end
                task.wait(0.5)
            end
        end)
    end
    local function desligar()
        pararAuto()
        N.mostrar=false
        N.geracao=N.geracao+1
        for _,conn in ipairs(N.conns) do conn:Disconnect() end
        table.clear(N.conns)
        table.clear(N.reg)
        for _,m in pairs(N.marcas) do m.gui:Destroy() end
        table.clear(N.marcas)
        for _,b in ipairs(linhas) do b.Visible=false end
        mostrar.Text="NOMES: OFF"
        estado.Text="Ative para explorar os nomes dos objetos carregados."
    end
    GS.pararFarmaNome=pararAuto
    GS.conectar(mostrar.MouseButton1Click,function()
        if N.mostrar then desligar() else ligar() end
    end)
    GS.conectar(ir.MouseButton1Click,function()
        if N.auto then pararAuto() else iniciarAuto() end
    end)
    GS.conectar(campo:GetPropertyChangedSignal("Text"),function()
        N.pagina=1
        if N.auto then pararAuto() end
    end)
    GS.conectar(ScreenGui.Destroying,desligar)
end
GS.rodar("Farma por nome",GS.iniciarFarmaNome,GS.painelFarmaNome)



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
    local grade = GS.novaInstancia("Frame", box)
    grade.Size = UDim2.new(1, 0, 0, 32); grade.BackgroundTransparency = 1; grade.LayoutOrder = 8
    do
        local gl = GS.novaInstancia("UIGridLayout", grade)
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
        local b = GS.novaInstancia("TextButton", grade)
        b.Text = nome; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.AutoButtonColor = false
        b.BackgroundColor3 = T.card; b.TextColor3 = T.dim; b.BorderSizePixel = 0; b.LayoutOrder = i
        U.mkC(8, b); U.mkS(1, T.stroke, b); U.press(b)
        GS.conectar(b.MouseButton1Click,function()
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
    GS.conectar(mais.MouseButton1Click,function() passoRaio(true) end)
    GS.conectar(menos.MouseButton1Click,function() passoRaio(false) end)

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
        table.insert(E.regConns, GS.conectar(workspace.DescendantAdded,registrar))
        GS.spawn(function()
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
        st.conn = GS.conectar(m.DescendantAdded,function(d) neutralizar(st, d) end)
        st.att = GS.novaInstancia("Attachment"); st.att.Name = "GringoEscudoAtt"; st.att.Parent = r
        st.ap = GS.novaInstancia("AlignPosition"); st.ap.Name = "GringoEscudoAP"
        st.ap.Mode = Enum.PositionAlignmentMode.OneAttachment; st.ap.Attachment0 = st.att
        st.ap.RigidityEnabled = true; st.ap.Position = r.Position; st.ap.Parent = r
        st.ao = GS.novaInstancia("AlignOrientation"); st.ao.Name = "GringoEscudoAO"
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
            t.conn = GS.conectar(m.DescendantAdded,function(d) pcall(pegar, d) end)
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
        local b = GS.novaInstancia("Part")
        b.Name = "GringoEscudoBolha"; b.Shape = Enum.PartType.Ball; b.Material = Enum.Material.ForceField
        b.Color = Color3.fromRGB(120, 200, 255); b.Anchored = true; b.CanCollide = false
        b.CanQuery = false; b.CanTouch = false; b.CastShadow = false
        b.Parent = workspace.CurrentCamera
        E.bolha = b
        E.avisou = false
        table.insert(E.conns, GS.conectar(RunService.Heartbeat,function(dt)
            local ok, err = pcall(passo, dt)
            if not ok and not E.avisou then E.avisou = true warn("[GRINGO ESCUDO] " .. tostring(err)) end
        end))
        -- re-trava antes da fisica (servidor teleportou → volta no mesmo passo)
        table.insert(E.conns, GS.conectar(RunService.Stepped,function()
            for _, st in pairs(E.alvos) do
                if st.cf and st.r.Parent then
                    pcall(function() st.r.CFrame = st.cf; st.r.AssemblyLinearVelocity = ZERO end)
                end
            end
        end))
    end

    GS.conectar(togE.MouseButton1Click,function()
        E.ativo = not E.ativo
        togE.Text = E.ativo and "ESCUDO: ON" or "ESCUDO: OFF"
        if E.ativo then ligar() else desligar() end
    end)
    GS.conectar(togBolha.MouseButton1Click,function()
        E.bolhaOn = not E.bolhaOn
        togBolha.Text = E.bolhaOn and "BOLHA: ON" or "BOLHA: OFF"
    end)
    GS.conectar(ScreenGui.Destroying,function()
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
        GS.defer(function()
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
        table.insert(P.conns, GS.conectar(UserInputService.JumpRequest,function() pcall(pular) end))
        table.insert(P.conns, GS.conectar(RunService.Heartbeat,function() pcall(pousoSuave) end))
    end
    local function desligar()
        for _, c in ipairs(P.conns) do pcall(function() c:Disconnect() end) end
        P.conns = {}
    end

    if GS.puloBtn then
        GS.puloBtn:SetAttribute("Controlado", true)
        mostrar()
        GS.conectar(GS.puloBtn.MouseButton1Click,function()
            P.ativo = not P.ativo
            GS.puloBtn.Text = P.ativo and "SUPER PULO: ON" or "SUPER PULO: OFF"
            if P.ativo then ligar() else desligar() end
        end)
        GS.conectar(GS.puloMais.MouseButton1Click,function() P.idx = math.min(P.idx + 1, #ALTURAS); mostrar() end)
        GS.conectar(GS.puloMenos.MouseButton1Click,function() P.idx = math.max(P.idx - 1, 1); mostrar() end)
        GS.conectar(ScreenGui.Destroying,desligar)
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
        GS.spawn(function()
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
        local sg = GS.novaInstancia("ScreenGui")
        sg.Name = "GringoResolver"; sg.ResetOnSpawn = false; sg.DisplayOrder = 96; sg.IgnoreGuiInset = true
        sg.Parent = GS.pai
        local f = GS.novaInstancia("Frame", sg)
        f.Size = UDim2.fromOffset(360, 300); f.Position = UDim2.new(0, 16, 0.5, -150)
        f.BackgroundColor3 = T.bg; f.BackgroundTransparency = 0.08; f.BorderSizePixel = 0; f.Active = true
        U.mkC(12, f); U.mkS(1, T.strokeHi, f)
        local topo = GS.novaInstancia("TextLabel", f)
        topo.Size = UDim2.new(1, -16, 0, 30); topo.Position = UDim2.new(0, 10, 0, 4)
        topo.BackgroundTransparency = 1; topo.Font = Enum.Font.GothamBlack; topo.TextSize = 14
        topo.TextColor3 = T.text; topo.TextXAlignment = Enum.TextXAlignment.Left; topo.Text = "🧠 RESOLVER"
        local sub = GS.novaInstancia("TextLabel", f)
        sub.Size = UDim2.new(1, -16, 0, 14); sub.Position = UDim2.new(0, 10, 0, 30)
        sub.BackgroundTransparency = 1; sub.Font = Enum.Font.Gotham; sub.TextSize = 10
        sub.TextColor3 = T.mute; sub.TextXAlignment = Enum.TextXAlignment.Left; sub.Text = "o que fazer agora"
        local lista = GS.novaInstancia("ScrollingFrame", f)
        lista.Size = UDim2.new(1, -16, 1, -54); lista.Position = UDim2.new(0, 8, 0, 48)
        lista.BackgroundTransparency = 1; lista.BorderSizePixel = 0; lista.ScrollBarThickness = 3
        lista.CanvasSize = UDim2.new(); lista.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local ll = GS.novaInstancia("UIListLayout", lista); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0, 3)
        -- arrastar pelo topo
        local arr, ini, pos
        GS.conectar(f.InputBegan,function(i)
            if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch)
            and i.Position.Y - f.AbsolutePosition.Y < 46 then
                arr, ini, pos = true, i.Position, f.Position
                GS.conectar(i.Changed,function() if i.UserInputState == Enum.UserInputState.End then arr = false end end)
            end
        end)
        table.insert(RS.conns, GS.conectar(UserInputService.InputChanged,function(i)
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
                l = GS.novaInstancia("TextLabel", RS.lista)
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
                local g = GS.novaInstancia("BillboardGui")
                g.Name = "GringoResolverMarca"; g.AlwaysOnTop = true; g.Size = UDim2.fromOffset(200, 36)
                g.StudsOffset = Vector3.new(0, 3, 0); g.MaxDistance = math.huge; g.LightInfluence = 0; g.Adornee = p
                local bg = GS.novaInstancia("Frame", g)
                bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(40, 30, 0)
                bg.BackgroundTransparency = 0.25; bg.BorderSizePixel = 0
                GS.novaInstancia("UICorner", bg).CornerRadius = UDim.new(0, 6)
                local s = GS.novaInstancia("UIStroke", bg); s.Color = Color3.fromRGB(255, 210, 60); s.Thickness = 1.5
                local l = GS.novaInstancia("TextLabel", bg)
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
                RS.attEu = GS.novaInstancia("Attachment"); RS.attEu.Name = "GringoResolverEu"; RS.attEu.Parent = meuRoot
            end
            if not RS.attAlvo or RS.attAlvo.Parent ~= principal.alvo then
                if RS.attAlvo then RS.attAlvo:Destroy() end
                RS.attAlvo = GS.novaInstancia("Attachment"); RS.attAlvo.Name = "GringoResolverAlvo"; RS.attAlvo.Parent = principal.alvo
            end
            if not RS.beam then
                local b = GS.novaInstancia("Beam")
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
        table.insert(RS.conns, GS.conectar(workspace.DescendantAdded,function(o) pcall(indexar, o) end))
        RS.analiseT, RS.marcaT, RS.limpaT = 99, 0, 0
        table.insert(RS.conns, GS.conectar(RunService.Heartbeat,function(dt)
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

    GS.conectar(togR.MouseButton1Click,function()
        RS.ativo = not RS.ativo
        togR.Text = RS.ativo and "RESOLVER: ON" or "RESOLVER: OFF"
        if RS.ativo then ligar() else desligar() end
    end)
    GS.conectar(togM.MouseButton1Click,function()
        RS.marcar = not RS.marcar
        togM.Text = RS.marcar and "MARCAR: ON" or "MARCAR: OFF"
    end)
    GS.conectar(togS.MouseButton1Click,function()
        RS.seta = not RS.seta
        togS.Text = RS.seta and "SETA: ON" or "SETA: OFF"
    end)
    GS.conectar(buscaBox.FocusLost,function()
        RS.busca = norm(buscaBox.Text or "")
        RS.analiseT = 99
    end)
    GS.conectar(copiar.MouseButton1Click,function()
        if RS.relatorio == "" then GS.toast("🧠  Liga o RESOLVER primeiro", false) return end
        print(RS.relatorio)
        if setclipboard then
            pcall(setclipboard, RS.relatorio)
            GS.toast("📋  Relatório copiado (também está no F9)", true)
        else
            GS.toast("📋  Relatório no F9 (seu executor não copia)", true)
        end
    end)
    GS.conectar(ScreenGui.Destroying,desligar)
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
            m = GS.novaInstancia("BillboardGui")
            m.Name = "GringoAntiScriptMarca"; m.AlwaysOnTop = true; m.Size = UDim2.fromOffset(140, 26)
            m.StudsOffset = Vector3.new(0, 3.5, 0); m.LightInfluence = 0
            local l = GS.novaInstancia("TextLabel", m)
            l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundColor3 = Color3.fromRGB(120, 0, 20)
            l.BackgroundTransparency = 0.2; l.Font = Enum.Font.GothamBlack; l.TextSize = 12
            l.TextColor3 = Color3.new(1, 1, 1); l.Text = "⚠ SCRIPT"
            GS.novaInstancia("UICorner", l).CornerRadius = UDim.new(0, 6)
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
        table.insert(A.conns, GS.conectar(RunService.Stepped,function()
            pcall(semColisaoComOutros)
            pcall(antiFling)
        end))
        table.insert(A.conns, GS.conectar(RunService.Heartbeat,function(dt)
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

    GS.conectar(togA.MouseButton1Click,function()
        A.ativo = not A.ativo
        togA.Text = A.ativo and "ANTI-SCRIPTS: ON" or "ANTI-SCRIPTS: OFF"
        if A.ativo then ligar() else desligar() end
    end)
    GS.conectar(ScreenGui.Destroying,desligar)
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
            reg.conn = GS.conectar(p.CharacterAdded,function(c)
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
            GS.spawn(function()
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
        table.insert(AA.conns, GS.conectar(RunService.Heartbeat,function(dt)
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

    GS.conectar(togAA.MouseButton1Click,function()
        AA.ativo = not AA.ativo
        togAA.Text = AA.ativo and "ANTI-ASSÉDIO: ON" or "ANTI-ASSÉDIO: OFF"
        if AA.ativo then ligar() else desligar() end
    end)
    GS.conectar(togF.MouseButton1Click,function()
        AA.fugir = not AA.fugir
        togF.Text = AA.fugir and "FUGIR: ON" or "FUGIR: OFF"
    end)
    GS.conectar(mostrarBtn.MouseButton1Click,function()
        local n = 0
        for p in pairs(AA.ocultos) do mostrar(p); n = n + 1 end
        AA.dados = {}
        GS.toast("👁  " .. n .. " jogador(es) visível(is) de novo", true)
    end)
    GS.conectar(ScreenGui.Destroying,desligar)
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
    GS.conectar(togG.MouseButton1Click,function()
        CH.seguirDegraus = not CH.seguirDegraus
        togG.Text = CH.seguirDegraus and "DEGRAUS: ON" or "DEGRAUS: OFF"
    end)

    local function mostrarTamanho() valor.Text = CH.tamanho .. " m" end
    mostrarTamanho()
    GS.conectar(mais.MouseButton1Click,function() CH.tamanho = math.min(CH.tamanho + 2, 60); mostrarTamanho() end)
    GS.conectar(menos.MouseButton1Click,function() CH.tamanho = math.max(CH.tamanho - 2, 4); mostrarTamanho() end)

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
        local p = GS.novaInstancia("Part")
        p.Name = "GringoChaoInvisivel"; p.Anchored = true; p.CanCollide = true; p.CanTouch = false
        p.CastShadow = false; p.Material = Enum.Material.ForceField
        p.Color = Color3.fromRGB(120, 200, 255); p.TopSurface = Enum.SurfaceType.Smooth
        p.Transparency = 1
        p.Parent = workspace
        CH.plat = p
    end

    -- ── Botoes ⬆ ⬇ na tela (PC e celular) ──
    local function criarBotoes()
        local sg = GS.novaInstancia("ScreenGui")
        sg.Name = "GringoChaoBotoes"; sg.ResetOnSpawn = false; sg.DisplayOrder = 95; sg.Parent = GS.pai
        local function botao(txt, y, campo)
            local b = GS.novaInstancia("TextButton", sg)
            b.Size = UDim2.fromOffset(54, 54); b.Position = UDim2.new(1, -74, 0.5, y)
            b.BackgroundColor3 = T.card; b.BackgroundTransparency = 0.15; b.Text = txt
            b.Font = Enum.Font.GothamBlack; b.TextSize = 22; b.TextColor3 = T.text; b.AutoButtonColor = false
            U.mkC(14, b); U.mkS(1, T.strokeHi, b)
            GS.conectar(b.InputBegan,function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    CH[campo] = true; b.BackgroundColor3 = T.on; b.TextColor3 = T.knobOn
                end
            end)
            GS.conectar(b.InputEnded,function(i)
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
        table.insert(CH.conns, GS.conectar(RunService.Heartbeat,function(dt)
            local ok, err = pcall(passo, dt)
            if not ok and not CH.avisou then CH.avisou = true warn("[GRINGO CHAO] " .. tostring(err)) end
        end))
        -- renasceu: recomeca na altura nova
        table.insert(CH.conns, GS.conectar(LocalPlayer.CharacterAdded,function() CH.nivel = nil end))
    end

    GS.conectar(togC.MouseButton1Click,function()
        CH.ativo = not CH.ativo
        togC.Text = CH.ativo and "CHÃO: ON" or "CHÃO: OFF"
        if CH.ativo then ligar() else desligar() end
    end)
    GS.conectar(togD.MouseButton1Click,function()
        CH.degrau = not CH.degrau
        togD.Text = CH.degrau and "DEGRAU: ON" or "DEGRAU: OFF"
    end)
    GS.conectar(togV.MouseButton1Click,function()
        CH.mostrar = not CH.mostrar
        togV.Text = CH.mostrar and "MOSTRAR: ON" or "MOSTRAR: OFF"
    end)
    GS.conectar(ScreenGui.Destroying,desligar)
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
    local grade = GS.novaInstancia("Frame", painel)
    grade.Size = UDim2.new(1, 0, 0, 32); grade.BackgroundTransparency = 1; grade.LayoutOrder = 23
    do
        local gl = GS.novaInstancia("UIGridLayout", grade)
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
        local b = GS.novaInstancia("TextButton", grade)
        b.Text = nome; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.AutoButtonColor = false
        b.BackgroundColor3 = T.card; b.TextColor3 = T.dim; b.BorderSizePixel = 0; b.LayoutOrder = i
        U.mkC(8, b); U.mkS(1, T.stroke, b); U.press(b)
        GS.conectar(b.MouseButton1Click,function() AT.modo = nome; pintar() end)
        botoesModo[nome] = b
    end
    pintar()
    local function mostrarAnt() valor.Text = math.floor(AT.antecedencia * 1000 + 0.5) .. "" end
    mostrarAnt()
    GS.conectar(mais.MouseButton1Click,function() AT.antecedencia = math.min(AT.antecedencia + 0.02, 0.8); mostrarAnt() end)
    GS.conectar(menos.MouseButton1Click,function() AT.antecedencia = math.max(AT.antecedencia - 0.02, 0.08); mostrarAnt() end)

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
        table.insert(AT.conns, GS.conectar(RunService.Heartbeat,function(dt)
            local ok, err = pcall(passo, dt)
            if not ok and not AT.avisou then AT.avisou = true warn("[GRINGO AUTO TOQUE] " .. tostring(err)) end
        end))
    end
    local function desligar()
        for _, c in ipairs(AT.conns) do pcall(function() c:Disconnect() end) end
        AT.conns, AT.rastros = {}, {}
        status.Text = "🔴 DESLIGADO"
    end

    GS.conectar(togAT.MouseButton1Click,function()
        AT.ativo = not AT.ativo
        togAT.Text = AT.ativo and "AUTO TOQUE: ON" or "AUTO TOQUE: OFF"
        if AT.ativo then ligar() else desligar() end
    end)
    GS.conectar(togCl.MouseButton1Click,function()
        AT.clash = not AT.clash
        togCl.Text = AT.clash and "CLASH: ON" or "CLASH: OFF"
    end)
    GS.conectar(ScreenGui.Destroying,desligar)
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
        GS.conectar(GS.emotesBtn.MouseButton1Click,function()
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
            GS.spawn(function()
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
        local grade = GS.novaInstancia("Frame", pai)
        grade.Size = UDim2.new(1, 0, 0, 34); grade.BackgroundTransparency = 1; grade.LayoutOrder = ord
        local gl = GS.novaInstancia("UIGridLayout", grade)
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
            local b = GS.novaInstancia("TextButton", grade)
            b.Text = par[2]; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.AutoButtonColor = false
            b.BackgroundColor3 = T.card; b.TextColor3 = T.dim; b.BorderSizePixel = 0; b.LayoutOrder = i
            U.mkC(9, b); U.mkS(1, T.stroke, b); U.press(b)
            GS.conectar(b.MouseButton1Click,function()
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
    GS.conectar(togCt.MouseButton1Click,function()
        GS.fovCentro = not GS.fovCentro
        togCt.Text = GS.fovCentro and "CENTRO: ON" or "CENTRO: OFF"
    end)

    -- ── Desenhos: circulo do FOV, marcador e destaque do alvo ──
    local circulo = GS.novaInstancia("Frame")
    circulo.Name = "GringoSilentFov"; circulo.AnchorPoint = Vector2.new(0.5, 0.5)
    circulo.BackgroundTransparency = 1; circulo.Visible = false; circulo.ZIndex = 0
    U.redondo(circulo)
    local circuloBorda = U.mkS(1.5, T.on, circulo, 0.25)
    circulo.Parent = ScreenGui
    local marcador = GS.novaInstancia("Frame")
    marcador.Name = "GringoSilentAlvo"; marcador.AnchorPoint = Vector2.new(0.5, 0.5)
    marcador.Size = UDim2.fromOffset(18, 18); marcador.BackgroundTransparency = 1; marcador.Visible = false
    U.redondo(marcador); U.mkS(2, T.on, marcador, 0)
    do
        local ponto = GS.novaInstancia("Frame", marcador)
        ponto.AnchorPoint = Vector2.new(0.5, 0.5); ponto.Position = UDim2.fromScale(0.5, 0.5)
        ponto.Size = UDim2.fromOffset(4, 4); ponto.BackgroundColor3 = T.on; ponto.BorderSizePixel = 0
        U.redondo(ponto)
    end
    marcador.Parent = ScreenGui
    local destaque = GS.novaInstancia("Highlight")
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
            mouse1press(); GS.delay(0.03, function() pcall(mouse1release) end)
        elseif mouse1click then
            if mouseEmCimaDoPainel(seta) then return end
            S.tiroAte = os.clock() + 0.3
            mouse1click()
        elseif VIM then
            if mouseEmCimaDoPainel(pos) then return end
            S.tiroAte = os.clock() + 0.3
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            GS.delay(0.03, function() pcall(function() VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0) end) end)
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
        table.insert(S.conns, GS.conectar(workspace.DescendantAdded,registrar))
        table.insert(S.conns, GS.conectar(RunService.RenderStepped,function() pcall(passo) end))
        -- janela de tiro: clique (PC) ou toque (celular). Fica aberta um
        -- pouquinho depois de soltar, pra bala que sai no soltar do botao
        local function ehTiro(io)
            local t = io.UserInputType
            return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
        end
        table.insert(S.conns, GS.conectar(UserInputService.InputBegan,function(io)
            if ehTiro(io) then S.mouseBaixo = true; S.tiroAte = os.clock() + 0.4 end
        end))
        table.insert(S.conns, GS.conectar(UserInputService.InputEnded,function(io)
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
        GS.conectar(btn.MouseButton1Click,function()
            S[campo] = not S[campo]
            btn.Text = nome .. (S[campo] and ": ON" or ": OFF")
            if aoMudar then aoMudar(S[campo]) end
        end)
    end
    GS.conectar(togS.MouseButton1Click,function()
        if S.ativo then desligar() else ligar() end
    end)
    GS.conectar(togJ.MouseButton1Click,function()
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
    GS.conectar(fovMenos.MouseButton1Click,function()
        S.fov = S.fov >= 1000 and 600 or math.max(50, S.fov - 25); atualizarFov()
    end)
    GS.conectar(fovMais.MouseButton1Click,function()
        S.fov = S.fov >= 600 and 1000 or math.min(600, S.fov + 25); atualizarFov()
    end)
    GS.conectar(chMenos.MouseButton1Click,function() S.chance = math.max(10, S.chance - 10); chLbl.Text = S.chance .. "%" end)
    GS.conectar(chMais.MouseButton1Click,function() S.chance = math.min(100, S.chance + 10); chLbl.Text = S.chance .. "%" end)
    GS.conectar(cpsMenos.MouseButton1Click,function() S.cps = math.max(2, S.cps - 2); cpsLbl.Text = tostring(S.cps) end)
    GS.conectar(cpsMais.MouseButton1Click,function() S.cps = math.min(30, S.cps + 2); cpsLbl.Text = tostring(S.cps) end)
    local function atualizarHitbox()
        hbLbl.Text = tostring(S.tamHitbox)
        if S.hitbox then S.proximaHitbox = 0 end
    end
    GS.conectar(hbMenos.MouseButton1Click,function() S.tamHitbox = math.max(3, S.tamHitbox - 1); atualizarHitbox() end)
    GS.conectar(hbMais.MouseButton1Click,function() S.tamHitbox = math.min(20, S.tamHitbox + 1); atualizarHitbox() end)

    GS.conectar(ScreenGui.Destroying,function()
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
        GS.spawn(function()
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
        table.insert(R.conns, GS.conectar(RunService.RenderStepped,function() pcall(passoCamera) end))
        pcall(function()
            GS.bindRender(RunService,"GringoNoRecoil", Enum.RenderPriority.Last.Value + 1,
                function() pcall(passoCamera) end)
        end)
        table.insert(R.conns, GS.conectar(RunService.Heartbeat,function() pcall(manter) end))
        -- equipou/trocou de arma: varre na hora
        local function aoPersonagem(char)
            table.insert(R.conns, GS.conectar(char.ChildAdded,function(o)
                if o:IsA("Tool") then
                    GS.delay(0.35, function() if R.ativo then aplicarArma() end end)
                end
            end))
        end
        if LocalPlayer.Character then aoPersonagem(LocalPlayer.Character) end
        table.insert(R.conns, GS.conectar(LocalPlayer.CharacterAdded,aoPersonagem))
        aplicarArma()
        -- status + revarredura (arma que recria a config ao atirar/recarregar)
        GS.spawn(function()
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
            GS.delay(0.6, function() GS.toast("Sem getgc: só câmera + Tools", false) end)
        end
        if not UserInputService.MouseEnabled then
            GS.delay(1.2, function() GS.toast("Celular: câmera fica de fora", false) end)
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
    GS.conectar(togR.MouseButton1Click,function()
        if R.ativo then desligar() else ligar() end
    end)
    local function reaplicar()
        if not R.ativo then return end
        restaurar()
        aplicarArma()
    end
    GS.conectar(togC.MouseButton1Click,function()
        R.camera = not R.camera; R.pitch = nil
        togC.Text = R.camera and "CAMERA: ON" or "CAMERA: OFF"
    end)
    GS.conectar(togA.MouseButton1Click,function()
        R.arma = not R.arma
        togA.Text = R.arma and "ARMA: ON" or "ARMA: OFF"
        reaplicar()
    end)
    GS.conectar(togB.MouseButton1Click,function()
        R.bala = not R.bala
        togB.Text = R.bala and "SPREAD: ON" or "SPREAD: OFF"
        reaplicar()
    end)
    GS.conectar(forMenos.MouseButton1Click,function() R.forca = math.max(10, R.forca - 10); forLbl.Text = R.forca .. "%" end)
    GS.conectar(forMais.MouseButton1Click,function() R.forca = math.min(100, R.forca + 10); forLbl.Text = R.forca .. "%" end)

    GS.conectar(ScreenGui.Destroying,function()
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
            table.insert(M.sinais, GS.conectar(sinal,function()
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
        GS.spawn(function()
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
        table.insert(M.conns, GS.conectar(RunService.Heartbeat,function() pcall(manter) end))
        local function aoPersonagem(char)
            table.insert(M.conns, GS.conectar(char.ChildAdded,function(o)
                if o:IsA("Tool") then
                    GS.delay(0.35, function() if M.ativo then aplicar() end end)
                end
            end))
        end
        if LocalPlayer.Character then aoPersonagem(LocalPlayer.Character) end
        table.insert(M.conns, GS.conectar(LocalPlayer.CharacterAdded,aoPersonagem))
        aplicar()
        GS.spawn(function()
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
            GS.delay(0.6, function() GS.toast("Sem getgc: só Values da Tool", false) end)
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
    GS.conectar(togM.MouseButton1Click,function()
        if M.ativo then desligar() else ligar() end
    end)
    local function reaplicar()
        if not M.ativo then return end
        restaurar()
        aplicar()
    end
    GS.conectar(togR.MouseButton1Click,function()
        M.recarga = not M.recarga
        togR.Text = M.recarga and "RECARGA: ON" or "RECARGA: OFF"
        reaplicar()
    end)
    GS.conectar(togD.MouseButton1Click,function()
        M.destravar = not M.destravar
        togD.Text = M.destravar and "DESTRAVAR: ON" or "DESTRAVAR: OFF"
        reaplicar()
    end)

    GS.conectar(ScreenGui.Destroying,function()
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
        table.insert(V.sinais, GS.conectar(sinal,function()
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
        GS.spawn(function()
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
        table.insert(V.conns, GS.conectar(UserInputService.InputBegan,function(io, gpe)
            local atirou = false
            if ehTiroPC(io) then V.mb1 = true; atirou = true
            elseif io.UserInputType == Enum.UserInputType.Touch and gpe then V.toques[io] = true; atirou = true end
            -- comecou a atirar e a ultima varredura e velha: varre a arma da mao
            if atirou and relogioReal() - V.ultimaVarredura > 4 then GS.spawn(aplicar) end
            -- trocou de arma no teclado (1 a 9): varre a arma nova
            if NUMEROS[io.KeyCode] then
                GS.delay(0.4, function() if V.ativo then aplicar() end end)
            end
        end))
        table.insert(V.conns, GS.conectar(UserInputService.InputEnded,function(io)
            if io.UserInputType == Enum.UserInputType.MouseButton1 then V.mb1 = false
            elseif io.UserInputType == Enum.UserInputType.Touch then V.toques[io] = nil end
        end))
        table.insert(V.conns, GS.conectar(RunService.Heartbeat,function(dt)
            pcall(manter)
            pcall(passoRajada, dt)
        end))
        local function aoPersonagem(char)
            table.insert(V.conns, GS.conectar(char.ChildAdded,function(o)
                if o:IsA("Tool") then
                    GS.delay(0.35, function() if V.ativo then aplicar() end end)
                end
            end))
        end
        if LocalPlayer.Character then aoPersonagem(LocalPlayer.Character) end
        table.insert(V.conns, GS.conectar(LocalPlayer.CharacterAdded,aoPersonagem))
        aplicar()
        GS.spawn(function()
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
            GS.delay(1.2, function() GS.toast("Executor sem hookfunction", false) end)
        end
        if V.relogio then instalarRelogio() end
        togV.Text = "VELOCIDADE DA BALA: ON"
        status.TextColor3 = T.text
        setStatus("ON · PROCURANDO A ARMA...")
        GS.toast("Velocidade da bala ON", true)
        if not (GS.municao and GS.municao.ativo) then
            GS.delay(0.6, function() GS.toast("Liga a munição infinita junto", true) end)
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
    GS.conectar(togV.MouseButton1Click,function()
        if V.ativo then desligar() else ligar() end
    end)
    local function reaplicar()
        if not V.ativo then return end
        restaurar()
        aplicar()
    end
    local function chave(btn, campo, nome, refazer)
        GS.conectar(btn.MouseButton1Click,function()
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
    GS.conectar(tpsMenos.MouseButton1Click,function()
        V.tps = V.tps > 60 and V.tps - 10 or math.max(5, V.tps - 5); atualizarTps()
    end)
    GS.conectar(tpsMais.MouseButton1Click,function()
        V.tps = V.tps >= 60 and math.min(120, V.tps + 10) or V.tps + 5; atualizarTps()
    end)
    GS.conectar(togE.MouseButton1Click,function()
        V.espera = not V.espera
        togE.Text = V.espera and "ESPERA: ON" or "ESPERA: OFF"
        if V.espera and V.ativo and not instalarEspera() then GS.toast("Executor sem hookfunction", false) end
    end)
    GS.conectar(togRl.MouseButton1Click,function()
        V.relogio = not V.relogio
        togRl.Text = V.relogio and "RELOGIO: ON" or "RELOGIO: OFF"
        if V.relogio and V.ativo and not instalarRelogio() then GS.toast("Executor sem hookfunction", false) end
    end)
    GS.conectar(togU.MouseButton1Click,function()
        V.universal = not V.universal
        togU.Text = V.universal and "UNIVERSAL: ON" or "UNIVERSAL: OFF"
        table.clear(cacheArma)
        reaplicar()
    end)

    GS.conectar(ScreenGui.Destroying,function()
        if V.ativo then desligar(true) end
    end)
end
GS.rodar("Velocidade da bala", GS.iniciarVelocidade, GS.painelMunicao)

-- ═══════════════════════════════════════════════════════════════
-- CAMERA LONGE: substitui o antigo Modo Fantasma.
GS.iniciarCameraLonge = function()
    local U,painel=GS.ui,GS.painelPersonagem
    if not U or not painel then return end
    local player=game:GetService("Players").LocalPlayer
    local C={ativo=false,morto=false,limite=1000,escrevendo=false,ciclo=0,conns={}}
    local grupo=U.grupo(painel,"Câmera longe","Afaste a câmera com a rodinha do mouse · até 60.000 studs","maximize",1.5)
    local toggle=U.tog(grupo,"CÂMERA LONGE: OFF",1,"maximize")
    local menos,mais,valor=U.ctrl(grupo,"Distância máxima (studs)",C.limite,2)
    local afastar=U.acao(grupo,"AFASTAR ATÉ O LIMITE","arrow-up-to-line",3)
    local maximo=U.acao(grupo,"DEFINIR LIMITE: 60.000 STUDS","maximize",4)
    local status=U.pequeno(grupo,"Ative e role a rodinha para trás para afastar",nil,5,"info")
    status.AutoButtonColor=false

    local Run=game:GetService("RunService")
    local entrada=game:GetService("UserInputService")
    local nomeRender="GringoCameraLongeLivre"
    C.cameras=setmetatable({}, {__mode="k"})
    C.distancia=12;C.yaw=0;C.pitch=0.2

    function C.centro()
        local char=player.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and (char:FindFirstChild("HumanoidRootPart") or (hum and hum.RootPart) or char.PrimaryPart)
        if not root then return nil end
        return root.Position+Vector3.new(0,hum and hum.HipHeight or 2,0)+(hum and hum.CameraOffset or Vector3.zero)
    end
    function C.soltarMouse()
        if C.mouseOriginal~=nil then
            pcall(function()
                if entrada.MouseBehavior==Enum.MouseBehavior.LockCurrentPosition then entrada.MouseBehavior=C.mouseOriginal end
            end)
        end
        C.mouseOriginal=nil;C.arrastando=false
    end
    function C.lerCamera(camera,centro)
        local delta=camera.CFrame.Position-centro
        if delta.Magnitude>0.1 then
            C.distancia=math.clamp(delta.Magnitude,0.5,C.limite)
            C.yaw=math.atan2(delta.X,delta.Z)
            C.pitch=math.clamp(math.asin(math.clamp(delta.Y/delta.Magnitude,-1,1)),-1.45,1.45)
        end
    end
    function C.passoCamera()
        if not C.ativo or C.morto or GS.fechando then return end
        -- O foco explicito da Vale Rush tem prioridade enquanto estiver travado.
        if GS.valeRush and GS.valeRush.alvoFoco then
            C.soltarMouse();C.retomar=true
            return
        end
        local camera=workspace.CurrentCamera
        local centro=C.centro()
        if not camera or not centro then return end
        if not C.cameras[camera] then
            C.cameras[camera]={tipo=camera.CameraType,foco=camera.Focus}
            if not C.inicializada then C.lerCamera(camera,centro);C.inicializada=true end
        end
        if C.retomar then C.lerCamera(camera,centro);C.retomar=false end
        C.distancia=math.clamp(C.distancia,0.5,C.limite)
        local cp=math.cos(C.pitch)
        local offset=Vector3.new(math.sin(C.yaw)*cp,math.sin(C.pitch),math.cos(C.yaw)*cp)*C.distancia
        -- Camera propria: nao usa o recuo automatico do controlador de colisao.
        camera.CameraType=Enum.CameraType.Scriptable
        camera.CFrame=CFrame.lookAt(centro+offset,centro)
        local foco=CFrame.new(centro)
        C.cameras[camera].aplicado=foco
        camera.Focus=foco
    end
    function C.iniciarCameraLivre()
        C.inicializada=false
        local camera=workspace.CurrentCamera
        local centro=C.centro()
        if camera and centro then C.lerCamera(camera,centro);C.inicializada=true end
        table.insert(C.conns,GS.conectar(entrada.InputBegan,function(input,processado)
            if processado or entrada:GetFocusedTextBox() then return end
            if GS.valeRush and GS.valeRush.alvoFoco then return end
            if input.UserInputType==Enum.UserInputType.MouseButton2 then
                C.arrastando=true;C.mouseOriginal=entrada.MouseBehavior
                entrada.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition
            end
        end))
        table.insert(C.conns,GS.conectar(entrada.InputEnded,function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton2 then C.soltarMouse() end
        end))
        table.insert(C.conns,GS.conectar(entrada.WindowFocusReleased,C.soltarMouse))
        table.insert(C.conns,GS.conectar(entrada.InputChanged,function(input,processado)
            if processado or entrada:GetFocusedTextBox() then return end
            if GS.valeRush and GS.valeRush.alvoFoco then return end
            if input.UserInputType==Enum.UserInputType.MouseWheel then
                C.distancia=math.clamp(C.distancia*math.exp(-input.Position.Z*0.2),0.5,C.limite)
            elseif input.UserInputType==Enum.UserInputType.MouseMovement
                and (C.arrastando or entrada.MouseBehavior==Enum.MouseBehavior.LockCenter) then
                C.yaw=C.yaw-input.Delta.X*0.005
                C.pitch=math.clamp(C.pitch+input.Delta.Y*0.005,-1.45,1.45)
            end
        end))
        GS.bindRender(Run,nomeRender,Enum.RenderPriority.Last.Value+3,function()
            local ok,erro=pcall(C.passoCamera)
            if not ok and os.clock()>(C.erroEm or 0) then
                C.erroEm=os.clock()+5
                warn("[DEBUG-BOT]: Camera livre:",erro)
            end
        end)
        C.passoCamera()
    end
    function C.pararCameraLivre()
        Run:UnbindFromRenderStep(nomeRender)
        if GS.recursos then GS.recursos.renders[nomeRender]=nil end
        C.soltarMouse()
        for camera,r in pairs(C.cameras) do
            pcall(function()
                if camera.CameraType==Enum.CameraType.Scriptable then camera.CameraType=r.tipo end
                if camera.Focus==r.aplicado then camera.Focus=r.foco end
            end)
        end
        C.cameras=setmetatable({}, {__mode="k"})
        C.inicializada=false;C.retomar=false
    end

    function C.aplicar()
        if not C.ativo or C.morto or C.escrevendo then return end
        C.escrevendo=true
        local ok,erro=pcall(function()
            local minimo=C.minimoTemporario or 0.5
            if player.CameraMinZoomDistance>C.limite then player.CameraMinZoomDistance=0.5 end
            if player.CameraMaxZoomDistance~=C.limite then player.CameraMaxZoomDistance=C.limite end
            if player.CameraMinZoomDistance~=minimo then player.CameraMinZoomDistance=minimo end
            if player.CameraMode~=Enum.CameraMode.Classic then player.CameraMode=Enum.CameraMode.Classic end
        end)
        C.escrevendo=false
        if not ok then
            status.Text="Não foi possível ajustar a câmera"
            warn("[DEBUG-BOT]: Câmera longe:",erro)
        end
    end
    function C.ativar()
        if C.morto or C.ativo then return end
        C.original={min=player.CameraMinZoomDistance,max=player.CameraMaxZoomDistance,modo=player.CameraMode}
        C.ativo=true
        if GS.valeRush and GS.valeRush.focar then GS.valeRush.focar(false) end
        for _,prop in ipairs({"CameraMinZoomDistance","CameraMaxZoomDistance","CameraMode"}) do
            table.insert(C.conns,GS.conectar(player:GetPropertyChangedSignal(prop),C.aplicar))
        end
        C.aplicar()
        C.iniciarCameraLivre()
        toggle.Text="CÂMERA LONGE: ON"
        status.Text="Rodinha: zoom · botão direito: girar · câmera atravessa objetos"
        print("[DEBUG-BOT]: Câmera longe: ativa",C.limite)
    end
    function C.desativar()
        C.ativo=false;C.ciclo=C.ciclo+1;C.minimoTemporario=nil
        C.pararCameraLivre()
        for _,conn in ipairs(C.conns) do conn:Disconnect() end
        table.clear(C.conns)
        local original=C.original
        C.original=nil
        if original then
            local ok,erro=pcall(function()
                -- Ordem evita o ajuste automatico entre min/max do Roblox.
                player.CameraMinZoomDistance=0.5
                player.CameraMaxZoomDistance=original.max
                player.CameraMinZoomDistance=original.min
                player.CameraMode=original.modo
            end)
            if not ok then warn("[DEBUG-BOT]: Restaurar câmera longe:",erro) end
        end
        toggle.Text="CÂMERA LONGE: OFF"
        status.Text="Desligada · distância original restaurada"
    end
    function C.ajustar(delta)
        C.limite=math.clamp(C.limite+delta,50,60000)
        valor.Text=tostring(C.limite)
        if C.minimoTemporario then C.minimoTemporario=C.limite end
        C.distancia=math.min(C.distancia,C.limite)
        C.aplicar()
    end
    function C.afastar()
        if C.morto then return end
        if not C.ativo then C.ativar() end
        C.distancia=C.limite
        C.inicializada=true
        C.passoCamera()
    end
    function C.desligar()
        if C.morto then return end
        C.desativar()
        C.morto=true
    end
    GS.conectar(toggle.MouseButton1Click,function() if C.ativo then C.desativar() else C.ativar() end end)
    GS.conectar(menos.MouseButton1Click,function() C.ajustar(-250) end)
    GS.conectar(mais.MouseButton1Click,function() C.ajustar(250) end)
    GS.conectar(afastar.MouseButton1Click,C.afastar)
    GS.conectar(maximo.MouseButton1Click,function() C.ajustar(60000) end)
    GS.conectar(ScreenGui.Destroying,C.desligar)
    GS.controladorCameraLonge=C
end
GS.rodar("Câmera longe",GS.iniciarCameraLonge,GS.painelPersonagem)

--   RETORNO SEGURO — TELEPORTE > PLAYERS
GS.iniciarRetorno = function()
    local U = GS.ui
    if not U or not GS.painelRetorno then error("Tela de retorno indisponivel") end
    local C = {}
    local s = {
        ativo=false, escolhendo=false, tecla=nil, destino=nil,
        ultimoUso=-math.huge, ultimaAmostra=-math.huge,
        historico={}, conns={}, pendente=nil, id=0,
        morto=false, remoto=nil, remotoConn=nil,
        mensagem="Defina uma tecla; o ponto seguro sera atualizado ao caminhar.",
        proximaPonte=0, proximaUI=0, sucessos=0, falhas=0,
    }
    C.s = s
    C.cfg = {
        intervalo=0.1, movimento=0.3, maxHistorico=32, normal=0.55,
        alturaMinima=25, velocidadeVertical=12, velocidadeMaxima=180,
        timeoutPonte=1.5, cooldown=2, tolerancia=6,
        prazoMinimo=20, tentativas=3, esperaVerificacao=0.3,
    }
    GS.resetMesmoLugar = false
    GS.resetStatus = nil
    GS.retornoSeguro = s

    function C.conectar(signal,fn)
        local conn = GS.conectar(signal,fn)
        table.insert(s.conns,conn)
        return conn
    end
    function C.finito(n)
        return type(n)=="number" and n==n and n>-math.huge and n<math.huge
    end
    function C.vetor(v)
        return v and C.finito(v.X) and C.finito(v.Y) and C.finito(v.Z)
    end
    function C.personagem()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not char.Parent or not hum or not root then return end
        if hum.Health<=0 or not root.Parent or not C.vetor(root.Position) then return end
        return char,hum,root
    end
    function C.piso(char,hum,root)
        if hum.Sit or hum.PlatformStand or root.Anchored then return nil,"imobilizado" end
        if hum.FloorMaterial==Enum.Material.Air then return nil,"no_ar" end
        if not C.vetor(root.AssemblyLinearVelocity) then return nil,"velocidade_invalida" end
        if math.abs(root.AssemblyLinearVelocity.Y)>C.cfg.velocidadeVertical then
            return nil,"queda"
        end
        if root.AssemblyLinearVelocity.Magnitude>C.cfg.velocidadeMaxima then
            return nil,"movimento_instavel"
        end
        if root.Position.Y<=workspace.FallenPartsDestroyHeight+C.cfg.alturaMinima then
            return nil,"void"
        end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {char}
        params.RespectCanCollide = true
        params.IgnoreWater = true
        local comprimento = math.max(7,hum.HipHeight+root.Size.Y*0.5+3)
        local hit = workspace:Raycast(root.Position,Vector3.new(0,-comprimento,0),params)
        if not hit or not C.vetor(hit.Position) or hit.Normal.Y<C.cfg.normal then
            return nil,"sem_chao_estavel"
        end
        local apoio = hit.Instance
        if not apoio or not apoio.Parent then return nil,"apoio_removido" end
        local modelo = apoio:FindFirstAncestorOfClass("Model")
        if modelo and modelo:FindFirstChildOfClass("Humanoid") then
            return nil,"outro_personagem"
        end
        if apoio:IsA("BasePart") and not apoio.Anchored then
            return nil,"apoio_movel"
        end
        return hit
    end
    function C.candidato()
        local char,hum,root = C.personagem()
        if not char then return nil,"sem_personagem" end
        local hit,motivo = C.piso(char,hum,root)
        if not hit then return nil,motivo end
        return {
            cf=root.CFrame, pos=root.Position, apoio=hit.Instance,
            normal=hit.Normal, chao=hit.Position, hora=os.clock(), char=char,
        }
    end
    function C.valido(ponto)
        if not ponto or not C.vetor(ponto.pos) or not ponto.cf then return false end
        if ponto.pos.Y<=workspace.FallenPartsDestroyHeight+C.cfg.alturaMinima then return false end
        if not ponto.apoio or not ponto.apoio.Parent then return false end
        if ponto.apoio:IsA("BasePart") and not ponto.apoio.Anchored then return false end
        return true
    end
    function C.salvar(forcar)
        if s.morto or not s.ativo or s.pendente then return false,"pausado" end
        local ponto,motivo = C.candidato()
        if not ponto then return false,motivo end
        if not forcar and s.destino and (ponto.pos-s.destino.pos).Magnitude<C.cfg.movimento then
            return false,"sem_movimento"
        end
        s.destino = ponto
        table.insert(s.historico,ponto)
        while #s.historico>C.cfg.maxHistorico do table.remove(s.historico,1) end
        return true
    end
    function C.escolherPonto()
        if C.valido(s.destino) then return s.destino end
        for i=#s.historico,1,-1 do
            if C.valido(s.historico[i]) then return s.historico[i] end
        end
        return nil
    end
    function C.status(texto)
        s.mensagem = texto
        if C.texto and C.texto.Parent then C.texto.Text = texto end
    end
    function C.atualizarUI()
        if s.morto then return end
        if C.tecla then
            C.tecla.Text = s.escolhendo and "PRESSIONE UMA TECLA · ESC CANCELA"
                or (s.tecla and ("TECLA: "..s.tecla.Name) or "DEFINIR TECLA")
        end
        if C.ativar then
            C.ativar.Text = s.pendente and "RETORNO EM ANDAMENTO"
                or (s.ativo and "RETORNO SEGURO: ON" or "RETORNO SEGURO: OFF")
        end
    end
    function C.pausarMovimento()
        for _,nome in ipairs({
            "pararFarmaFrascos","pararFarmaLucky","pararFarmaTesouro","pararFarmaNome",
        }) do
            if type(GS[nome])=="function" then
                local ok,erro = pcall(GS[nome])
                if not ok then warn("[DEBUG-BOT]: Pausa de retorno:",nome,erro) end
            end
        end
        GS.farmaDirecao = nil
        pcall(function() if ghostAtivado then alternarGhost() end end)
        pcall(function() if flyAtivado then alternarFly() end end)
        pcall(function() if GS.limparCarregar then GS.limparCarregar() end end)
    end
    function C.pedidoAtual(p)
        return not s.morto and s.pendente==p and p.id==s.id and ScreenGui.Parent~=nil
    end
    function C.finalizar(p,sucesso,motivo)
        if not C.pedidoAtual(p) then return end
        s.pendente = nil
        s.ultimoUso = os.clock()
        if sucesso then
            s.sucessos = s.sucessos+1
            -- Continua no ponto de retorno; nao grava o spawn intermediario.
            s.destino = p.ponto
            C.status("Retorno confirmado · salvamento automatico retomado")
        else
            s.falhas = s.falhas+1
            C.status("Retorno interrompido: "..tostring(motivo))
        end
        s.ultimaAmostra = os.clock()
        C.atualizarUI()
        print("[DEBUG-BOT]: Retorno",sucesso and "confirmado" or "falhou",motivo or "")
    end
    function C.resetLocal(p)
        if not C.pedidoAtual(p) or p.resetSolicitado or p.servidor then return end
        p.resetSolicitado = true
        p.fase = "renascendo"
        C.status("Renascendo · aguardando o tempo normal do servidor")
        if type(GS.renascer)~="function" then
            C.finalizar(p,false,"reset indisponivel")
            return
        end
        local ok,erro = pcall(GS.renascer)
        if not ok then C.finalizar(p,false,tostring(erro)) end
    end
    function C.ack(comando,dados)
        local p = s.pendente
        if comando~="return" or type(dados)~="table" or not p then return end
        if dados.id~=p.id or not C.pedidoAtual(p) then return end
        if dados.ok~=true then
            -- Sem confirmacao de reset, o caminho local ainda pode ser usado.
            if not p.servidor then
                C.resetLocal(p)
            else
                C.finalizar(p,false,dados.reason or "servidor recusou")
            end
            return
        end
        if dados.phase=="accepted" then
            p.servidor = true
            p.fase = "servidor"
            C.status("Retorno autorizado · servidor carregando personagem")
        elseif dados.phase=="completed" then
            p.servidor = true
            p.concluidoServidor = true
            p.concluidoEm = os.clock()
            if C.vetor(dados.position) then p.posServidor = dados.position end
            C.status("Servidor concluiu · verificando personagem")
        end
    end
    function C.procurarPonte()
        if s.remoto and s.remoto.Parent then return s.remoto end
        if s.remotoConn then s.remotoConn:Disconnect(); s.remotoConn=nil end
        s.remoto = nil
        local rs = game:GetService("ReplicatedStorage")
        local remoto = rs:FindFirstChild("GringoPanelBridge")
        if not remoto or not remoto:IsA("RemoteEvent") then return nil end
        s.remoto = remoto
        s.remotoConn = GS.conectar(remoto.OnClientEvent,C.ack)
        return remoto
    end
    function C.solicitar()
        if s.morto or not s.ativo or s.escolhendo or s.pendente then return false,"ocupado" end
        if os.clock()-s.ultimoUso<C.cfg.cooldown then return false,"intervalo" end
        local char = C.personagem()
        if not char then return false,"sem_personagem" end
        C.salvar(true)
        local ponto = C.escolherPonto()
        if not ponto then
            C.status("Aguarde em um chao firme para registrar o primeiro ponto")
            return false,"sem_ponto_seguro"
        end
        s.id = s.id+1
        local p = {
            id=s.id, ponto=ponto, antigo=char, inicio=os.clock(),
            prazo=os.clock()+math.max(C.cfg.prazoMinimo,Players.RespawnTime+12),
            fase="solicitando", servidor=false, resetSolicitado=false,
            tentativas=0, proximaTentativa=0,
        }
        s.pendente = p
        s.ultimoUso = os.clock()
        C.pausarMovimento()
        C.atualizarUI()
        local remoto = C.procurarPonte()
        local enviou = false
        if remoto then
            enviou = pcall(function()
                remoto:FireServer("return",{id=p.id,version=1})
            end)
        end
        if enviou then
            p.enviadoServidor = true
            C.status("Solicitando retorno ao servidor de playtest")
        else
            C.resetLocal(p)
        end
        return true
    end
    function C.verificar(p,char,root)
        if not C.pedidoAtual(p) or char==p.antigo then return false end
        local destino = p.posServidor or p.ponto.pos
        if (root.Position-destino).Magnitude<=C.cfg.tolerancia then
            if not p.pertoEm then p.pertoEm=os.clock() end
            if os.clock()-p.pertoEm>=C.cfg.esperaVerificacao then
                C.finalizar(p,true,"posicao estavel")
                return true
            end
        else
            p.pertoEm = nil
        end
        return false
    end
    function C.aplicarLocal(p,char,hum,root)
        if p.servidor or not C.pedidoAtual(p) or char==p.antigo then return end
        if not C.valido(p.ponto) then
            C.finalizar(p,false,"o apoio salvo foi removido")
            return
        end
        if os.clock()<p.proximaTentativa then return end
        if p.tentativas>=C.cfg.tentativas then
            C.finalizar(p,false,"o jogo corrigiu a posicao")
            return
        end
        p.tentativas = p.tentativas+1
        p.proximaTentativa = os.clock()+0.8
        p.fase = "verificando"
        local ok,erro = pcall(function()
            hum.Sit = false
            hum.PlatformStand = false
            root.CFrame = p.ponto.cf
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        if not ok then
            C.finalizar(p,false,tostring(erro))
            return
        end
        C.status("Verificando retorno · tentativa "..p.tentativas)
    end
    function C.passo()
        if s.morto then return end
        local agora = os.clock()
        local p = s.pendente
        if p then
            if agora>p.prazo then
                C.finalizar(p,false,"tempo de resposta excedido")
                return
            end
            if not p.servidor and not p.resetSolicitado and agora-p.inicio>C.cfg.timeoutPonte then
                if p.enviadoServidor then
                    if not p.avisouDemora then
                        p.avisouDemora = true
                        C.status("Servidor sem resposta · aguardando sem duplicar o reset")
                    end
                else
                    C.resetLocal(p)
                end
            end
            local char,hum,root = C.personagem()
            if char and char~=p.antigo then
                if C.verificar(p,char,root) then return end
                if not p.servidor then C.aplicarLocal(p,char,hum,root) end
            end
        elseif s.ativo and agora-s.ultimaAmostra>=C.cfg.intervalo then
            s.ultimaAmostra = agora
            local gravou = C.salvar(false)
            if gravou then
                local pos = s.destino.pos
                C.status(string.format("Ponto automatico: %.0f, %.0f, %.0f · tecla %s",
                    pos.X,pos.Y,pos.Z,s.tecla and s.tecla.Name or "?"))
            end
        end
        if agora>=s.proximaUI then
            s.proximaUI = agora+0.25
            C.atualizarUI()
        end
    end
    function C.definirTecla(tecla)
        if tecla==Enum.KeyCode.Unknown or tecla==Enum.KeyCode.Escape
            or tecla==Enum.KeyCode.K or tecla==Enum.KeyCode.L or tecla==teclaMenu then
            return false
        end
        s.tecla = tecla
        s.escolhendo = false
        s.ativo = true
        C.salvar(true)
        C.atualizarUI()
        C.status("Retorno ativo · caminhe para atualizar o ponto automaticamente")
        return true
    end
    function C.entrada(input,processado)
        if input.UserInputType~=Enum.UserInputType.Keyboard then return end
        if UserInputService:GetFocusedTextBox() or escutandoTecla then return end
        if s.escolhendo then
            if input.KeyCode==Enum.KeyCode.Escape then
                s.escolhendo = false
                C.atualizarUI()
                return
            end
            if not C.definirTecla(input.KeyCode) then
                C.status("Tecla reservada; escolha outra diferente de K, L e menu")
            end
            return
        end
        if processado or input.KeyCode~=s.tecla or input.KeyCode==teclaMenu then return end
        C.solicitar()
    end
    function C.desligar()
        if s.morto then return end
        s.morto = true
        s.ativo = false
        s.escolhendo = false
        s.id = s.id+1
        s.pendente = nil
        for _,conn in ipairs(s.conns) do conn:Disconnect() end
        table.clear(s.conns)
        if s.remotoConn then s.remotoConn:Disconnect(); s.remotoConn=nil end
        s.remoto = nil
        table.clear(s.historico)
    end
    local grupo = U.grupo(GS.painelRetorno,"Retorno seguro",
        "A tecla renasce e retorna. O ponto e salvo automaticamente ao caminhar.","shield-check",1)
    C.tecla = U.pequeno(grupo,"DEFINIR TECLA",nil,1,"keyboard")
    C.ativar = U.tog(grupo,"Retorno seguro",2,"shield-check")
    C.texto = U.pequeno(grupo,s.mensagem,nil,3,"info")
    C.texto.Active = false
    C.texto.AutoButtonColor = false
    C.texto.TextWrapped = true
    C.conectar(C.tecla.MouseButton1Click,function()
        if s.pendente or escutandoTecla then return end
        s.escolhendo = true
        C.atualizarUI()
    end)
    C.conectar(C.ativar.MouseButton1Click,function()
        if s.pendente then
            C.status("Aguarde o retorno terminar antes de desativar")
            return
        end
        if not s.tecla then
            s.escolhendo = true
        else
            s.ativo = not s.ativo
            if s.ativo then C.salvar(true) end
            C.status(s.ativo and "Salvamento automatico ativado" or "Retorno desativado")
        end
        C.atualizarUI()
    end)
    C.conectar(UserInputService.InputBegan,C.entrada)
    C.conectar(RunService.Heartbeat,function()
        local ok,erro = pcall(C.passo)
        if not ok then
            if s.pendente then C.finalizar(s.pendente,false,tostring(erro)) end
            if os.clock()>=(s.proximoErro or 0) then
                s.proximoErro = os.clock()+5
                warn("[DEBUG-BOT]: Retorno seguro:",erro)
            end
        end
    end)
    C.conectar(ScreenGui.Destroying,C.desligar)
    GS.controladorRetorno = C
    C.atualizarUI()
    return C
end
GS.rodar("Retorno seguro", GS.iniciarRetorno, GS.painelRetorno)

-- MODO LEVE (CONFIGURACOES): pra PC fraco / Windows 10 que crasha.
-- Pausa as animacoes em loop (borda girando, brilho do titulo), desliga o
-- efeito de onda dos cliques e deixa a checagem das chaves mais espacada.
do
    if GS.leveBtn then
        GS.conectar(GS.leveBtn.MouseButton1Click,function()
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
GS.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        for _, f in ipairs(GS.syncToggles or {}) do pcall(f) end
        task.wait(GS.leve and 0.8 or 0.3)
    end
end)

-- ABERTURA SILENCIOSA: nada liga sozinho (toda funcao principal nasce OFF) e
-- os avisos de "ativado/desativado" so valem depois que tudo carregou e as
-- chaves sincronizaram (o sync roda a cada 0.3s; 2s cobre com folga).
GS.delay(2, function() GS.avisosLiberados = true end)



