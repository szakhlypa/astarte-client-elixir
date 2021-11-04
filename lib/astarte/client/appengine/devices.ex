defmodule Astarte.Client.AppEngine.Devices do
  alias Astarte.Client.{APIError, AppEngine}

  def get_device_status(%AppEngine{} = client, device_id) when is_binary(device_id) do
    request_path = "devices/#{device_id}"
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
