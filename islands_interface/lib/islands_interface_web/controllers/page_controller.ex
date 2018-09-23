defmodule IslandsInterfaceWeb.PageController do
  use IslandsInterfaceWeb, :controller

  alias IslandsEngine.GameSupervisor

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def test(conn, %{"name" => name}) do
    flash_msg =
      case GameSupervisor.start_game(name) do
        {:ok, _pid} ->
          %{type: :info, text: "You entered the name: " <> name}

        {:error, {:already_started, _pid}} ->
          %{type: :error, text: "A game with this name is already started: " <> name}

        _ ->
          %{type: :error, text: "Unknown error"}
      end

    conn
    |> put_flash(flash_msg.type, flash_msg.text)
    |> render("index.html")
  end
end
