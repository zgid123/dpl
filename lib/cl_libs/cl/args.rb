require 'cl_libs/cl/arg'

class Cl
  class Args
    include Enumerable

    def define(const, name, *args)
      opts = args.last.is_a?(Hash) ? args.pop.dup : {}
      opts[:description] = args.shift if args.any?

      arg = Arg.new(name, opts)
      arg.define(const)
      self.args << arg
    end

    def apply(cmd, values, opts)
      values = splat(values) if splat?
      values = default(values) if default?
      validate(values)
      return values if args.empty?
      values = args.zip(values).map { |(arg, value)| arg.set(cmd, value) }.flatten(1) #.compact
      compact_args(values)
    end

    def each(&block)
      args.each(&block)
    end

    def index(*args, &block)
      self.args.index(*args, &block)
    end

    attr_writer :args

    def args
      @args ||= []
    end

    def clear
      args.clear
    end

    def dup
      args = super
      args.args = args.args.dup
      args
    end

    private

      def validate(args)
        # raise ArgumentError.new(:unknown_arg, arg) if unknown?(arg)
        raise ArgumentError.new(:missing_args, args.size, required) if args.size < required
        raise ArgumentError.new(:too_many_args, args.join(' '), args.size, allowed) if args.size > allowed && !splat?
      end

      def allowed
        args.size
      end

      def splat?
        any?(&:splat?)
      end

      def default?
        any?(&:default?)
      end

      def required
        select(&:required?).size
      end

      def splat(values)
        args.each.with_index.inject([]) do |group, (arg, ix)|
          count = arg && arg.splat? ? [values.size - args.size + ix + 1] : []
          count = 0 if count.first.to_i < 0
          group << values.shift(*count)
        end
      end

      def default(values)
        args.each.with_index.inject([]) do |args, (arg, ix)|
          args << (values[ix] || arg.default)
        end
      end

      def compact_args(args)
        args = compact_args(args[0..-2]) while args.last.nil? && args.size > 0
        args
      end
  end
end
