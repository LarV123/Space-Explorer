package game

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

GAME_WIDTH :: 640
GAME_HEIGHT :: 480

appMode :: enum {
    Game,
    Gjk
}

main :: proc(){

    rl.InitWindow(GAME_WIDTH, GAME_HEIGHT, "Star-Explorer")

    app_mode : appMode = .Game

    game_data : gameData;
    game_data.max_asteroids = 6
    game_data.camera.zoom = 1

    game_data.asteroids = make([dynamic]asteroidData, 0, 6)
    defer delete(game_data.asteroids)

    gjk_data : gjkAppData
    gjk_data.polygon_points_a = make([dynamic]vec2, 0, 10)
    gjk_data.polygon_points_b = make([dynamic]vec2, 0, 10)
    append(&gjk_data.polygon_points_a, vec2{0, 1}, vec2{1, 1}, vec2{1, 0}, vec2{0, 0}, vec2{0, 1})
    append(&gjk_data.polygon_points_b, vec2{-0.5, 0}, vec2{0, 0}, vec2{0, -0.5}, vec2{-0.5, -0.5}, vec2{-0.5, 0})

    for i in 0..<game_data.max_asteroids {
        SpawnNewAsteroid(&game_data.asteroids)
    }

    rl.SetExitKey(.KEY_NULL)

    for !rl.WindowShouldClose() {

        using game_data

        if ShouldChangeMode(&app_mode) {
            rl.PollInputEvents()
            continue
        }

        switch app_mode {
            case .Game:
                UpdateGame(&game_data)
                DrawGame(&game_data)
            case .Gjk:
                UpdateGJKApp(&gjk_data)
                DrawGJKApp(&gjk_data)
        }

        free_all(context.temp_allocator)
    }
}

ShouldChangeMode :: proc(app_mode : ^appMode) -> bool {
    if rl.IsKeyPressed(.TAB) {
        switch app_mode^ {
            case .Game:
                app_mode^ = .Gjk
            case .Gjk:
                app_mode^ = .Game
        }
        return true
    }
    return false
}