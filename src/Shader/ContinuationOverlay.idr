module Shader.ContinuationOverlay

import Shader.Source

%default total

mix_vec3 : ShaderFloatTuple 3 -> ShaderFloatTuple 3 -> Double -> ShaderFloatTuple 3
mix_vec3 left right weight =
  add_components (scale_components (1.0 - weight) left) (scale_components weight right)

distance_to_segment : ShaderFloatTuple 2 -> ShaderFloatTuple 2 -> ShaderFloatTuple 2 -> Double
distance_to_segment point start finish =
  let segment = subtract_components finish start
      length_squared = component_product_sum segment segment
      along = clampF (component_product_sum (subtract_components point start) segment /
                      maxF length_squared 0.00000000000000000001) 0.0 1.0
      nearest = add_components start (scale_components along segment)
   in euclidean_component_norm (subtract_components point nearest)

step_values : ShaderFloatTuple 2 -> Double -> ShaderFloatTuple 4 -> ShaderFloatTuple 2 -> Double -> Double -> ShaderFloatTuple 4
step_values point world_per_pixel previous_state disc_center disc_radius path_distance =
  let distance_from_center = euclidean_component_norm (subtract_components point disc_center)
      edge_width = 1.25 * world_per_pixel
      disc_reveal = 1.0 - smoothstepF (disc_radius - edge_width)
                                        (disc_radius + edge_width)
                                        distance_from_center
      revealed = if disc_radius < 0.0
                    then 1.0
                    else maxF (x previous_state) disc_reveal
      boundary = maxF (y previous_state)
                      (1.0 - smoothstepF (1.0 * world_per_pixel)
                                           (2.5 * world_per_pixel)
                                           (absF (distance_from_center - disc_radius)))
      path_line = maxF (z previous_state)
                       (1.0 - smoothstepF 1.5 3.0
                                            (path_distance / world_per_pixel))
      center_mark = maxF (w previous_state)
                         (1.0 - smoothstepF 3.0 4.5
                                              (distance_from_center / world_per_pixel))
   in vec4 revealed boundary path_line center_mark

first_step : ShaderFloatTuple 2 -> Double -> Double -> SArray 24 (ShaderFloatTuple 2) ->
             SArray 24 Double -> ShaderFloatTuple 4 -> ShaderFloatTuple 4
first_step point world_per_pixel count centers radii previous_state =
  let disc_center = array_at centers 0.0
      disc_radius = array_at radii 0.0
      next_state = step_values point world_per_pixel previous_state
                               disc_center disc_radius 1000000000.0
   in if 0.0 < count then next_state else previous_state

next_step : ShaderFloatTuple 2 -> Double -> Double -> SArray 24 (ShaderFloatTuple 2) ->
            SArray 24 Double -> ShaderFloatTuple 4 -> Double -> Double -> ShaderFloatTuple 4
next_step point world_per_pixel count centers radii previous_state previous_index index =
  let disc_center = array_at centers index
      previous_center = array_at centers previous_index
      disc_radius = array_at radii index
      path_distance = distance_to_segment point previous_center disc_center
      next_state = step_values point world_per_pixel previous_state
                               disc_center disc_radius path_distance
   in if index < count then next_state else previous_state

continuation_state_24 : ShaderFloatTuple 2 -> Double -> Double -> SArray 24 (ShaderFloatTuple 2) ->
                        SArray 24 Double -> ShaderFloatTuple 4
continuation_state_24 point world_per_pixel count centers radii =
  let state_0 = first_step point world_per_pixel count centers radii (vec4 0.0 0.0 0.0 0.0)
      state_1 = next_step point world_per_pixel count centers radii state_0 0.0 1.0
      state_2 = next_step point world_per_pixel count centers radii state_1 1.0 2.0
      state_3 = next_step point world_per_pixel count centers radii state_2 2.0 3.0
      state_4 = next_step point world_per_pixel count centers radii state_3 3.0 4.0
      state_5 = next_step point world_per_pixel count centers radii state_4 4.0 5.0
      state_6 = next_step point world_per_pixel count centers radii state_5 5.0 6.0
      state_7 = next_step point world_per_pixel count centers radii state_6 6.0 7.0
      state_8 = next_step point world_per_pixel count centers radii state_7 7.0 8.0
      state_9 = next_step point world_per_pixel count centers radii state_8 8.0 9.0
      state_10 = next_step point world_per_pixel count centers radii state_9 9.0 10.0
      state_11 = next_step point world_per_pixel count centers radii state_10 10.0 11.0
      state_12 = next_step point world_per_pixel count centers radii state_11 11.0 12.0
      state_13 = next_step point world_per_pixel count centers radii state_12 12.0 13.0
      state_14 = next_step point world_per_pixel count centers radii state_13 13.0 14.0
      state_15 = next_step point world_per_pixel count centers radii state_14 14.0 15.0
      state_16 = next_step point world_per_pixel count centers radii state_15 15.0 16.0
      state_17 = next_step point world_per_pixel count centers radii state_16 16.0 17.0
      state_18 = next_step point world_per_pixel count centers radii state_17 17.0 18.0
      state_19 = next_step point world_per_pixel count centers radii state_18 18.0 19.0
      state_20 = next_step point world_per_pixel count centers radii state_19 19.0 20.0
      state_21 = next_step point world_per_pixel count centers radii state_20 20.0 21.0
      state_22 = next_step point world_per_pixel count centers radii state_21 21.0 22.0
      state_23 = next_step point world_per_pixel count centers radii state_22 22.0 23.0
   in state_23

public export
continuation_overlay : ShaderFloatTuple 2 -> ShaderFloatTuple 2 -> ShaderFloatTuple 2 -> Double -> Double ->
                       SArray 24 (ShaderFloatTuple 2) -> SArray 24 Double -> ShaderFloatTuple 3 -> ShaderFloatTuple 3
continuation_overlay ndc resolution point world_per_pixel count centers radii base_color =
  let state = continuation_state_24 point world_per_pixel count centers radii
      revealed = x state
      boundary = y state
      path_line = z state
      center_mark = w state
      pixel_x = (x ndc + 1.0) * 0.5 * x resolution
      pixel_y = (y ndc + 1.0) * 0.5 * y resolution
      diagonal_a = 0.5 + 0.5 * cosF ((pixel_x + pixel_y) * 6.28318530717958647692 / 28.0)
      diagonal_b = 0.5 + 0.5 * cosF ((pixel_x - pixel_y) * 6.28318530717958647692 / 28.0)
      weave = 0.5 * (smoothstepF 0.92 1.0 diagonal_a +
                     smoothstepF 0.92 1.0 diagonal_b)
      unrevealed = add_components (vec3 0.080 0.086 0.096)
                        (scale_components weave (vec3 0.018 0.020 0.024))
      marker_dark = vec3 0.09411765 0.09411765 0.09411765
      marker_light = vec3 0.98 0.95 0.76
      revealed_color = mix_vec3 unrevealed base_color revealed
      boundary_color = mix_vec3 revealed_color marker_light (boundary * 0.86)
      path_color = mix_vec3 boundary_color marker_dark path_line
   in mix_vec3 path_color (vec3 0.96078431 0.94901961 0.92156863) center_mark
