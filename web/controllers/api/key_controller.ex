defmodule HexWeb.API.KeyController do
  use HexWeb.Web, :controller

  plug :authorize when action != :create
  plug :authorize, [only_basic: true, allow_unconfirmed: true] when action == :create

  def index(conn, _params) do
    keys = Key.all(conn.assigns.user) |> HexWeb.Repo.all

    conn
    |> api_cache(:private)
    |> render(:index, keys: keys)
  end

  def show(conn, %{"name" => name}) do
    key = HexWeb.Repo.one!(Key.get(name, conn.assigns.user))

    when_stale(conn, key, fn conn ->
      conn
      |> api_cache(:private)
      |> render(:show, key: key)
    end)
  end

  def create(conn, params) do
    case Key.create(conn.assigns.user, conn.params) |> HexWeb.Repo.insert do
      {:ok, key} ->
        location = key_url(conn, :show, params["name"])

        conn
        |> put_resp_header("location", location)
        |> api_cache(:private)
        |> put_status(201)
        |> render(:show, key: key)
      {:error, errors} ->
        validation_failed(conn, errors)
    end
  end

  def delete(conn, %{"name" => name}) do
    if key = HexWeb.Repo.one(Key.get(name, conn.assigns.user)) do
      HexWeb.Repo.delete!(key)

      conn
      |> api_cache(:private)
      |> send_resp(204, "")
    else
      not_found(conn)
    end
  end
end
