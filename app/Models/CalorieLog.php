<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CalorieLog extends Model
{
    protected $table = 'calorie_logs';
    protected $primaryKey = 'id_calorie_log';
    public $timestamps = false;

    protected $fillable = [
        'id_user',
        'nama_makanan',
        'jumlah_kalori',
        'meal_type',
        'logged_time',
        'log_date'
    ];
}