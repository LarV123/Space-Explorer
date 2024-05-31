package game

import rl "vendor:raylib"
import "core:math"

tri_top_dist :: -15
tri_hor_dist :: 10
tri_bot_dist :: 5
player_polygon : [3]rl.Vector2 = {{-tri_hor_dist, tri_bot_dist}, {tri_hor_dist, tri_bot_dist}, {0, tri_top_dist}}
expiredTime :: 0.06;

gameState :: enum {
    Start,
    Game,
    GameOver
}

fuelData :: struct{
    using position : rl.Vector2,
    is_spawn : bool,
    time_to_spawn : f32,
    current_time : f32,
}

FUEL_WIDTH :: 15
FUEL_HEIGHT :: 25

playerData :: struct{
    using position : rl.Vector2,
    direction : rl.Vector2,
    rotation : f32,
    speed : i32,
}

trailData :: struct{
    time_to_expired : f32,
    trail_points : [6]rl.Vector2,
    idx : i32,
    len : i32,
}

gameData :: struct{
    game_state : gameState,
    start_time : f64,
    end_time : f64,
    player : playerData,
    player_trail : trailData,
    camera : rl.Camera2D,
    fuel : fuelData,
    asteroids : [dynamic] asteroidData,
    max_asteroids : i32,
    is_paused : bool,
}

UpdateGame :: proc(game_data : ^gameData){

    using game_data

    switch game_state {
        case .Start:
            UpdateStartState(game_data)
        case .Game:
            UpdateGameState(game_data)
        case .GameOver:
            UpdateGameOverState(game_data)
    }

    if len(asteroids) < int(max_asteroids) {
        SpawnNewAsteroid(&asteroids)
    }
    if !is_paused {
        UpdateAsteroids(&asteroids)
    }
    DestoryAsteroidInEdge(game_data)
}

UpdateStartState :: proc(game_data : ^gameData){
    using game_data
    using player

    if rl.IsKeyPressed(.SPACE) {
        game_state = .Game
        start_time = rl.GetTime()
        end_time = start_time + 10
        end_time = start_time + 10
        player.position = {320, 400}
        rotation = 0
        player_trail = {}
    }
}

UpdateGameState :: proc(game_data : ^gameData){
    using game_data
    using player

    player.direction = {math.sin_f32(rotation), -math.cos_f32(rotation)}

    if !is_paused {
        player.position += player.direction * f32(speed) * rl.GetFrameTime()
    }

    speed = i32(100 + (math.floor((rl.GetTime()-start_time)/5) * 20))
    // speed = 100

    if(rl.IsKeyDown(.LEFT)){
        rotation -= rl.PI * rl.GetFrameTime()
    }

    if(rl.IsKeyDown(.RIGHT)){
        rotation += rl.PI * rl.GetFrameTime()
    }

    // if rl.IsKeyPressed(.SPACE) {
    //     is_paused = !is_paused
    // }

    if(!fuel.is_spawn){
        fuel.position = {f32(rl.GetRandomValue(FUEL_WIDTH, 640-20)), f32(rl.GetRandomValue(FUEL_HEIGHT, 480-40))}
        fuel.is_spawn = true
    }

    CheckCollision(game_data)

    is_out_screen := (player.x < 0 || player.x > GAME_WIDTH) || (player.y < 0 || player.y > GAME_HEIGHT);

    if is_out_screen || rl.GetTime() > end_time {
        game_state = .GameOver
    }
}

UpdateGameOverState :: proc(game_data : ^gameData){
    using game_data

    if rl.IsKeyPressed(.SPACE) {
        game_state = .Start
    }
}

DestoryAsteroidInEdge :: proc(game_data : ^gameData){
    using game_data
    for asteroid, i in asteroids {
        // asteroid should be out of bound if
        // 1. the center is out of the screen
        // 2. the asteroid is moving out of the screen
        //    this can be calculated using dot product
        //    if the result is negative, then it should be moving out of the center
        is_out_screen := (asteroid.x < 0 || asteroid.x > GAME_WIDTH) || (asteroid.y < 0 || asteroid.y > GAME_HEIGHT);
        if !is_out_screen {
            continue
        }

        dir_to_center := rl.Vector2Normalize(rl.Vector2{GAME_WIDTH/2, GAME_HEIGHT/2} - asteroid.position)
        asteroid_dir := rl.Vector2Normalize(asteroid.velocity)

        if dot_prod := rl.Vector2DotProduct(dir_to_center, asteroid_dir) >= 0; dot_prod {
            continue
        }

        //destory
        unordered_remove(&asteroids, i)
    }
}

