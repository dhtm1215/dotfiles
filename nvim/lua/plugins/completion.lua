-- Disable completion UI (blink.cmp) from LazyVim defaults.
-- This keeps LSP diagnostics/hover/etc. but removes popup completion.
return {
  { "saghen/blink.cmp", enabled = false },
}
