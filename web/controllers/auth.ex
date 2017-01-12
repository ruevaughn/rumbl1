defmodule Rumbl.Auth do
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]


  def init(opts) do
    # In the init function, we take the given options,
    # extracting the repository. Keyword.fetch!
    # raises an exception if the given key doesn’t exist,
    # so Rumbl.Auth always requires the :repo option.
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    # I think this still IS functional, because even though we're assigning a variable, it's never
    # being changed, only used for pattern matching. Variable assignment if it was never used
    # your code would be a lot of long one liners.

    # TODO: Find out when in the conn -> endpoint -> delivery conn pipeline this gets executed.

    user_id = get_session(conn, :user_id)

    cond do
      user = conn.assigns[:current_user] ->
        conn
      user = user_id && repo.get(Rumbl.User, user_id) ->
        assign(conn, :current_user, user)
      true ->
        # Yes this is an else, last case resort run this. why not just do nothing?
        # Extra security?
        assign(conn, :current_user, nil)

    end
  end

  def login(conn, user) do
    # assign(conn, key, value)
    # Assigns a value to a key in the connection

    # put_session(conn, key, value)
    # Puts the specified value in the session for the given key

    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  def login_by_username_and_pass(conn, username, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    user = repo.get_by(Rumbl.User, username: username)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}
      user ->
        {:error, :unauthorized, conn}
      true ->
        # When a user isn’t found, we use comeonin’s dummy_checkpw() function to simulate a password check with variable timing. This hardens our authentication layer against timing attacks
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end

  import Phoenix.Controller
  alias Rumbl.Router.Helpers

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Helpers.page_path(conn, :index))
      |> halt()
    end
  end


end
