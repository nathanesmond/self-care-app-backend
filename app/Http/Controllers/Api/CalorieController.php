<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CalorieLog;
use App\Models\UserProfile;
use Illuminate\Support\Facades\Validator;

class CalorieController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nama_makanan' => 'required|string|max:255',
            'jumlah_kalori' => 'required|integer|min:1',
            'meal_type' => 'required|string|in:Breakfast,Lunch,Dinner,Snack',
            'logged_time' => 'required|string',
            'log_date' => 'required|date_format:Y-m-d'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $userId = $request->user()->id_user;

        try {
            $log = CalorieLog::create([
                'id_user' => $userId,
                'nama_makanan' => $request->nama_makanan,
                'jumlah_kalori' => $request->jumlah_kalori,
                'meal_type' => $request->meal_type,
                'logged_time' => $request->logged_time,
                'log_date' => $request->log_date
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Food log saved successfully!',
                'data' => $log
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to save food log.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    private function calculateTargetKalori($profile)
    {
        if (strtolower($profile->gender) === 'male') {
            $bmr = (10 * $profile->berat_badan) + (6.25 * $profile->tinggi_badan) - (5 * $profile->usia) + 5;
        } else {
            $bmr = (10 * $profile->berat_badan) + (6.25 * $profile->tinggi_badan) - (5 * $profile->usia) - 161;
        }

        $level = strtolower($profile->fitness_level);
        switch ($level) {
            case 'beginner':
                $tdee = $bmr * 1.2;
                break;
            case 'intermediate':
                $tdee = $bmr * 1.55;
                break;
            case 'advanced':
                $tdee = $bmr * 1.725;
                break;
            default:
                $tdee = $bmr * 1.2;
        }

        $goal = strtolower($profile->target_kesehatan);
        if (str_contains($goal, 'lose weight')) {
            $targetKalori = $tdee - 500;
        } elseif (str_contains($goal, 'build muscle')) {
            $targetKalori = $tdee + 400;
        } else {
            $targetKalori = $tdee;
        }

        return (int) round($targetKalori);
    }


    public function getDailyLogs(Request $request)
    {
        $validator = Validator::make($request->query(), [
            'date' => 'required|date_format:Y-m-d'
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $userId = $request->user()->id_user;
        $targetDate = $request->query('date');

        $profile = UserProfile::where('id_user', $userId)->first();
        $targetCalorie = 2100; // Fallback default

        if ($profile) {
            $targetCalorie = $this->calculateTargetKalori($profile);

            if ($profile->target_calorie !== $targetCalorie) {
                $profile->update(['target_calorie' => $targetCalorie]);
            }
        }

        $logs = CalorieLog::where('id_user', $userId)
            ->where('log_date', $targetDate)
            ->get();

        $totalConsumed = $logs->sum('jumlah_kalori');

        return response()->json([
            'success' => true,
            'target_date' => $targetDate,
            'target_calorie' => $targetCalorie,
            'total_consumed' => $totalConsumed,
            'logs' => $logs
        ], 200);
    }

    public function destroy(Request $request, $id)
    {
        $userId = $request->user()->id_user;

        $log = CalorieLog::where('id_calorie_log', $id)
            ->where('id_user', $userId)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Food log not found or you do not have access.'
            ], 404);
        }

        try {
            $log->delete();

            return response()->json([
                'success' => true,
                'message' => 'Food log deleted successfully!'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete food log.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}