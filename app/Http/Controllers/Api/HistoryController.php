<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\EmaMoodLog;
use App\Models\CalorieLog;
use App\Models\WorkoutSession;
use App\Models\UserProfile;
use Carbon\Carbon;

class HistoryController extends Controller
{
    public function getDashboardHistory(Request $request)
    {
        $userId = $request->user()->id_user;
        $oneWeekAgo = Carbon::now()->subDays(7)->toDateString();
        $today = Carbon::today()->toDateString();

        // ── 1. AMBIL DATA RAW DETAIL 7 HARI TERAKHIR ──
        $moodLogs = EmaMoodLog::where('id_user', $userId)
            ->where('log_date', '>=', $oneWeekAgo)
            ->orderBy('log_date', 'desc')
            ->get();

        $calorieLogs = CalorieLog::where('id_user', $userId)
            ->where('log_date', '>=', $oneWeekAgo)
            ->orderBy('log_date', 'desc')
            ->get();

        $workoutLogs = WorkoutSession::with('exercises')
            ->where('id_user', $userId)
            ->where('log_date', '>=', $oneWeekAgo)
            ->whereIn('status', ['completed', 'skipped'])
            ->orderBy('log_date', 'desc')
            ->get();

        $avgMood = $moodLogs->avg('skor_mood') ?? 0;

        $totalCaloriesConsumed = $calorieLogs->sum('jumlah_kalori');
        $profile = UserProfile::where('id_user', $userId)->first();
        $targetCaloriePerDay = $profile ? 2000 : 2000;

        $completedWorkouts = $workoutLogs->where('status', 'completed')->count();
        $skippedWorkouts = $workoutLogs->where('status', 'skipped')->count();

        $trendConclusion = "Stable";
        if ($avgMood >= 4)
            $trendConclusion = "Very Positive";
        elseif ($avgMood <= 2)
            $trendConclusion = "Needs Rest";

        return response()->json([
            'success' => true,
            'data' => [
                'overview' => [
                    'average_mood' => round($avgMood, 1),
                    'mood_trend' => $trendConclusion,
                    'total_calories' => $totalCaloriesConsumed,
                    'daily_target_calorie' => $targetCaloriePerDay,
                    'workouts_completed' => $completedWorkouts,
                    'workouts_skipped' => $skippedWorkouts,
                    'range_period' => "$oneWeekAgo to $today"
                ],
                'details' => [
                    'mood_history' => $moodLogs,
                    'calorie_history' => $calorieLogs,
                    'workout_history' => $workoutLogs
                ]
            ]
        ], 200);
    }
}