defmodule Astarte.Client.Credentials do
  @moduledoc false

  defstruct claims: %{},
            expiry: nil

  alias __MODULE__

  @api_all_access_claim_value ".*::.*"
  @default_expiry 5 * 60

  def new do
    %Credentials{}
  end

  def api_all_access_claim_value do
    @api_all_access_claim_value
  end

  def dashboard_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_appengine_claim(@api_all_access_claim_value)
    |> append_realm_management_claim(@api_all_access_claim_value)
    |> append_pairing_claim(@api_all_access_claim_value)
    |> append_flow_claim(@api_all_access_claim_value)
    |> append_channels_claim("JOIN::.*")
    |> append_channels_claim("WATCH::.*")
    |> set_expiry(expiry)
  end

  def appengine_all_access_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_appengine_claim(@api_all_access_claim_value)
    |> append_channels_claim("JOIN::.*")
    |> append_channels_claim("WATCH::.*")
    |> set_expiry(expiry)
  end

  def pairing_all_access_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_pairing_claim(@api_all_access_claim_value)
    |> set_expiry(expiry)
  end

  def realm_management_all_access_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_realm_management_claim(@api_all_access_claim_value)
    |> set_expiry(expiry)
  end

  def housekeeping_all_access_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_housekeeping_claim(@api_all_access_claim_value)
    |> set_expiry(expiry)
  end

  def astartectl_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_appengine_claim(@api_all_access_claim_value)
    |> append_realm_management_claim(@api_all_access_claim_value)
    |> append_pairing_claim(@api_all_access_claim_value)
    |> append_flow_claim(@api_all_access_claim_value)
    |> set_expiry(expiry)
  end

  def append_housekeeping_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_ha", claim)
  end

  def append_realm_management_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_rma", claim)
  end

  def append_pairing_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_pa", claim)
  end

  def append_appengine_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_aea", claim)
  end

  def append_channels_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_ch", claim)
  end

  def append_flow_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_f", claim)
  end

  defp append_claim(%Credentials{claims: claims} = credentials, claim_key, claim_value) do
    updated_claims = Map.update(claims, claim_key, [claim_value], &[claim_value | &1])
    %{credentials | claims: updated_claims}
  end

  def set_expiry(%Credentials{} = credentials, :infinity) do
    %{credentials | expiry: :infinity}
  end

  def set_expiry(%Credentials{} = credentials, expiry_seconds)
      when is_integer(expiry_seconds) do
    %{credentials | expiry: expiry_seconds}
  end

  def to_jwt(%Credentials{claims: astarte_claims, expiry: expiry}, private_key_pem) do
    base_config =
      %{}
      |> Joken.Config.add_claim("iss", fn -> "Astarte Cloud" end)
      |> Joken.Config.add_claim("iat", fn -> Joken.current_time() end)

    config =
      cond do
        expiry == :infinity ->
          base_config

        is_integer(expiry) and expiry > 0 ->
          base_config
          |> Joken.Config.add_claim("exp", fn -> Joken.current_time() + expiry end)

        true ->
          base_config
          |> Joken.Config.add_claim("exp", fn -> Joken.current_time() + @default_expiry end)
      end

    with {:ok, algo} <- signing_algorithm(private_key_pem),
         signer = Joken.Signer.create(algo, %{"pem" => private_key_pem}),
         {:ok, token, _claims} <- Joken.generate_and_sign(config, astarte_claims, signer) do
      {:ok, token}
    end
  end

  defp signing_algorithm(private_key) do
    case X509.PrivateKey.from_pem(private_key) do
      {:ok, key} when elem(key, 0) == :ECPrivateKey ->
        {:ok, "ES256"}

      {:ok, key} when elem(key, 0) == :RSAPrivateKey ->
        {:ok, "RS256"}

      _ ->
        {:error, :unsupported_private_key}
    end
  end
end
