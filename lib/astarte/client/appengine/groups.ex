defmodule Astarte.Client.AppEngine.Groups do
  alias Astarte.Client.{APIError, AppEngine}

  def get_group_config(%AppEngine{} = client, group_name) when is_binary(group_name) do
    request_path = "groups/#{group_name}"
    tesla_client = client.http_client

    with {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end
end
