package game

import rl "vendor:raylib"
import "core:fmt"
import "core:math"

vec2 :: [2]f32

gjkAppMode :: enum {
    HIT_TEST,
    INSERT_POINT_A,
    EDIT_POINT_A,
    INSERT_POINT_B,
    EDIT_POINT_B,
}

gjkAppData :: struct {
    polygon_points_a : [dynamic]vec2,
    polygon_points_b : [dynamic]vec2,
    app_mode : gjkAppMode,
    step_index : int,
}

UpdateGJKApp :: proc(app_data : ^gjkAppData){
    #partial switch app_data.app_mode {
        case .INSERT_POINT_A :
            InsertPolyMode(app_data, &app_data.polygon_points_a)
        case .INSERT_POINT_B :
            InsertPolyMode(app_data, &app_data.polygon_points_b)
        case .EDIT_POINT_A :
            EditPolyMode(app_data, &app_data.polygon_points_a)
        case .EDIT_POINT_B :
            EditPolyMode(app_data, &app_data.polygon_points_b)
        case .HIT_TEST :
            HitTestMode(app_data)
    }
}

InsertPolyMode :: proc(app_data : ^gjkAppData, poly_points : ^[dynamic]vec2){
    if rl.IsKeyPressed(.C) {
        clear(poly_points)
    }

    mat : rl.Matrix
    mat = rl.MatrixTranslate(GAME_WIDTH/2, GAME_HEIGHT/2, 0) * rl.MatrixScale(100, -100, 1)
    mat = rl.MatrixInvert(mat)
    mouse_position := rl.GetMousePosition()
    mouse_position = (mat * rl.Vector4{mouse_position.x, mouse_position.y, 0, 1}).xy
    if rl.IsMouseButtonPressed(.LEFT) {
        poly_points_count := len(poly_points)
        if poly_points_count == cap(poly_points) - 1 {
            poly_points[poly_points_count] = mouse_position
        } else {
            append(poly_points, mouse_position)
        }
    }

    if rl.IsKeyPressed(.ENTER) {
        append(poly_points, poly_points[0])
        app_data.app_mode = .HIT_TEST
    }
}

EditPolyMode :: proc(app_data : ^gjkAppData, poly_points : ^[dynamic]vec2){

    mat : rl.Matrix
    mat = rl.MatrixTranslate(GAME_WIDTH/2, GAME_HEIGHT/2, 0) * rl.MatrixScale(100, -100, 1)
    mat = rl.MatrixInvert(mat)
    mouse_position := rl.GetMousePosition()
    mouse_position = (mat * rl.Vector4{mouse_position.x, mouse_position.y, 0, 1}).xy

    poly_points_count := len(poly_points) - 1 

    if rl.IsKeyPressed(.A) {
        app_data.step_index = (app_data.step_index - 1 + poly_points_count) % poly_points_count
    }

    if rl.IsKeyPressed(.D) {
        app_data.step_index = (app_data.step_index + 1) % poly_points_count
    }

    if rl.IsMouseButtonPressed(.LEFT) {
        poly_points[app_data.step_index] = mouse_position
    }

    poly_points[poly_points_count] = poly_points[0]

    if rl.IsKeyPressed(.ESCAPE) || rl.IsKeyPressed(.ENTER) {
        app_data.app_mode = .HIT_TEST
        app_data.step_index = 0
    }
}

HitTestMode :: proc(app_data : ^gjkAppData){
    if rl.IsKeyPressed(.I) {
        app_data.app_mode = !rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT) ? .INSERT_POINT_A : .INSERT_POINT_B
    }
    if rl.IsKeyPressed(.E) {
        app_data.app_mode = !rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT) ? .EDIT_POINT_A : .EDIT_POINT_B
        app_data.step_index = 0
    }

    if rl.IsKeyPressed(.A) {
        app_data.step_index -= 1
    }

    if rl.IsKeyPressed(.D) {
        app_data.step_index += 1
    }

    app_data.step_index = math.max(0, app_data.step_index)

}

