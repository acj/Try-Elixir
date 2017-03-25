defmodule WebsocketsTerminal.ShellServer do
  alias WebsocketsTerminal.Eval
  use GenServer
  require Logger

  @timeout 300_000

  def start(id) do
    {:ok, _} = WebsocketsTerminal.Supervisor.start_child(id)
  end

  def start_link(id, opts \\ []) do
    Logger.info("Starting #{__MODULE__} with timeout #{@timeout}")
    GenServer.start_link(__MODULE__, [], opts)
  end

  def eval(server, command) do
    GenServer.cast(server, {:eval, command})
  end

  # gen server callbacks
  def init(_) do
    {:ok, evaluator} = WebsocketsTerminal.Eval.start_link()
    state = %{evaluator: evaluator}
    {:ok, state, @timeout}
  end

  def handle_info(:timeout, _) do
		Logger.info("#{__MODULE__} shutting down due to timeout")

		{:stop, :normal, []}
	end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_cast({:eval, command}, state) do
    Logger.info "[command] #{command}"
    response = Eval.evaluate(state[:evaluator], command)
    data = format_json(response)
    Logger.info "[response] #{data}"
    WebsocketsTerminal.Endpoint.broadcast! "shell", "stdout", %{data: data}

    {:noreply, state, @timeout}
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
