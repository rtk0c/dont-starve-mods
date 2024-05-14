function SafeWrapper(func, default_return)
  if not modinfo.opt_safe_mode then
    return func
  end

  return function(...)
    local status, res = GLOBAL.pcall(func, ...)
    if status then return res end

    -- Handle error
    print("["..modinfo.name.."] [error] "..res)
    return default_return
  end
end
