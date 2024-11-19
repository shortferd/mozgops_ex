# mozgops_ex

Simple elixir HTTP-server application automating creation of proper Linux task execution order based on inter-task dependencies.
## How it works
Application is a server operating through HTTP-interface and supporting JSON-API and REST. As an output it returns either correctly ordered JSON object, or bash script with correctly ordered commands. The Application logic will be described in next sections. 
### Input and output data format
The input JSON object is expected to be as follows:
```json
 [
    {
      "name": "task_1", 
      "command": "ls -l", 
      "requires": ["task_2"]},
    { 
      "name": "task_2", 
      "command": "echo 'Hello, World!'"
    },
    {
      "name": "task_3", 
      "command": "touch /tmp/file.txt", 
      "requires":["task_1"]
    }
 ]
```
Here you can see, that the tasks are ordered based on **"requires"** key. So the resulting output JSON object is expected to look as follows:
```json
 [
    {
      "name": "task_2", 
      "command": "echo 'Hello, World!'"
    },
    {
      "name": "task_1", 
      "command": "ls -l"
    },
    {
      "name": "task_3", 
      "command": "touch /tmp/file.txt"
    }
 ]
```
and bash script is expected to be like:
```bash
#!/usr/bin/env bash
echo 'Hello, World!
ls -l
touch /tmp/file.txt
```
Meanwhile, the application also supports validation of necessary task object keys. The task JSON object **must contain** **"name"** and **"command"** keys. Otherwise, an error response like:
```json
{
  "errors":[
              {
                "title": "Invalid request",
                "detail": "One or multiple tasks miss mandatory keys"
              }
           ]
}
``` 
will be returned for JSON object, and the following Response 
```
  "One or multiple tasks miss mandatory keys"
```
will be returned instead of bash script.
### HTTP API
In order to retrieve data described in [previous subsection](#input-and-output-data-format) the following requests are needed:
* for JSON:
  ```
  POST {input_json} /
  ```
* for bash
  ```
  POST {input_json} /bash
  ```
If the input data are correct, then you receive:
```
200
{output JSON or bash}
```
otherwise
```
400
{error response}
```

If you try to access non-existing endpoint or perform unsupported request: you will get:
  ```
  POST {input_json} /backup

  GET  /  
  ```

you will get:
  ```
  404
  not found
  ```
for both cases.

And if the unexpected error occurs, you may get:
  ```
  500
  ""
  ```
This happens, most likely, in case of crash at server side.
## Prerequisites
Tested within following environment:
* **OS**: Ubuntu 20.04
* **Elixir**: 1.17.3
* **Erlang**: 27.1.2

## Installation, setup and testing

Before going to following sections, ensure that you have installed all dependencies described in [prerequisites](#prerequisites) section.
### Development mode
Since project is in active development, all potential contributors can play with it in development mode. To install and use the application in development mode, you can do the following:
```bash
# Clone project source code
git clone https://github.com/shortferd/mozgops_ex.git
# Move to local project directory
cd mozgopx_ex
# Install project dependencies
mix deps.get
# Start project 
iex -S mix
```
The last command will open the iex shell with all the application modules loaded. So this is useful when you would like to test function manually.
If you would like to launch tests, after installing dependencies y 

### Release
As mentioned in [Mix documentation](https://hexdocs.pm/mix/1.17.3/Mix.Tasks.Release.html) you can create and launch a new release for production-like use.
To do this, after dependencies installation step from [previous subsection](#development-mode), execute the following:
```bash
# Create new release
MIX_ENV=prod mix release --path $PATH_TO_RELEASE
# Move to release directory
cd  $PATH_TO_RELEASE
# Start the release
bin/mozgops_ex start
```
### Configuration
Currently, only applications default ip address and tcp port can be configured. By default, those are set as:
```
IP_ADDRESS=0.0.0.0
PORT=4000
```
To set up your own values change the following sections in dev.exs or test.exs:
```elixir
config :mozgops_ex, MozgopsEx.BanditServer,
    ip: # your ip adress in form of tuple, i.e. {0,0,0,0}
    port: # your tcp port
```
for production you can set them up using Linux env variables:
```bash
IP_ADDRESS={your_ip} PORT={your_port} path_to_release/bin/mozgops_ex start
```

### Use in docker container
To try application in docker container, from project directory run the following to build an image:
```bash
docker build -t mozgops .
``` 
After image is build run the following commands to launch the container:
```bash
## Launch the container
docker run -d -e IP_ADDRESS={your_ip} -e PORT={your_port} -p {your_port}:{your_port} --name mz_server mozgops
## Verify that container is running
docker ps
```
If you don't desire to specify IP_ADDRESS or PORT then look to [configuration](#configuration) section to find default values for -p flag.

## Future plans

1. Current implementation heavily relies on "required" key. Maybe custom LLM using [Bumblebee](https://github.com/elixir-nx/bumblebee) would be good improvement.
2. Maybe upgrade to full-scale Phoenix app with GUI.  