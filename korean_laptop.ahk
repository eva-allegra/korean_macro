#Requires AutoHotkey v2.0
#SingleInstance Force

; Korean 3x4 keypad mapper for NUMPAD only.
; Top-row number keys remain unchanged.
; Press the same numpad key repeatedly within 700ms to cycle symbols.

global isActive := true
global koreanMode := false
global tapTimeoutMs := 700
global lastKey := ""
global lastTick := 0
global lastIndex := 1
global outputTokens := []
global lastRendered := ""
global arrowSeq := ""
global arrowSeqTimes := []
global arrowStepTimeoutMs := 350

; Physical numpad layout on German keyboards:
; 7 8 9
; 4 5 6
; 1 2 3
;   0
;
; This map uses a classic mobile-style 3x4 Korean keypad preset.
; Numpad position -> Korean symbols (tap to cycle)
global keyMap := Map(
    "N4", ["ㄱ", "ㅋ", "ㄲ"], ; phone key 1
    "N5", ["ㄴ", "ㄹ"],  ; phone key 2
    "N6", ["ㄷ", "ㅌ", "ㄸ"],  ; phone key 3
    "N1", ["ㅂ", "ㅍ", "ㅃ"],  ; phone key 4
    "N2", ["ㅅ", "ㅎ", "ㅆ"],  ; phone key 5
    "N3", ["ㅈ", "ㅊ", "ㅉ"],  ; phone key 6
    "N0", ["ㅇ", "ㅁ"],  ; phone key 7
    "N7", ["ㅣ"],        ; phone key 8
    "N8", ["ㆍ"],        ; phone key 9
    "N9", ["ㅡ"]         ; phone key 0
)

; Two-step vowel composition (Cheonjiin-style)
global vowelCompose2 := Map(
    "ㆍㅣ", "ㅓ",
    "ㅣㆍ", "ㅏ",
    "ㆍㅡ", "ㅗ",
    "ㅡㆍ", "ㅜ",
    "ㅡㅣ", "ㅢ",
    "ㅏㅣ", "ㅐ",
    "ㅓㅣ", "ㅔ",
    "ㅑㅣ", "ㅒ",
    "ㅕㅣ", "ㅖ",
    "ㅗㅣ", "ㅚ",
    "ㅜㅣ", "ㅟ",
    "ㅗㅏ", "ㅘ",
    "ㅗㅐ", "ㅙ",
    "ㅜㅓ", "ㅝ",
    "ㅜㅔ", "ㅞ"
)

; Three-step vowel composition
global vowelCompose3 := Map(
    "ㅣㆍㆍ", "ㅑ",
    "ㆍㆍㅣ", "ㅕ",
    "ㆍㆍㅡ", "ㅛ",
    "ㅡㆍㆍ", "ㅠ"
)

; Four-step fallback patterns needed for practical Cheonjiin flows.
global vowelCompose4 := Map(
    "ㅡㆍㆍㅣ", "ㅝ"
)

; Preferred step-back target when deleting a 3-step vowel.
global vowelBackspace3 := Map(
    "ㅣㆍㆍ", "ㅣㆍ", ; ㅑ -> ㅏ
    "ㆍㆍㅣ", "ㆍㅣ", ; ㅕ -> ㅓ
    "ㆍㆍㅡ", "ㆍㅡ", ; ㅛ -> ㅗ
    "ㅡㆍㆍ", "ㅡㆍ"  ; ㅠ -> ㅜ
)

global choseongIndex := Map(
    "ㄱ", 0, "ㄲ", 1, "ㄴ", 2, "ㄷ", 3, "ㄸ", 4, "ㄹ", 5, "ㅁ", 6, "ㅂ", 7, "ㅃ", 8,
    "ㅅ", 9, "ㅆ", 10, "ㅇ", 11, "ㅈ", 12, "ㅉ", 13, "ㅊ", 14, "ㅋ", 15, "ㅌ", 16,
    "ㅍ", 17, "ㅎ", 18
)

global jungseongIndex := Map(
    "ㅏ", 0, "ㅐ", 1, "ㅑ", 2, "ㅒ", 3, "ㅓ", 4, "ㅔ", 5, "ㅕ", 6, "ㅖ", 7,
    "ㅗ", 8, "ㅘ", 9, "ㅙ", 10, "ㅚ", 11, "ㅛ", 12, "ㅜ", 13, "ㅝ", 14, "ㅞ", 15,
    "ㅟ", 16, "ㅠ", 17, "ㅡ", 18, "ㅢ", 19, "ㅣ", 20
)

