<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'users';
    protected $primaryKey = 'id_user';

    protected $fillable = [
        'id_role',
        'email',
        'password',
        'status_akun',
    ];

    protected $hidden = [
        'password',
    ];

    public function role()
    {
        return $this->belongsTo(Role::class, 'id_role', 'id_role');
    }

    public function isAdmin()
    {
        return $this->role->nama_role === 'Admin';
    }
    public function profile()
    {
        return $this->hasOne(UserProfile::class, 'id_user', 'id_user');
    }

    public function equipments()
    {
        return $this->hasMany(UserEquipment::class, 'id_user', 'id_user');
    }
    public $timestamps = false;
}