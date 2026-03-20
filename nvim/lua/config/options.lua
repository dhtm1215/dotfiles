local opt = vim.opt

-- Markdown 본문이 완전히 감춰지는 문제를 막기 위해 conceallevel을 끈다.
-- LazyVim 기본값(2)은 Markdown 구문 문자들을 숨기는데, 일부 환경에서는
-- 전체 줄이 conceal 처리되어 빈 화면처럼 보일 수 있다.
opt.conceallevel = 0
