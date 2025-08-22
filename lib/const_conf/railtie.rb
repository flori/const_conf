# A Railtie implementation that integrates ConstConf with Rails application
# initialization.
#
# This class ensures that configuration settings defined through ConstConf are
# properly reloaded and synchronized when the Rails application prepares its
# configuration, maintaining thread safety during the process.
#
# @example
#   This Railtie is automatically included in a Rails application when the
#   ConstConf gem is loaded, requiring no explicit usage in application code.
class ConstConf::Railtie < Rails::Railtie
  config.to_prepare { ConstConf.reload }
end
