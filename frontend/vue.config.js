let settings
try {
    settings = require('./vue.config.settings')
} catch (ex) {
    settings = {}
}

settings = Object.assign({}, require('./vue.config.settings.default'), settings)
module.exports = {
    devServer: {
        host: '0.0.0.0',
        port: 8080,
        disableHostCheck: true
    }
}