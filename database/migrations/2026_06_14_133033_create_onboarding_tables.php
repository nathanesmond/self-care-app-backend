<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // 1. Tabel user_profiles
        Schema::create('user_profiles', function (Blueprint $box) {
            $box->id('id_profile');

            // 🔥 SOLUSI UTAMA: Menggunakan integer() biasa (SIGNED) agar pas dengan phpMyAdmin
            $box->integer('id_user');

            $box->string('name');
            $box->integer('usia');
            $box->string('gender');
            $box->double('tinggi_badan');
            $box->double('berat_badan');
            $box->string('fitness_level');
            $box->string('gym_membership');
            $box->string('target_kesehatan');

            $box->foreign('id_user')->references('id_user')->on('users')->onDelete('cascade');
        });

        // 2. Tabel user_equipments
        Schema::create('user_equipments', function (Blueprint $box) {
            $box->id('id_equipment');

            // 🔥 SAMAKAN DI SINI JUGA: Menjadi signed integer biasa
            $box->integer('id_user');

            $box->string('nama_alat');

            $box->foreign('id_user')->references('id_user')->on('users')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_equipments');
        Schema::dropIfExists('user_profiles');
    }
};