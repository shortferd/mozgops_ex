defmodule MozgopsEx.Application do

  @moduledoc false
  use Application
  def start(_type, _args) do
    children = [
      {Bandit, Application.get_env(:mozgops_ex, MozgopsEx.BanditServer)},
    ]
    opts = [strategy: :one_for_one, name: MozgopsEx.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
