<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmaMoodLog extends Model
{
    protected $table = 'ema_mood_logs';
    protected $primaryKey = 'id_mood_log';
    public $timestamps = false;

    protected $fillable = [
        'id_user',
        'skor_mood',
        'mood',
        'influences',
        'notes',
        'log_date'
    ];

    protected $casts = [
        'influences' => 'array'
    ];
}