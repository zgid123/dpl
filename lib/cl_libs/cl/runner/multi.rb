class Cl
  module Runner
    class Multi
      Runner.register :multi, self

      attr_reader :ctx, :cmds

      def initialize(ctx, *args)
        @ctx = ctx
        @cmds = build(group(args))
      end

      def run
        cmds.map(&:run)
      end

      private

        def group(args, cmds = [])
          args.flatten.map(&:to_s).inject([[]]) do |cmds, arg|
            cmd = Cmd.registered?(arg) ? Cmd[arg] : nil
            cmd ? cmds << [cmd] : cmds.last << arg
            cmds.reject(&:empty?)
          end
        end

        def build(cmds)
          cmds.map do |(cmd, *args)|
            cmd.new(ctx, args)
          end
        end
    end
  end
end
