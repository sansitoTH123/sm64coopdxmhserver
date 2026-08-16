-- gui_main.lua - created by Marioiscool246 on 2/7/2024, last updated on 10/16/2024 MM/DD/YY

-- GUI render table and cursor render global
GUIMainWindow = nil

-- GUI Types
GUI_TYPE_WINDOW              = 0
GUI_SELECTABLE_TYPE_SPACER   = 100
GUI_SELECTABLE_TYPE_LABEL    = 101
GUI_SELECTABLE_TYPE_TOGGLE   = 102
GUI_SELECTABLE_TYPE_BUTTON   = 103
GUI_SELECTABLE_TYPE_LRSELECT = 104

-- GUIWindow

GUIWindow = {
    type = GUI_TYPE_WINDOW,
    title = "",
    tooltip = "DPad U/D: Change Selection | B: Close",
    posX = 0.0,
    posY = 0.0,
    width = 0.0,
    height = 0.0,
    selectables = {},
    selectablesPosX = 0,
    selectablesPosY = 0,
    selectablesWidth = 0,
    selectablesHeight = 0,
    selectablesSize = 42.0,
    selectablesCount = 0,
    selectedSelectableId = -1,
    hideSelectedHighlight = false
}

---@param title string
---@param posX number
---@param posY number
---@param width number
---@param height number
function GUIWindow:init(title, posX, posY, width, height)
    self.title = title
    self.posX = posX
    self.posY = posY
    self.width = width
    self.height = height

    local posYOffset = 72.0
    local marginX = 25.0

    self.selectablesPosX = self.posX + marginX
    self.selectablesPosY = self.posY + posYOffset
    self.selectablesWidth = self.width - (marginX * 2)
    self.selectablesHeight = self.height - (posYOffset - 32.0)
end

function GUIWindow:render()
    local bgWidth = self.width
    local bgHeight = self.height

    local bgPosX = self.posX
    local bgPosY = self.posY

    local bgCenterX = bgPosX + (bgWidth * 0.5)

    djui_hud_set_font(FONT_HUD)

    local titleScale = 2.0
    local titleWidth = djui_hud_measure_text(self.title) * titleScale

    -- render bg
    djui_hud_set_color(0, 0, 0, 200)
    djui_hud_render_rect(bgPosX, bgPosY, bgWidth, bgHeight)

    -- render title
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(self.title, bgCenterX - (titleWidth * 0.5), bgPosY + 20, titleScale)

    local selectedId = self.selectedSelectableId

    -- render selected highlight
    local selectedRectMarginX = 4
    local selectedRectMarginY = selectedRectMarginX * 2
    local selectedRectX = self.selectablesPosX - selectedRectMarginX
    local selectedRectY = (self.selectablesPosY + (self.selectablesSize * selectedId)) - selectedRectMarginX
    local selectedRectWidth = self.selectablesWidth + selectedRectMarginY
    local selectedRectHeight = 32 + selectedRectMarginY

    djui_hud_set_color(255, 255, 255, 100)
    djui_hud_render_rect(selectedRectX, selectedRectY, selectedRectWidth, selectedRectHeight)

    local tooltipText = self.tooltip

    -- render selectables
    for i, selectable in pairs(self.selectables) do
        local isSelected = i == (selectedId + 1)
        selectable:render_selectable(isSelected)

        -- concat selected tooltip
        if (isSelected ~= false and selectable.tooltip ~= nil) then
            tooltipText = tooltipText .. " | " .. selectable.tooltip
        end
    end

    -- render tooltips
    djui_hud_set_font(FONT_NORMAL)

    local tooltipScale = 0.75
    local tooltipWidth = djui_hud_measure_text(tooltipText) * tooltipScale
    local tooltipRectMarginX = 4 * tooltipScale
    local tooltipRectMarginY = tooltipRectMarginX * 2
    local tooltipPosX = bgCenterX - (tooltipWidth * 0.5)
    local tooltipPosY = (bgPosY + bgHeight) + 40
    local tooltipWidth = tooltipWidth + tooltipRectMarginY
    local tooltipHeight = (32 * tooltipScale) + tooltipRectMarginY

    djui_hud_set_color(0, 0, 0, 200)
    djui_hud_render_rect(tooltipPosX - tooltipRectMarginX, tooltipPosY - tooltipRectMarginX, tooltipWidth, tooltipHeight)

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(tooltipText, tooltipPosX, tooltipPosY, tooltipScale)

    local localMarioState = gMarioStates[0]
    local buttonPressed = localMarioState.controller.buttonPressed

    -- gui button controls and sound
    if ((buttonPressed & U_JPAD) ~= 0 or (buttonPressed & D_JPAD) ~= 0) then
        if ((buttonPressed & U_JPAD) ~= 0) then
            self:set_next_selectable(1)
        elseif ((buttonPressed & D_JPAD) ~= 0) then
            self:set_next_selectable(0)
        end

        if (selectedId ~= self.selectedSelectableId) then
            play_sound(SOUND_MENU_MESSAGE_NEXT_PAGE, localMarioState.marioObj.header.gfx.cameraToObject)
        end
    end

    if ((buttonPressed & B_BUTTON) ~= 0) then
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, localMarioState.marioObj.header.gfx.cameraToObject)
        gui_toggle()
    end

    return true