CheckCollision :: proc(game_data : ^gameData){
    using game_data

    if fuel.is_spawn {
        //Check fuel collision with player

        fuel_bound : rl.Rectangle = {fuel.x - FUEL_WIDTH/2, fuel.y - FUEL_HEIGHT/2, FUEL_WIDTH, FUEL_HEIGHT}

        bound_extent_fuel : rl.Vector3 = {FUEL_WIDTH/2, FUEL_HEIGHT/2, 0}
        bound_center_fuel : rl.Vector3 = {fuel.x, fuel.y, 5}

        if rl.CheckCollisionBoxSphere({bound_center_fuel - bound_extent_fuel, bound_center_fuel + bound_extent_fuel}, {player.x, player.y, 0}, 20){
            fuel.is_spawn = false
            end_time += 10
        }
    }

    //asteroids vs player
    for asteroid, i in asteroids { 
        //check bounding box
        if(rl.Vector2DistanceSqrt(player.position, asteroid.position) < 100*100){
            mat_asteroid_to_player := GetMatrixAsteroidToPlayer(player, asteroid)
            if GjkCheckPolygon(player_polygon[:], ASTEROID_POINTS[asteroid.type][0:len(ASTEROID_POINTS[asteroid.type])], mat_asteroid_to_player) {
                game_state = .GameOver
                // is_paused = true
                break
            }
        }
    }
}

GetMatrixAsteroidToPlayer :: proc(player : playerData, asteroid : asteroidData) -> rl.Matrix {

    mat_asteroid_to_player := rl.Matrix(1)
    mat_asteroid_to_player = rl.MatrixRotateZ(asteroid.rotation) * mat_asteroid_to_player
    mat_asteroid_to_player = rl.MatrixTranslate(asteroid.x, asteroid.y, 0) * mat_asteroid_to_player
    mat_asteroid_to_player = rl.MatrixTranslate(-player.x, -player.y, 0) * mat_asteroid_to_player
    mat_asteroid_to_player = rl.MatrixRotateZ(-player.rotation) * mat_asteroid_to_player

    return mat_asteroid_to_player
}

DrawGame :: proc(game_data : ^gameData){
    using game_data
    rl.BeginDrawing()

    rl.ClearBackground(rl.BLACK)

    switch game_state {
        case .Start:
            DrawStartState(game_data)
        case .Game:
            DrawGameState(game_data)
        case .GameOver:
            DrawGameOverState(game_data)
    }

    rl.EndDrawing()
}

DrawStartState :: proc(game_data : ^gameData){
    using game_data

    rl.BeginMode2D(camera)

    rl.DrawText("SPACE EXPLORE", GAME_WIDTH/2 - 80, 50, 20, rl.WHITE)
    
    DrawAsteroids(game_data)

    cur_time := rl.GetTime()

    if i32(cur_time) % 2 == 0 {
        rl.DrawText("PRESS \"SPACE\" TO START", GAME_WIDTH/2 - 60, GAME_HEIGHT-100, 10, rl.WHITE)
    }

    rl.EndMode2D()
}

DrawGameState :: proc(game_data : ^gameData){
    using game_data

    DrawHUD(game_data)

    rl.BeginMode2D(camera)

    DrawPlayer(game_data)
    DrawFuel(fuel)
    DrawAsteroids(game_data)

    // rl.rlPushMatrix()
    // rl.rlTranslatef(GAME_WIDTH/2, GAME_HEIGHT/2, 0)
    // //DEBUG

    // for point, i in player_polygon {
    //     next_i := (i + 1) % len(player_polygon)
    //     next_point := player_polygon[next_i]

    //     rl.DrawLineV(point, next_point, rl.GREEN)
    // }

    // for asteroid in asteroids { 
    //     //check bounding box
    //     if(rl.Vector2DistanceSqrt(player.position, asteroid.position) < 100*100){
    //         mat_asteroid_to_player := GetMatrixAsteroidToPlayer(player, asteroid)
    //         asteroid_polygon : []vec2 = ASTEROID_POINTS[asteroid.type]
    //         for point, i in asteroid_polygon {
    //             trans_point := (mat_asteroid_to_player * rl.Vector4{point.x, point.y, 0, 1}).xy
    //             next_i := (i + 1) % len(asteroid_polygon)
    //             next_point := asteroid_polygon[next_i]
    //             trans_next_point := (mat_asteroid_to_player * rl.Vector4{next_point.x, next_point.y, 0, 1}).xy

    //             rl.DrawLineV(trans_point, trans_next_point, rl.PURPLE)
    //         }
    //     }
    // }
    // rl.rlPopMatrix()
    
    rl.EndMode2D()
}

