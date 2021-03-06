defmodule AsyncWithTest do
  use ExUnit.Case
  use AsyncWith

  import ExUnit.CaptureIO

  @async_with_timeout 50

  doctest AsyncWith

  test "raises a CompileError error if 'async' is not followed by 'with'" do
    assert_raise CompileError, ~r/"async" macro must be used with "with"/, fn ->
      ast =
        quote do
          async a <- 1 do
            a
          end
        end

      Code.eval_quoted(ast)
    end
  end

  test "raises a CompileError error if 'async' is not followed by 'with' (without clauses)" do
    assert_raise CompileError, ~r/"async" macro must be used with "with"/, fn ->
      ast =
        quote do
          async do
            2
          end
        end

      Code.eval_quoted(ast)
    end
  end

  test "raises a CompileError error if 'async' is not followed by 'with' (without :do block)" do
    assert_raise CompileError, ~r/"async" macro must be used with "with"/, fn ->
      ast =
        quote do
          async a <- 1
        end

      Code.eval_quoted(ast)
    end
  end

  test "raises a CompileError error if 'async' is not followed by 'with' (single line)" do
    assert_raise CompileError, ~r/"async" macro must be used with "with"/, fn ->
      ast =
        quote do
          async a <- 1, do: a
        end

      Code.eval_quoted(ast)
    end
  end

  test "raises a CompileError error if :do option is missing" do
    assert_raise CompileError, ~r/missing :do option in "async with"/, fn ->
      ast =
        quote do
          async with a <- 1
        end

      Code.eval_quoted(ast)
    end
  end

  test "raises a CompileError error if :do option is missing (without clauses)" do
    assert_raise CompileError, ~r/missing :do option in "async with"/, fn ->
      ast =
        quote do
          async with
        end

      Code.eval_quoted(ast)
    end
  end

  test "emits a warning if 'else' clauses will never match" do
    expexted_message =
      ~s("else" clauses will never match because all patterns in "async with" will always match)

    unexpected_message =
      ~s("else" clauses will never match because all patterns in "with" will always match)

    message =
      capture_io(:stderr, fn ->
        string = """
          defmodule AsyncWithTest.A do
            use AsyncWith

            def test do
              async with a <- 1, b = 2 do
                a + b
              else
                :error -> :error
              end
            end
          end
        """

        Code.eval_string(string)
      end)

    assert warnings_count(message) == 1
    assert message =~ expexted_message
    refute message =~ unexpected_message
  end

  test "emits a warning if 'else' clauses will never match (single line)" do
    expexted_message =
      ~s("else" clauses will never match because all patterns in "async with" will always match)

    unexpected_message =
      ~s("else" clauses will never match because all patterns in "with" will always match)

    message =
      capture_io(:stderr, fn ->
        string = """
          defmodule AsyncWithTest.B do
            use AsyncWith

            def test do
              async with a <- 1, b = 2, do: a + b, else: (:error -> :error)
            end
          end
        """

        Code.eval_string(string)
      end)

    assert warnings_count(message) == 1
    assert message =~ expexted_message
    refute message =~ unexpected_message
  end

  test "emits a warning if 'else' clauses will never match (without clauses)" do
    expexted_message =
      ~s("else" clauses will never match because all patterns in "async with" will always match)

    unexpected_message =
      ~s("else" clauses will never match because all patterns in "with" will always match)

    message =
      capture_io(:stderr, fn ->
        string = """
          defmodule AsyncWithTest.C do
            use AsyncWith

            def test do
              async with do
                2
              else
                :error -> :error
              end
            end
          end
        """

        Code.eval_string(string)
      end)

    assert warnings_count(message) == 1
    assert message =~ expexted_message
    refute message =~ unexpected_message
  end

  test "emits a warning if 'else' clauses will never match (without clauses, single line)" do
    expexted_message =
      ~s("else" clauses will never match because all patterns in "async with" will always match)

    unexpected_message =
      ~s("else" clauses will never match because all patterns in "with" will always match)

    message =
      capture_io(:stderr, fn ->
        string = """
          defmodule AsyncWithTest.D do
            use AsyncWith

            def test do
              async with, do: 2, else: (:error -> :error)
            end
          end
        """

        Code.eval_string(string)
      end)

    assert warnings_count(message) == 1
    assert message =~ expexted_message
    refute message =~ unexpected_message
  end

  test "does not emit a warning if 'else' clauses are missing and clauses will always match" do
    message =
      capture_io(:stderr, fn ->
        string = """
          defmodule AsyncWithTest.E do
            use AsyncWith

            def test do
              async with a <- 1, b = 2 do
                a + b
              end
            end

            def test_single_line do
              async with a <- 1, b = 2, do: a + b
            end
          end
        """

        Code.eval_string(string)
      end)

    assert message == ""
  end

  test "does not emit a warning `warning: variable '<variable>' is unused` with rebinded vars" do
    message =
      capture_io(:stderr, fn ->
        string = """
          defmodule AsyncWithTest.F do
            use AsyncWith

            def test do
              async with a <- 1,
                         b <- 2,
                         a <- a + 3 do
                a + b
              end
            end
          end
        """

        Code.eval_string(string)
      end)

    assert message == ""
  end

  test "does not emit a warning `warning: variable '<variable>' is unused` with temp vars" do
    message =
      capture_io(:stderr, fn ->
        string = """
          defmodule AsyncWithTest.G do
            use AsyncWith

            def test do
              async with a <- 1,
                         b <- 2,
                         c <- a + b do
                c
              end
            end
          end
        """

        Code.eval_string(string)
      end)

    assert message == ""
  end

  test "emits a warning if the result of the expression is not being used" do
    expexted_message =
      "the result of the expression is ignored (suppress the warning by assigning the " <>
        "expression to the _ variable)"

    message =
      capture_io(:stderr, fn ->
        string = """
          defmodule AsyncWithTest.H do
            use AsyncWith

            def test do
              async with a <- 1,
                         b <- 2 do
                a + b
              end

              :test
            end
          end
        """

        Code.eval_string(string)
      end)

    assert warnings_count(message) == 1
    assert message =~ expexted_message
  end

  test "can be used outside of a module" do
    {value, _binding} =
      Code.eval_string("""
        use AsyncWith

        async with a <- 1,
                   b <- 2 do
          a + b
        end
      """)

    assert value == 3
  end

  test "works without clauses" do
    result =
      async with do
        1
      end

    assert result == 1
  end

  test "works without clauses (single line)" do
    result = async with, do: 1

    assert result == 1
  end

  test "works with one clause" do
    result =
      async with {:ok, a} <- echo("a") do
        a
      end

    assert result == "a"
  end

  test "works with one clause (single line)" do
    result = async with {:ok, a} <- echo("a"), do: a

    assert result == "a"
  end

  test "works with several clauses" do
    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- echo("b"),
                 {:ok, c} <- echo("c"),
                 {:ok, d} <- echo("d"),
                 {:ok, e} <- echo("e"),
                 {:ok, f} <- echo("f"),
                 {:ok, g} <- echo("g") do
        Enum.join([a, b, c, d, e, f, g], " ")
      end

    assert result == "a b c d e f g"
  end

  test "works with several clauses (single line)" do
    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- echo("b"),
                 {:ok, c} <- echo("c"),
                 {:ok, d} <- echo("d"),
                 {:ok, e} <- echo("e"),
                 {:ok, f} <- echo("f"),
                 {:ok, g} <- echo("g"),
                 do: Enum.join([a, b, c, d, e, f, g], " ")

    assert result == "a b c d e f g"
  end

  test "works with clauses that depend on variables binded in previous clauses" do
    result =
      async with {:ok, a} <- echo("a"),
                 b = "b",
                 {:ok, c} <- echo("c(#{a})"),
                 {:ok, d} <- echo("d"),
                 {:ok, e} <- echo("e(#{a})"),
                 {:ok, f} <- echo("f(#{e}, #{d})"),
                 {:ok, g} <- echo("g(#{e})"),
                 {:ok, h} <- echo("h(#{f})"),
                 i = "i",
                 {:ok, j} <- echo("j(#{h}, #{i})") do
        Enum.join([a, b, c, d, e, f, g, h, i, j], " ")
      end

    assert result == "a b c(a) d e(a) f(e(a), d) g(e(a)) h(f(e(a), d)) i j(h(f(e(a), d)), i)"
  end

  test "works with clauses that reference external variables" do
    a = "a"
    b = "b"

    result =
      async with {:ok, c} <- echo("c(#{a})"),
                 {:ok, d} <- echo("d"),
                 {:ok, e} <- echo("e(#{a})"),
                 {:ok, f} <- echo("f(#{e}, #{d})"),
                 {:ok, g} <- echo("g(#{e})"),
                 {:ok, h} <- echo("h(#{f})"),
                 {:ok, i} <- echo("i"),
                 {:ok, j} <- echo("j(#{h}, #{i})") do
        Enum.join([a, b, c, d, e, f, g, h, i, j], " ")
      end

    assert result == "a b c(a) d e(a) f(e(a), d) g(e(a)) h(f(e(a), d)) i j(h(f(e(a), d)), i)"
  end

  test "works with clauses with pin matching" do
    ok = :ok
    e = "e(a)"

    result =
      async with {:ok, a} <- echo("a"),
                 b = "b",
                 {:ok, c} <- echo("c(#{a})"),
                 {^ok, d} <- echo("d"),
                 {:ok, ^e} <- echo("e(#{a})"),
                 {:ok, f} <- echo("f(#{e}, #{d})"),
                 {ok, g} <- echo("g(#{e})"),
                 {:ok, h} <- echo("h(#{f})"),
                 i = "i",
                 {^ok, j} <- echo("j(#{h}, #{i})") do
        Enum.join([a, b, c, d, e, f, g, h, i, j], " ")
      end

    assert result == "a b c(a) d e(a) f(e(a), d) g(e(a)) h(f(e(a), d)) i j(h(f(e(a), d)), i)"
  end

  test "works with clauses with ignored and unbound variables" do
    result =
      async with _..42 <- 1..42,
                 {_ok, a} <- echo("a"),
                 {_, _} = b <- echo("b(#{a})"),
                 {_, _} <- {"c", "c"} do
        {:ok, b} = b
        Enum.join([a, b], " ")
      end

    assert result == "a b(a)"
  end

  test "works with clauses with variable rebinding" do
    a = "a"
    b = "b"

    result =
      async with {:ok, c} <- echo("c(#{a})"),
                 {:ok, d} <- echo("d"),
                 {:ok, _} = a <- echo("A"),
                 {:ok, a} <- a,
                 {:ok, e} <- echo("e(#{a})"),
                 {:ok, f} <- echo("f(#{e}, #{d})"),
                 {:ok, g} <- echo("g(#{e})"),
                 {:ok, _} = a <- echo("ä"),
                 {:ok, a} <- a,
                 e = "E",
                 {:ok, h} <- echo("h(#{f}, #{e})"),
                 {:ok, i} <- echo("i"),
                 {:ok, j} <- echo("j(#{h}, #{i})") do
        Enum.join([a, b, c, d, e, f, g, h, i, j], " ")
      end

    assert result == "ä b c(a) d E f(e(A), d) g(e(A)) h(f(e(A), d), E) i j(h(f(e(A), d), E), i)"
  end

  test "works with clauses with guards" do
    ok = :ok
    e = "e(a)"

    result =
      async with {:ok, a} <- echo("a"),
                 b = "b",
                 {:ok, c} <- echo("c(#{a})"),
                 {^ok, d} <- echo("d"),
                 {:ok, ^e} <- echo("e(#{a})"),
                 {:ok, f} when is_binary(f) <- echo("f(#{e}, #{d})"),
                 {ok, g} when ok == :ok <- echo("g(#{e})"),
                 {:ok, h} when is_binary(h) <- echo("h(#{f})"),
                 i = "i",
                 {^ok, j} <- echo("j(#{h}, #{i})") do
        Enum.join([a, b, c, d, e, f, g, h, i, j], " ")
      end

    assert result == "a b c(a) d e(a) f(e(a), d) g(e(a)) h(f(e(a), d)) i j(h(f(e(a), d)), i)"
  end

  test "works with clauses with complex pattern matching" do
    ok = :ok

    result =
      async with true <- get_true(),
                 {{:ok, a}, {:ok, a}} <- {echo("a"), echo("a")},
                 {^ok, {^ok, b}, {:ok, b}} <- {:ok, echo("b(#{a})"), {:ok, "b(a)"}} do
        Enum.join([a, b], " ")
      end

    assert result == "a b(a)"
  end

  test "works with bare expressions" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    result =
      async with {:ok, a} <- echo(1),
                 Agent.update(agent, fn count -> count + a end),
                 {:ok, b} <- echo(2),
                 Agent.update(agent, fn count -> count + b end) do
        Enum.join([a, b], " ")
      end

    assert result == "1 2"
    assert Agent.get(agent, & &1) == 3

    :ok = Agent.stop(agent)
  end

  test "raises MatchError when the sides of a clause does not match" do
    assert_raise MatchError, "no match of right hand side value: :error", fn ->
      async with {:ok, a} <- echo("a"), {:ok, b} = error(a) do
        Enum.join([a, b], " ")
      end
    end
  end

  test "returns the error if no else conditions are present" do
    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- echo("b"),
                 {:ok, c} <- echo("c"),
                 {:ok, d} <- echo("d(#{a})"),
                 {:ok, e} <- error("e(#{b})"),
                 {:ok, f} <- echo("f(#{b})"),
                 {:ok, g} <- echo("g(#{e})") do
        Enum.join([a, b, c, d, e, f, g], " ")
      end

    assert result == :error
  end

  test "executes else conditions when present" do
    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- echo("b"),
                 {:ok, c} <- echo("c"),
                 {:ok, d} <- echo("d(#{a})"),
                 {:ok, e} <- error("e(#{b})"),
                 {:ok, f} <- echo("f(#{b})"),
                 {:ok, g} <- echo("g(#{e})") do
        Enum.join([a, b, c, d, e, f, g], " ")
      else
        {:error, error} -> error
        :error -> :test
      end

    assert result == :test
  end

  test "executes else conditions when present (single line)" do
    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- echo("b"),
                 {:ok, c} <- echo("c"),
                 {:ok, d} <- echo("d(#{a})"),
                 {:ok, e} <- error("e(#{b})"),
                 {:ok, f} <- echo("f(#{b})"),
                 {:ok, g} <- echo("g(#{e})"),
                 do: Enum.join([a, b, c, d, e, f, g], " "),
                 else:
                   (
                     {:error, error} -> error
                     :error -> :test
                   )

    assert result == :test
  end

  test "allows guards on else conditions" do
    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- echo("b"),
                 {:ok, c} <- echo("c"),
                 {:ok, d} <- echo("d(#{a})"),
                 {:ok, e} <- error("e(#{b})"),
                 {:ok, f} <- echo("f(#{b})"),
                 {:ok, g} <- echo("g(#{e})") do
        Enum.join([a, b, c, d, e, f, g], " ")
      else
        error when is_atom(error) -> error
      end

    assert result == :error
  end

  test "does not leak variables to else conditions" do
    value = 1

    result =
      async with 1 <- value,
                 value = 2,
                 :ok <- error() do
        value
      else
        _ -> value
      end

    assert result == 1
    assert value == 1
  end

  test "raises AsyncWith.ClauseError when there are not else condition that match the error" do
    assert_raise AsyncWith.ClauseError, "no async with clause matching: :error", fn ->
      async with {:ok, value} <- error() do
        value
      else
        {:error, error} -> error
      end
    end
  end

  test "does not override CaseClauseError produced inside of else conditions" do
    assert_raise CaseClauseError, "no case clause matching: :error", fn ->
      async with {:ok, value} <- error() do
        value
      else
        :error = error ->
          case error do
            {:error, error} -> error
          end
      end
    end
  end

  test "does not override WithClauseError produced inside of else conditions" do
    assert_raise WithClauseError, "no with clause matching: :error", fn ->
      async with {:ok, value} <- error() do
        value
      else
        :error = error ->
          with {:ok, value} <- error do
            value
          else
            {:error, error} -> error
          end
      end
    end
  end

  test "re-throws uncaught values" do
    result =
      try do
        async with _ <- throw(:test), do: :error
      catch
        :test -> :ok
      end

    assert result == :ok
  end

  test "re-raises unrescued errors" do
    result =
      try do
        async with _ <- raise("oops"), do: :error
      rescue
        error -> error
      end

    assert result == %RuntimeError{message: "oops"}
  end

  test "returns `{:exit, :normal}` on normal exit" do
    result = async with _ <- exit(:normal), do: :ok

    assert result == {:exit, :normal}
  end

  test "returns `{:exit, {:timeout, {AsyncWith, :async, [@async_with_timeout]}}}` on timeout" do
    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- echo("b"),
                 {:ok, c} <- echo("c"),
                 {:ok, d} <- echo("d(#{a})"),
                 {:ok, e} <- delayed_echo("e(#{b})", @async_with_timeout + 10),
                 {:ok, f} <- echo("f(#{b})"),
                 {:ok, g} <- echo("g(#{e})") do
        Enum.join([a, b, c, d, e, f, g], " ")
      end

    assert result == {:exit, {:timeout, {AsyncWith, :async, [50]}}}
  end

  test "executes else conditions on timeout" do
    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- echo("b"),
                 {:ok, c} <- echo("c"),
                 {:ok, d} <- echo("d(#{a})"),
                 {:ok, e} <- delayed_echo("e(#{b})", @async_with_timeout + 10),
                 {:ok, f} <- echo("f(#{b})"),
                 {:ok, g} <- echo("g(#{e})") do
        Enum.join([a, b, c, d, e, f, g], " ")
      else
        {:exit, {:timeout, _}} -> :timeout
      end

    assert result == :timeout
  end

  test "executes each clause in a different process" do
    result =
      async with {:ok, pid_a} <- pid(),
                 {:ok, pid_b} <- pid(),
                 {:ok, pid_c} <- pid(pid_a),
                 {:ok, pid_d} <- pid(),
                 {:ok, pid_e} <- pid(pid_a),
                 {:ok, pid_f} <- pid([pid_e, pid_d]),
                 {:ok, pid_g} <- pid(pid_e),
                 {:ok, pid_h} <- pid(pid_f),
                 {:ok, pid_i} <- pid(),
                 {:ok, pid_j} <- pid([pid_h, pid_i]) do
        Enum.uniq([pid_a, pid_b, pid_c, pid_d, pid_e, pid_f, pid_g, pid_h, pid_i, pid_j])
      else
        _ -> []
      end

    assert length(result) == 10
  end

  test "kills all the spawned processes on error" do
    {:ok, agent} = Agent.start_link(fn -> %{} end)

    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- delayed_echo("b(#{a})", 10),
                 {:ok, c} <- echo("c(#{a})"),
                 {:ok, d} <- error("d(#{b})"),
                 {:ok, e} <- {register_pid_and_wait(agent, :e), "e(#{c})"},
                 {:ok, f} <- {register_pid_and_wait(agent, :f), "f(#{c})"},
                 {:ok, g} <- {register_pid_and_wait(agent, :g), "g(#{e})"} do
        Enum.join([a, b, c, d, e, f, g], " ")
      end

    pids = Agent.get(agent, & &1)

    assert result == :error
    refute Process.alive?(pids.e)
    refute Process.alive?(pids.f)
    refute Map.has_key?(pids, :g)

    :ok = Agent.stop(agent)
  end

  @tag :capture_log
  test "kills all the spawned processes when an error is raised" do
    {:ok, agent} = Agent.start_link(fn -> %{} end)

    result =
      try do
        async with {:ok, a} <- echo("a"),
                   {:ok, b} <- echo("b(#{a})"),
                   {:ok, c} <- echo("c(#{a})"),
                   {:ok, d} <- {register_pid_and_wait(agent, :d), "d(#{b})"},
                   {:ok, e} <- {register_pid_and_wait(agent, :e), "e(#{c})"},
                   {:ok, f} <- delay(10, fn -> raise_oops("f(#{c})") end),
                   {:ok, g} <- {register_pid_and_wait(agent, :g), "g(#{e})"} do
          Enum.join([a, b, c, d, e, f, g], " ")
        end
      rescue
        error -> error
      end

    pids = Agent.get(agent, & &1)

    assert result == %RuntimeError{message: "oops"}
    refute Process.alive?(pids.d)
    refute Process.alive?(pids.e)
    refute Map.has_key?(pids, :g)

    :ok = Agent.stop(agent)
  end

  @tag :capture_log
  test "kills all the spawned processes when a value is thrown" do
    {:ok, agent} = Agent.start_link(fn -> %{} end)

    result =
      try do
        async with {:ok, a} <- echo("a"),
                   {:ok, b} <- echo("b(#{a})"),
                   {:ok, c} <- echo("c(#{a})"),
                   {:ok, d} <- {register_pid_and_wait(agent, :d), "d(#{b})"},
                   {:ok, e} <- {register_pid_and_wait(agent, :e), "e(#{c})"},
                   {:ok, f} <- delay(10, fn -> throw("f(#{c})") end),
                   {:ok, g} <- {register_pid_and_wait(agent, :g), "g(#{e})"} do
          Enum.join([a, b, c, d, e, f, g], " ")
        end
      catch
        thrown_value -> thrown_value
      end

    pids = Agent.get(agent, & &1)

    assert result == "f(c(a))"
    refute Process.alive?(pids.d)
    refute Process.alive?(pids.e)
    refute Map.has_key?(pids, :g)

    :ok = Agent.stop(agent)
  end

  test "kills all the spawned processes on timeout" do
    {:ok, agent} = Agent.start_link(fn -> %{} end)

    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- echo("b(#{a})"),
                 {:ok, c} <- echo("c(#{a})"),
                 {:ok, d} <- {register_pid_and_wait(agent, :d), "d(#{b})"},
                 {:ok, e} <- {register_pid_and_wait(agent, :e), "e(#{c})"},
                 {:ok, f} <- delayed_echo("f(#{c})", @async_with_timeout + 10),
                 {:ok, g} <- {register_pid_and_wait(agent, :g), "g(#{e})"} do
        Enum.join([a, b, c, d, e, f, g], " ")
      end

    pids = Agent.get(agent, & &1)

    assert result == {:exit, {:timeout, {AsyncWith, :async, [50]}}}
    refute Process.alive?(pids.d)
    refute Process.alive?(pids.e)
    refute Map.has_key?(pids, :g)

    :ok = Agent.stop(agent)
  end

  @tag :capture_log
  test "kills all the spawned processes on exit" do
    {:ok, agent} = Agent.start_link(fn -> %{} end)

    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- echo("b_#{a}_"),
                 {:ok, c} <- echo("c_#{a}_"),
                 {:ok, d} <- {register_pid_and_wait(agent, :d), "d_#{b}_"},
                 {:ok, e} <- {register_pid_and_wait(agent, :e), "e_#{c}_"},
                 {:ok, f} <- delay(10, fn -> exit(:"f_#{c}_") end),
                 {:ok, g} <- {register_pid_and_wait(agent, :g), "g_#{e}_"} do
        Enum.join([a, b, c, d, e, f, g], " ")
      end

    pids = Agent.get(agent, & &1)

    assert result == {:exit, :f_c_a__}
    refute Process.alive?(pids.d)
    refute Process.alive?(pids.e)
    refute Map.has_key?(pids, :g)

    :ok = Agent.stop(agent)
  end

  @async_with_timeout 100
  test "optimizes the execution" do
    started_at = System.system_time(:millisecond)

    result =
      async with {:ok, a} <- delayed_echo("a", 20),
                 {:ok, b} <- delayed_echo("b", 20),
                 {:ok, c} <- delayed_echo("c", 40),
                 {:ok, d} <- delayed_echo("d(#{a})", 20),
                 {:ok, e} <- delayed_echo("e(#{b})", 40),
                 {:ok, f} <- delayed_echo("f(#{b})", 20),
                 {:ok, g} <- delayed_echo("g(#{e})", 20) do
        Enum.join([a, b, c, d, e, f, g], " ")
      end

    # The dependency graph is:
    #
    #           A(20)        B(20)       C(40)
    #             ↓          ↙  ↘
    #           C(20)   E(40)    F(20)
    #                     ↓
    #                   G(20)
    #
    # The most time consuming path should be B -> E -> G ~ 400 milliseconds

    finished_at = System.system_time(:millisecond)

    assert result == "a b c d(a) e(b) f(b) g(e(b))"
    assert finished_at - started_at < 95
  end

  test "clauses should be executed as soon as their dependencies are resolved" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    task =
      Task.async(fn ->
        :timer.sleep(1)
        Agent.get(agent, & &1)
      end)

    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b} <- delayed_echo("b", 20),
                 {:ok, c} <- {Agent.update(agent, fn _ -> 1 end), "c(#{a})"},
                 {:ok, d} <- echo("d(#{a}, #{b})") do
        Enum.join([a, b, c, d], " ")
      end

    # c should not wait for b
    assert Task.await(task) == 1
    assert result == "a b c(a) d(a, b)"

    :ok = Agent.stop(agent)
  end

  test "errors with the same internal representation are not misinterpreted" do
    result =
      async with {:ok, a} <- echo("a"),
                 {:ok, b, c} <- {:ok, [a: 1]} do
        Enum.join([a, b, c], " ")
      end

    assert result == {:ok, [a: 1]}
  end

  test "internal variable 'values' cannot be accessed outside the macro's context" do
    values = ["X", "Y", "Z"]

    result = async with _ <- 1, do: values

    assert result == ["X", "Y", "Z"]
    assert values == ["X", "Y", "Z"]
  end

  test "internal variable 'values' cannot be rebinded" do
    result =
      async with a <- "a",
                 b <- "b",
                 c <- "c",
                 values <- [a, b, c],
                 d <- hd(values) do
        Enum.join([a, b, c, d], " ")
      end

    assert result == "a b c a"
  end

  defp warnings_count(string) do
    length(String.split(string, "warning:")) - 1
  end

  defp delay(delay, fun) when is_function(fun) do
    :timer.sleep(delay)
    fun.()
  end

  defp echo(value) do
    {:ok, value}
  end

  defp delayed_echo(value, delay) do
    :timer.sleep(delay)
    echo(value)
  end

  defp get_true(_value \\ nil) do
    true
  end

  defp error(_value \\ nil) do
    :error
  end

  defp raise_oops(_value) do
    raise("oops")
  end

  defp pid(_value \\ nil) do
    {:ok, self()}
  end

  defp register_pid(agent, key) do
    pid = self()
    Agent.update(agent, &Map.merge(&1, %{key => pid}))
    :ok
  end

  defp register_pid_and_wait(agent, key) do
    register_pid(agent, key)
    # Wait to be killed
    :timer.sleep(1_000)
  end
end
