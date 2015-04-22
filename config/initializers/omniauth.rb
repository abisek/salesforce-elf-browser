# OAuth Credentials
Rails.application.config.middleware.use OmniAuth::Builder do
  # Salesforce Production Instance
  provider :salesforce,
           (ENV['SALESFORCE_ELF_CONSUMER_KEY'] || raise("'SALESFORCE_ELF_CONSUMER_KEY' environment variable not set")),
           (ENV['SALESFORCE_ELF_CONSUMER_SECRET'] || raise("'SALESFORCE_ELF_CONSUMER_SECRET' environment variable not set"))

  # Salesforce Sandbox Instance
  provider OmniAuth::Strategies::SalesforceSandbox,
           ENV['SALESFORCE_ELF_SANDBOX_CONSUMER_KEY'] || raise("'SALESFORCE_ELF_SANDBOX_CONSUMER_KEY' environment variable not set"),
           ENV['SALESFORCE_ELF_SANDBOX_CONSUMER_SECRET'] || raise("'SALESFORCE_ELF_SANDBOX_CONSUMER_SECRET' environment variable not set")
end