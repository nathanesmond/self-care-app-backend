<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{



    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:6',
            'id_role' => 'required|integer|exists:roles,id_role'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Registration Failed - Validation Error',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::create([
            'id_role' => $request->id_role,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'status_akun' => 'Active',
        ]);
        $user->load('role');

        $otp = rand(100000, 999999);

        DB::table('email_verification_tokens')->updateOrInsert(
            ['email' => $request->email],
            [
                'token' => $otp,
                'created_at' => Carbon::now()
            ]
        );

        try {
            Mail::raw("Hello!\n\nWelcome to Self-Care App. Your email verification code is: {$otp}\n\nThis code will expire in 15 minutes.", function ($message) use ($request) {
                $message->to($request->email)
                    ->subject('Self-Care App - Verify Your Email');
            });
        } catch (\Exception $e) {
            // We continue even if email fails, they can request a resend later
        }

        $token = $user->createToken('auth_token', [$user->role->nama_role])->plainTextToken;

        $user->load('role');

        $token = $user->createToken('auth_token', [$user->role->nama_role])->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registration Successful',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id_user' => $user->id_user,
                'email' => $user->email,
                'role' => $user->role->nama_role
            ]
        ], 201);
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Login Failed - Validation Error',
                'errors' => $validator->errors()
            ], 422);
        }


        $user = User::with('role')->where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Login Failed - Invalid Credentials'
            ], 401);
        }

        if ($user->status_akun !== 'Active') {
            return response()->json([
                'success' => false,
                'message' => 'Login Failed - Account Suspended'
            ], 403);
        }

        $roleName = $user->role->nama_role;

        $token = $user->createToken('auth_token', [$roleName])->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id_user' => $user->id_user,
                'email' => $user->email,
                'role' => $roleName
            ]
        ], 200);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout successful'
        ], 200);
    }

    public function sendOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Email not found in our system.'
            ], 404);
        }

        // 1. Generate a random 6-digit OTP
        $otp = rand(100000, 999999);

        // 2. Save it to the database (Update if exists, Insert if new)
        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $request->email],
            [
                'token' => $otp,
                'created_at' => Carbon::now()
            ]
        );

        // 3. Send the OTP via Email
        try {
            Mail::raw("Hello!\n\nYour password reset code is: {$otp}\n\nThis code will expire in 15 minutes.", function ($message) use ($request) {
                $message->to($request->email)
                    ->subject('Self-Care App - Password Reset Code');
            });
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to send email. Please check server configuration.'
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'OTP sent to your email successfully.'
        ], 200);
    }

    /**
     * Phase 2: Verify OTP and Reset the Password
     */
    public function resetPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
            'otp' => 'required|numeric',
            'password' => 'required|min:6'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation Error',
                'errors' => $validator->errors()
            ], 422);
        }

        // 1. Find the OTP record
        $resetRecord = DB::table('password_reset_tokens')
            ->where('email', $request->email)
            ->where('token', $request->otp)
            ->first();

        if (!$resetRecord) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid OTP code.'
            ], 400);
        }

        // 2. Check if OTP is expired (older than 15 minutes)
        $createdAt = Carbon::parse($resetRecord->created_at);
        if ($createdAt->addMinutes(15)->isPast()) {
            DB::table('password_reset_tokens')->where('email', $request->email)->delete();
            return response()->json([
                'success' => false,
                'message' => 'OTP has expired. Please request a new one.'
            ], 400);
        }

        // 3. Update the user's password
        $user = User::where('email', $request->email)->first();
        $user->password = Hash::make($request->password);
        $user->save();

        // 4. Clean up: Delete the OTP record so it can't be reused
        DB::table('password_reset_tokens')->where('email', $request->email)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Password reset successfully. You can now log in.'
        ], 200);
    }

    /**
     * Verify Email with OTP
     */
    public function verifyEmail(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:users,email',
            'otp' => 'required|numeric'
        ]);

        $record = DB::table('email_verification_tokens')
            ->where('email', $request->email)
            ->where('token', $request->otp)
            ->first();

        if (!$record) {
            return response()->json(['success' => false, 'message' => 'Invalid verification code.'], 400);
        }

        // Check expiration (15 minutes)
        if (Carbon::parse($record->created_at)->addMinutes(15)->isPast()) {
            DB::table('email_verification_tokens')->where('email', $request->email)->delete();
            return response()->json(['success' => false, 'message' => 'Code has expired. Please request a new one.'], 400);
        }

        // Update user
        $user = User::where('email', $request->email)->first();
        $user->email_verified_at = Carbon::now();
        $user->save();

        // Delete token
        DB::table('email_verification_tokens')->where('email', $request->email)->delete();

        return response()->json(['success' => true, 'message' => 'Email verified successfully!'], 200);
    }

    /**
     * Resend Verification OTP
     */
    public function resendVerificationOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:users,email'
        ]);

        $otp = rand(100000, 999999);

        DB::table('email_verification_tokens')->updateOrInsert(
            ['email' => $request->email],
            ['token' => $otp, 'created_at' => Carbon::now()]
        );

        try {
            Mail::raw("Hello!\n\nYour new email verification code is: {$otp}\n\nThis code will expire in 15 minutes.", function ($message) use ($request) {
                $message->to($request->email)->subject('Self-Care App - New Verification Code');
            });
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to send email.'], 500);
        }

        return response()->json(['success' => true, 'message' => 'A new code has been sent to your email.'], 200);
    }

    /**
     * Change Email (Logged In User)
     */
    public function changeEmail(Request $request)
    {
        // 1. Validate the new email (must be a valid email and not already taken)
        $request->validate([
            'new_email' => 'required|email|unique:users,email'
        ]);

        $user = $request->user(); // Get the currently authenticated user

        // 2. Update the email and reset the verification status
        $user->email = $request->new_email;
        $user->email_verified_at = null;
        $user->save();

        // 3. Generate a new OTP for the new email
        $otp = rand(100000, 999999);

        DB::table('email_verification_tokens')->updateOrInsert(
            ['email' => $user->email],
            ['token' => $otp, 'created_at' => Carbon::now()]
        );

        // 4. Send the verification email
        try {
            Mail::raw("Hello!\n\nYou recently changed your email. Your new verification code is: {$otp}\n\nThis code will expire in 15 minutes.", function ($message) use ($user) {
                $message->to($user->email)->subject('Self-Care App - Verify New Email');
            });
        } catch (\Exception $e) {
            // Fails silently, user can request a resend later
        }

        return response()->json([
            'success' => true,
            'message' => 'Email updated. We sent a verification code to your new email.'
        ], 200);
    }
}