local create = require("gist.api.create")
local list = require("gist.api.list")

return {
    create_from_buffer = create.from_buffer,
    create_from_file = create.from_file,
    list_gists = list.gists,
}