global jongseongIndex := Map(
    "", 0,
    "ㄱ", 1, "ㄲ", 2, "ㄳ", 3, "ㄴ", 4, "ㄵ", 5, "ㄶ", 6, "ㄷ", 7, "ㄹ", 8, "ㄺ", 9,
    "ㄻ", 10, "ㄼ", 11, "ㄽ", 12, "ㄾ", 13, "ㄿ", 14, "ㅀ", 15, "ㅁ", 16, "ㅂ", 17,
    "ㅄ", 18, "ㅅ", 19, "ㅆ", 20, "ㅇ", 21, "ㅈ", 22, "ㅊ", 23, "ㅋ", 24, "ㅌ", 25,
    "ㅍ", 26, "ㅎ", 27
)

global finalPairCompose := Map(
    "ㄱㅅ", "ㄳ",
    "ㄴㅈ", "ㄵ",
    "ㄴㅎ", "ㄶ",
    "ㄹㄱ", "ㄺ",
    "ㄹㅁ", "ㄻ",
    "ㄹㅂ", "ㄼ",
    "ㄹㅅ", "ㄽ",
    "ㄹㅌ", "ㄾ",
    "ㄹㅍ", "ㄿ",
    "ㄹㅎ", "ㅀ",
    "ㅂㅅ", "ㅄ"
)

global finalPairSplit := Map(
    "ㄳ", ["ㄱ", "ㅅ"],
    "ㄵ", ["ㄴ", "ㅈ"],
    "ㄶ", ["ㄴ", "ㅎ"],
    "ㄺ", ["ㄹ", "ㄱ"],
    "ㄻ", ["ㄹ", "ㅁ"],
    "ㄼ", ["ㄹ", "ㅂ"],
    "ㄽ", ["ㄹ", "ㅅ"],
    "ㄾ", ["ㄹ", "ㅌ"],
    "ㄿ", ["ㄹ", "ㅍ"],
    "ㅀ", ["ㄹ", "ㅎ"],
    "ㅄ", ["ㅂ", "ㅅ"]
)

; Toggle mapper on/off
F12:: {
    global isActive, koreanMode, lastKey, lastTick, lastIndex, outputTokens, lastRendered
    isActive := !isActive
    if !isActive {
        koreanMode := false
    }
    ; Reset state on toggle to avoid stale composition/cycle state.
    lastKey := ""
    lastTick := 0
    lastIndex := 1
    outputTokens := []
    lastRendered := ""
    state := isActive ? "ON" : "OFF"
    TrayTip "Korean Numpad Mapper", "Mapper is now " state, 1000
}

#HotIf isActive

~Down::RegisterArrowStep("D")
~Up::RegisterArrowStep("U")

#HotIf isActive && koreanMode

i::HandleMappedKey("N7", "i")
o::HandleMappedKey("N8", "o")
p::HandleMappedKey("N9", "p")
k::HandleMappedKey("N4", "k")
l::HandleMappedKey("N5", "l")
vkBA::HandleMappedKey("N6", "vkBA") ; oe/Ö fallback 1
vkC0::HandleMappedKey("N6", "vkC0") ; oe/Ö fallback 2
sc027::HandleMappedKey("N6", "sc027") ; physical key right of L on many DE layouts
,::HandleMappedKey("N1", ",")
.::HandleMappedKey("N2", ".")
-::HandleMappedKey("N3", "-")
m::HandleMappedKey("N0", "m")
AppsKey::HandleMappedKey("N0", "AppsKey")
RAlt::HandleMappedKey("N0", "RAlt")
Backspace::HandleBackspace()

#HotIf

HandleMappedKey(keyId, physKey) {
    SendMapped(keyId)
    ; Prevent key auto-repeat from generating duplicate symbols/syllables.
    KeyWait physKey
}

