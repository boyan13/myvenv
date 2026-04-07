# myvenv
A global venv manager for Python.

This is a project I wrote for personal use. It's a powershell cli tool for Windows that manages a collection of global venvs, similar to conda envs but very lightweight. 

> [!NOTE] 
> Naturally, you'd have to adjust ownership and execution policy to allow ps1 scripts originating from the internet to run.

## Basic usage

Create venv (additional args exist for more advanced use cases):

```shell
myvenv create <NAME>
```
Activate venv:
```shell
myvenv activate <NAME>
```
Delete venv:
```shell
myvenv delete <NAME>
```

## Getting help / docs

You can invoke the script directly or with "help" to get help. The name of a command can be passed as argument to help in order to print help for that specific command.

```shell
myvenv
myvenv help
myvenv help <CMD>
```

## Information

- Windows is the only supported platform. **(tested on Windows 11, powershell version 5.1)**. 
- The default global venvs directory is `$HOME\.myvenv`, but this can be changed with `myvenv set HomeDir=path/to/dir` or by manually editing the config file created at `$HOME\.myvenv.json`.
- Providing a python version to the `create` command requires py launcher / python installation manager (the default system python is invoked if no version is specified).
