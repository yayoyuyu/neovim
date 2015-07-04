-- ShaDa registers saving/reading support
local helpers = require('test.functional.helpers')
local nvim, nvim_window, nvim_curwin, nvim_command, nvim_feed, nvim_eval, eq =
  helpers.nvim, helpers.window, helpers.curwin, helpers.command, helpers.feed,
  helpers.eval, helpers.eq

local shada_helpers = require('test.functional.shada.helpers')
local reset, set_additional_cmd, clear =
  shada_helpers.reset, shada_helpers.set_additional_cmd,
  shada_helpers.clear

local nvim_current_line = function()
  return nvim_window('get_cursor', nvim_curwin())[1]
end

local setreg = function(name, contents, typ)
  local expr = 'setreg("' .. name .. '", ['
  if type(contents) == 'string' then
    contents = {contents}
  end
  for _, line in ipairs(contents) do
    expr = expr .. '"' .. line:gsub('[\\"]', '\\\\\\0') .. '", '
  end
  expr = expr .. '], "' .. typ .. '")'
  nvim_eval(expr)
end

local getreg = function(name)
  return {
    nvim_eval(('getreg("%s", 1, 1)'):format(name)),
    nvim_eval(('getregtype("%s")'):format(name)),
  }
end

describe('ShaDa support code', function()
  before_each(reset)
  after_each(clear)

  it('is able to dump and restore registers and their type', function()
    setreg('c', {'d', 'e', ''}, 'c')
    setreg('l', {'a', 'b', 'cde'}, 'l')
    setreg('b', {'bca', 'abc', 'cba'}, 'b3')
    nvim_command('qa')
    reset()
    eq({{'d', 'e', ''}, 'v'}, getreg('c'))
    eq({{'a', 'b', 'cde'}, 'V'}, getreg('l'))
    eq({{'bca', 'abc', 'cba'}, '\0223'}, getreg('b'))
  end)

  it('does not dump registers with zero <', function()
    nvim_command('set viminfo=\'0,<0')
    setreg('c', {'d', 'e', ''}, 'c')
    setreg('l', {'a', 'b', 'cde'}, 'l')
    setreg('b', {'bca', 'abc', 'cba'}, 'b3')
    nvim_command('qa')
    reset()
    eq({nil, ''}, getreg('c'))
    eq({nil, ''}, getreg('l'))
    eq({nil, ''}, getreg('b'))
  end)

  it('does restore registers with zero <', function()
    setreg('c', {'d', 'e', ''}, 'c')
    setreg('l', {'a', 'b', 'cde'}, 'l')
    setreg('b', {'bca', 'abc', 'cba'}, 'b3')
    set_additional_cmd('set viminfo=\'0,<0')
    nvim_command('qa')
    reset()
    eq({{'d', 'e', ''}, 'v'}, getreg('c'))
    eq({{'a', 'b', 'cde'}, 'V'}, getreg('l'))
    eq({{'bca', 'abc', 'cba'}, '\0223'}, getreg('b'))
  end)

  it('does not dump registers with zero "', function()
    nvim_command('set viminfo=\'0,\\"0')
    setreg('c', {'d', 'e', ''}, 'c')
    setreg('l', {'a', 'b', 'cde'}, 'l')
    setreg('b', {'bca', 'abc', 'cba'}, 'b3')
    nvim_command('qa')
    reset()
    eq({nil, ''}, getreg('c'))
    eq({nil, ''}, getreg('l'))
    eq({nil, ''}, getreg('b'))
  end)

  it('does restore registers with zero "', function()
    setreg('c', {'d', 'e', ''}, 'c')
    setreg('l', {'a', 'b', 'cde'}, 'l')
    setreg('b', {'bca', 'abc', 'cba'}, 'b3')
    set_additional_cmd('set viminfo=\'0,\\"0')
    nvim_command('qa')
    reset()
    eq({{'d', 'e', ''}, 'v'}, getreg('c'))
    eq({{'a', 'b', 'cde'}, 'V'}, getreg('l'))
    eq({{'bca', 'abc', 'cba'}, '\0223'}, getreg('b'))
  end)

  it('does dump registers with zero ", but non-zero <', function()
    nvim_command('set viminfo=\'0,\\"0,<50')
    setreg('c', {'d', 'e', ''}, 'c')
    setreg('l', {'a', 'b', 'cde'}, 'l')
    setreg('b', {'bca', 'abc', 'cba'}, 'b3')
    nvim_command('qa')
    reset()
    eq({{'d', 'e', ''}, 'v'}, getreg('c'))
    eq({{'a', 'b', 'cde'}, 'V'}, getreg('l'))
    eq({{'bca', 'abc', 'cba'}, '\0223'}, getreg('b'))
  end)

  it('does limit number of lines according to <', function()
    nvim_command('set viminfo=\'0,<2')
    setreg('o', {'d'}, 'c')
    setreg('t', {'a', 'b', 'cde'}, 'l')
    nvim_command('qa')
    reset()
    eq({{'d'}, 'v'}, getreg('o'))
    eq({nil, ''}, getreg('t'))
  end)

  it('does limit number of lines according to "', function()
    nvim_command('set viminfo=\'0,\\"2')
    setreg('o', {'d'}, 'c')
    setreg('t', {'a', 'b', 'cde'}, 'l')
    nvim_command('qa')
    reset()
    eq({{'d'}, 'v'}, getreg('o'))
    eq({nil, ''}, getreg('t'))
  end)

  it('does limit number of lines according to < rather then "', function()
    nvim_command('set viminfo=\'0,\\"2,<3')
    setreg('o', {'d'}, 'c')
    setreg('t', {'a', 'b', 'cde'}, 'l')
    setreg('h', {'abc', 'acb', 'bac', 'bca', 'cab', 'cba'}, 'b3')
    nvim_command('qa')
    reset()
    eq({{'d'}, 'v'}, getreg('o'))
    eq({{'a', 'b', 'cde'}, 'V'}, getreg('t'))
    eq({nil, ''}, getreg('h'))
  end)
end)
