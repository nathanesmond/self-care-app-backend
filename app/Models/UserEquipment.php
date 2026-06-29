<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserEquipment extends Model
{
    protected $table = 'user_equipments';
    protected $primaryKey = 'id_user_equipment';
    public $timestamps = false;

    protected $fillable = ['id_user', 'nama_alat'];
}