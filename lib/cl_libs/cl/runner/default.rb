require 'forwardable'
require 'cl_libs/cl/ctx'
require 'cl_libs/cl/helper'

class Cl
  module Runner
    class Default
      Runner.register :default, self

      singleton_class.send(:attr_accessor, :run_method)
      self.run_method = :run

      extend Forwardable
      include Merge, Suggest

      def_delegators :ctx, :abort

      attr_reader :ctx, :const, :args, :opts

      def initialize(ctx, args)
        @ctx = ctx
        @const, @args = lookup(args)
      end

      def run
        cmd.help? ? help.run : cmd.send(self.class.run_method)
      rescue OptionParser::InvalidOption => e
        raise UnknownOption.new(const, e.message)
      end

      def cmd
        @cmd ||= const.new(ctx, args)
      end

      def help
        cmd.is_a?(Help) ? cmd : Help.new(ctx, [cmd.registry_key])
      end

      def suggestions(args)
        keys = args.inject([]) { |keys, arg| keys << [keys.last, arg].compact.join(':') }
        keys.map { |key| suggest(providers.map(&:to_s), key) }.flatten
      end

        private

        # Finds a command class to run for the given arguments.
        #
        # Stopping at any arg that starts with a dash, find the command
        # with the key matching the most args when joined with ":", and
        # remove these used args from the array
        #
        # For example, if there are commands registered with the keys
        #
        #   git:pull
        #   git:push
        #
        # then for the arguments:
        #
        #   git push master
        #
        # the method `lookup` will find the constant registered as `git:push`,
        # remove these from the `args` array, and return both the constant, and
        # the remaining args.
        #
        # @param args [Array<String>] arguments to run (usually ARGV)
        def lookup(args)
          keys = args.take_while { |key| !key.start_with?('-') }

          keys = keys.inject([[], []]) do |keys, key|
            keys[1] << key
            keys[0] << [Cmd[keys[1].join(':')], keys[1].dup] if Cmd.registered?(keys[1].join(':'))
            keys
          end

          cmd, keys = keys[0].last
          raise UnknownCmd.new(self, args) if cmd.nil? || cmd.abstract?
          keys.each { |key| args.delete_at(args.index(key)) }
          [cmd, args]
        end

      def providers
        Cmd.registry.keys
      end
    end
  end
end
