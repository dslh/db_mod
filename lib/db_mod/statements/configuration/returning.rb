module DbMod
  module Statements
    module Configuration
      # Provides functionality backing the {MethodConfiguration#returning}
      # setting. Allows a block to be declared that may perform additional
      # processing on the SQL result set (the result of whatever other
      # result transformations have been specified using
      # {MethodConfiguration#as} or {MethodConfiguration#single}), and
      # which may transform or replace entirely the method return value.
      #
      #  def_statement(:csv_email, 'SELECT * FROM foo') do
      #    as(:csv)
      #    returning { |csv| build_email(csv) }
      #  end
      module Returning
        # Extend the given method definition with additional result
        # coercion, if specified using {MethodConfiguration#returning}.
        #
        # @param definition [Proc] base method definition
        # @param config [MethodConfiguration] method configuration
        # @return [Proc] wrapped method definition, or the original
        #   definition if no coercion has been specified
        def self.extend(definition, config)
          return definition unless config.key? :returning

          Configuration.attach_result_processor definition, config[:returning]
        end
      end
    end
  end
end
