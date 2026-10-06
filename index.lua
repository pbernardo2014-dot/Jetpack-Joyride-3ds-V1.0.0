TOP_SCREEN = 0
BOTTOM_SCREEN = 1

local colGiallo   = Color.new(255, 220, 0)
local colRosso    = Color.new(235, 50, 35)
local colArancio  = Color.new(255, 140, 0)
local colVerde    = Color.new(0, 230, 100)
local colNero     = Color.new(20, 20, 20)
local colGrigioSc = Color.new(70, 75, 85)
local colGrigioCh = Color.new(140, 145, 155)
local colBluAbito = Color.new(40, 60, 120)

local barryY = 100
local velY = 0
local gravitaBase = 0.3
local spintaBase = -0.6
local gravita = gravitaBase
local spinta = spintaBase
local staSpingendo = false

local velocitaGioco = 4

-- Ostacolo Zapper
local zapperX = 300
local zapperY = 80
local zapperAltezza = 50

-- Moneta
local monetaX = 380
local monetaY = 100
local monetaRaccolta = false
local moneteTotali = 0

-- Metri e Difficolta
local metri = 0
local frameCount = 0
local gameOver = false

local function pausetta()
    for i = 1, 150000 do end
end

-- Funzione sicura per i bordi dello schermo
local function drawRectSafe(x1, x2, y1, y2, color)
    if x1 < 0 then x1 = 0 end
    if x2 > 399 then x2 = 399 end
    if y1 < 0 then y1 = 0 end
    if y2 > 239 then y2 = 239 end
    
    if x1 <= x2 and y1 <= y2 then
        Screen.fillRect(x1, x2, y1, y2, color, TOP_SCREEN)
    end
end

-- Disegna cifre 7 segmenti
local function disegnaCifra(x, y, num, colore)
    colore = colore or colVerde
    local seg = {
        [0] = {1,1,1,0,1,1,1},
        [1] = {0,0,1,0,0,1,0},
        [2] = {1,0,1,1,1,0,1},
        [3] = {1,0,1,1,0,1,1},
        [4] = {0,1,1,1,0,1,0},
        [5] = {1,1,0,1,0,1,1},
        [6] = {1,1,0,1,1,1,1},
        [7] = {1,0,1,0,0,1,0},
        [8] = {1,1,1,1,1,1,1},
        [9] = {1,1,1,1,0,1,1}
    }
    local s = seg[num] or seg[0]
    
    if s[1] == 1 then drawRectSafe(x, x + 10, y, y + 2, colore) end
    if s[2] == 1 then drawRectSafe(x, x + 2, y, y + 8, colore) end
    if s[3] == 1 then drawRectSafe(x + 8, x + 10, y, y + 8, colore) end
    if s[4] == 1 then drawRectSafe(x, x + 10, y + 7, y + 9, colore) end
    if s[5] == 1 then drawRectSafe(x, x + 2, y + 8, y + 14, colore) end
    if s[6] == 1 then drawRectSafe(x + 8, x + 10, y + 8, y + 14, colore) end
    if s[7] == 1 then drawRectSafe(x, x + 10, y + 13, y + 15, colore) end
end

local function mostraNumero(x, y, valore, colore)
    local v = math.floor(valore) % 1000
    local c1 = math.floor(v / 100)
    local c2 = math.floor((v % 100) / 10)
    local c3 = v % 10

    disegnaCifra(x, y, c1, colore)
    disegnaCifra(x + 13, y, c2, colore)
    disegnaCifra(x + 26, y, c3, colore)
end

-- Sfondo Laboratorio
local function disegnaSfondoFabbrica()
    drawRectSafe(0, 399, 0, 239, colGrigioSc)
    
    for px = 0, 399, 80 do
        drawRectSafe(px, px + 2, 0, 239, colGrigioCh)
    end

    drawRectSafe(0, 399, 0, 15, colNero)
    drawRectSafe(0, 399, 215, 239, colNero)

    for i = 0, 399, 20 do
        drawRectSafe(i, i + 10, 12, 15, colGiallo)
        drawRectSafe(i, i + 10, 215, 218, colGiallo)
    end
end

