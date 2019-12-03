import Config

machine_name = System.get_env("MACHINE", "machine-name")

config :server, :dns, :"dns@ec2-54-226-208-169.compute-1.amazonaws.com"

config :server, :tolerance, String.to_integer(System.get_env("TOL", "2"))
