const fs = require("fs")

exports("readDir", function(dir) {
    if (GetInvokingResource() == GetCurrentResourceName())
        return fs.readdirSync(dir)
    else
        return false
})

exports("isDir", function(path) {
    if (GetInvokingResource() == GetCurrentResourceName()) {
        const stats = fs.statSync(path);
        return stats.isDirectory()
    } else
        return false
})