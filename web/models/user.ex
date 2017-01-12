defmodule Rumbl.User do
  use Rumbl.Web, :model

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    has_many :videos, Rumbl.Video

    timestamps
  end

  def changeset(model, params \\ :empty) do

    # model is user.
    # %Rumbl.User{__meta__: #Ecto.Schema.Metadata<:built, "users">, id: nil,
    # inserted_at: nil, name: nil, password: nil, password_hash: nil,
    # updated_at: nil, username: nil,
    # videos: #Ecto.Association.NotLoaded<association :videos is not loaded>}

    model
    |> cast(params, ~w(name username))
    |> validate_required([:name, :username])
    |> validate_length(:username, min: 1, max: 20)
  end

  def registration_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, ~w(password))
    |> validate_required(:password)
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    # A changeset is literally a struct that stores a set of changes
    # (as well as the validation rules.) You pass a changeset to your
    # Ecto Repo to persist the changes if they are valid.

    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
     _ ->
      changeset
    end
  end
end
