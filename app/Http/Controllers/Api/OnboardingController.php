<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\UserProfile;
use App\Models\UserEquipment;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class OnboardingController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'age' => 'required|integer|min:1',
            'gender' => 'required|string|in:Male,Female',
            'height' => 'required|numeric',
            'weight' => 'required|numeric',
            'fitness_level' => 'required|string|in:Beginner,Intermediate,Advanced',
            'gym_membership' => 'required|string|in:Yes,No',
            'goal' => 'required|string',
            'equipments' => 'required|array|min:1'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $userId = $request->user()->id_user;

        DB::beginTransaction();

        try {
            UserProfile::updateOrCreate(
                ['id_user' => $userId],
                [
                    'name' => $request->name,
                    'usia' => $request->age,
                    'gender' => $request->gender,
                    'tinggi_badan' => $request->height,
                    'berat_badan' => $request->weight,
                    'fitness_level' => $request->fitness_level,
                    'gym_membership' => $request->gym_membership,
                    'target_kesehatan' => $request->goal,
                ]
            );

            UserEquipment::where('id_user', $userId)->delete();

            foreach ($request->equipments as $alat) {
                UserEquipment::create([
                    'id_user' => $userId,
                    'nama_alat' => $alat
                ]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Onboarding data successfully saved to user profile.'
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while saving onboarding data.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getProfile(Request $request)
    {
        $user = $request->user();

        // 2. Fetch the profile details from the 'user_profiles' table
        $profile = DB::table('user_profiles')->where('id_user', $user->id_user)->first();

        // 3. Fetch the equipment list from 'user_equipments' table and pluck just the names into an array
        $equipments = DB::table('user_equipments')
            ->where('id_user', $user->id_user)
            ->pluck('nama_alat');

        // 4. Return everything combined perfectly for Flutter
        return response()->json([
            'success' => true,
            'data' => [
                // Fallback to 'No Name' if they somehow haven't finished onboarding
                'name' => $profile ? $profile->name : 'No Name',
                'email' => $user->email, // 🔥 HERE IS THE MISSING EMAIL!
                'age' => $profile ? $profile->usia : '-',
                'gender' => $profile ? $profile->gender : '-',
                'height' => $profile ? $profile->tinggi_badan : '-',
                'weight' => $profile ? $profile->berat_badan : '-',
                'fitness_level' => $profile ? $profile->fitness_level : '-',
                'gym_membership' => $profile ? $profile->gym_membership : '-',
                'goal' => $profile ? $profile->target_kesehatan : 'Stay Active',
                'equipments' => $equipments
            ]
        ], 200);
    }

    public function updateProfile(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'age' => 'required|integer|min:1',
            'gender' => 'required|string|in:Male,Female',
            'height' => 'required|numeric',
            'weight' => 'required|numeric',
            'fitness_level' => 'required|string|in:Beginner,Intermediate,Advanced',
            'gym_membership' => 'required|string|in:Yes,No',
            'goal' => 'required|string',
            'equipments' => 'required|array|min:1'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $userId = $request->user()->id_user;

        DB::beginTransaction();

        try {

            UserProfile::updateOrCreate(
                ['id_user' => $userId],
                [
                    'name' => $request->name,
                    'usia' => $request->age,
                    'gender' => $request->gender,
                    'tinggi_badan' => $request->height,
                    'berat_badan' => $request->weight,
                    'fitness_level' => $request->fitness_level,
                    'gym_membership' => $request->gym_membership,
                    'target_kesehatan' => $request->goal,
                ]
            );

            UserEquipment::where('id_user', $userId)->delete();
            foreach ($request->equipments as $alat) {
                UserEquipment::create([
                    'id_user' => $userId,
                    'nama_alat' => $alat
                ]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Your profile has been updated successfully!'
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to update profile.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}