-- Barry con Jetpack
local function disegnaBarry(x, y, spintaAttiva)
    drawRectSafe(x - 6, x - 1, y + 4, y + 16, colGrigioCh)
    
    if spintaAttiva then
        drawRectSafe(x - 5, x - 2, y + 16, y + 24, colArancio)
        drawRectSafe(x - 4, x - 3, y + 22, y + 28, colGiallo)
    end

    drawRectSafe(x, x + 14, y + 6, y + 18, colBluAbito)
    drawRectSafe(x + 2, x + 12, y, y + 6, colGiallo)
    drawRectSafe(x + 6, x + 14, y + 1, y + 4, colNero)
end

-- Zapper Elettrico
local function disegnaZapper(x, y, h)
    drawRectSafe(x, x + 15, y, y + 8, colGrigioCh)
    drawRectSafe(x, x + 15, y + h - 8, y + h, colGrigioCh)

    local centroY = y + math.floor(h / 2)
    drawRectSafe(x - 3, x + 18, centroY - 8, centroY + 8, colRosso)
    drawRectSafe(x, x + 15, centroY - 5, centroY + 5, colArancio)
    drawRectSafe(x + 3, x + 12, centroY - 2, centroY + 2, colGiallo)
end

-- Moneta d'Oro
local function disegnaMoneta(x, y)
    drawRectSafe(x, x + 10, y, y + 10, colGiallo)
    drawRectSafe(x + 2, x + 8, y + 2, y + 8, colArancio)
end

-- CICLO PRINCIPALE DEL GIOCO
while true do
    local pad = Controls.read()

    if not gameOver then
        -- 1. Metri e calcolo velocita
        frameCount = frameCount + 1
        if frameCount >= 8 then
            metri = metri + 1
            frameCount = 0

            local livello = math.floor(metri / 50)
            velocitaGioco = 4 + (livello * 1.5)
            gravita = gravitaBase + (livello * 0.08)
            spinta = spintaBase - (livello * 0.08)
        end

        -- 2. Controlli e fisica
        staSpingendo = false
        if Controls.check(pad, KEY_A) then
            velY = velY + spinta
            staSpingendo = true
        end

        velY = velY + gravita
        barryY = barryY + velY

        if barryY < 16 then barryY = 16; velY = 0 end
        if barryY > 195 then barryY = 195; velY = 0 end

        -- 3. Movimento ostacoli
        zapperX = zapperX - math.floor(velocitaGioco)

        if zapperX < -25 then 
            zapperX = 380
            zapperY = math.random(20, 150)
            zapperAltezza = math.random(45, 65)
        end

        -- 4. Movimento e collisione moneta
        monetaX = monetaX - math.floor(velocitaGioco)

        if monetaX < -15 then
            monetaX = math.random(380, 480)
            monetaY = math.random(30, 180)
            monetaRaccolta = false
        end

        if not monetaRaccolta and
           50 < monetaX + 10 and 64 > monetaX and
           barryY < monetaY + 10 and barryY + 18 > monetaY then
            monetaRaccolta = true
            moneteTotali = moneteTotali + 1
        end

        -- 5. Collisione zapper
        if 50 < zapperX + 15 and 64 > zapperX and
           barryY < zapperY + zapperAltezza and barryY + 18 > zapperY then
            gameOver = true
        end
    else
        -- Restart con tasto X
        if Controls.check(pad, KEY_X) then
            barryY = 100
            velY = 0
            zapperX = 350
            monetaX = 380
            metri = 0
            moneteTotali = 0
            velocitaGioco = 4
            gravita = gravitaBase
            spinta = spintaBase
            frameCount = 0
            monetaRaccolta = false
            gameOver = false
        end
    end

    -- Rendering
    Screen.refresh()
    Screen.clear(TOP_SCREEN)
    Screen.clear(BOTTOM_SCREEN)

    local posY = math.floor(barryY)

    disegnaSfondoFabbrica()

    if not gameOver then
        if not monetaRaccolta then
            disegnaMoneta(monetaX, monetaY)
        end

        disegnaBarry(50, posY, staSpingendo)
        disegnaZapper(zapperX, zapperY, zapperAltezza)

        mostraNumero(20, 20, metri, colVerde)
        mostraNumero(330, 20, moneteTotali, colGiallo)
    else
        drawRectSafe(130, 270, 70, 150, colRosso)
        mostraNumero(175, 170, metri, colGiallo)
    end

    Screen.flip()
    pausetta()

    if Controls.check(pad, KEY_START) then
        break
    end
end

System.exit()
