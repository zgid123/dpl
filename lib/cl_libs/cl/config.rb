require 'cl_libs/cl/config/env'
require 'cl_libs/cl/config/files'
require 'cl_libs/cl/helper'

class Cl
  class Config
    include Merge

    attr_reader :name, :opts

    def initialize(name)
      @name = name
      @opts = load
    end

    def to_h
      opts
    end

    private

      def load
        merge(*sources.map(&:load))
      end

      def sources
        [Files.new(name), Env.new(name)]
      end
  end
end
