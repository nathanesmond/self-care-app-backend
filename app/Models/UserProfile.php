<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserProfile extends Model
{
    protected $table = 'user_profiles';
    protected $primaryKey = 'id_profile';
    public $timestamps = false;

    protected $fillable = [
        'id_user',
        'name',
        'usia',
        'gender',
        'tinggi_badan',
        'berat_badan',
        'fitness_level',
        'gym_membership',
        'target_kesehatan'
    ];
}