DrawGameOverState :: proc(game_data : ^gameData){
    using game_data

    rl.BeginMode2D(camera)

    rl.DrawText("GAME OVER", GAME_WIDTH/2 - 60, 50, 20, rl.WHITE)
    
    DrawAsteroids(game_data)

    rl.DrawText("PRESS \"SPACE\" TO RESTART", GAME_WIDTH/2 - 60, GAME_HEIGHT-100, 10, rl.WHITE)

    rl.EndMode2D()
}

DrawPlayer :: proc(game_data : ^gameData){
    using game_data

    {
        rl.rlPushMatrix()

        defer rl.rlPopMatrix()

        rl.rlTranslatef(player.x, player.position.y, 0)

        rl.DrawLineV({0, 0}, player.direction*10, rl.WHITE)

        rl.rlRotatef(player.rotation * rl.RAD2DEG, 0, 0, 1)

        //drawing
        rl.DrawTriangleLines({0, tri_top_dist}, {-tri_hor_dist, tri_bot_dist}, {tri_hor_dist, tri_bot_dist}, rl.WHITE)
    }

    {
        using player_trail
        if(time_to_expired > 0){
            time_to_expired -= rl.GetFrameTime()
        }else{

            trail_points[(idx+len) % 6] = player.position;
            if(len < 6){
                len += 1
            }else{
                idx = (idx + 1) % 6
            }

            time_to_expired = expiredTime;
        }

        offset_A := rl.Vector2Rotate({-tri_hor_dist, tri_bot_dist}, player.rotation)
        offset_B := rl.Vector2Rotate({tri_hor_dist, tri_bot_dist}, player.rotation)

        for i in 0..<len-1 {
            vertex_i := (idx + i) % 6
            vertex_i_next := (vertex_i + 1) % 6

            color : rl.Color = rl.WHITE;
            color.a = u8((f32(i) + 1) / 7 * 255)
            
            rl.DrawLineV(trail_points[vertex_i] + offset_A, trail_points[vertex_i_next] + offset_A, color)
        
            rl.DrawLineV(trail_points[vertex_i] + offset_B, trail_points[vertex_i_next] + offset_B, color)
        }

        if(len > 0){
            rl.DrawLineV(trail_points[(idx + len - 1) % 6] + offset_A, player.position + offset_A, rl.WHITE)
            rl.DrawLineV(trail_points[(idx + len - 1) % 6] + offset_B, player.position + offset_B, rl.WHITE)
        }
    }
}

DrawHUD :: proc(game_data : ^gameData){
    using game_data
    rl.DrawText(rl.TextFormat("Speed : %d", player.speed), 0, 0, 15, rl.WHITE)
    rl.DrawText(rl.TextFormat("Time : %d", i32(end_time - rl.GetTime())), 0, 20, 15, rl.WHITE)
}

DrawFuel :: proc(fuel : fuelData){
    if !fuel.is_spawn {
        return
    }

    rl.rlPushMatrix()
    defer rl.rlPopMatrix()

    rl.rlTranslatef(fuel.x, fuel.y, 0)

    rec : rl.Rectangle = {-FUEL_WIDTH/2, -FUEL_HEIGHT/2, FUEL_WIDTH, FUEL_HEIGHT}

    rl.DrawRectangleLinesEx(rec, 1, rl.WHITE)
    rl.DrawLineV(vec2{-FUEL_WIDTH/2, -FUEL_HEIGHT/2}, vec2{FUEL_WIDTH/2, FUEL_HEIGHT/2}, rl.WHITE)
    rl.DrawLineV(vec2{FUEL_WIDTH/2, -FUEL_HEIGHT/2}, vec2{-FUEL_WIDTH/2, FUEL_HEIGHT/2}, rl.WHITE)
}

DrawAsteroids :: proc(game_data : ^gameData){
    for asteroid in game_data.asteroids {
        DrawAsteroid(asteroid)
    }
}

DrawAsteroid :: proc(asteroid : asteroidData){
    rl.rlPushMatrix()
    defer rl.rlPopMatrix()

    rl.rlTranslatef(asteroid.x, asteroid.y, 0)
    rl.rlRotatef(asteroid.rotation, 0, 0, 1)

    idx : int = asteroid.type
    points_ptr : [^]rl.Vector2 = raw_data(ASTEROID_POINTS[idx][:])
    points_len : int = len(ASTEROID_POINTS[idx])
    
    rl.DrawLineStrip(points_ptr, i32(points_len), rl.WHITE)
}