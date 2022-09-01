set backspace=indent,eol,start
set autoindent
set ruler
set history=50
set showcmd 
set hlsearch
set mouse=a
set number
set relativenumber
set clipboard=unnamedplus
let mapleader = " " 

call plug#begin('~/.config/nvim/plugged')

" Collection of common configurations for the Nvim LSP client
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/nvim-treesitter-context'
Plug 'ray-x/lsp_signature.nvim'
" Extensions to built-in LSP, for example, providing type inlay hints
Plug 'nvim-lua/lsp_extensions.nvim'
" Autocompletion framework for built-in LSP
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/nvim-cmp'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
" Formatting
Plug 'psf/black', { 'branch': 'stable' }
" GUI
Plug 'itchyny/lightline.vim'
Plug 'catppuccin/nvim', {'as': 'catppuccin'}
" Plug 'morhetz/gruvbox'
" Plug 'tyrannicaltoucan/vim-deep-space' 
" Fuzzy Finder
Plug 'airblade/vim-rooter'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'nvim-telescope/telescope.nvim'
call plug#end()

" syntax enable
filetype plugin indent on
set completeopt=menu,menuone,noinsert,noselect
" colorscheme gruvbox 
set termguicolors
" colorscheme deep-space
let g:catppuccin_flavour = "macchiato" " latte, frappe, macchiato, mocha
" set shortmess+=c

lua << EOF
-- GUI
require("catppuccin").setup()

-- Autocomplete / Suggestions
local cmp = require'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body) 
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-j>'] = cmp.mapping.scroll_docs(-4),
    ['<C-k>'] = cmp.mapping.scroll_docs(4), 
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    ['<Tab>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' }, 
  }, {
    { name = 'buffer' },
  })
})

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

-- LSP
local on_attach = function(client, bufnr)

	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	-- Mappings
	local opts = { noremap = true, silent = true }

	buf_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
	buf_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
	buf_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	buf_set_keymap("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
	buf_set_keymap("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
	buf_set_keymap("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
	buf_set_keymap("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
	buf_set_keymap("n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
	buf_set_keymap("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
	buf_set_keymap("n", "<leader>dp", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
	buf_set_keymap("n", "<leader>dn", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
	buf_set_keymap("n", "<leader>dl", "<cmd>Telescope diagnostics<CR>", opts)

	if client.server_capabilities.document_formatting then
		vim.cmd([[
			augroup formatting
				autocmd! * <buffer>
				autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()
			augroup END
		]])
	end

	if client.server_capabilities.document_highlight then
		vim.cmd([[
			augroup lsp_document_highlight
				autocmd! * <buffer>
				autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
				autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
			augroup END
		]])
	end

	require "lsp_signature".on_attach({
    		doc_lines = 0,
		handler_opts = {
			border = "none"
    		},
  	})
end


local nvim_lsp = require('lspconfig')


nvim_lsp.rust_analyzer.setup { 
  capabilities=capabilities,
  on_attach=on_attach,
  flags = {
    debounce_text_changes = 150,
  },
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
      completion = {
	postfix = {
	  enable = false,
	},
      },
      checkOnSave = {
        -- default: `cargo check`
        command = "cargo clippy"
        },
      },
      inlayHints = {
        lifetimeElisionHints = {
          enable = true,
          useParameterNames = true
        },
    },
  },
}

nvim_lsp.pyright.setup {
  capabilities=capabilities,
  on_attach=on_attach
}

nvim_lsp.omnisharp.setup {
  capabilities=capabilities,
  on_attach=on_attach,
  cmd = { "/usr/bin/omnisharp", "--languageserver" , "--hostPID", tostring(pid) }
}

-- TreeSitter
require('nvim-treesitter.configs').setup{
  ensure_installed = {"rust", "lua", "python", "toml", "svelte"},
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false
  },
}

require'treesitter-context'.setup{
    enable = true, 
    max_lines = 0,
    trim_scope = 'outer',
    patterns = { 
        default = {
            'class',
            'function',
            'method',
        },
        rust = {
            'impl_item',
        },
    },
    exact_patterns = {
    },
    zindex = 20, -- The Z-index of the context window
    mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
    separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
}
-- Telescope
require('telescope').load_extension('fzf')

EOF


colorscheme catppuccin
set updatetime=300

" double space to switch buffers
nnoremap <leader><leader> <c-^>
" SHIFT + f to find files
nnoremap <S-f> :Telescope find_files<cr>
" Space + f to show buffers
nnoremap <leader>f :Telescope buffers theme=ivy<cr>
" Leader +  g + l to list git commits
nnoremap <leader>gl :Telescope git_commits<cr>
nnoremap <leader>lg :Telescope live_grep<cr>
" Leader + F to show file explorer
nnoremap <leader>F :Vexplore 15<cr>

" autocmd CursorHold,CursorHoldI *.rs :lua require'lsp_extensions'.inlay_hints{ only_current_line = true }

" I can type :help on my own, thanks
map <F1> <Esc>
imap <F1> <Esc>

set signcolumn=yes

augroup format_on_save
  autocmd!
  autocmd BufWritePre *.py Black
  autocmd BufWritePre *.py PyrightOrganizeImports
augroup end



let g:rustfmt_autosave = 1
let g:deepspace_italics = 1
