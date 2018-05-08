# ![RealWorld Example App](logo.png)

> Elixir (Phoenix / Absinthe / GraphQL) codebase containing real world examples (CRUD, auth, advanced patterns, etc) that adheres (in spirit) to the [RealWorld](https://github.com/gothinkster/realworld-example-apps) spec.

This codebase was created to demonstrate a fully fledged backend application built with **Elixir, Phoenix and Absinthe** including CRUD operations, authentication, pagination, and more.

This won't work with existing RealWorld front-ends, but we plan to write one or more example front ends

## Installing / Getting started

To run this project, you will need to install the following dependencies on your system:

* [Elixir](https://elixir-lang.org/install.html)
* [Phoenix](https://hexdocs.pm/phoenix/installation.html)
* [PostgreSQL](https://www.postgresql.org/download/macosx/)

To get started, run the following commands in your project folder:

```shell
cp config/dev.exs.example config/dev.exs  # creates the project's configuration file
mix deps.get  # installs the dependencies
mix ecto.create  # creates the database.
mix ecto.migrate  # run the database migrations.
mix phx.server  # run the application.
```

## GraphiQL Browser

To browse the graphql schema and see interactive documentation you can go to:
`http://localhost:4000/graphiql`

## Tests

To run the tests for this project, simply run in your terminal:

```shell
mix test
```

## Documentation

To generate the documentation, your can run in your terminal:

```shell
mix docs
```

This will generate a `doc/` directory with a documentation in HTML. To view the documentation, open the `index.html` file in the generated directory.

## Style guide

This project uses [mix format](https://hexdocs.pm/mix/master/Mix.Tasks.Format.html). You can find the configuration file for the formatter in the `.formatter.ext` file.

## Licensing

MIT © Ezinwa Okpoechi
