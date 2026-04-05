<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // POST /api/register
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:100',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
            'phone'    => 'required|string|max:15',
        ]);

        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
            'phone'    => $validated['phone'],
            'role'     => 'customer',
            'status'   => 'active',
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user'  => $user,
            'token' => $token,
        ], 201);
    }

    // POST /api/login
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Email hoặc mật khẩu không đúng'], 401);
        }

        if ($user->status !== 'active') {
            return response()->json(['message' => 'Tài khoản đã bị vô hiệu hóa'], 403);
        }

        // Revoke old tokens (single session)
        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user'  => $user,
            'token' => $token,
        ]);
    }

    // GET /api/me
    public function me(Request $request)
    {
        return response()->json($request->user()->load('addresses'));
    }

    // POST /api/logout
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Đã đăng xuất']);
    }

    // GET /api/admin/users (admin)
    public function adminUsers(Request $request)
    {
        $query = User::with('addresses')
            ->withCount('orders')
            ->withSum('orders as total_spent', 'final_amount')
            ->latest();

        if ($role = $request->get('role')) {
            $query->where('role', $role);
        }

        return response()->json($query->paginate(20));
    }

    // Placeholder — not used (schema uses role field, not email_verified_at)
    public function verifyEmail(Request $request) {
        return response()->json(['message' => 'Không sử dụng'], 404);
    }
    public function resendVerificationCode(Request $request) {
        return response()->json(['message' => 'Không sử dụng'], 404);
    }
    public function facebookLogin(Request $request) {
        return response()->json(['message' => 'Chưa cài đặt'], 501);
    }
    public function facebookRedirect(Request $request) {
        return response()->json(['message' => 'Chưa cài đặt'], 501);
    }
    public function facebookCallback(Request $request) {
        return response()->json(['message' => 'Chưa cài đặt'], 501);
    }
}
