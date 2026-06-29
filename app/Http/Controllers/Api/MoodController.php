<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\EmaMoodLog;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class MoodController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'skor_mood' => 'required|integer|between:1,5',
            'mood' => 'required|string|max:50',
            'influences' => 'nullable|array',
            'notes' => 'nullable|string',
            'log_date' => 'required|date_format:Y-m-d'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $userId = $request->user()->id_user;
        $today = $request->log_date;

        $alreadyLogged = EmaMoodLog::where('id_user', $userId)
            ->where('log_date', $today)
            ->exists();

        if ($alreadyLogged) {
            return response()->json([
                'success' => false,
                'message' => 'You Already Logged Your Mood for Today.'
            ], 400);
        }

        // 3. Simpan Jurnal Mood Baru
        try {
            $moodLog = EmaMoodLog::create([
                'id_user' => $userId,
                'skor_mood' => $request->skor_mood,
                'mood' => $request->mood,
                'influences' => $request->influences,
                'notes' => $request->notes,
                'log_date' => $today
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Mood log successfully saved for today!',
                'data' => $moodLog
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to save mood log.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}