end

function GUIWindow:set_next_selectable(direction)
    local selectablesCount = self.selectablesCount

    if (selectablesCount == 0) then
        return
    end

    local selectedId = self.selectedSelectableId

    local iterateAmount

    if (selectedId == -1) then
        selectedId = 0
        iterateAmount = 1
    else
        if (direction == 0) then
            iterateAmount = 1
        elseif (direction == 1) then
            iterateAmount = -1
        end
    end

    -- find the next selectable that can be selected/changed
    local numIterations = 0

    repeat
        selectedId = selectedId + iterateAmount

        -- clamp
        if (selectedId >= selectablesCount) then
            selectedId = 0
        elseif (selectedId < 0) then
            selectedId = selectablesCount - 1
        end

        numIterations = numIterations + 1

        -- every selectable cannot be selected, don't try anymore
        if (numIterations > selectablesCount) then
            self.selectedSelectableId = -1
            self.hideSelectedHighlight = true
            return
        end

        local selectable = self.selectables[selectedId + 1]
    until (selectable ~= nil and selectable.canSelect ~= false)

    self.selectedSelectableId = selectedId
    self.hideSelectedHighlight = false
end

function GUIWindow:on_gui_toggle()
    if (self.selectedSelectableId == -1) then
        self:set_next_selectable(0)
    end
end

function GUIWindow:add_selectable(selectable)
    local selectablesCount = self.selectablesCount

    if (selectable.canSelect ~= false and self.selectedSelectableId == -1) then
        self.selectedSelectableId = selectablesCount
    end

    local posY = self.selectablesPosY + (self.selectablesSize * selectablesCount)

    selectable:init(self, self.selectablesPosX, posY, self.selectablesWidth, self.selectablesHeight)
    table.insert(self.selectables, selectable)
    self.selectablesCount = selectablesCount + 1
end

-- GUISelectableSpacer

GUISelectableSpacer = {
    type = GUI_SELECTABLE_TYPE_SPACER,
    canSelect = false
}

---@param window table
---@param selectableX number
---@param selectableY number
---@param selectableWidth number
---@param selectableHeight number
function GUISelectableSpacer:init(window, selectableX, selectableY, selectableWidth, selectableHeight)
    if (window == nil or window.type ~= GUI_TYPE_WINDOW) then
        error("gui selectable initialized with no window!")
        return
    end
end

function GUISelectableSpacer:render_selectable(selected)
    -- not meant to render anything
end

-- GUISelectableLabel

