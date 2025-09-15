<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Spatie\Permission\Models\Role;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        $role = Role::firstOrCreate(['name' => 'admin']);

        $user = User::firstOrCreate(
            ['email' => 'admin@kpi.co.id'],
            [
                'name' => 'Admin',
                'password' => bcrypt('Admin@12345'),
            ]
        );

        if (! $user->hasRole('admin')) {
            $user->assignRole($role);
        }
    }
}