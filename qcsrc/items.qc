/*  Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/
void() W_SetCurrentAmmo;
/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */


void() SUB_regen =
{
	self.model = self.mdl;		// restore original model
	self.solid = SOLID_TRIGGER;	// allow it to be touched again
	sound (self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);
};



/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
	dprint ("noclass spawned at");
	dprint (vtos(self.origin));
	dprint ("\n");
	remove (self);
};


// ================
// Dropped powerups
// ================

void() q_touch =
{
local entity    stemp;
local float     best;
local string    s;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	self.mdl = self.model;

	sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	other.items = other.items | IT_QUAD;
	self.model = string_null;
		if (deathmatch == 4)
		{
			other.armortype = 0;
			other.armorvalue = 0 * 0.01;
			other.ammo_cells = 0;
		}

// do the apropriate action
	other.super_time = 1;
	other.super_damage_finished = self.cnt;

	s=ftos(rint(other.super_damage_finished - time));

	bprint (PRINT_LOW, other.netname);
	if (deathmatch == 4)
		bprint (PRINT_LOW, " recovered an OctaPower with ");
	else 
		bprint (PRINT_LOW, " recovered a Quad with ");
	bprint (PRINT_LOW, s);
	bprint (PRINT_LOW, " seconds remaining!\n");

	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};


void(float timeleft) DropQuad =
{
	local entity    item;

	item = spawn();
	item.origin = self.origin;
	
	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);
	
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	item.noise = "items/damage.wav";
	setmodel (item, "progs/quaddama.mdl");
	setsize (item, '-16 -16 -24', '16 16 32');
	item.cnt = time + timeleft;
	item.touch = q_touch;
	item.nextthink = time + timeleft;    // remove it with the time left on it
	item.think = SUB_Remove;

#ifdef __QW__ // EF_BLUE is not supported in NQ
	item.effects = EF_BLUE;
#endif
};


void() r_touch;

void() r_touch =
{
local entity    stemp;
local float     best;
local string    s;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	self.mdl = self.model;

	sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	other.items = other.items | IT_INVISIBILITY;
	self.model = string_null;

// do the apropriate action
	other.invisible_time = 1;
	other.invisible_finished = self.cnt;
	s=ftos(rint(other.invisible_finished - time));
	bprint (PRINT_LOW, other.netname);
	bprint (PRINT_LOW, " recovered a Ring with ");
	bprint (PRINT_LOW, s);
	bprint (PRINT_LOW, " seconds remaining!\n");
      

	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};


void(float timeleft) DropRing =
{
	local entity    item;

	item = spawn();
	item.origin = self.origin;
	
	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);
	
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	item.noise = "items/inv1.wav";
	setmodel (item, "progs/invisibl.mdl");
	setsize (item, '-16 -16 -24', '16 16 32');
	item.cnt = time + timeleft;
	item.touch = r_touch;
	item.nextthink = time + timeleft;    // remove after 30 seconds
	item.think = SUB_Remove;
};

