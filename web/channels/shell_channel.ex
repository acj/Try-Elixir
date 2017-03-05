defmodule WebsocketsTerminal.ShellChannel do
  use Phoenix.Channel

  def join("shell", _message, socket) do
    IO.puts "JOIN #{socket.channel}.#{socket.topic}"
    {:ok, %{status: "REMOTE IEX TERMINAL READY", version: System.version()}, socket}
  end

  def join(_private_topic, _message, _socket) do
    IO.puts "JOIN unauthorized"
    {:error, %{reason: :unauthorized}}
  end

  def handle_in("shell:stdin", message, socket) do
    WebsocketsTerminal.ShellServer.eval(:shell, message["data"])
    {:noreply, socket}
  end

  def handle_out("shell", message, socket) do
    push socket, "shell:stdout", message
    {:noreply, socket}
  end
end
