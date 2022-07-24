Logger.configure_backend(:console,
  level: :debug,
  metadata: :all
)

ExUnit.start(timeout: 5000)
