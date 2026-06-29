<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\UserProfile;
use App\Models\EmaMoodLog;
use App\Models\WorkoutSession;
use App\Models\WorkoutSessionExercise;
use App\Models\UserEquipment;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class ExerciseController extends Controller
{
    private $mlServiceUrl = 'http://localhost:5001';

    private $splitChain = [
        0 => ['name' => 'Push Day', 'parts' => ['Chest', 'Shoulders', 'Triceps']],
        1 => ['name' => 'Pull Day', 'parts' => ['Lats', 'Middle Back', 'Biceps', 'Traps']],
        2 => ['name' => 'Legs Day', 'parts' => ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves']],
        3 => ['name' => 'Core & Cardio Day', 'parts' => ['Abdominals', 'Lower Back']],
    ];


    public function getDynamicWeeklyPlan(Request $request)
    {
        $userId = $request->user()->id_user;
        $today = Carbon::today()->toDateString();


        //////////////////////////////////////////////////////////
        $todaySession = WorkoutSession::with('exercises')
            ->where('id_user', $userId)
            ->where('log_date', $today)
            ->first();

        if ($todaySession) {
            return response()->json([
                'success' => true,
                'ai_adaptations' => $todaySession->status === 'pending'
                    ? ["Continuing with today's workout session. Remember to listen to your body and adjust intensity as needed!"]
                    : ["Today's session is already marked as {$todaySession->status}. No further adaptations will be made until the next session is generated."],
                'weekly_plan' => [$todaySession]
            ], 200);
        }
        //////////////////////////////////////////////////////////

        return response()->json([
            'success' => true,
            'ai_adaptations' => [],
            'weekly_plan' => []
        ], 200);
    }


    public function generateTodayWorkout(Request $request)
    {
        $userId = $request->user()->id_user;
        $today = Carbon::today()->toDateString();

        // ////////////////////////////////////////////////////
        $exists = WorkoutSession::where('id_user', $userId)->where('log_date', $today)->exists();
        if ($exists) {
            return response()->json(['success' => false, 'message' => 'Today\'s session already exists.'], 400);
        }

        // ////////////////////////////////////////////////////

        $profile = UserProfile::where('id_user', $userId)->first();
        if (!$profile) {
            return response()->json(['success' => false, 'message' => 'Please complete your profile.'], 404);
        }

        $lastSession = WorkoutSession::where('id_user', $userId)
            ->whereIn('status', ['completed', 'skipped'])
            ->orderBy('id_session', 'desc')
            ->first();

        $nextIndex = 0;
        if ($lastSession) {
            foreach ($this->splitChain as $index => $chain) {
                if ($chain['name'] === $lastSession->session_name) {
                    $nextIndex = ($index + 1) % count($this->splitChain);
                    break;
                }
            }
        }

        $targetSplit = $this->splitChain[$nextIndex];
        $sessionName = $targetSplit['name'];
        $bodyParts = $targetSplit['parts'];

        $level = $profile->fitness_level === 'Advanced' ? 'expert' : strtolower($profile->fitness_level);
        $location = $profile->gym_membership === 'Yes' ? 'gym' : 'home';
        $goalMapping = [
            'Lose Weight' => 'weight_loss',
            'Build Muscle' => 'muscle',
            'Improve Endurance' => 'strength',
            'Stay Active' => 'flexibility'
        ];
        $goal = $goalMapping[$profile->target_kesehatan] ?? 'strength';

        $userEquipments = UserEquipment::where('id_user', $userId)->pluck('nama_alat')->toArray();
        if (in_array('Full Gym', $userEquipments)) {
            $userEquipments = array_unique(array_merge($userEquipments, ['barbell', 'cable', 'machine', 'dumbbell', 'e-z curl bar']));
        }
        if (empty($userEquipments))
            $userEquipments = ['body only'];


        $recentMoods = EmaMoodLog::where('id_user', $userId)
            ->where('log_date', '<=', $today)
            ->orderBy('log_date', 'desc')
            ->take(7)
            ->get();

        $weeklyMoodAvg = $recentMoods->avg('skor_mood') ?? 5.0;

        $isChronicLow = false;
        if ($recentMoods->count() >= 3) {
            if ($recentMoods[0]->skor_mood < 2.5 && $recentMoods[1]->skor_mood < 2.5 && $recentMoods[2]->skor_mood < 2.5) {
                $isChronicLow = true;
            }
        }

        $isAcuteDrop = false;
        if ($recentMoods->count() >= 2) {
            if (($recentMoods[1]->skor_mood - $recentMoods[0]->skor_mood) >= 2) {
                $isAcuteDrop = true;
            }
        }

        $adaptationMessages = [];

        /*Logika Rekomendasi Gym Berdasarkan mood yang mengambil referensi dari POMS Iceberg Profile (Morgan et al., 1987), 
        Stress & Muscle Recovery Kinetics (Stults-Kolehmainen & Bartholomew, 2012), dan
        Acute vs. Chronic Mood Drops (Allostatic Load Theory) dari medical concept of Allostasis and Allostatic Load (McEwen, 1998) 
        dan the Joint Consensus Statement on Overtraining Syndrome (Meeusen et al., 2013).
        */

        if ($weeklyMoodAvg < 2.0) {
            $sessionName = "Rest & Deep Recovery Day";
            $bodyParts = ['Stretching'];
            $level = 'beginner';
            $goal = 'flexibility';
            $adaptationMessages[] = "The CBF system detects Severe Burnout (Weekly Average < 2.0). Based on somatic recovery studies, your muscle repair capabilities are drastically hindered. Weight training is suspended and redirected to total recovery.";
        } elseif ($isChronicLow) {
            $sessionName = "Active Recovery & De-load";
            $bodyParts = ['Stretching', 'Abdominals'];
            $level = 'beginner';
            $goal = 'flexibility';
            $adaptationMessages[] = "Indicators of emotional depression detected for 3 consecutive days (Inverted Iceberg Profile). To prevent overtraining syndrome within the central nervous system (CNS), today's target is shifted to Active Recovery.";
        } elseif ($isAcuteDrop) {
            $level = 'beginner';
            $adaptationMessages[] = "An acute stress spike detected today. The CBF system has activated 'Endorphin Chaser Mode'—your daily workout layout is maintained, but intensity is dialed down to the minimum to stimulate dopamine without overstraining your muscles.";
        } else {
            $adaptationMessages[] = "Your psychological condition is stable and optimal (Vigor Iceberg Profile). Your central nervous system is fully prepared to handle high-intensity training loads.";
        }


        try {
            $response = Http::post("{$this->mlServiceUrl}/daily-recommendation", [
                'body_parts' => $bodyParts,
                'level' => $level,
                'goal' => $goal,
                'location' => $location,
                'equipments' => $userEquipments
            ]);

            if ($response->failed()) {
                return response()->json(['success' => false, 'message' => 'Failed to connect to CBF Engine.'], 500);
            }

            $exercisesData = $response->json()['exercises'] ?? [];

            DB::beginTransaction();
            $newSession = WorkoutSession::create([
                'id_user' => $userId,
                'session_name' => $sessionName,
                'status' => 'pending',
                'log_date' => $today
            ]);

            foreach ($exercisesData as $ex) {
                WorkoutSessionExercise::create([
                    'id_session' => $newSession->id_session,
                    'title' => $ex['title'],
                    'body_part' => $ex['body_part'],
                    'equipment' => $ex['equipment'],
                    'level' => $ex['level'],
                    'is_done' => 0
                ]);
            }
            DB::commit();

            return response()->json([
                'success' => true,
                'ai_adaptations' => $adaptationMessages,
                'weekly_plan' => [WorkoutSession::with('exercises')->find($newSession->id_session)]
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Error server.', 'error' => $e->getMessage()], 500);
        }
    }

    public function completeWorkoutSession(Request $request, $id)
    {
        $session = WorkoutSession::find($id);

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Workout session not found.'
            ], 404);
        }

        $session->status = 'completed';
        $session->save();

        return response()->json([
            'success' => true,
            'message' => 'Workout session completed successfully!'
        ], 200);
    }


    public function skipWorkoutSession(Request $request, $id)
    {
        // Cari sesi berdasarkan ID parameter url
        $session = WorkoutSession::find($id);

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Workout session not found.'
            ], 404);
        }

        $session->status = 'skipped';
        $session->save();

        return response()->json([
            'success' => true,
            'message' => 'Workout session skipped successfully.'
        ], 200);
    }


    public function toggleExerciseCheck(Request $request, $id)
    {
        $exercise = WorkoutSessionExercise::find($id);

        if (!$exercise) {
            return response()->json([
                'success' => false,
                'message' => 'Workout exercise not found.'
            ], 404);
        }

        $exercise->is_done = $exercise->is_done == 1 ? 0 : 1;
        $exercise->save();

        return response()->json([
            'success' => true,
            'is_done' => $exercise->is_done
        ], 200);
    }
}
