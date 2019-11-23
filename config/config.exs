import Config

machine_name = System.get_env("MACHINE", "machine-name")
config :server, :node_list, [
    :"foo@#{machine_name}", 
    :"bar@#{machine_name}", 
    :"goku@#{machine_name}", 
    :"wayne@#{machine_name}"]

config :server, :tolerance, 2
