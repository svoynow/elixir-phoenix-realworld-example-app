defmodule RealWorldWeb.GraphqlFragments do
  @error_fragment """
    successful
    messages {
      code
      field
      message
    }
  """

  def errors_on(type) do
    """
      fragment errorFields on #{type} {
        #{@error_fragment}
      }
    """
  end
end
