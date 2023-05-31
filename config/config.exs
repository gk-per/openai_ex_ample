import Config

config :openai,
  # find it at https://platform.openai.com/account/api-keys
  api_key: System.get_env("OPENAI_API_KEY"),
  # find it at https://platform.openai.com/account/org-settings under "Organization ID"
  organization_key: System.get_env("OPENAI_ORGANIZATION_KEY")
