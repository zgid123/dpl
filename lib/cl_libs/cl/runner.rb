require 'registry'

class Cl
  module Runner
    include Registry
  end
end

require 'cl_libs/cl/runner/default'
require 'cl_libs/cl/runner/multi'
