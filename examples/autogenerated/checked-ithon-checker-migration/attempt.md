# Checked-Ithon checker migration

Purpose: repair the expanded first-party Python checker/mock debt introduced by
merged PR #68, without relabeling the old Python executions as Ithon acceptance.
Production baseline: a71a198b0e001a34dc662c8d68ac22500adad1d8.

The changed first-party files are check_analytic_continuation.py,
check_backend.py, check_fragment_mocks.py, check_shared_factor_portrait.py,
check_surfer_root_search.py and fragment_mock_vm.py under tools/. The old
division-migration note incorrectly called these files unchanged debt.

Type sketch: a checker assertion maps a Boolean condition and a text diagnostic
to no result on success, or an assertion exception on failure. The central
operation is require(condition ∈ bool, message ∈ str) → None. Full checker
entry points additionally need checked filesystem/temporary-directory and
subprocess boundaries. The mock parser maps text to structured instructions;
its interpreter maps those instructions and typed numeric inputs to a fragment
tuple. Existing Any payloads, dataclass construction and nested instructions
need an explicit typed replacement, not a foreign-Python escape.

This first real slice retains the require operation used by the Surfer checker.
It uses Ithon membership types and asks the mandatory whole-module checker to
check the function before any consumer effect. It deliberately does not call
Python or import the maintained Python checker as a substitute.

Compiler target: Linux host, dilapidated-shed/ithon main source
396d8b7af1417a0a61245db940fdb22ef9fbac51.
The repository's actual `ithon` host frontend was invoked with require.pi.
It returned status 1 before executing the module:
`ithon_static.StaticTypeError: unary operator is not statically defined for bool`
at the real checker's `if not condition` operation. No Python fallback ran.

That historical failure is cleared by Ithon's accepted control-flow frontend,
source d6e83969f82512e920fb17b44326cb54f31d015c, merged on main as
9d530f4ad51f5b0a09c3e74dbe45cac5bb6d52d3. Its actual host qualifier ran
42 required tests with zero skips during BACKLOG-REPAIR-02. The require
slice passes with an explicit AssertionError import.

The complete Surfer checker is retained as surfer.pi and replaces the owned
Python program under tools/ as check_surfer_root_search.pi. The module uses
checked Boolean/integer/text operations. pathlib, tempfile, subprocess and
shutil remain explicit standard-library foreign boundaries. Their return
fields receive local int/text annotations before comparison or concatenation.
Path joining uses joinpath rather than an unsupported overloaded operator;
formatting uses checked text concatenation. All original shader assertions and
the optional glslang validation remain. The script is a command entrypoint.

The real frontend checked the entire candidate, then its main refused the
absent backend executable in this scratch environment. This proves frontend
admission and the missing-producer refusal, not shader emission. The hosted
workflow pins the accepted Ithon frontend and executes the replacement against
the actual built backend through the existing complete check target.

Five other expanded checker/mock files remain migration debt. In particular,
the mock interpreter needs a checked replacement for decorated dataclass and
Any-shaped instruction payloads. No foreign import of a first-party Python
checker is used to pretend this work is complete.

This attempt is not a migrated production checker, a passing shader test, or
Ithon acceptance of PR #68. The production Python programs remain named debt
until checked replacements pass the original backend and negative controls.
