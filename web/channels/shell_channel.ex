defmodule WebsocketsTerminal.ShellChannel do
  require Logger
  use Phoenix.Channel

  def join("shell", _message, socket) do
    Logger.debug "JOIN #{socket.channel}.#{socket.topic}"
    id = random_string(20)
    {:ok, %{identifier: id, status: "REMOTE IEX TERMINAL READY", version: System.version()}, socket}
  end

  def join("shell:" <> shell_identifier, _message, socket) do
    WebsocketsTerminal.ShellServer.start(shell_identifier)
    Logger.debug "JOIN #{socket.channel}.#{socket.topic}"
    {:ok, %{status: "REMOTE IEX TERMINAL READY", version: System.version()}, socket}
  end

  def join(_private_topic, _message, _socket) do
    Logger.info "JOIN unauthorized"
    {:error, %{reason: :unauthorized}}
  end

  def handle_in("shell:" <> shell_identifier, message, socket) do
    result = WebsocketsTerminal.ShellServer.eval(shell_identifier, message["data"])
    {:reply, {:ok, %{command_result: result}}, socket}
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