DrawGJKApp :: proc(app_data : ^gjkAppData){
    rl.BeginDrawing()

    rl.ClearBackground(rl.BLACK)

    rl.rlPushMatrix()

    rl.rlTranslatef(GAME_WIDTH/2, GAME_HEIGHT/2, 0)
    rl.rlScalef(100, -100, 1)

    rl.DrawLineV(vec2{-GAME_WIDTH/100, 0}, vec2{GAME_WIDTH/100, 0}, rl.WHITE)
    rl.DrawLineV(vec2{0, GAME_HEIGHT/100}, vec2{0, -GAME_HEIGHT/100}, rl.WHITE)

    rl.DrawLineStrip(raw_data(app_data.polygon_points_a[:]), i32(len(app_data.polygon_points_a)), rl.GREEN)
    rl.DrawLineStrip(raw_data(app_data.polygon_points_b[:]), i32(len(app_data.polygon_points_b)), rl.BLUE)

    GjkHitTest(app_data, app_data.polygon_points_a[:], app_data.polygon_points_b[:])

    rl.rlPopMatrix()

    mode_text : cstring = "None"
    switch app_data.app_mode {
        case .HIT_TEST:
            mode_text = "HIT TEST MODE"
        case .INSERT_POINT_A:
            mode_text = "INSERT POINT POLYGON A"
        case .INSERT_POINT_B:
            mode_text = "INSERT POINT POLYGON B"
        case .EDIT_POINT_A:
            mode_text = "EDIT POINT POLYGON A"
        case .EDIT_POINT_B:
            mode_text = "EDIT POINT POLYGON B"
    }

    rl.DrawText(mode_text, 0, 0, 18, rl.WHITE)
    rl.DrawText(rl.TextFormat("STEP INDEX : %d", app_data.step_index), 0, 20, 18, rl.WHITE)

    rl.EndDrawing()
}

GjkSupport :: proc(polygon_points : []vec2, direction : vec2, t_mat : rl.Matrix) -> vec2 {
    cur_max : f32 = -10000000000
    max_index : int = 0
    max_point : vec2 = {0, 0}
    for point, i in polygon_points {
        t_point := (t_mat * rl.Vector4{point.x, point.y, 0, 1}).xy
        dot_product := rl.Vector2DotProduct(direction, t_point)
        if dot_product > cur_max {
            cur_max = dot_product
            max_index = i
            max_point = t_point
        }
    }
    return max_point
}

GjkSupportPolygons_NoMat :: proc(poly_points_a : []vec2, poly_points_b : []vec2, direction : vec2) -> vec2 {
    return GjkSupport(poly_points_a, direction, rl.Matrix(1)) - GjkSupport(poly_points_b, -direction, rl.Matrix(1))
}

GjkSupportPolygons_WithMat :: proc(poly_points_a : []vec2, poly_points_b : []vec2, mat_b_to_a : rl.Matrix, direction : vec2) -> vec2 {
    return GjkSupport(poly_points_a, direction, rl.Matrix(1)) - GjkSupport(poly_points_b, -direction, mat_b_to_a)
}

GjkSupportPolygons :: proc {
    GjkSupportPolygons_NoMat,
    GjkSupportPolygons_WithMat,
}

