defmodule MozgopsEx.Router do
  @moduledoc """
  Routing worker for HTTP requests

  """

  use Plug.Router

  alias MozgopsEx.Processor

  plug :match
  plug :dispatch

  post "/" do
    with {:ok, req_body, conn} <- read_body(conn),
         {:ok, resp_body} <- Processor.to_json(req_body) do
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, resp_body)
    else
      {:error, error} when is_binary(error) ->
        conn
        |> put_resp_content_type("application/error+json")
        |> send_resp(400, error)
      ohh ->
        IO.inspect ohh
        send_resp(conn, 500, " ")
    end
  end

  post "/bash" do
    with {:ok, req_body, conn} <- read_body(conn),
         {:ok, resp_body} <- Processor.to_bash(req_body) do
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, resp_body)
    else
      {:error, error} when is_bitstring(error) ->
         conn
        |> put_resp_content_type("text/plain")
        |> send_resp(400, error)
      _ ->
        send_resp(conn, 500, "")
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

end
