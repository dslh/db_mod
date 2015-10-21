module DbMod
  # Module which provides transaction blocks for db_mod
  # enabled classes.
  module Transaction
    protected

    # Create a transaction on the db_mod database connection.
    # Calls +BEGIN+ then yields to the given block. Calls
    # +COMMIT+ once the block yields, or +ROLLBACK+ if the
    # block raises an exception.
    #
    # Not thread safe. May not be called from inside another
    # transaction.
    # @return [Object] the result of +yield+
    def transaction
      start_transaction!

      result = yield

      query 'COMMIT'

      result
    rescue
      query 'ROLLBACK'
      raise

    ensure
      end_transaction!
    end

    private

    # Start the database transaction, or fail if
    # one is already open.
    #
    # @raise [Exceptions::AlreadyInTransaction]
    # @see #transaction
    def start_transaction!
      fail DbMod::Exceptions::AlreadyInTransaction if @in_transaction
      @in_transaction = true

      query 'BEGIN'
    end

    # End the database transaction
    #
    # @see #transaction
    def end_transaction!
      @in_transaction = false
    end
  end
end
