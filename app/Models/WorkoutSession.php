<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkoutSession extends Model
{
    protected $table = 'workout_sessions';
    protected $primaryKey = 'id_session';
    public $timestamps = false;

    protected $fillable = ['id_user', 'session_name', 'status', 'log_date'];

    public function exercises()
    {
        return $this->hasMany(WorkoutSessionExercise::class, 'id_session', 'id_session');
    }
}