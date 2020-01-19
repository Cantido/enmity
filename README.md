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

Place your bot's token into your config file.

```elixir
import Config

config :enmity,
  token: "a big, fifty-nine-character string"
```

That's all you need to start making API calls.

```elixir
{:ok, resp} = Enmity.User.get("625487844994973716")

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
where you define the `:token` given to you by Discord.

Run the tests by setting the `MIX_ENV` to `integration`:

```bash
MIX_ENV=integration mix test
```

## License

Copyright © 2019 Rosa Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following conditions:


* The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

* The software may not be used by individuals, corporations, governments, or
other groups for systems or activities that actively and knowingly endanger,
harm, or otherwise threaten the physical, mental, economic, or general
well-being of underprivileged individuals or groups.


THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.

This license is derived from the MIT License, as amended to limit the impact
of the unethical use of open source software.
