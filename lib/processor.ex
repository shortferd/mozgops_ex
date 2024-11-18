defmodule MozgopsEx.Processor do
  @moduledoc """

  A module containing the logic
  for linux tasks data processing

  @TODO: Consider the OTP-behaviour-based implementation of
  the processing loop
  """

  defmacrop error_payload(title, detail) do
    quote do
      %{errors: [
                  %{title: unquote(title),
                    detail: unquote(detail)}
                ]}
    end
  end

  @doc """
  Rearranges Linux tasks in input JSON object
  with respect to execution order.
  Or returns error if input JSON is malformed.

  ## Parameters

    - tasks_bin: binary representation of tasks object

  ## Examples
  iex> tasks_bin ="[{\"command\":\"rm /tmp/renamed_file1\",\"name\":\"task_2\",\"requires\":[\"task_1\"]},
                    {\"command\":\"mv /tmp/file1 /tmp/renamed_file1\",\"name\":\"task_1\"}]"
  iex> to_json(tasks_bin)
  {:ok,
  "[{\"command\":\"mv /tmp/file1 /tmp/renamed_file1\",\"name\":\"task_1\"},{\"command\":\"rm /tmp/renamed_file1\",\"name\":\"task_2\"}]"}

  """

  @spec to_json(binary()) :: {:ok, binary()} | {:error, binary()}
  def to_json(tasks_bin) do
    tasks = :json.decode(tasks_bin)
    case order(tasks) do
      [%{}] ->
        title = "Invalid request"
        detail = "One or multiple tasks miss mandatory keys"
        error = error_payload(title, detail)
        error = error
                |> :json.encode()
                |> IO.iodata_to_binary()
        {:error, error}
      ordered->
        ordered
        |> :json.encode()
        |> IO.iodata_to_binary()
        |> (&{:ok, &1}).()
    end
  end

  @doc """
  Rearranges Linux tasks in input JSON object
  with respect to execution order, and groups
  respective linux commands into bash script.
  Or returns error if input JSON is malformed.

  ## Parameters

    - tasks_bin: binary representation of tasks object

  ## Examples
    iex> tasks_bin ="[{\"command\":\"rm /tmp/renamed_file1\",\"name\":\"task_2\",\"requires\":[\"task_1\"]},
                    {\"command\":\"mv /tmp/file1 /tmp/renamed_file1\",\"name\":\"task_1\"}]"
  iex> to_bash(tasks_bin)
  {:ok,
    "#!/usr/bin/env bash\r\nmv /tmp/file1 /tmp/renamed_file1\r\nrm /tmp/renamed_file1\r\n"}

  """

  @spec to_bash(binary()) :: {:ok, String.t()} | {:error, String.t()}
  def to_bash(tasks_bin) do
    tasks = :json.decode(tasks_bin)
    case order(tasks) do
      [%{}] ->
        detail = "One or multiple tasks miss mandatory keys"
        {:error, detail}
      ordered->
        header = "#!/usr/bin/env bash"
        sep = "\r\n"
        ordered
        |> Enum.reduce(header, fn %{"command" => command},acc -> acc<>sep<>command end)
        |> (&(&1 <> sep)).() # Add EOF to bash script
        |> (&{:ok, &1}).()
    end
  end

  @doc """
  Orders the maps composed of Linux tasks with respect to
  defined execution priority.
  Checks if the task object has all necessary keys.
  Returns ordered map if check is successful and
  empty map otherwise.

  ## Parameters

    - tasks: List it the input Linux tasks.

  ## Examples

      iex> tasks = [
      ...>          %{"name" => "task_2", "command" => "rm /tmp/renamed_file1", "requires" => ["task_1"]},
      ...>          %{"name" => "task_1", "command" => "mv /tmp/file1 /tmp/renamed_file1"}
      ...>           ]
      iex(5)> order(tasks)
      [
        %{"command" => "mv /tmp/file1 /tmp/renamed_file1", "name" => "task_1"},
        %{"command" => "rm /tmp/renamed_file1", "name" => "task_2"}
      ]
      ...
      iex> tasks = [
      ...>          %{"command" => "rm /tmp/renamed_file1", "requires" => ["task_1"]},
      ...>          %{"name" => "task_1", "command" => "mv /tmp/file1 /tmp/renamed_file1"}
      ...>          ]
      iex> order(tasks)
      [%{}]

  """
  @spec order([map()]|[], [String.t()]) :: [map()]
  defp order(tasks, processed \\ [])
  defp order([], _processed), do: []
  defp order([%{"name" => name,
              "command" => _command,
              "requires" => requires} = current| rest],
             processed) do
    if sublist?(requires, processed) do
      current = Map.delete(current, "requires")
      [current | order(rest, [name | processed])]
    else
      # @TODO: since '++' operator copies the left-hand side
      # operand, a better approach is needed for future.
      order(rest ++ [current], processed)
    end
  end
  defp order([%{"name" => name,
               "command" => _command} = current | rest],
             processed) do
    [current | order(rest, [name | processed])]
  end
  defp order(_tasks, _processed) do
    [%{}]
  end

  @doc """
  Checks if list1 is a sublist of list2

  ## Parameters

    list1, list2: lists of arbitrary items

  ## Examples

      iex> sublist?([1,2], [1,2,3])
      true

      iex> sublist?([1,2,3], [1,2,])
      false

      iex> sublist?([1,4], [1,3])
      false
  """
  @spec sublist?(list(), list()) :: boolean()
  defp sublist?(list1, list2) do
    set1 = MapSet.new(list1)
    set2  = MapSet.new(list2)
    MapSet.subset?(set1, set2)
  end

end
