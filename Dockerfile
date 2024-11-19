# Stage 1: Build
FROM hexpm/elixir:1.17.3-erlang-27.1.2-ubuntu-noble-20241015 AS build

# Set environment variables
ENV MIX_ENV=prod \
    LANG=C.UTF-8 

# Install build tools
RUN apt-get update &&\
    apt-get install -y build-essential git

# Set the working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Cache and install dependencies
COPY mix.exs ./
RUN mix deps.get && \
    mix deps.compile

# Compile the project
COPY . .

# Create release
RUN mix release

# Stage 2: Run
FROM ubuntu:noble-20241015
    
ENV LANG=C.UTF-8 

# Install runtime dependencies
RUN apt-get update &&\ 
    apt-get install -y libstdc++6 openssl libssl-dev libncurses6

# Set working directory
WORKDIR /app

# Copy the release from the build stage
COPY --from=build /app/_build/prod/rel/mozgops_ex ./

# Start the application
CMD ["./bin/mozgops_ex", "start"]
