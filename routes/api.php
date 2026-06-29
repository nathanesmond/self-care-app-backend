<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ExerciseController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\OnboardingController;
use App\Http\Controllers\Api\MoodController;
use App\Http\Controllers\Api\CalorieController;
use App\Http\Controllers\Api\HistoryController;
use App\Http\Controllers\Api\AdminUserController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [App\Http\Controllers\Api\AuthController::class, 'login']);
// Password Reset Routes (Public)
Route::post('/forgot-password/send-otp', [AuthController::class, 'sendOtp']);
Route::post('/forgot-password/reset', [AuthController::class, 'resetPassword']);

Route::post('/verify-email', [AuthController::class, 'verifyEmail']);
Route::post('/resend-verification', [AuthController::class, 'resendVerificationOtp']);


Route::middleware('auth:sanctum')->group(function () {

    //PROFILE
    Route::post('/onboarding', [OnboardingController::class, 'store']);
    Route::get('/profile', [OnboardingController::class, 'getProfile']);
    Route::put('/profile', [OnboardingController::class, 'updateProfile']);
    Route::get('/user-profile', function (Request $request) {
        return response()->json([
            'success' => true,
            'data' => $request->user()->load('role')
        ]);
    });

    Route::post('/change-email', [AuthController::class, 'changeEmail']);
    Route::post('/logout', [AuthController::class, 'logout']);

    //MOOD TRACKER
    Route::post('/mood-log', [MoodController::class, 'store']);


    //CALORIE TRACKER
    Route::post('/calorie-log', [CalorieController::class, 'store']);
    Route::get('/calorie-daily', [CalorieController::class, 'getDailyLogs']);
    Route::delete('/calorie-log/{id}', [CalorieController::class, 'destroy']);


    //WORKOUT

    Route::get('/workout/recommendation', [ExerciseController::class, 'getDynamicWeeklyPlan']);
    Route::post('/workout/generate', [ExerciseController::class, 'generateTodayWorkout']);
    Route::post('/workout/exercise/toggle/{id}', [ExerciseController::class, 'toggleExerciseCheck']);
    Route::post('/workout/session/complete/{id}', [ExerciseController::class, 'completeWorkoutSession']);
    Route::post('/workout/session/skip/{id}', [ExerciseController::class, 'skipWorkoutSession']);

    //HISTORY
    Route::get('/history/dashboard', [HistoryController::class, 'getDashboardHistory']);


    //ADMIN
    Route::get('/admin/users', [AdminUserController::class, 'getAllUsers']);

    // Update a specific user
    Route::put('/admin/users/{id}', [AdminUserController::class, 'updateUser']);
});



Route::post('/debug/filter', function (Request $request) {
    $payload = [
        'body_part' => $request->input('body_part'),
        'level' => $request->input('level'),
        'equipment' => $request->input('equipment'),
        'top_n' => $request->input('top_n', 10),
    ];

    $flaskUrl = 'http://localhost:5001/filter';
    $response = \Illuminate\Support\Facades\Http::post($flaskUrl, $payload);

    return response()->json([
        'laravel_received' => $request->all(),
        'sent_to_flask' => $payload,
        'flask_status_code' => $response->status(),
        'flask_response' => $response->json(),
    ]);
});