RegisterArrowStep(step) {
    global isActive, koreanMode, arrowSeq, arrowSeqTimes, arrowStepTimeoutMs

    if !isActive {
        return
    }

    now := A_TickCount

    if (arrowSeqTimes.Length > 0) && ((now - arrowSeqTimes[arrowSeqTimes.Length]) > arrowStepTimeoutMs) {
        arrowSeq := ""
        arrowSeqTimes := []
    }

    arrowSeq .= step
    arrowSeqTimes.Push(now)

    if StrLen(arrowSeq) > 3 {
        arrowSeq := SubStr(arrowSeq, -2)
        arrowSeqTimes.RemoveAt(1)
    }

    if (arrowSeq = "DUD") && (arrowSeqTimes.Length = 3) {
        totalGap := arrowSeqTimes[3] - arrowSeqTimes[1]
        if totalGap <= arrowStepTimeoutMs * 2 {
            koreanMode := !koreanMode
            ClearOutputTracking()
            state := koreanMode ? "Korean ON" : "Korean OFF"
            TrayTip "Korean Laptop Mapper", state, 1000
        }
        arrowSeq := ""
        arrowSeqTimes := []
    }
}

SendMapped(keyId) {
    global keyMap, tapTimeoutMs, lastKey, lastTick, lastIndex, outputTokens

    ; If user typed normal keys between mapped presses, drop stale composition context.
    if (outputTokens.Length > 0) && !IsMappedContinuationKey(A_PriorKey) {
        ClearOutputTracking()
    }

    chars := keyMap[keyId]
    if chars.Length = 0 {
        return
    }

    now := A_TickCount
    if (lastKey = keyId) && ((now - lastTick) <= tapTimeoutMs) && (chars.Length > 1) {
        ; Replace the last inserted token with the next symbol from this key's cycle.
        lastIndex := Mod(lastIndex, chars.Length) + 1
        if outputTokens.Length > 0 {
            outputTokens.RemoveAt(outputTokens.Length)
        }
    } else {
        lastIndex := 1
    }

    SendWithComposition(chars[lastIndex])
    lastKey := keyId
    lastTick := now
}

IsMappedContinuationKey(priorKey) {
    switch priorKey {
        case "i", "o", "p", "k", "l", "vkBA", "vkC0", "sc027", ",", ".", "-", "m", "AppsKey", "RAlt", "Backspace":
            return true
        default:
            return false
    }
}

SendWithComposition(char) {
    global outputTokens

    len := outputTokens.Length

    if len >= 2 {
        tokenA := outputTokens[len - 1]
        tokenB := outputTokens[len]
        if (StrLen(tokenA.raw) = 1) && (StrLen(tokenB.raw) = 1) {
            seq3 := tokenA.raw . tokenB.raw . char
            composed3 := ComposeSequence(seq3)
            if composed3 != "" {
                outputTokens.RemoveAt(len)
                outputTokens.RemoveAt(len - 1)
                outputTokens.Push({raw: seq3, text: composed3})
                RenderFromTokens()
                return
            }
        }
    }

    if outputTokens.Length > 0 {
        token := outputTokens[outputTokens.Length]
        candidateBase := token.raw . char
        composed := ComposeSequence(candidateBase)

        if composed != "" {
            token.raw := candidateBase
            token.text := composed
            outputTokens[outputTokens.Length] := token
            RenderFromTokens()
            return
        }
    }

    outputTokens.Push({raw: char, text: char})
    if outputTokens.Length > 24 {
        outputTokens.RemoveAt(1)
    }
    RenderFromTokens()
}

ComposeSequence(seq) {
    global vowelCompose2, vowelCompose3, vowelCompose4

    if StrLen(seq) = 1 {
        return seq
    }

    if StrLen(seq) = 2 && vowelCompose2.Has(seq) {
        return vowelCompose2[seq]
    }

    if StrLen(seq) = 3 && vowelCompose3.Has(seq) {
        return vowelCompose3[seq]
    }

    if StrLen(seq) = 4 && vowelCompose4.Has(seq) {
        return vowelCompose4[seq]
    }

    return ""
}

HandleBackspace() {
    global outputTokens, lastKey, lastTick, lastIndex, vowelBackspace3, lastRendered

    ; Stop multi-tap carry-over when user starts deleting.
    lastKey := ""
    lastTick := 0
    lastIndex := 1

    if outputTokens.Length = 0 {
        lastRendered := ""
        Send "{Backspace}"
        return
    }

    token := outputTokens[outputTokens.Length]
    if StrLen(token.raw) > 1 {
        reducedBase := SubStr(token.raw, 1, StrLen(token.raw) - 1)
        if (StrLen(token.raw) = 3) && vowelBackspace3.Has(token.raw) {
            reducedBase := vowelBackspace3[token.raw]
        }
        reducedOut := ComposeSequence(reducedBase)

        if reducedOut != "" {
            token.raw := reducedBase
            token.text := reducedOut
            outputTokens[outputTokens.Length] := token
            RenderFromTokens()
            return
        }
    }

    outputTokens.RemoveAt(outputTokens.Length)
    RenderFromTokens()
}

