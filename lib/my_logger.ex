defmodule MyLogger do
  # Custom macro for logging with caller info
  defmacro log(level, message) do
    # Access the caller's metadata
    caller = __CALLER__
    function_name = inspect(caller.function) |> to_string()
    line_number = caller.line
    message_string = inspect(message)
    # Create the log message with function name and line number
    log_message = "[#{function_name} (Line #{line_number})] #{message_string}"

    # Log the message at the desired log level
    quote do
      Logger.unquote(level)(unquote(log_message))
    end
  end
end
