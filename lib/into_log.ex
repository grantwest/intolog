defmodule IntoLog do
  defstruct [:log_fn]
  import Logger

  @moduledoc """
  Collectable protocol for Logging, allowing a logger to be
  passed anywhere a Collectable is accepted.

      require IntoLog
      System.cmd("echo", ["hello"], into: IntoLog.log(:info))
      09:24:42.866 [info]  hello
  """

  @doc """
  Returns a Collectable that logs each message with the given
  `level` and metadata.

      Enum.into(["hello", "world"], IntoLog.log(:info))


  """
  defmacro log(level, metadata \\ []) do
    macro_log(level, metadata, __CALLER__)
  end

  defp macro_log(level, metadata, caller) do
    {maybe_application, file} = compile_time_application_and_file(caller)

    location =
      case caller do
        %{module: module, function: {fun, arity}, line: line} ->
          %{mfa: {module, fun, arity}, file: file, line: line}

        _ ->
          %{}
      end

    {compile_metadata, quoted_metadata} =
      if Keyword.keyword?(metadata) do
        metadata = Keyword.merge(maybe_application, metadata)
        {Map.merge(location, Map.new(metadata)), escape_metadata(metadata)}
      else
        {%{},
         quote do
           Enum.into(unquote(metadata), unquote(escape_metadata(maybe_application)))
         end}
      end

    compile_level = if is_atom(level), do: level, else: :error

    if compile_time_purge_matching?(compile_level, compile_metadata) do
      :ok
    else
      quote do
        case Logger.__should_log__(unquote(level), __MODULE__) do
          nil ->
            %IntoLog{log_fn: fn _data -> nil end}

          level ->
            %IntoLog{
              log_fn: fn data ->
                Logger.__do_log__(
                  level,
                  data,
                  unquote(Macro.escape(location)),
                  unquote(quoted_metadata)
                )
              end
            }
        end
      end
    end
  end

  defp escape_metadata(metadata) do
    {_, metadata} =
      Keyword.get_and_update(metadata, :mfa, fn
        nil -> :pop
        mfa -> {mfa, Macro.escape(mfa)}
      end)

    {:%{}, [], metadata}
  end

  defp compile_time_application_and_file(%{file: file}) do
    if app = Application.get_env(:logger, :compile_time_application) do
      {[application: app], file |> Path.relative_to_cwd() |> String.to_charlist()}
    else
      {[], file |> Path.relative_to_cwd() |> String.to_charlist()}
    end
  end

  defp compile_time_purge_matching?(level, compile_metadata) do
    matching = Application.get_env(:logger, :compile_time_purge_matching, [])

    if not is_list(matching) do
      bad_compile_time_purge_matching!(matching)
    end

    Enum.any?(matching, fn filter ->
      if not is_list(filter) do
        bad_compile_time_purge_matching!(matching)
      end

      Enum.all?(filter, fn
        {:level_lower_than, min_level} ->
          compare_levels(level, min_level) == :lt

        {:module, module} ->
          match?({:ok, {^module, _, _}}, Map.fetch(compile_metadata, :mfa))

        {:function, func} ->
          case Map.fetch(compile_metadata, :mfa) do
            {:ok, {_, f, a}} -> "#{f}/#{a}" == func
            _ -> false
          end

        {k, v} when is_atom(k) ->
          Map.fetch(compile_metadata, k) == {:ok, v}

        _ ->
          bad_compile_time_purge_matching!(matching)
      end)
    end)
  end

  defp bad_compile_time_purge_matching!(matching) do
    raise "expected :compile_time_purge_matching to be a list of keyword lists, " <>
            "got: #{inspect(matching)}"
  end
end

defimpl Collectable, for: IntoLog do
  require Logger

  def into(log) do
    {log,
     fn
       log_acc, {:cont, elem} ->
         log_acc.log_fn.(elem)
         log_acc

       log_acc, :done ->
         log_acc

       _log_acc, :halt ->
         :not_used
     end}
  end
end
