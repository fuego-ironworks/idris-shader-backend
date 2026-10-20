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

At the first accepted slice, five other expanded checker/mock files remained migration debt. In particular,
the mock interpreter needs a checked replacement for decorated dataclass and
Any-shaped instruction payloads. No foreign import of a first-party Python
checker is used to pretend this work is complete.

The next slice replaces analytic continuation and the shared factor portrait
with checked modules. All original interface, capacity, runtime bound,
phase/log placement, lowp/highp IR identity, palette, operand-only select,
continuation count, GLSL validation and vertex-link assertions remain. A
separate checked library exports loop_blocks without running the command on
import. Standard-library subprocess, pathlib, tempfile, shutil and regex are
explicit foreign boundaries; result fields are typed before checked use.

The real accepted Ithon frontend refused the retained attempts in this order:
analytic-original.pi uses Python colon annotations; analytic-augassign.pi
uses unsupported AugAssign; analytic-method-results.pi uses untyped foreign
count results; analytic-unpacking.pi uses unsupported tuple assignment;
analytic-regex-result.pi compares an untyped foreign regex result. Explicit
assignments, typed results, indexed tuple projections and Boolean regex
presence preserve the original operations. Both complete replacement modules
then passed mandatory frontend checking and refused the absent local backend.
That is frontend admission, not successful shader emission. Hosted make check
must execute these replacements against the exact built backend before merge.

mock-original.pi retains the expanded production interpreter verbatim and
fails on Python annotations. mock-dataclass.pi retains its actual Program
shape with membership annotations (object payload remains explicitly
unfinished) and the real frontend refuses typed class decorators. No Python
import fallback or object-shaped fake checked interpreter replaces it.

The third slice replaces check_backend.py with check_backend.pi. Every golden
shader/typed IR comparison, CSE and interface-width assertion, precision
directive case, structured branch and guarded sentinel check, fixed-array
emission check, four backend refusals and tuple-width refusal remains. The
private compile helper takes an explicit typed list of directive arguments;
the actual producer argv bytes and order are unchanged for all 13 calls.

Actual frontend failures are retained as backend-optional-argument.pi
(truthiness did not narrow optional text), backend-none-comparison.pi (optional
text versus None comparison is unsupported) and backend-not-in.pi (NotIn is
unsupported). Explicit directive lists and Boolean negation of membership
preserve the existing operations. The complete replacement then passed the
real mandatory frontend and refused the absent local backend; hosted actual
backend execution remains required before integration.

mock-variadic-tuple.pi records the actual Program constructor's unsupported
variadic tuple annotations. mock-instance-state.pi minimizes those payload
annotations explicitly to unfinished objects and proves the next actual gap:
self.interfaces assignment is rejected because static assignment currently
requires a simple name target. This is a compiler blocker, not an accepted
mock replacement. The mock Program, nested binding types and interpreter must
receive a checked design; there is no first-party Python import escape.

check_fragment_mocks.py and fragment_mock_vm.py remain the two expanded files
with unresolved migration debt. Other unchanged legacy Python tools remain
separate debt. This does not establish Ithon acceptance of the whole of PR
#68. Physical GPUs and live renderer integration remain separate obligations.

Concurrent accepted main ce4bc6101155bc1850bcf5d68207eac584f42718 adds
optional GPU followers and a required pinned-Ike outer build graph with an
independent AICI receipt gate. All that unique work is retained by normal
merge ancestry. The two-checker d85a77b run passed actual backend, GLSL/link,
41 backend tests, nine mock targets and Mesa checks on its older graph; it is
historical for the new graph. The combined three-checker follow-up must run
through the maintained pinned Ike and independent gate on its current head.
