<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\VerificationCodeMail;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class AuthController extends Controller
{
    // POST /api/register — validate rồi gửi OTP, chưa tạo user
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:100',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
            'phone'    => 'required|string|max:15',
        ]);

        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Xóa bản ghi cũ nếu có (gửi lại)
        DB::table('email_verifications')->where('email', $validated['email'])->delete();

        DB::table('email_verifications')->insert([
            'email'      => $validated['email'],
            'name'       => $validated['name'],
            'phone'      => $validated['phone'],
            'password'   => Hash::make($validated['password']),
            'code'       => $code,
            'expires_at' => now()->addMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Mail::to($validated['email'])->send(new VerificationCodeMail($validated['name'], $code));

        return response()->json([
            'message' => 'Mã xác thực đã được gửi đến email của bạn.',
            'email'   => $validated['email'],
        ], 200);
    }

    // POST /api/verify-email — xác thực OTP, tạo user thật
    public function verifyEmail(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'code'  => 'required|string|size:6',
        ]);

        $record = DB::table('email_verifications')
            ->where('email', $request->email)
            ->first();

        if (!$record) {
            return response()->json(['message' => 'Không tìm thấy yêu cầu đăng ký. Vui lòng đăng ký lại.'], 422);
        }

        if (now()->isAfter($record->expires_at)) {
            DB::table('email_verifications')->where('email', $request->email)->delete();
            return response()->json(['message' => 'Mã xác thực đã hết hạn. Vui lòng đăng ký lại.'], 422);
        }

        if ($record->code !== $request->code) {
            return response()->json(['message' => 'Mã xác thực không đúng.'], 422);
        }

        // Kiểm tra lại email chưa bị đăng ký trong lúc chờ
        if (User::where('email', $request->email)->exists()) {
            DB::table('email_verifications')->where('email', $request->email)->delete();
            return response()->json(['message' => 'Email này đã được đăng ký. Vui lòng đăng nhập.'], 422);
        }

        $user = User::create([
            'name'     => $record->name,
            'email'    => $record->email,
            'password' => $record->password,
            'phone'    => $record->phone,
            'role'     => 'customer',
            'status'   => 'active',
        ]);

        DB::table('email_verifications')->where('email', $request->email)->delete();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user'  => $user,
            'token' => $token,
        ], 201);
    }

    // POST /api/resend-verification — gửi lại OTP
    public function resendVerificationCode(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $record = DB::table('email_verifications')
            ->where('email', $request->email)
            ->first();

        if (!$record) {
            return response()->json(['message' => 'Không tìm thấy yêu cầu đăng ký.'], 422);
        }

        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        DB::table('email_verifications')->where('email', $request->email)->update([
            'code'       => $code,
            'expires_at' => now()->addMinutes(10),
            'updated_at' => now(),
        ]);

        Mail::to($request->email)->send(new VerificationCodeMail($record->name, $code));

        return response()->json(['message' => 'Mã xác thực mới đã được gửi.'], 200);
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

    // PUT /api/change-password
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password'          => 'required',
            'new_password'              => 'required|string|min:8|confirmed',
        ]);

        if (!Hash::check($request->current_password, $request->user()->password)) {
            return response()->json(['message' => 'Mật khẩu hiện tại không đúng'], 422);
        }

        $request->user()->update([
            'password' => Hash::make($request->new_password),
        ]);

        return response()->json(['message' => 'Đổi mật khẩu thành công']);
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
