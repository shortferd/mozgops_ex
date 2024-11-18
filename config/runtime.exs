import Config

if config_env() == :prod do
  config :mozgops_ex, MozgopsEx.BanditServer,
    ## @TODO: Bad practice made for readability purpose only
    ip: "IP_ADDRESS" |> System.get_env  |> String.split(".") |> Enum.map(&String.to_integer/1) |> List.to_tuple || :any,
    port: "PORT" |> System.get_env() |> String.to_integer() || 4000
end
