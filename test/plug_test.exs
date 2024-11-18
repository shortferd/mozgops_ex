defmodule MozgopsEx.PlugTest do
  use ExUnit.Case
  doctest MozgopsEx.Router
  use Plug.Test

  alias MozgopsEx.Router

  @opts Router.init([])

  test "test normal return of JSON" do
    # Create a test connection
    tasks = [
              %{"name" => "task_2", "command" => "rm /tmp/renamed_file1", "requires" => ["task_1"]},
              %{"name" => "task_1", "command" => "mv /tmp/file1 /tmp/renamed_file1"}
            ]
    req_body = tasks
               |> :json.encode()
               |> IO.iodata_to_binary()
    conn = conn(:post, "/", req_body)

    # Invoke the plug
    conn = Router.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "[{\"command\":\"mv /tmp/file1 /tmp/renamed_file1\",\"name\":\"task_1\"},"<>
                              "{\"command\":\"rm /tmp/renamed_file1\",\"name\":\"task_2\"}]"
  end

  test "test normal return of bash" do
    # Create a test connection
    tasks = [
              %{"name" => "task_2", "command" => "rm /tmp/renamed_file1", "requires" => ["task_1"]},
              %{"name" => "task_1", "command" => "mv /tmp/file1 /tmp/renamed_file1"}
            ]
    req_body = tasks
               |> :json.encode()
               |> IO.iodata_to_binary()
    conn = conn(:post, "/bash", req_body)

    # Invoke the plug
    conn = Router.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "#!/usr/bin/env bash\r\nmv /tmp/file1 /tmp/renamed_file1\r\nrm /tmp/renamed_file1"
  end

  test "test erroneous JSON" do
    # Create a test connection
    tasks = [ ## Command name is missing in the first map
              %{"command" => "rm /tmp/renamed_file1", "requires" => ["task_1"]},
              %{"name" => "task_1", "command" => "mv /tmp/file1 /tmp/renamed_file1"}
            ]
    req_body = tasks
               |> :json.encode()
               |> IO.iodata_to_binary()
    conn = conn(:post, "/", req_body)

    # Invoke the plug
    conn = Router.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 400
    assert conn.resp_body == "{\"errors\":[{\"title\":\"Invalid request\",\"detail\":\"One or multiple tasks miss mandatory keys\"}]}"
  end

  test "test erroneous bash" do
    # Create a test connection
    tasks = [
              %{"name" => "task_2", "command" => "rm /tmp/renamed_file1", "requires" => ["task_1"]},
              %{"name" => "task_1"}
            ]
    req_body = tasks
               |> :json.encode()
               |> IO.iodata_to_binary()
    conn = conn(:post, "/bash", req_body)

    # Invoke the plug
    conn = Router.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 400
    assert conn.resp_body == "One or multiple tasks miss mandatory keys"
  end

  test "test non-existent endpoint" do
    # Create a test connection
    conn = conn(:get, "/hello")

    # Invoke the plug
    conn = Router.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "not found"
  end
end
