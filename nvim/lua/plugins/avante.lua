-- nvim/lua/plugins/avante.lua
return {
    "2KAbhishek/avante.nvim",
    config = function()
        require("avante").setup({
            -- 이 곳에 avante.nvim 관련 설정을 추가합니다.
        })
    end,
}