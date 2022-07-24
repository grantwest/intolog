defmodule IntoLogTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  doctest IntoLog

  test "log lines" do
    log = capture_log(fn -> Enum.into(["hello", "world"], IntoLog.log(:info)) end)
    assert log =~ "hello"
    assert log =~ "world"
  end

  test "log at different levels" do
    msg = msg()
    assert capture_log(fn -> Enum.into([msg], IntoLog.log(:info)) end) =~ "[info]  #{msg}"

    msg = msg()
    assert capture_log(fn -> Enum.into([msg], IntoLog.log(:error)) end) =~ "[error] #{msg}"
  end

  test "uses calling module for metadata" do
    msg = msg()
    log = capture_log(fn -> Enum.into([msg], IntoLog.log(:info)) end)
    assert log =~ msg
    assert log =~ "module=IntoLogTest"
    assert log =~ "function=test uses calling module for metadata/1"
    assert log =~ "mfa=IntoLogTest.\"test uses calling module for metadata\"/1"
    assert log =~ "file=test/into_log_test.exs"
    assert log =~ "line=22"
    # assert log =~ "application=into_log"
  end

  test "can fetch __CALLER__ metadata in iex" do
    Code.eval_string("""
      require IntoLog
      Enum.into(["helloiex"], IntoLog.log(:info))
    """)
  end

  test "logs additional metadata" do
    msg = msg()
    log = capture_log(fn -> Enum.into([msg], IntoLog.log(:info, foo: "bar")) end)
    assert log =~ msg
    assert log =~ "foo=bar"
  end

  test "works with System.cmd/3" do
    log = capture_log(fn -> System.cmd("echo", ["echotest"], into: IntoLog.log(:info)) end)
    assert log =~ "echotest"
    assert log =~ "module=IntoLogTest"
    assert log =~ "mfa=IntoLogTest.\"test works with System.cmd/3\"/1"
    assert log =~ "file=test/into_log_test.exs"
  end

  test "this test just logs a few lines for developer convenience" do
    Enum.into(["line1"], IntoLog.log(:info, foo: "bar"))
    System.cmd("echo", ["line2"], into: IntoLog.log(:info, baz: "bif"))
  end

  defp msg() do
    "msg-#{System.unique_integer()}"
  end
end
