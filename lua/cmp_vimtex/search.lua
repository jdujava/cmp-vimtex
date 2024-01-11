local cmp = require "cmp"

local search = {}

search.perform_search = function(opts, label)
  local source = require("cmp_vimtex").source
  if not source then
    return
  end

  local extract_bib_data = function(label)
    if source.bib_files ~= nil then
      for _, el in pairs(source.bib_files) do
        if el.result[label] ~= nil then
          return el.result[label]
        end
      end
    end
    return label
  end

  if cmp.visible() or label ~= nil then
    if not (label ~= nil) then
      label = cmp.get_selected_entry():get_word()
    end

    local data = extract_bib_data(label)

    -- Execute search
    local url = nil
    if source.config ~= nil then
      if opts ~= nil and opts.engine ~= nil then
        if source.config.search.search_engines[opts.engine] ~= nil then
          url = source.config.search.search_engines[opts.engine].get_url(data)
        else
          url = source.config.search.search_engines[source.config.search.default].get_url(data)
        end
      else
        url = source.config.search.search_engines[source.config.search.default].get_url(data)
      end
    end

    if url ~= nil then
      vim.cmd(
        string.format(
          [[silent execute '!%s ' .. shellescape(expand("%s"), v:true)]],
          source.config.search.browser,
          url
        )
      )
    end
  else
    -- Check if under cursor there is a citation key. If so, query the cache to
    -- get additional data for a websearch; if no data can be found, simply
    -- search using the citation key.
  end
end

search.search_menu = function()
  local source = require("cmp_vimtex").source
  if not source then
    return
  end

  local label = nil
  if cmp.visible() then
    label = cmp.get_selected_entry():get_word()
  else
    return
  end

  local engines = {}
  for _, el in pairs(source.config.search.search_engines) do
    table.insert(engines, el.name)
  end

  require("cmp").close()
  table.sort(engines, function(a, b)
    return a:upper() < b:upper()
  end)
  vim.ui.select(engines, {}, function(choice)
    if choice == nil then
      return
    end

    local selected = nil
    for ix, el in pairs(source.config.search.search_engines) do
      if el.name == choice then
        selected = ix
        break
      end
    end
    search.perform_search({ engine = selected }, label)
  end)
end

return search
