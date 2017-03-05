defmodule WebsocketsTerminal.PageController do
  use WebsocketsTerminal.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
