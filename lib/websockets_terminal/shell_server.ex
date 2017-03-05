defmodule WebsocketsTerminal.ShellServer do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def eval(server, command) do
    GenServer.cast(server, {:eval, command})
  end

  # gen server callbacks
  def init(:ok) do
    WebsocketsTerminal.Eval.start
    {:ok, Process.get(:evaluator)}
  end

  def handle_info(_msg, proc) do
    {:noreply, proc}
  end

  def handle_cast({:eval, command}, proc) do
    proc =
      case Process.alive?(proc) do
        true -> proc
        false ->
          WebsocketsTerminal.Eval.start
          Process.get(:evaluator)
      end

    Logger.info "[command] #{command}"
    send(proc, {self(), {:input, command}})

    receive do
      response ->
        data = format_json(response)
        Logger.info "[response] #{data}"
        WebsocketsTerminal.Endpoint.broadcast! "shell", "stdout", %{data: data}
    end

    {:noreply, proc}
  end

    defp format_json({prompt, nil}) do
    ~s/{"prompt":"#{prompt}"}/
  end

  defp format_json({prompt, {"error", result}}) do
    result = Inspect.BitString.escape(result, ?")
    ~s/{"prompt":"#{prompt}","type":"error","result":"#{result}"}/
  end

  defp format_json({prompt, {type, result}}) do
    # show double-quotes in strings
    result = Inspect.BitString.escape(inspect(result), ?")
    ~s/{"prompt":"#{prompt}","type":"#{type}","result":"#{result}"}/
  end
end
