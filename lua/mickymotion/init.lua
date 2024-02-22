vim.cmd.set("mousemoveevent")
local ns = vim.api.nvim_create_namespace("mickeymotion")

---@param range {[1]: integer, [2]: integer, [3]: integer, [4]: integer}
local function f(range)
	range = range or { 2, 10, 2, 10 }
	local mousepos = vim.fn.getmousepos()
	local bufnr = vim.api.nvim_win_get_buf(mousepos.winid)
	local topline = vim.fn.getwininfo(mousepos.winid)[1].topline - 1
	local row, col = mousepos.winrow + topline - 1, mousepos.wincol - 1
	local start_row = math.max(0, row - range[1])
	local end_row = row + range[3]
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)

	local heads = {}
	local labels = { "q", "w", "e", "r", "t", "a", "s", "d", "f", "g", "z", "x", "c", "v", "b" }
	local nth = 1

	for i, line in pairs(lines) do
		heads[i] = {}
		local s_consumed = ""
		local n_consumed = 0
		while true do
			local sc, ec = string.find(line, "%w+")
			if not sc then
				break
			end
			local delta = col - n_consumed - sc
			if (delta >= 0 and delta <= range[2]) or (delta < 0 and -delta <= range[4]) then
				table.insert(heads[i], n_consumed + sc - 1)
			end
			s_consumed = s_consumed .. string.sub(line, 1, ec)
			n_consumed = n_consumed + ec
			line = string.sub(line, ec + 1)
		end
	end

	if #heads == 0 then
		return
	end

	local targets = {}

	for i, cols_hl in pairs(heads) do
		local row_hl = start_row + i - 1
		for _, col_hl in pairs(cols_hl) do
			local label = labels[nth]
			if not label then
				break
			end
			targets[label] = { row_hl, col_hl }
			nth = nth + 1
			vim.api.nvim_buf_set_extmark(bufnr, ns, row_hl, col_hl, {
				end_row = row_hl,
				end_col = col_hl + 1,
				virt_text = { { label, "@text.warning" } },
				virt_text_pos = "overlay",
			})
		end
	end

	vim.cmd.redraw()
	local ok, charstr = pcall(vim.fn.getcharstr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 1, -1)
	if not ok then
		return
	end

	local selection = targets[charstr]
	if selection then
		vim.api.nvim_set_current_win(mousepos.winid)
		vim.api.nvim_win_set_cursor(mousepos.winid, { selection[1] + 1, selection[2] })
	end
end

vim.keymap.set("n", "<MouseMove><Space>", f)
