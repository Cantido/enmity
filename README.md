# Enmity

A Discord library for Elixir.

## Installation

The package can be installed by adding `enmity` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:enmity, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/enmity](https://hexdocs.pm/enmity).

## Usage

Use the functions defined in the `Enmity` module.

```elixir
{:ok, resp} = Enmity.user("625487844994973716", token: @token)

assert resp == [
  avatar: nil,
  bot: true,
  discriminator: "4646",
  id: "625487844994973716",
  username: "testbot"
]
```

## Testing

Alongside the usual `mix test`, this library also has integration tests.
To run integration tests, you must first create the file `config/integration.secret.exs`,
where you define the `:token` given to you by Discord, like so:

```elixir
import Config

config :enmity,
  token: "a big, fifty-nine-character string"
```

## License

Copyright © 2017 Rosa Richter (formerly Robert Richter)

Licensed under the MIT License.