GUISelectableLabel = {
    type = GUI_SELECTABLE_TYPE_LABEL,
    canSelect = false,
    text = "",
    textX = 0.0,
    textY = 0.0
}

---@param window table
---@param selectableX number
---@param selectableY number
---@param selectableWidth number
---@param selectableHeight number
function GUISelectableLabel:init(window, selectableX, selectableY, selectableWidth, selectableHeight)
    if (window == nil or window.type ~= GUI_TYPE_WINDOW) then
        error("gui selectable initialized with no window!")
        return
    end

    self.textX = selectableX
    self.textY = selectableY
end

---@param selected boolean
function GUISelectableLabel:render_selectable(selected)
    djui_hud_set_font(FONT_NORMAL)

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(self.text, self.textX, self.textY, 1.0)
end

function GUISelectableLabel:set_text(text)
    self.text = text
end

-- GUISelectableToggle

GUISelectableToggle = {
    type = GUI_SELECTABLE_TYPE_TOGGLE,
    canSelect = true,
    text = "",
    tooltip = "A: Toggle",
    posX = 0.0,
    posY = 0.0,
    togglePosX = 0.0,
    togglePosY = 0.0,
    toggleRectSize = 32,
    getValCb = nil,
    setValCb = nil
}

---@param window table
---@param selectableX number
---@param selectableY number
---@param selectableWidth number
---@param selectableHeight number
function GUISelectableToggle:init(window, selectableX, selectableY, selectableWidth, selectableHeight)
    if (window == nil or window.type ~= GUI_TYPE_WINDOW) then
        error("gui selectable initialized with no window!")
        return
    end

    self.posX = selectableX
    self.posY = selectableY

    self.togglePosX = selectableX + (selectableWidth - self.toggleRectSize)
    self.togglePosY = selectableY
end

---@param selected boolean
function GUISelectableToggle:render_selectable(selected)
    local canSelect = self.canSelect

    local localMarioState = gMarioStates[0]

    -- label
    djui_hud_set_font(FONT_NORMAL)

    if (canSelect == false) then
        djui_hud_set_color(255, 255, 255, 127)
    else
        djui_hud_set_color(255, 255, 255, 255)
    end
    djui_hud_print_text(self.text, self.posX, self.posY, 1.0)

    -- toggle box
    local toggleRectPosX = self.togglePosX
    local toggleRectPosY = self.togglePosY

    local toggleRectSize = self.toggleRectSize

    -- outer rect
    if (canSelect == false) then
        djui_hud_set_color(0, 0, 0, 127)
    elseif (selected and (localMarioState.controller.buttonDown & A_BUTTON) ~= 0) then
        djui_hud_set_color(64, 64, 64, 200)
    else
        djui_hud_set_color(0, 0, 0, 200)
    end
    djui_hud_render_rect(toggleRectPosX, toggleRectPosY, toggleRectSize, toggleRectSize)

    local toggleVar

    if (self.getValCb ~= nil) then
        toggleVar = self.getValCb()
    else
        toggleVar = false
    end

    -- inner rect
    if (toggleVar) then
        local innerRectScale = toggleRectSize * 0.21875
        local innerRectSize = toggleRectSize - (innerRectScale * 2)

        if (canSelect == false) then
            djui_hud_set_color(255, 255, 255, 127)
        else
            djui_hud_set_color(255, 255, 255, 255)
        end
        djui_hud_render_rect(toggleRectPosX + innerRectScale, toggleRectPosY + innerRectScale, innerRectSize, innerRectSize)
    end

    if (canSelect ~= false and selected ~= false and (localMarioState.controller.buttonPressed & A_BUTTON) ~= 0) then
        if (self.setValCb ~= nil) then
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, localMarioState.marioObj.header.gfx.cameraToObject)
            self.setValCb(not toggleVar)
        end
    end
end

---@param text string
function GUISelectableToggle:set_text(text)
    self.text = text
end

---@param canSelect boolean
function GUISelectableToggle:set_can_select(canSelect)
    self.canSelect = canSelect