~Left::ClearOutputTracking()
~Right::ClearOutputTracking()
~Up::ClearOutputTracking()
~Down::ClearOutputTracking()
~Home::ClearOutputTracking()
~End::ClearOutputTracking()
~LButton::ClearOutputTracking()
~RButton::ClearOutputTracking()
ClearOutputTracking() {
    global outputTokens, lastKey, lastTick, lastIndex, lastRendered

    outputTokens := []
    lastRendered := ""
    lastKey := ""
    lastTick := 0
    lastIndex := 1
}

~Enter:: {
    ; New line means old composition context is no longer reliable.
    ClearOutputTracking()
}

~Space::ClearOutputTracking()
~NumpadDiv::ClearOutputTracking()
~/::ClearOutputTracking()
~Tab::ClearOutputTracking()
~,::ClearOutputTracking()
~.::ClearOutputTracking()
~;::ClearOutputTracking()
~'::ClearOutputTracking()
~-::ClearOutputTracking()
~NumpadDot::ClearOutputTracking()
~NumpadAdd::ClearOutputTracking()
~NumpadSub::ClearOutputTracking()
~NumpadMult::ClearOutputTracking()

RenderFromTokens() {
    global outputTokens, lastRendered

    jamoChars := []
    for token in outputTokens {
        jamoChars.Push(token.text)
    }

    rendered := ComposeHangulText(jamoChars)

    if StrLen(lastRendered) > 0 {
        Send "{Backspace " StrLen(lastRendered) "}"
    }
    if StrLen(rendered) > 0 {
        SendText rendered
    }

    lastRendered := rendered
}

ComposeHangulText(chars) {
    global choseongIndex, jungseongIndex, jongseongIndex, finalPairCompose, finalPairSplit, vowelCompose2

    rendered := ""
    L := ""
    V := ""
    T := ""

    for c in chars {
        isVowel := jungseongIndex.Has(c)
        isInitial := choseongIndex.Has(c)
        isFinal := jongseongIndex.Has(c) && (c != "") && (jongseongIndex[c] > 0)

        if isVowel {
            if (L = "") {
                rendered .= c
                continue
            }

            if (V = "") {
                V := c
                continue
            }

            if (T != "") {
                if finalPairSplit.Has(T) {
                    parts := finalPairSplit[T]
                    rendered .= MakeSyllable(L, V, parts[1])
                    L := parts[2]
                    V := c
                    T := ""
                } else {
                    moved := T
                    rendered .= MakeSyllable(L, V, "")
                    L := moved
                    V := c
                    T := ""
                }
                continue
            }

            combinedV := V . c
            if vowelCompose2.Has(combinedV) {
                V := vowelCompose2[combinedV]
                continue
            }

            rendered .= MakeSyllable(L, V, "")
            L := ""
            V := ""
            T := ""
            rendered .= c
            continue
        }

        if isInitial {
            if (L = "") {
                L := c
                continue
            }

            if (V = "") {
                rendered .= L
                L := c
                continue
            }

            if (T = "") {
                if isFinal {
                    T := c
                    continue
                }
                rendered .= MakeSyllable(L, V, "")
                L := c
                V := ""
                T := ""
                continue
            }

            pair := T . c
            if finalPairCompose.Has(pair) {
                T := finalPairCompose[pair]
                continue
            }

            rendered .= MakeSyllable(L, V, T)
            L := c
            V := ""
            T := ""
            continue
        }

        if (L != "") {
            if (V != "") {
                rendered .= MakeSyllable(L, V, T)
            } else {
                rendered .= L
            }
            L := ""
            V := ""
            T := ""
        }
        rendered .= c
    }

    if (L != "") {
        if (V != "") {
            rendered .= MakeSyllable(L, V, T)
        } else {
            rendered .= L
        }
    }

    return rendered
}

MakeSyllable(L, V, T := "") {
    global choseongIndex, jungseongIndex, jongseongIndex

    if !choseongIndex.Has(L) || !jungseongIndex.Has(V) {
        return L . V . T
    }

    if !jongseongIndex.Has(T) {
        T := ""
    }

    code := 0xAC00 + ((choseongIndex[L] * 21 + jungseongIndex[V]) * 28) + jongseongIndex[T]
    return Chr(code)
}
