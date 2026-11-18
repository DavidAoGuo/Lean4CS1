import Lake
open Lake DSL

package «fp-course» where
  name := "fp-course"
  -- Keep the course toolchain aligned with the pinned Mathlib release.
  fixedToolchain := true

require graphfold from "GraphFold"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.33.0"

@[default_target]
lean_lib «FPCourse» where
  globs := #[.andSubmodules `FPCourse]
