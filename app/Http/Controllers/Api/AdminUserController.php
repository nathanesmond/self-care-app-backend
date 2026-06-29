<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB; // Make sure to import DB facade
use Illuminate\Support\Facades\Validator;

class AdminUserController extends Controller
{
    /**
     * Get all users for the Admin Dashboard
     */
    /**
     * Get all users for the Admin Dashboard (Excluding Admins)
     */
    public function getAllUsers(Request $request)
    {
        // Use leftJoin to connect the user_profiles table, 
        // and add a WHERE clause to only grab id_role = 2 (Regular Users)
        $users = User::leftJoin('user_profiles', 'users.id_user', '=', 'user_profiles.id_user')
            ->where('users.id_role', 2) // 🔥 This line explicitly hides Admins
            ->select(
                'users.id_user',
                'users.email',
                'users.status_akun',
                'user_profiles.name'
            )
            ->orderBy('users.created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Users fetched successfully',
            'users' => $users
        ], 200);
    }


    public function updateUser(Request $request, $id)
    {
        $user = User::where('id_user', $id)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found.'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $id . ',id_user',
            'status_akun' => 'required|in:Active,Suspended'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation Error',
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();

        try {
            $user->email = $request->email;
            $user->status_akun = $request->status_akun;
            $user->save();

            $profileExists = DB::table('user_profiles')->where('id_user', $id)->exists();

            if ($profileExists) {

                DB::table('user_profiles')
                    ->where('id_user', $id)
                    ->update(['name' => $request->name]);
            } else {

                DB::table('user_profiles')->insert([
                    'id_user' => $id,
                    'name' => $request->name,
                    'usia' => 0,
                    'gender' => 'Not Set',
                    'tinggi_badan' => 0.0,
                    'berat_badan' => 0.0,
                    'fitness_level' => 'Beginner',
                    'gym_membership' => 'No',
                    'target_kesehatan' => 'Not Set'
                ]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'User updated successfully.',
                'user' => [
                    'id_user' => $user->id_user,
                    'name' => $request->name,
                    'email' => $user->email,
                    'status_akun' => $user->status_akun,
                ]
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'success' => false,
                'message' => 'Failed to update user: ' . $e->getMessage()
            ], 500);
        }
    }
}