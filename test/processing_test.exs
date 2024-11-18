defmodule MozgopsEx.ProcessingTest do
  use ExUnit.Case
  # doctest MozgopsEx.Processor

  alias MozgopsEx.Processor


  test "no dependencies" do
    input = [
              %{ "name" => "task_1", "command" => "df -h" },
              %{ "name" => "task_2", "command" => "free -m" },
              %{ "name" => "task_3", "command" => "vmstat 1 3" },
            ]
            |> :json.encode
            |> IO.iodata_to_binary

    output_bash = "#!/usr/bin/env bash\r\n" <>
                   "df -h\r\n"<>
                   "free -m\r\n"<>
                   "vmstat 1 3\r\n"

    assert Processor.to_json(input) == {:ok, input}
    assert Processor.to_bash(input) == {:ok, output_bash}
  end

  test "single-task dependencies" do
    input =
        [
          %{ "name" => "task_1", "command" => "top" },
          %{ "name" => "task_2", "command" => "pgrep bash", "requires" => ["task_4"] },
          %{ "name" => "task_3", "command" => "kill -9 1234", "requires" => ["task_2"] },
          %{ "name" => "task_4", "command" => "ps aux" },
          %{ "name" => "task_5", "command" => "bg %1", "requires" => ["task_3"] },
          %{ "name" => "task_6", "command" => "jobs", "requires" => ["task_5"] }
        ]
        |> :json.encode
        |> IO.iodata_to_binary

    output_json = "[{\"command\":\"top\",\"name\":\"task_1\"}," <>
                   "{\"command\":\"ps aux\",\"name\":\"task_4\"}," <>
                   "{\"command\":\"pgrep bash\",\"name\":\"task_2\"}," <>
                   "{\"command\":\"kill -9 1234\",\"name\":\"task_3\"}," <>
                   "{\"command\":\"bg %1\",\"name\":\"task_5\"},"<>
                   "{\"command\":\"jobs\",\"name\":\"task_6\"}]"
    output_bash = "#!/usr/bin/env bash\r\n"<>
                   "top\r\n"<>
                   "ps aux\r\n"<>
                   "pgrep bash\r\n"<>
                   "kill -9 1234\r\n"<>
                   "bg %1\r\n"<>
                   "jobs\r\n"

    assert Processor.to_json(input) == {:ok, output_json}
    assert Processor.to_bash(input) == {:ok, output_bash}
  end

  test "multiple-task dependencies" do
    input = [
              %{"name" => "task_1", "command" => "sar -u 1 5", "requires" => ["task_5", "task_4"]},
              %{"name" => "task_2", "command" => "iostat"},
              %{"name" => "task_3", "command" => "df -h"},
              %{"name" => "task_4", "command" => "vmstat 1 3", "requires" => ["task_3", "task_6"]},
              %{"name" => "task_5", "command" => "uptime", "requires" => ["task_4"]},
              %{"name" => "task_6", "command" => "free -m"}
            ]
            |> :json.encode
            |> IO.iodata_to_binary

    output_json = "[{\"command\":\"iostat\",\"name\":\"task_2\"},"<>
                  "{\"command\":\"df -h\",\"name\":\"task_3\"},"<>
                  "{\"command\":\"free -m\",\"name\":\"task_6\"},"<>
                  "{\"command\":\"vmstat 1 3\",\"name\":\"task_4\"},"<>
                  "{\"command\":\"uptime\",\"name\":\"task_5\"},"<>
                  "{\"command\":\"sar -u 1 5\",\"name\":\"task_1\"}]"
    output_bash = "#!/usr/bin/env bash\r\n"<>
                  "iostat\r\n"<>
                  "df -h\r\n"<>
                  "free -m\r\n"<>
                  "vmstat 1 3\r\n"<>
                  "uptime\r\n"<>
                  "sar -u 1 5\r\n"

    assert Processor.to_json(input) == {:ok, output_json}
    assert Processor.to_bash(input) == {:ok, output_bash}
  end
end