end

---@param getValCb function
---@param setValCb function
function GUISelectableToggle:set_value_callbacks(getValCb, setValCb)
    self.getValCb = getValCb
    self.setValCb = setValCb
end

-- GUISelectableButton

GUISelectableButton = {
    type = GUI_SELECTABLE_TYPE_BUTTON,
    canSelect = true,
    text = "",
    tooltip = "A: Select",
    buttonText = "",
    posX = 0.0,
    posY = 0.0,
    buttonPosX = 0.0,
    buttonPosY = 0.0,
    buttonWidth = 0.0,
    clickCb = nil,
    getBtnTextCb = nil
}

---@param window table
---@param selectableX number
---@param selectableY number
---@param selectableWidth number
---@param selectableHeight number
function GUISelectableButton:init(window, selectableX, selectableY, selectableWidth, selectableHeight)
    if (window == nil or window.type ~= GUI_TYPE_WINDOW) then
        error("gui selectable initialized with no window!")
        return
    end

    self.posX = selectableX
    self.posY = selectableY

    self.buttonPosX = selectableX + selectableWidth
    self.buttonPosY = selectableY
end

---@param selected boolean
function GUISelectableButton:render_selectable(selected)
    local canSelect = self.canSelect

    local localMarioState = gMarioStates[0]

    -- label
    djui_hud_set_font(FONT_NORMAL)

    if (canSelect == false) then
        djui_hud_set_color(255, 255, 255, 127)
    else
        djui_hud_set_color(255, 255, 255, 255)
    end
    djui_hud_print_text(self.text, self.posX, self.posY, 1.0)

    -- button
    local fontSize = get_font_size(FONT_NORMAL)

    local buttonText
    if (self.getBtnTextCb ~= nil) then
        buttonText = self.getBtnTextCb()
    else
        buttonText = self.buttonText
    end

    local textWidth = djui_hud_measure_text(buttonText)
    local textHeight = fontSize

    local btnWidth = self.buttonWidth

    if (btnWidth < textWidth) then
        btnWidth = textWidth + (fontSize * 0.25)
    end

    local btnPosX = self.buttonPosX - btnWidth
    local btnPosY = self.buttonPosY

    local btnHeight = textHeight

    djui_hud_set_font(FONT_NORMAL)

    if (canSelect == false) then
        djui_hud_set_color(0, 0, 0, 127)
    elseif (selected and (localMarioState.controller.buttonDown & A_BUTTON) ~= 0) then
        djui_hud_set_color(64, 64, 64, 200)
    else
        djui_hud_set_color(0, 0, 0, 200)
    end
    djui_hud_render_rect(btnPosX, btnPosY, btnWidth, btnHeight)

    local textPosX = btnPosX + (btnWidth - textWidth) * 0.5
    local textPosY = btnPosY + (btnHeight - textHeight) * 0.5

    if (canSelect == false) then
        djui_hud_set_color(255, 255, 255, 127)
    else
        djui_hud_set_color(255, 255, 255, 255)
    end
    djui_hud_print_text(buttonText, textPosX, textPosY, 1.0)

    if (canSelect ~= false and selected ~= false and (localMarioState.controller.buttonPressed & A_BUTTON) ~= 0) then
        if (self.clickCb ~= nil) then
            play_sound(SOUND_MENU_CLICK_FILE_SELECT, localMarioState.marioObj.header.gfx.cameraToObject)
            self.clickCb(self)
        end
    end
end

---@param text string
function GUISelectableButton:set_text(text)
    self.text = text
end

---@param text string
function GUISelectableButton:set_button_text(text)
    self.buttonText = text
end

---@param canSelect boolean
function GUISelectableButton:set_can_select(canSelect)
    self.canSelect = canSelect
end

---@param width number
function GUISelectableButton:set_button_width(width)
    self.buttonWidth = width
end

---@param clickCb function
function GUISelectableButton:set_click_callback(clickCb)
    self.clickCb = clickCb
