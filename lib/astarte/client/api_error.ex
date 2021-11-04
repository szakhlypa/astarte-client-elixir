defmodule Astarte.Client.APIError do
  @enforce_keys [:status, :response]
  defstruct @enforce_keys
end
