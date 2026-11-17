# Shared compiler-owned operation bundle. No handwritten generated GLSL.
IDRIS2 ?= idris2
IDRIS2_GLSLES ?= ./build/exec/idris2-glsles
PHOTO_MATH_OUT ?= build/photo-math

.PHONY: generate
 generate:
	$(MAKE) backend IDRIS2="$(IDRIS2)"
	mkdir -p "$(PHOTO_MATH_OUT)/generated"
	cp generated/fullscreen.vert "$(PHOTO_MATH_OUT)/generated/fullscreen.vert"
	$(IDRIS2_GLSLES) --cg glsles --source-dir src --output-dir "$(PHOTO_MATH_OUT)/generated" src/Example/CoordinatePairing32Grayscale.idr -o coordinate-pairing32-grayscale
	$(IDRIS2_GLSLES) --cg glsles --source-dir src --output-dir "$(PHOTO_MATH_OUT)/generated" src/Example/RotateDifference8ToE1.idr -o rotate-difference8-to-e1
	$(IDRIS2_GLSLES) --cg glsles --source-dir src --output-dir "$(PHOTO_MATH_OUT)/generated" src/Example/ApplyTwoReflections8.idr -o apply-two-reflections8
	glslangValidator -S vert "$(PHOTO_MATH_OUT)/generated/fullscreen.vert"
	glslangValidator -S frag "$(PHOTO_MATH_OUT)/generated/coordinate-pairing32-grayscale.frag"
	glslangValidator -S frag "$(PHOTO_MATH_OUT)/generated/rotate-difference8-to-e1.frag"
	glslangValidator -S frag "$(PHOTO_MATH_OUT)/generated/apply-two-reflections8.frag"
	git rev-parse HEAD > "$(PHOTO_MATH_OUT)/source-revision.txt"
	sha256sum src/Shader/Orthogonal8.idr src/Example/ApplyTwoReflections8.idr src/Shader/Coordinates.idr src/Example/CoordinatePairing32Grayscale.idr > "$(PHOTO_MATH_OUT)/source.sha256"
	cd "$(PHOTO_MATH_OUT)" && sha256sum generated/* > generated.sha256
