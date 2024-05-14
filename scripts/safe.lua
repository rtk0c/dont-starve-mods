-- Disable this in production environment, or want to test mod in "real world conditions"
USE_SAFE_MODE = true

function SafeWrapper(func, default_return)
  if not USE_SAFE_MODE then
    return func
  end

  return function(...)
    local status, res = GLOBAL.pcall(func, ...)
    if status then return res end

    -- Handle error
    print("[error] ["..modinfo.name.."] "..res)
    return default_return
  end
end