end

---@param getBtnTextCb function
function GUISelectableButton:set_get_button_text_callback(getBtnTextCb)
    self.getBtnTextCb = getBtnTextCb
end

-- GUISelectableLRSelect

GUISelectableLRSelect = {
    type = GUI_SELECTABLE_TYPE_LRSELECT,
    canSelect = true,
    text = "",
    tooltip = "DPad L/R: Change Value | Z: Set Default Value",
    posX = 0.0,
    posY = 0.0,
    valuePosX = 0.0,
    valuePosY = 0.0,
    valueMin = 0.0,
    valueMax = 1.0,
    valueStep = 0.0,
    valueDefault = 0.0,
    selectFrames = 0,
    selectFramesMax = 10,
    selectFramesMaxFast = 90,
    getValCb = nil,
    setValCb = nil
}

function GUISelectableLRSelect:init(window, selectableX, selectableY, selectableWidth, selectableHeight)
    if (window == nil or window.type ~= GUI_TYPE_WINDOW) then
        error("gui selectable initialized with no window!")
        return
    end

    self.posX = selectableX
    self.posY = selectableY
    self.valuePosX = selectableX + (selectableWidth - 122)
    self.valuePosY = selectableY
end

---@param selected boolean
function GUISelectableLRSelect:render_selectable(selected)
    djui_hud_set_font(FONT_NORMAL)

    local canSelect = self.canSelect

    -- label
    if (canSelect == false) then
        djui_hud_set_color(255, 255, 255, 127)
    else
        djui_hud_set_color(255, 255, 255, 255)
    end
    djui_hud_print_text(self.text, self.posX, self.posY, 1)

    local localMarioState = gMarioStates[0]

    local currentValue

    if (self.getValCb ~= nil) then
        currentValue = self.getValCb()
    else
        currentValue = 0
    end

    -- render value
    if (canSelect == false) then
        djui_hud_set_color(255, 255, 255, 127)
    else
        djui_hud_set_color(255, 255, 255, 255)
    end
    djui_hud_print_text(string.format("%.2f", currentValue), self.valuePosX, self.valuePosY + 4, 0.75)

    local highlighted = canSelect ~= false and selected ~= false

    local zPressed = highlighted ~= false and (localMarioState.controller.buttonPressed & Z_TRIG) ~= 0
    local dpadLHeld = highlighted ~= false and zPressed == false and (localMarioState.controller.buttonDown & L_JPAD) ~= 0
    local dpadRHeld = highlighted ~= false and zPressed == false and (localMarioState.controller.buttonDown & R_JPAD) ~= 0

    -- render left and right buttons
    local buttonPosX = self.valuePosX + 50
    local buttonSize = 32
    self:render_button_lr("<", dpadLHeld, buttonPosX, self.valuePosY, buttonSize)
    self:render_button_lr(">", dpadRHeld, buttonPosX + (buttonSize + (buttonSize * 0.25)), self.valuePosY, buttonSize)

    -- adjust value
    if (highlighted ~= false and self.setValCb ~= nil) then
        if (zPressed) then
            self:set_value_default(localMarioState)
        elseif (not (dpadLHeld ~= false and dpadRHeld ~= false)) then
            self:adjust_value_l(localMarioState, currentValue)
            self:adjust_value_r(localMarioState, currentValue)
        end
    else
        self.selectFrames = 0
    end
end

function GUISelectableLRSelect:render_button_lr(text, buttonPressed, posX, posY, btnSize)
    djui_hud_set_font(FONT_NORMAL)

    local canSelect = self.canSelect

    if (canSelect == false) then
        djui_hud_set_color(0, 0, 0, 127)
    elseif (buttonPressed ~= false) then
        djui_hud_set_color(64, 64, 64, 200)
    else
        djui_hud_set_color(0, 0, 0, 200)
    end
    djui_hud_render_rect(posX, posY, btnSize, btnSize)

    local textHeight = get_font_size(FONT_NORMAL)
    local textWidth = djui_hud_measure_text(text)

    local textPosX = posX + (btnSize - textWidth) * 0.5
    local textPosY = posY + (btnSize - textHeight) * 0.5

    if (canSelect == false) then
        djui_hud_set_color(255, 255, 255, 127)
    else
        djui_hud_set_color(255, 255, 255, 255)
    end
    djui_hud_print_text(text, textPosX, textPosY, 1.0)
