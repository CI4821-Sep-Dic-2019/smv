import Config

config :server, :dns, String.to_atom(System.get_env("DNS", "dns@ec2-54-226-208-169.compute-1.amazonaws.com"))
config :server, :tolerance, String.to_integer(System.get_env("TOL", "2"))
