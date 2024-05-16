-- TODO it seems like this file is either not loaded, or the loading time is not late enough replacements to take effect
--      I have to manually dofile() this file in in-game console for it to start working

TextEdit.OnMouseButton = SafeWrapper(function(self, button, down, x, y)
  -- print(tostring(button) .. " " .. tostring(down))

  if button == MOUSEBUTTON_RIGHT and down then
    self:SetString("")
    self:SetEditing(true)
  end

  return EXPORTS.TextEdit_OnMouseButton(self, button, down, x, y)
end)

TextEdit.OnRawKey = SafeWrapper(function(self, key, down)
  if self.editing then
    -- TODO wnat readline-style shortcuts here?
    if key == KEY_U and TheInput:IsKeyDown(KEY_CTRL) then
      self:SetString("")
    end
  end

  return EXPORTS.TextEdit_OnRawKey(self, key, down)
end)