/*============
PlaceItem

plants the object on the floor
============*/
void() PlaceItem =
{
	local float	oldz;

	self.mdl = self.model;		// so it can be restored on respawn
	self.flags = FL_ITEM;		// make extra wide
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	oldz = self.origin_z;

	if (!droptofloor())
	{
		dprint ("Bonus item fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);

		return;
	}
};

/*============
StartItem

Sets the clipping size and plants the object on the floor
============*/
void() StartItem =
{
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = PlaceItem;
};

/*=========================================================================

HEALTH BOX

=========================================================================*/
//
// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
//
float (entity e, float healamount, float ignore) T_Heal =
{
	if (e.health <= 0)
		return 0;

	if ((!ignore) && (e.health >= e.max_health))
		return 0;

	healamount = ceil(healamount);

	e.health = e.health + healamount;

	if ((!ignore) && (e.health >= e.max_health))
		e.health = e.max_health;

	if (e.health > 250)
		e.health = 250;

	return 1;
};

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
{
    model({"path": "maps/b_bh10.bsp", "skin": 0, "frame": 0});
}
Health box. Normally gives 25 points.
Rotten box heals 5-10 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
*/

float	H_ROTTEN = 1;
float	H_MEGA = 2;
.float	healamount, healtype;
void() health_touch;
void() item_megahealth_rot;

void() item_health =
{
	if (deathmatch_no_health())
		return;

	if (self.spawnflags & H_ROTTEN)
	{
		precache_model("maps/b_bh10.bsp");

		precache_sound("items/r_item1.wav");
		setmodel(self, "maps/b_bh10.bsp");
		self.noise = "items/r_item1.wav";
		self.healamount = 15;
		self.healtype = 0;
	}

	else if (self.spawnflags & H_MEGA)
	{
		if (deathmatch_no_mega_health())
			return;

		precache_model("maps/b_bh100.bsp");
		precache_sound("items/r_item2.wav");
		setmodel(self, "maps/b_bh100.bsp");
		self.noise = "items/r_item2.wav";
		self.healamount = 100;
		self.healtype = 2;
	}

	else
	{
		precache_model("maps/b_bh25.bsp");
		precache_sound("items/health1.wav");
		setmodel(self, "maps/b_bh25.bsp");
		self.noise = "items/health1.wav";
		self.healamount = 25;
		self.healtype = 1;
	}

	self.touch = health_touch;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

void() health_touch =
{
	local	string	s;

	if (deathmatch_supermode())
		if (other.invincible_time > 0)
			return;

	if (other.classname != "player")
		return;

	if (self.healtype == 2) // Megahealth?  Ignore max_health...
	{
		if (other.health >= 250)
			return;
		if (!T_Heal(other, self.healamount, 1))
			return;
	}

	else
	{
		if (!T_Heal(other, self.healamount, 0))
			return;
	}

	sprint(other, PRINT_LOW, LOC_ITEM_PICKUP_HEALTH);
	s = ftos(self.healamount);
	sprint(other, PRINT_LOW, s);
	sprint(other, PRINT_LOW, LOC_ITEM_TYPE_HEALTH);
	sprint(other, PRINT_LOW, "\n");

	// health touch sound
	sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	stuffcmd (other, "bf\n");

	self.model = string_null;
	self.solid = SOLID_NOT;

	// Megahealth = rot down the player's super health
	if (self.healtype == 2 && !deathmatch_supermode())
	{
		other.items = other.items | IT_SUPERHEALTH;
		self.owner = other;
		self.nextthink = time + 5;
		self.think = item_megahealth_rot;
	}

	else
	{
		if (deathmatch_item_respawn())		// deathmatch 2 is the silly old rules
		{
			self.nextthink = time + 20;
			self.think = SUB_regen;
		}
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

void() item_megahealth_rot =
{
	other = self.owner;

	if (other.health > other.max_health)
	{
		other.health = other.health - 1;
		self.nextthink = time + 1;

		return;
	}

	// it is possible for a player to die and respawn between rots, so don't
	// just blindly subtract the flag off
	other.items = other.items - (other.items & IT_SUPERHEALTH);

	if (deathmatch_item_respawn())	// deathmatch 2 is silly old rules
	{
		self.nextthink = time + 20;
		self.think = SUB_regen;
	}
};

/*===============================================================================

ARMOR

===============================================================================*/

void() armor_touch =
{
	local	float	type, value, bit;

	type = 0.3;
	value = 100;
	bit = IT_ARMOR1;

	if (other.health <= 0)
		return;

	if (other.classname != "player")
		return;
	
	if (deathmatch_supermode())
		if (other.invincible_time > 0)
			return;

	// cypress (07 feb 2024) -- adopted switch
	switch(self.classname) {
		case "item_armor1":
			type = 0.3;
			value = 100;
			bit = IT_ARMOR1;
			break;
		case "item_armor2":
			type = 0.6;
			value = 150;
			bit = IT_ARMOR2;
			break;
		case "item_armorInv":
			type = 0.8;
			value = 200;
			bit = IT_ARMOR3;
			break;
		default:
			break;
	}

	if (other.armortype*other.armorvalue >= type*value)
		return;

	other.armortype = type;
	other.armorvalue = value;
	other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit;

	self.solid = SOLID_NOT;
	self.model = string_null;

	if (deathmatch_item_respawn())
		self.nextthink = time + 20;

	self.think = SUB_regen;

	sprint(other, PRINT_LOW, LOC_ITEM_PICKUP_NORMAL);
	sprint(other, PRINT_LOW, ftos(value));
	sprint(other, PRINT_LOW, LOC_ITEM_TYPE_ARMOR);
	sprint(other, PRINT_LOW, "\n");

	// armor touch sound
	sound(other, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
{
    model({"path": "progs/armor.mdl", "skin": 0, "frame": 0});
}
*/

void() item_armor1 =
{
	if (deathmatch_no_armor())
		return;

	self.touch = armor_touch;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 0;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
{
    model({"path": "progs/armor.mdl", "skin": 1, "frame": 0});
}
*/

void() item_armor2 =
{
	if (deathmatch_no_armor())
		return;

	self.touch = armor_touch;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 1;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
{
    model({"path": "progs/armor.mdl", "skin": 2, "frame": 0});
}
*/

void() item_armorInv =
{
	if (deathmatch_no_armor())
		return;

	self.touch = armor_touch;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 2;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*
===============================================================================

WEAPONS

===============================================================================
*/

void() bound_other_ammo =
{
	if (deathmatch_unlimited_ammo())
	{
		other.ammo_shells = 255;
		other.ammo_nails = 255;
		other.ammo_rockets = 255;
		other.ammo_cells = 255;
	}
	else
	{
		if (other.ammo_shells > 100)
			other.ammo_shells = 100;

		if (other.ammo_nails > 200)
			other.ammo_nails = 200;

		if (other.ammo_rockets > 100)
			other.ammo_rockets = 100;

		if (other.ammo_cells > 100)
			other.ammo_cells = 100;
	}
};


float(float w) RankForWeapon =
{
	if (w == IT_LIGHTNING)
		return 1;

	if (w == IT_ROCKET_LAUNCHER)
		return 2;

	if (w == IT_SUPER_NAILGUN)
		return 3;

	if (w == IT_GRENADE_LAUNCHER)
		return 4;

	if (w == IT_SUPER_SHOTGUN)
		return 5;

	if (w == IT_NAILGUN)
		return 6;

	return 7;
};

float (float w) WeaponCode = //copypasta'd directly from gpl'd qw source on github.
{
	if (w == IT_SUPER_SHOTGUN)
		return 3;

	if (w == IT_NAILGUN)
		return 4;

	if (w == IT_SUPER_NAILGUN)
		return 5;

	if (w == IT_GRENADE_LAUNCHER)
		return 6;

	if (w == IT_ROCKET_LAUNCHER)
		return 7;

	if (w == IT_LIGHTNING)
		return 8;

	return 1;
};

/*=============
Deathmatch_Weapon

Deathmatch weapon change rules for picking up a weapon

.float		ammo_shells, ammo_nails, ammo_rockets, ammo_cells;
=============*/
void(float old, float new) Deathmatch_Weapon =
{
	local float or, nr;

	// change self.weapon if desired
	or = RankForWeapon (self.weapon);
	nr = RankForWeapon (new);

	if ( nr < or )
		self.weapon = new;
};

/*=============
weapon_touch
=============*/
float() W_BestWeapon;

void() weapon_touch =
{
	local	float	hadammo, best, new, old;
	local	entity	stemp;
	local	float	leave;

	new = other.items;

	if (!(other.flags & FL_CLIENT))
		return;

// if the player was using his best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;

	if (deathmatch_weapon_stay() || coop)
		leave = 1;
	else
		leave = 0;

	if (self.classname == "weapon_nailgun")
	{
		if (leave && (other.items & IT_NAILGUN) )
			return;

		hadammo = other.ammo_nails;
		new = IT_NAILGUN;
		other.ammo_nails = other.ammo_nails + 30;
	}

	else if (self.classname == "weapon_supernailgun")
	{
		if (leave && (other.items & IT_SUPER_NAILGUN) )
			return;

		hadammo = other.ammo_rockets;
		new = IT_SUPER_NAILGUN;
		other.ammo_nails = other.ammo_nails + 30;
	}

	else if (self.classname == "weapon_supershotgun")
	{
		if (leave && (other.items & IT_SUPER_SHOTGUN) )
			return;

		hadammo = other.ammo_rockets;
		new = IT_SUPER_SHOTGUN;
		other.ammo_shells = other.ammo_shells + 5;
	}

	else if (self.classname == "weapon_rocketlauncher")
	{
		if (leave && (other.items & IT_ROCKET_LAUNCHER) )
			return;

		hadammo = other.ammo_rockets;
		new = IT_ROCKET_LAUNCHER;
		other.ammo_rockets = other.ammo_rockets + 5;
	}

	else if (self.classname == "weapon_grenadelauncher")
	{
		if (leave && (other.items & IT_GRENADE_LAUNCHER) )
			return;

		hadammo = other.ammo_rockets;
		new = IT_GRENADE_LAUNCHER;
		other.ammo_rockets = other.ammo_rockets + 5;
	}

	else if (self.classname == "weapon_lightning")
	{
		if (leave && (other.items & IT_LIGHTNING) )
			return;

		hadammo = other.ammo_rockets;
		new = IT_LIGHTNING;
		other.ammo_cells = other.ammo_cells + 15;
	}

	else
		objerror ("weapon_touch: unknown classname");

	sprint (other, PRINT_LOW, LOC_ITEM_PICKUP_NORMAL);
	sprint (other, PRINT_LOW, "the ");
	sprint (other, PRINT_LOW, self.netname);
	sprint (other, PRINT_LOW, "\n");
	// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	bound_other_ammo ();

	// change to the weapon
	old = other.items;
	other.items = other.items | new;

	stemp = self;
	self = other;

	if (!deathmatch)
		self.weapon = new;

	else
		Deathmatch_Weapon (old, new);

	W_SetCurrentAmmo();

	self = stemp;

	if (leave)
		return;

	// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;

	if (deathmatch && !deathmatch_weapon_stay())
		self.nextthink = time + 30;

	self.think = SUB_regen;

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
{
    model({"path": "progs/g_shot.mdl", "skin": 0, "frame": 0});
}
*/

void() weapon_supershotgun =
{
	if (deathmatch_no_weapons_on_map() || deathmatch_no_super_shotgun_on_map())
		return;
	
	precache_model ("progs/g_shot.mdl");
	setmodel (self, "progs/g_shot.mdl");
	self.weapon = IT_SUPER_SHOTGUN;
	self.netname = LOC_WEAPON_NAME_SUPER_SHOTGUN;
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
{
    model({"path": "progs/g_nail.mdl", "skin": 0, "frame": 0});
}
*/

void() weapon_nailgun =
{
	if (deathmatch_no_weapons_on_map() || deathmatch_no_nailgun_on_map())
		return;
	
	precache_model ("progs/g_nail.mdl");
	setmodel (self, "progs/g_nail.mdl");
	self.weapon = IT_NAILGUN;
	self.netname = LOC_WEAPON_NAME_NAILGUN;
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
{
    model({"path": "progs/g_nail2.mdl", "skin": 0, "frame": 0});
}
*/

void() weapon_supernailgun =
{
	if (deathmatch_no_weapons_on_map() || deathmatch_no_super_nailgun_on_map())
		return;
	
	precache_model ("progs/g_nail2.mdl");
	setmodel (self, "progs/g_nail2.mdl");
	self.weapon = IT_SUPER_NAILGUN;
	self.netname = LOC_WEAPON_NAME_SUPER_NAILGUN;
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
{
    model({"path": "progs/g_rock.mdl", "skin": 0, "frame": 0});
}
*/

void() weapon_grenadelauncher =
{
	if (deathmatch_no_weapons_on_map() || deathmatch_no_grenade_launcher_on_map())
		return;

	precache_model ("progs/g_rock.mdl");
	setmodel (self, "progs/g_rock.mdl");
	self.weapon = IT_GRENADE_LAUNCHER;
	self.netname = LOC_WEAPON_NAME_GRENADE_LAUNCH;
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
{
    model({"path": "progs/g_rock2.mdl", "skin": 0, "frame": 0});
}
*/

void() weapon_rocketlauncher =
{
	if (deathmatch_no_weapons_on_map() || deathmatch_no_rocket_launcher_on_map())
		return;
	
	precache_model ("progs/g_rock2.mdl");
	setmodel (self, "progs/g_rock2.mdl");
	self.weapon = IT_ROCKET_LAUNCHER;
	self.netname = LOC_WEAPON_NAME_ROCKET_LAUNCH;
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
{
    model({"path": "progs/g_light.mdl", "skin": 0, "frame": 0});
}
*/

void() weapon_lightning =
{
	if (deathmatch_no_weapons_on_map() || deathmatch_no_lightning_gun_on_map())
		return;
	
	precache_model ("progs/g_light.mdl");
	setmodel (self, "progs/g_light.mdl");
	self.weapon = IT_LIGHTNING;
	self.netname = LOC_WEAPON_NAME_THUNDERBOLT;
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*
===============================================================================

AMMO

===============================================================================
*/

void() ammo_touch =
{
	local entity	stemp;
	local float		best;

	if (other.classname != "player")
		return;

	if (other.health <= 0)
		return;

// if the player was using his best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;


// shotgun
	if (self.weapon == 1)
	{
		if (other.ammo_shells >= 100)
			return;

		other.ammo_shells = other.ammo_shells + self.aflag;
	}

	// spikes
	if (self.weapon == 2)
	{
		if (other.ammo_nails >= 200)
			return;

		other.ammo_nails = other.ammo_nails + self.aflag;
	}

	//	rockets
	if (self.weapon == 3)
	{
		if (other.ammo_rockets >= 100)
			return;

		other.ammo_rockets = other.ammo_rockets + self.aflag;
	}

	//	cells
	if (self.weapon == 4)
	{
		if (other.ammo_cells >= 100)
			return;
		other.ammo_cells = other.ammo_cells + self.aflag;
	}

	bound_other_ammo ();

	// Print message
	sprint (other, PRINT_LOW, LOC_ITEM_PICKUP_NORMAL);
	sprint (other, PRINT_LOW, ftos(self.aflag));
	sprint (other, PRINT_LOW, " ");
	sprint (other, PRINT_LOW, self.netname);
	sprint (other, PRINT_LOW, "\n");

	// ammo touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	// change to a better weapon if appropriate
	if ( other.weapon == best )
	{
		stemp = self;
		self = other;
		self.weapon = W_BestWeapon();
		W_SetCurrentAmmo ();
		self = stemp;
	}

	// if changed current ammo, update it
	stemp = self;
	self = other;
	W_SetCurrentAmmo();
	self = stemp;

	// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;

	if (deathmatch_item_respawn())
	{
		self.think = SUB_regen;
		if (deathmatch_slow_ammo())
			self.nextthink = time + 30;
		else
			self.nextthink = time + 15;
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};




float WEAPON_BIG2 = 1;

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
{
    model({"path": "maps/b_shell1.bsp", "skin": 0, "frame": 0});
}
*/

void() item_shells =
{
	if (deathmatch_no_shell_pickups())
		return;

	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_shell1.bsp");
		setmodel (self, "maps/b_shell1.bsp");
		self.aflag = 40;
	}

	else
	{
		precache_model ("maps/b_shell0.bsp");
		setmodel (self, "maps/b_shell0.bsp");
		self.aflag = 20;
	}

	self.weapon = 1;
	self.netname = LOC_WEAPON_AMMO_SHELLS;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
{
    model({"path": "maps/b_nail1.bsp", "skin": 0, "frame": 0});
}
*/

void() item_spikes =
{
	if (deathmatch_no_nail_pickups())
		return;
	
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_nail1.bsp");
		setmodel (self, "maps/b_nail1.bsp");
		self.aflag = 50;
	}

	else
	{
		precache_model ("maps/b_nail0.bsp");
		setmodel (self, "maps/b_nail0.bsp");
		self.aflag = 25;
	}

	self.weapon = 2;
	self.netname = LOC_WEAPON_AMMO_NAILS;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
{
    model({"path": "maps/b_rock1.bsp", "skin": 0, "frame": 0});
}
*/

void() item_rockets =
{
	if (deathmatch_no_rocket_pickups())
		return;
	
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_rock1.bsp");
		setmodel (self, "maps/b_rock1.bsp");
		self.aflag = 10;
	}

	else
	{
		precache_model ("maps/b_rock0.bsp");
		setmodel (self, "maps/b_rock0.bsp");
		self.aflag = 5;
	}

	self.weapon = 3;
	self.netname = LOC_WEAPON_AMMO_ROCKETS;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
{
    model({"path": "maps/b_batt1.bsp", "skin": 0, "frame": 0});
}
*/

void() item_cells =
{
	if (deathmatch_no_cell_pickups())
		return;
	
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_batt1.bsp");
		setmodel (self, "maps/b_batt1.bsp");
		self.aflag = 12;
	}

	else
	{
		precache_model ("maps/b_batt0.bsp");
		setmodel (self, "maps/b_batt0.bsp");
		self.aflag = 6;
	}

	self.weapon = 4;
	self.netname = LOC_WEAPON_AMMO_CELLS;
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

float WEAPON_SHOTGUN = 1;
float WEAPON_ROCKET = 2;
float WEAPON_SPIKES = 4;
float WEAPON_BIG = 8;
void() item_weapon =
{
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_SHOTGUN)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/b_shell1.bsp");
			setmodel (self, "maps/b_shell1.bsp");
			self.aflag = 40;
		}

		else
		{
			precache_model ("maps/b_shell0.bsp");
			setmodel (self, "maps/b_shell0.bsp");
			self.aflag = 20;
		}
		self.weapon = 1;
		self.netname = LOC_WEAPON_AMMO_SHELLS;
	}

	if (self.spawnflags & WEAPON_SPIKES)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/b_nail1.bsp");
			setmodel (self, "maps/b_nail1.bsp");
			self.aflag = 40;
		}

		else
		{
			precache_model ("maps/b_nail0.bsp");
			setmodel (self, "maps/b_nail0.bsp");
			self.aflag = 20;
		}
		self.weapon = 2;
		self.netname = LOC_WEAPON_AMMO_NAILS;
	}

	if (self.spawnflags & WEAPON_ROCKET)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/b_rock1.bsp");
			setmodel (self, "maps/b_rock1.bsp");
			self.aflag = 10;
		}

		else
		{
			precache_model ("maps/b_rock0.bsp");
			setmodel (self, "maps/b_rock0.bsp");
			self.aflag = 5;
		}
		self.weapon = 3;
		self.netname = LOC_WEAPON_AMMO_ROCKETS;
	}

	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*
===============================================================================

KEYS

===============================================================================
*/

void() key_touch =
{
	if (other.classname != "player")
		return;

	if (other.health <= 0)
		return;

	if (other.items & self.items)
		return;

	sprint (other, PRINT_LOW, LOC_ITEM_PICKUP_NORMAL);
	sprint (other, PRINT_LOW, self.netname);
	sprint (other, PRINT_LOW, "\n");

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	other.items = other.items | self.items;

	if (!coop)
	{
		self.solid = SOLID_NOT;
		self.model = string_null;
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


void() key_setsounds =
{
	if (world.worldtype == 0)
	{
		precache_sound ("misc/medkey.wav");
		self.noise = "misc/medkey.wav";
	}

	if (world.worldtype == 1)
	{
		precache_sound ("misc/runekey.wav");
		self.noise = "misc/runekey.wav";
	}

	if (world.worldtype == 2)
	{
		precache_sound2 ("misc/basekey.wav");
		self.noise = "misc/basekey.wav";
	}
};

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
{
    model({"path": "progs/w_s_key.mdl", "skin": 0, "frame": 0});
}
SILVER key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key1 =
{
	if (world.worldtype == 0)
	{
		precache_model ("progs/w_s_key.mdl");
		setmodel (self, "progs/w_s_key.mdl");
		self.netname = LOC_KEY_NAME_SILVER;
	}

	else if (world.worldtype == 1)
	{
		precache_model ("progs/m_s_key.mdl");
		setmodel (self, "progs/m_s_key.mdl");
		self.netname = LOC_KEY_NAME_SILVER_RUNE;
	}

	else if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_s_key.mdl");
		setmodel (self, "progs/b_s_key.mdl");
		self.netname = LOC_KEY_NAME_SILVER_CARD;
	}

	key_setsounds();
	self.touch = key_touch;
	self.items = IT_KEY1;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
{
    model({"path": "progs/w_g_key.mdl", "skin": 0, "frame": 0});
}
GOLD key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key2 =
{
	if (world.worldtype == 0)
	{
		precache_model ("progs/w_g_key.mdl");
		setmodel (self, "progs/w_g_key.mdl");
		self.netname = LOC_KEY_NAME_GOLD;
	}

	if (world.worldtype == 1)
	{
		precache_model ("progs/m_g_key.mdl");
		setmodel (self, "progs/m_g_key.mdl");
		self.netname = LOC_KEY_NAME_GOLD_RUNE;
	}

	if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_g_key.mdl");
		setmodel (self, "progs/b_g_key.mdl");
		self.netname = LOC_KEY_NAME_GOLD_CARD;
	}

	key_setsounds();
	self.touch = key_touch;
	self.items = IT_KEY2;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};



/*
===============================================================================

END OF LEVEL RUNES

===============================================================================
*/

void() sigil_touch =
{
	if (other.classname != "player")
		return;

	if (other.health <= 0)
		return;

#ifdef __LIBREQUAKE__

	string msg;

	// Announce collection of rune
	if (self.spawnflags & 1)
		msg = LOC_RUNE_LQ_BLOOD;
	else if (self.spawnflags & 2)
		msg = LOC_RUNE_LQ_BONE;
	else if (self.spawnflags & 4)
		msg = LOC_RUNE_LQ_MIND;
	else if (self.spawnflags & 8)
		msg = LOC_RUNE_LQ_SOUL;
	else
		msg = string_null;

	if (msg != string_null) {
		bprint (PRINT_HIGH, other.netname);
		bprint (PRINT_HIGH, msg);
		bprint (PRINT_HIGH, "\n");
		centerprint2 (other, LOC_RUNE_LQ_YOU, msg);
	} 

#else

	centerprint(other, LOC_RUNE_GET);

#endif // __LIBREQUAKE__

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	self.model = string_null;
	serverflags = serverflags | (self.spawnflags & 15);
	self.classname = string_null;		// so rune doors won't find it

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
{
    model({"path": "progs/end1.mdl", "skin": 0, "frame": 0});
}
End of level sigil, pick up to end episode and return to jrstart.
*/

void() item_sigil =
{
	if (!self.spawnflags)
		objerror ("no spawnflags");

	precache_sound ("misc/runekey.wav");
	self.noise = "misc/runekey.wav";

	if (self.spawnflags & 1)
	{
		precache_model ("progs/end1.mdl");
		setmodel (self, "progs/end1.mdl");
	}

	if (self.spawnflags & 2)
	{
		precache_model2 ("progs/end2.mdl");
		setmodel (self, "progs/end2.mdl");
	}

	if (self.spawnflags & 4)
	{
		precache_model2 ("progs/end3.mdl");
		setmodel (self, "progs/end3.mdl");
	}

	if (self.spawnflags & 8)
	{
		precache_model2 ("progs/end4.mdl");
		setmodel (self, "progs/end4.mdl");
	}

	self.touch = sigil_touch;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*
===============================================================================

POWERUPS

===============================================================================
*/

void() powerup_touch =
{

	if (other.classname != "player")
		return;

	if (other.health <= 0)
		return;

	sprint (other, PRINT_LOW, LOC_ITEM_PICKUP_NORMAL);
	sprint (other, PRINT_LOW, self.netname);
	sprint (other, PRINT_LOW, "\n");

	if (deathmatch)
	{
		self.mdl = self.model;

		if ((self.classname == "item_artifact_invulnerability") || (self.classname == "item_artifact_invisibility"))
			self.nextthink = time + 60*5;
		else
			self.nextthink = time + 60;

		self.think = SUB_regen;
	}

	sound (other, CHAN_AUTO, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	other.items = other.items | self.items;
	self.model = string_null;

	// do the apropriate action
	if (self.classname == "item_artifact_envirosuit")
	{
		other.rad_time = 1;
		other.radsuit_finished = time + 30;
	}

	if (self.classname == "item_artifact_invulnerability")
	{
		other.invincible_time = 1;
		other.invincible_finished = time + 30;
	}

	if (self.classname == "item_artifact_invisibility")
	{
		other.invisible_time = 1;
		other.invisible_finished = time + 30;
	}

	if (self.classname == "item_artifact_super_damage")
	{
		if (deathmatch_supermode())
		{
			other.armortype = 0;
			other.armorvalue = 0;
			other.ammo_cells = 0;
		}
		other.super_time = 1;
		other.super_damage_finished = time + 30;
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};



/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
{
    model({"path": "progs/invulner.mdl", "skin": 0, "frame": 0});
}
Player is invulnerable for 30 seconds
*/
void() item_artifact_invulnerability =
{
	if (deathmatch_no_powerups())
		return;

	self.touch = powerup_touch;

	precache_model ("progs/invulner.mdl");
	precache_sound ("items/protect.wav");
	precache_sound ("items/protect2.wav");
	precache_sound ("items/protect3.wav");
	self.noise = "items/protect.wav";
	setmodel (self, "progs/invulner.mdl");
	self.netname = LOC_ITEM_NAME_PENTPROT;

#ifdef __QW__ // EF_RED is not supported in NQ
	self.effects = self.effects | EF_RED;
#endif

	self.items = IT_INVULNERABILITY;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
{
    model({"path": "progs/suit.mdl", "skin": 0, "frame": 0});
}
Player takes no damage from water or slime for 30 seconds
*/
void() item_artifact_envirosuit =
{
	self.touch = powerup_touch;

	precache_model ("progs/suit.mdl");
	precache_sound ("items/suit.wav");
	precache_sound ("items/suit2.wav");
	self.noise = "items/suit.wav";
	setmodel (self, "progs/suit.mdl");
	self.netname = LOC_ITEM_NAME_BIOSUIT;
	self.items = IT_SUIT;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};


/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
{
    model({"path": "progs/invisibl.mdl", "skin": 0, "frame": 0});
}
Player is invisible for 30 seconds
*/
void() item_artifact_invisibility =
{
	if (deathmatch_no_powerups())
		return;

	self.touch = powerup_touch;

	precache_model ("progs/invisibl.mdl");
	precache_sound ("items/inv1.wav");
	precache_sound ("items/inv2.wav");
	precache_sound ("items/inv3.wav");
	self.noise = "items/inv1.wav";
	setmodel (self, "progs/invisibl.mdl");
	self.netname = LOC_ITEM_NAME_SHADRING;
	self.items = IT_INVISIBILITY;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
{
    model({"path": "progs/quaddama.mdl", "skin": 0, "frame": 0});
}
The next attack from the player will do 4x damage
*/
void() item_artifact_super_damage =
{
	if (deathmatch_no_powerups())
		return;

	self.touch = powerup_touch;

	precache_model ("progs/quaddama.mdl");
	precache_sound ("items/damage.wav");
	self.noise = "items/damage.wav";
	setmodel (self, "progs/quaddama.mdl");

	if (deathmatch_supermode())
		self.netname = LOC_ITEM_NAME_OCTDMG;
	else
		self.netname = LOC_ITEM_NAME_QUADDMG;

#ifdef __QW__ // EF_BLUE is not supported in NQ
	self.effects = self.effects | EF_BLUE;
#endif

	self.items = IT_QUAD;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};



/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

//the entirety of BackpackTouch
//copypasta'd directly from gpl'd qw source on github.
void() BackpackTouch =
{
	local string    s;
	local   float   best, old, new;
	local           entity  stemp;
	local   float   acount;

	if (deathmatch_supermode())
		if (other.invincible_time > 0)
			return;

	if (other.classname != "player")
		return;

	if (other.health <= 0)
		return;

	acount = 0;
 	sprint (other, PRINT_LOW, LOC_ITEM_PICKUP_NORMAL);

	// Deathmatch 4 functionality
	if (deathmatch_supermode())
	{
		other.health = other.health + 10;
		sprint (other, PRINT_LOW, "10");
		sprint (other, PRINT_LOW, LOC_ITEM_PICKUP_ADD_HEALTH);
		sprint (other, PRINT_LOW, "\n");
		if ((other.health > 250) && (other.health < 300))
			sound (other, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
		else
			sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
		stuffcmd (other, "bf\n");
		remove(self);

		if (other.health > 299)
		{
			if (other.invincible_time != 1)
			{
				other.invincible_time = 1;
				other.invincible_finished = time + 30;
				other.items = other.items | IT_INVULNERABILITY;

				other.super_time = 1;
				other.super_damage_finished = time + 30;
				other.items = other.items | IT_QUAD;

				other.ammo_cells = 0;

				sound (other, CHAN_VOICE, "boss1/sight1.wav", 1, ATTN_NORM);
				stuffcmd (other, "bf\n");
				bprint (PRINT_HIGH, other.netname);
				bprint (PRINT_HIGH, LOC_BONUS_POWERS);
				bprint (PRINT_HIGH, "\n");
			}
		}
		self = other;
		return;
	}

	if (self.items)
	{
		if ((other.items & self.items) == 0)
		{
			acount = 1;
			sprint (other, PRINT_LOW, self.netname);
		}
 	}

	// if the player was using his best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;

	// change weapons
	other.ammo_shells = other.ammo_shells + self.ammo_shells;
	other.ammo_nails = other.ammo_nails + self.ammo_nails;
	other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
	other.ammo_cells = other.ammo_cells + self.ammo_cells;

	new = self.items;
	if (!new)
		new = other.weapon;

	old = other.items;
	other.items = other.items | self.items;

	bound_other_ammo ();

	if (self.ammo_shells)
	{
		if (acount)
			sprint(other, PRINT_LOW, ", ");

		acount = 1;
		s = ftos(self.ammo_shells);
		sprint (other, PRINT_LOW, s);
		sprint (other, PRINT_LOW, " ");
		sprint (other, PRINT_LOW, LOC_WEAPON_AMMO_SHELLS);
	}

	if (self.ammo_nails)
	{
		if (acount)
			sprint(other, PRINT_LOW, ", ");

		acount = 1;
		s = ftos(self.ammo_nails);
		sprint (other, PRINT_LOW, s);
		sprint (other, PRINT_LOW, " ");
		sprint (other, PRINT_LOW, LOC_WEAPON_AMMO_NAILS);
	}

	if (self.ammo_rockets)
	{
		if (acount)
			sprint(other, PRINT_LOW, ", ");

		acount = 1;
		s = ftos(self.ammo_rockets);
		sprint (other, PRINT_LOW, s);
		sprint (other, PRINT_LOW, " ");
		sprint (other, PRINT_LOW, LOC_WEAPON_AMMO_ROCKETS);
	}
	if (self.ammo_cells)
	{
		if (acount)
			sprint(other, PRINT_LOW, ", ");

		acount = 1;
		s = ftos(self.ammo_cells);
		sprint (other, PRINT_LOW, s);
		sprint (other, PRINT_LOW, " ");
		sprint (other, PRINT_LOW, LOC_WEAPON_AMMO_CELLS);
	}

	// sprint (other, PRINT_LOW, LOC_ITEM_FROM_BACKPACK);
	sprint (other, PRINT_LOW, "\n");

	// If backpack has a grenade or rocket launcher in it, fill it with at least five rockets
	if ( deathmatch_backpack_min_rockets() && ( (WeaponCode(new)==6) || (WeaponCode(new)==7) ) && (other.ammo_rockets < 5) )
		other.ammo_rockets = 5;

	// backpack touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	remove(self);
	self = other;

	// change to the weapon

		if (self.flags & FL_INWATER)
		{
			if (new != IT_LIGHTNING)
			{
				Deathmatch_Weapon (old, new);
			}
		}

		else
		{
			Deathmatch_Weapon (old, new);
		}

	W_SetCurrentAmmo ();

};


/*===============
DropBackpack
===============*/
void() DropBackpack =
{
	local entity    item;

	if (!(self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells))
		return; // nothing in it

	item = spawn();
	item.origin = self.origin - '0 0 24';

	item.items = self.weapon;

	if (item.items == IT_AXE)
		item.netname = LOC_WEAPON_NAME_AXE;
	else if (item.items == IT_SHOTGUN)
		item.netname = LOC_WEAPON_NAME_SHOTGUN;
	else if (item.items == IT_SUPER_SHOTGUN)
		item.netname = LOC_WEAPON_NAME_SUPER_SHOTGUN;
	else if (item.items == IT_NAILGUN)
		item.netname = LOC_WEAPON_NAME_NAILGUN;
	else if (item.items == IT_SUPER_NAILGUN)
		item.netname = LOC_WEAPON_NAME_SUPER_NAILGUN;
	else if (item.items == IT_GRENADE_LAUNCHER)
		item.netname = LOC_WEAPON_NAME_GRENADE_LAUNCH;
	else if (item.items == IT_ROCKET_LAUNCHER)
		item.netname = LOC_WEAPON_NAME_ROCKET_LAUNCH;
	else if (item.items == IT_LIGHTNING)
		item.netname = LOC_WEAPON_NAME_THUNDERBOLT;
	else
		item.netname = LOC_ITEM_NAME_BACKPACK;

	item.ammo_shells = self.ammo_shells;
	item.ammo_nails = self.ammo_nails;
	item.ammo_rockets = self.ammo_rockets;
	item.ammo_cells = self.ammo_cells;

	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);

	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;

	item.nextthink = time + 120;    // remove after 2 minutes
	item.think = SUB_Remove;
};