GjkCheckPolygon :: proc(polygon_a : []vec2, polygon_b : []vec2, mat_b_to_a : rl.Matrix) -> bool {
    vec_dir := vec2{1, 0}
    points_arr : [dynamic]vec2 = make([dynamic]vec2, 0, 3, context.temp_allocator)
    defer delete(points_arr)

    vec_point := GjkSupportPolygons(polygon_a, polygon_b, mat_b_to_a, vec_dir)
    append(&points_arr, vec_point)

    //10 iteration to test
    for i in 0..<100 {
        
        point_count := len(points_arr)

        if(point_count == 1){
            vec_dir = -points_arr[0]
            vec_point = GjkSupportPolygons(polygon_a, polygon_b, mat_b_to_a, vec_dir)

            if rl.Vector2DotProduct(vec_dir, vec_point) < 0 {
                return false
            }

            append(&points_arr, vec_point)
        }else if(point_count == 2){
            vec_dir = LineDirectionToPoint(points_arr[0], points_arr[1] - points_arr[0], vec2{0, 0})
            vec_point = GjkSupportPolygons(polygon_a, polygon_b, mat_b_to_a, vec_dir)

            if rl.Vector2DotProduct(vec_dir, vec_point) < 0 {
                return false
            }

            append(&points_arr, vec_point)
            simplex_contain_origin := CheckSimplex(points_arr[:])

            if simplex_contain_origin {
                return true
            }
        
            ordered_remove(&points_arr, 0)
        }

        if i == 99 {
            fmt.println("MAX ITER")
        }
    }


    return false
}

GjkHitTest :: proc(app_data : ^gjkAppData, polygon_points_a : []vec2, polygon_points_b : []vec2) -> bool {
    cur_dir := vec2{1,0}
    points_arr : [dynamic]vec2 = make([dynamic]vec2, 0, 3, context.temp_allocator)
    vec_point := GjkSupportPolygons(polygon_points_a, polygon_points_b, cur_dir)
    append(&points_arr, vec_point)

    vec_dir : vec2
    contain_origin : bool
    for cur_step := 0; cur_step < app_data.step_index; cur_step += 1 {
        point_count := len(points_arr)
        //Line check
        if point_count == 1 {

            last_point := points_arr[0]

            vec_dir = rl.Vector2Normalize(vec2{0, 0} - last_point)
            next_vec_point := GjkSupportPolygons(polygon_points_a, polygon_points_b, vec_dir)

            append(&points_arr, next_vec_point)

        }//Triangle check
        else if point_count == 2 {

            last_point := points_arr[0]
            newest_point := points_arr[1]

            vec_dir = newest_point-last_point
            normal_line_vec : f32 = rl.Vector2DotProduct(-last_point, vec_dir) 
            line_origin_dir := rl.Vector2Normalize(last_point + vec_dir * normal_line_vec / rl.Vector2LengthSqr(vec_dir))
            vec_dir = rl.Vector2Normalize(vec2{0,0} - line_origin_dir)

            third_point : vec2 = GjkSupportPolygons(polygon_points_a, polygon_points_b, vec_dir)
            
            append(&points_arr, third_point)
        } else if point_count == 3 {
            ordered_remove(&points_arr, 0)
        }

    }

    if len(points_arr) == 3 {
        contain_origin = CheckSimplex(points_arr[:])
    }

    for point, i in points_arr {
        next_i := (i + 1) % len(points_arr)
        rl.DrawLineV(point, points_arr[next_i], contain_origin ? rl.RED : rl.PURPLE)
    }

    return false
}

LineDirectionToPoint :: proc(line_point : vec2, line_vector : vec2, point : vec2) -> vec2 {
    point_inline := line_point + line_vector * rl.Vector2DotProduct(point - line_point, line_vector) / rl.Vector2LengthSqr(line_vector)
    
    return rl.Vector2Normalize(point - point_inline)
}

CheckSimplex ::proc(points : []vec2) -> bool {
    for point_a, i in points {
        point_b := points[(i+1)%len(points)]
        point_c := points[(i+2)%len(points)]

        line_dir_to_c := LineDirectionToPoint(point_a, point_a - point_b, point_c)
        line_dir_to_origin := LineDirectionToPoint(point_a, point_a - point_b, vec2{0, 0})

        if(rl.Vector2DotProduct(line_dir_to_c, line_dir_to_origin) < 0){
            return false
        }
    }

    return true
}