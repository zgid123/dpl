require 'cl_libs/cl/opt'
require 'cl_libs/cl/opts/validate'

class Cl
  class Opts
    include Enumerable, Validate

    def define(const, *args, &block)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      strs = args.select { |arg| arg.start_with?('-') }
      opts[:description] = args.-(strs).first

      opt = Opt.new(strs, opts, block)
      opt.define(const)
      insert(opt, const)
    end

    def apply(cmd, opts)
      return opts if opts[:help]
      orig = opts.dup
      opts = defaults(cmd, opts)
      opts = downcase(opts)
      opts = upcase(opts)
      opts = cast(opts)
      opts = taint(opts)
      validate(cmd, self, opts, orig)
      opts
    end

    def insert(opt, const)
      delete(opt)
      return opts << opt if const == Cmd
      ix = opts.index(const.superclass.opts.first)
      opts.empty? ? opts << opt : opts.insert(ix.to_i, opt)
    end

    def [](key)
      opts.detect { |opt| opt.name == key }
    end

    def each(&block)
      opts.each(&block)
    end

    def delete(opt)
      opts.delete(opts.detect { |o| o.strs == opt.strs })
    end

    def first
      opts.first
    end

    def to_a
      opts
    end

    attr_writer :opts

    def opts
      @opts ||= []
    end

    def deprecated
      map(&:deprecated).flatten.compact
    end

    def ==(other)
      strs == other.strs
    end

    def dup
      super.tap { |obj| obj.opts = opts.dup }
    end

    private

      def defaults(cmd, opts)
        select(&:default?).inject(opts) do |opts, opt|
          next opts if opts.key?(opt.name)
          value = opt.default
          value = resolve(cmd, opts, value) if value.is_a?(Symbol)
          opts.merge(opt.name => value)
        end
      end

      def resolve(cmd, opts, key)
        opts[key] || cmd.respond_to?(key) && cmd.send(key)
      end

      def downcase(opts)
        select(&:downcase?).inject(opts) do |opts, opt|
          next opts unless value = opts[opt.name]
          opts.merge(opt.name => value.to_s.downcase)
        end
      end

      def upcase(opts)
        select(&:upcase?).inject(opts) do |opts, opt|
          next opts unless value = opts[opt.name]
          opts.merge(opt.name => value.to_s.upcase)
        end
      end

      def cast(opts)
        opts.map do |key, value|
          [key, self[key] ? self[key].cast(value) : value]
        end.to_h
      end

      def taint(opts)
        opts.to_h
      end
  end
end
