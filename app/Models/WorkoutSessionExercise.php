<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkoutSessionExercise extends Model
{
    protected $table = 'workout_session_exercises';
    protected $primaryKey = 'id_session_exercise';
    public $timestamps = false;

    protected $fillable = ['id_session', 'title', 'body_part', 'equipment', 'level', 'is_done'];
}