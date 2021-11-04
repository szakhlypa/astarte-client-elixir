defmodule Astarte.Client.AppEngine do
  @enforce_keys [:http_client]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          http_client: Tesla.Client.t()
        }

  alias Astarte.Client.AppEngine
  alias Astarte.Client.Credentials

  @jwt_expiry 5 * 60

  @spec new(String.t(), String.t(), String.t()) :: {:ok, t()} | {:error, any}
  def new(base_api_url, private_key, realm_name) do
    base_url = Path.join([base_api_url, "appengine", "v1", realm_name])
    credentials = Credentials.appengine_all_access_credentials(expiry: @jwt_expiry)

    case Credentials.to_jwt(credentials, private_key) do
      {:ok, jwt} ->
        middleware = [
          {Tesla.Middleware.BaseUrl, base_url},
          Tesla.Middleware.JSON,
          {Tesla.Middleware.Headers, [{"Authorization", "Bearer: " <> jwt}]}
        ]

        http_client = Tesla.client(middleware)
        {:ok, %AppEngine{http_client: http_client}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