end

---@param localMarioState MarioState
function GUISelectableLRSelect:adjust_value_l(localMarioState, currentValue)
    local valueMin = self.valueMin

    if (currentValue <= valueMin) then
        self.selectFrames = 0
        return
    end

    local valueStep

    if ((localMarioState.controller.buttonPressed & L_JPAD) ~= 0) then
        valueStep = self.valueStep
        self.selectFrames = 0
    elseif ((localMarioState.controller.buttonDown & L_JPAD) ~= 0) then
        local selectFrames = self.selectFrames + 1

        if ((selectFrames > self.selectFramesMaxFast) or (selectFrames > self.selectFramesMax and (selectFrames & 1) ~= 0)) then
            valueStep = self.valueStep
        end

        self.selectFrames = selectFrames
    end

    if (valueStep ~= nil) then
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, localMarioState.marioObj.header.gfx.cameraToObject)

        local valueMax = self.valueMax

        if (currentValue > valueMax) then
            currentValue = valueMax
        end

        local value = currentValue - valueStep

        if (value < valueMin) then
            value = valueMin
        end

        self.setValCb(value)
    end
end

---@param localMarioState MarioState
function GUISelectableLRSelect:adjust_value_r(localMarioState, currentValue)
    local valueMax = self.valueMax

    if (currentValue >= valueMax) then
        self.selectFrames = 0
        return
    end

    local valueStep

    if ((localMarioState.controller.buttonPressed & R_JPAD) ~= 0) then
        valueStep = self.valueStep
        self.selectFrames = 0
    elseif ((localMarioState.controller.buttonDown & R_JPAD) ~= 0) then
        local selectFrames = self.selectFrames + 1

        if ((selectFrames > self.selectFramesMaxFast) or (selectFrames > self.selectFramesMax and (selectFrames & 1) ~= 0)) then
            valueStep = self.valueStep
        end

        self.selectFrames = selectFrames
    end

    if (valueStep ~= nil) then
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, localMarioState.marioObj.header.gfx.cameraToObject)

        local valueMin = self.valueMin

        if (currentValue < valueMin) then
            currentValue = valueMin
        end

        local value = currentValue + valueStep

        if (value > valueMax) then
            value = valueMax
        end

        self.setValCb(value)
    end
end

---@param localMarioState MarioState
function GUISelectableLRSelect:set_value_default(localMarioState)
    local currentValue

    if (self.getValCb ~= nil) then
        currentValue = self.getValCb()
    end

    local valueDefault = self.valueDefault

    if (currentValue ~= nil and currentValue == valueDefault) then
        return
    end

    play_sound(SOUND_MENU_LET_GO_MARIO_FACE, localMarioState.marioObj.header.gfx.cameraToObject)

    self.setValCb(self.valueDefault)
end

---@param text string
function GUISelectableLRSelect:set_text(text)
    self.text = text
end

---@param canSelect boolean
function GUISelectableLRSelect:set_can_select(canSelect)
    self.canSelect = canSelect
end

---@param valueMin number
---@param valueMax number
---@param valueStep number
function GUISelectableLRSelect:set_value_params(valueMin, valueMax, valueStep, valueDefault)
    self.valueMin = valueMin
    self.valueMax = valueMax
    self.valueStep = valueStep
    self.valueDefault = valueDefault
end

---@param getValCb function
---@param setValCb function
function GUISelectableLRSelect:set_value_callbacks(getValCb, setValCb)
    self.getValCb = getValCb
    self.setValCb = setValCb
end