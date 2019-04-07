#define FILTERSCRIPT

#include <a_samp>
#include <foreach>     
#include <progress2>    
#include <zcmd>        

#define BULLET_BATTERY_MIN       120 // 120 minutes, or 2 hours. This is the battery time.
#define UPDATE_BULLET_POS_SEC    1 // 1 sec. How long will the GPS Bullet updates its position.

#define GPS_Bullet_Menu          26969 // GPS bullet Menu
#define GPS_Bullet_Acquire       26900 // Acquire Bullet Menu
#define GPS_Bullet_Configure     20690 // Configure Bullet Menu
#define GPS_Bullet_CeaseMsg      20069 // Cease Confirmation Msg

#define GPSB_SniperCost          15000 // Cost of GPS Bullet Sniper Rifle
#define GPSB_PistolCost          12000 // Cost of GPS Bullet Silenced Pistol

enum GPSB
{
	bool: GPSBulletuser,
	GPSBulletusedon,
	bool: GPSBulletvictim,
	bool: GPSBulletactivated,
};
new BPlayer[MAX_PLAYERS][GPSB];

new RGY[100] = // forum.sa-mp.com/showpost.php?p=3372369&postcount=19, tnx for saving my time <3
{
    0xFF0000FF,0xFF0500FF,0xFF0A00FF,0xFF0F00FF,0xFF1400FF,0xFF1900FF,0xFF1E00FF,0xFF2300FF,0xFF2800FF,0xFF2D00FF,
    0xFF3300FF,0xFF3800FF,0xFF3D00FF,0xFF4200FF,0xFF4700FF,0xFF4C00FF,0xFF5100FF,0xFF5600FF,0xFF5B00FF,0xFF6000FF,
    0xFF6600FF,0xFF6B00FF,0xFF7000FF,0xFF7500FF,0xFF7A00FF,0xFF7F00FF,0xFF8400FF,0xFF8900FF,0xFF8E00FF,0xFF9300FF,
    0xFF9900FF,0xFF9E00FF,0xFFA300FF,0xFFA800FF,0xFFAD00FF,0xFFB200FF,0xFFB700FF,0xFFBC00FF,0xFFC100FF,0xFFC600FF,
    0xFFCC00FF,0xFFD100FF,0xFFD600FF,0xFFDB00FF,0xFFE000FF,0xFFE500FF,0xFFEA00FF,0xFFEF00FF,0xFFF400FF,0xFFF900FF,
    0xFFFF00FF,0xF9FF00FF,0xF4FF00FF,0xEFFF00FF,0xEAFF00FF,0xE4FF00FF,0xDFFF00FF,0xDAFF00FF,0xD5FF00FF,0xD0FF00FF,
    0xCAFF00FF,0xC5FF00FF,0xC0FF00FF,0xBBFF00FF,0xB6FF00FF,0xB0FF00FF,0xABFF00FF,0xA6FF00FF,0xA1FF00FF,0x9CFF00FF,
    0x96FF00FF,0x91FF00FF,0x8CFF00FF,0x87FF00FF,0x82FF00FF,0x7CFF00FF,0x77FF00FF,0x72FF00FF,0x6DFF00FF,0x68FF00FF,
    0x62FF00FF,0x5DFF00FF,0x58FF00FF,0x53FF00FF,0x4EFF00FF,0x48FF00FF,0x43FF00FF,0x3EFF00FF,0x39FF00FF,0x34FF00FF,
    0x2EFF00FF,0x29FF00FF,0x24FF00FF,0x1FFF00FF,0x1AFF00FF,0x14FF00FF,0x0FFF00FF,0x0AFF00FF,0x05FF00FF,0x00FF00FF
};

new TrackBulletswitch[MAX_PLAYERS];
new BatteryBulletswitch[MAX_PLAYERS];

new BatteryTick[MAX_PLAYERS],
    GPSTick[MAX_PLAYERS];

new PlayerBar:Battery[MAX_PLAYERS], 
    PlayerText:BulletTD[MAX_PLAYERS];

public OnFilterScriptInit()
{
	print("______________________________________________________");
	print(" ");
	print("GPS Bullet v0.9 by Jiizutin Kiru (MicroKyrr) loaded  ");
	print("github.com/Kiiruuu & myanimelist.net/profile/Kiiruuu ");
	print(" ");
	print("______________________________________________________");
	return 1;
}

public OnFilterScriptExit()
{
	print("____________________________");
	print(" ");
	print("GPS Bullet v0.9 unloaded");
	print(" ");
	print("___________________________");
	return 1;
}

public OnPlayerConnect(playerid)
{
	// Create Textdraw
	BulletTD[playerid] = CreatePlayerTextDraw(playerid, 497.0000, 117.0000, "Bullet_Life:");
    PlayerTextDrawFont(playerid, BulletTD[playerid], 1);
    PlayerTextDrawLetterSize(playerid, BulletTD[playerid], 0.5000, 1.0000);
    PlayerTextDrawColor(playerid, BulletTD[playerid], -1);
    PlayerTextDrawSetShadow(playerid, BulletTD[playerid], 0);
    PlayerTextDrawSetOutline(playerid, BulletTD[playerid], 1);
    PlayerTextDrawBackgroundColor(playerid, BulletTD[playerid], 255);
    PlayerTextDrawSetProportional(playerid, BulletTD[playerid], 1);
    PlayerTextDrawTextSize(playerid, BulletTD[playerid], 0.0000, 0.0000);

    // Create Progress bar
    Battery[playerid] = CreatePlayerProgressBar(playerid, 500.00, 130.00, 110, 7, 16711935, 100, 0);

    ResetVariables(playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	ResetVariables(playerid);
	KillTimer(BatteryTick[playerid]);
	KillTimer(GPSTick[playerid]);
	PlayerTextDrawDestroy(playerid, BulletTD[playerid]);
	DestroyPlayerProgressBar(playerid, Battery[playerid]);
	DisablePlayerCheckpoint(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if (BPlayer[playerid][GPSBulletusedon] != -1)
	{
		ResetVariables(playerid);
		KillTimer(BatteryTick[playerid]);
		KillTimer(GPSTick[playerid]);
		PlayerTextDrawHide(playerid, BulletTD[playerid]);
		HidePlayerProgressBar(playerid, Battery[playerid]);
		DisablePlayerCheckpoint(playerid);
		BPlayer[playerid][GPSBulletactivated] = false;
	}	

	if (BPlayer[playerid][GPSBulletvictim] == true)
	{
		foreach(new i: Player)
	    {
		    if (BPlayer[i][GPSBulletusedon] == playerid)
		    {
		    	ResetVariables(playerid);
		    	BPlayer[i][GPSBulletuser] = false;
                BPlayer[i][GPSBulletusedon] = -1;
                BPlayer[i][GPSBulletvictim] = false;
                BPlayer[i][GPSBulletactivated] = false;
                BatteryBulletswitch[i] = 0;
                TrackBulletswitch[i] = 0;
                KillTimer(BatteryTick[i]);
		        KillTimer(GPSTick[i]);
		        PlayerTextDrawHide(i, BulletTD[i]);
		        HidePlayerProgressBar(i, Battery[i]);
		        DisablePlayerCheckpoint(playerid);
		    	SendClientMessage(playerid, -1, "Someone removed your GPS bullet, it could be a doctor!");
		    }
		}
	}		
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if (BPlayer[playerid][GPSBulletuser] == true && weaponid == 34 || 23)
		BPlayer[playerid][GPSBulletuser] = false;
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
	if (BPlayer[playerid][GPSBulletuser] == true && weaponid == 34 || 23)
	{
	    BPlayer[playerid][GPSBulletusedon] = damagedid; 
		BPlayer[playerid][GPSBulletactivated] = true;
        BatteryBulletswitch[playerid] = 1;
		TrackBulletswitch[playerid] = 1;
	    SetPlayerProgressBarValue(playerid, Battery[playerid], 100);
        SetPlayerProgressBarColour(playerid, Battery[playerid], RGY[99]);
        ShowPlayerProgressBar(playerid, Battery[playerid]);
	    PlayerTextDrawShow(playerid, BulletTD[playerid]);
	    GPSTick[playerid] = SetTimerEx("BulletPPos", UPDATE_BULLET_POS_SEC*1000, true, "i", playerid); // Don't tamper with the 1000 value
        BatteryTick[playerid] = SetTimerEx("BatteryLife", 500, true, "i", playerid); // Don't tamper with the 600 value
	}	
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if (dialogid == GPS_Bullet_Menu)
	{
		if (response)
		{
			if (listitem == 0)
			{
				if (BPlayer[playerid][GPSBulletuser] != false)
					return SendClientMessage(playerid, -1, "Either you already bought one or have an active GPS bullet.");

				if (BPlayer[playerid][GPSBulletactivated] == true)
					return SendClientMessage(playerid, -1, "You have an active GPS bullet.");


				ShowPlayerDialog(playerid, GPS_Bullet_Acquire, DIALOG_STYLE_TABLIST, "Choose your weapon", "Sniper Rifle\t$15000\nSilenced Pistol\t$12000", "Select", "SAMP 0.3.8");
			}

			if (listitem == 1)
			{
				if (BPlayer[playerid][GPSBulletuser] == true)
					return SendClientMessage(playerid, -1, "You haven't use your GPS bullet yet.");

				if (BPlayer[playerid][GPSBulletactivated] != true)
					return SendClientMessage(playerid, -1, "You have no active GPS bullet.");

				ShowPlayerDialog(playerid, GPS_Bullet_Configure, DIALOG_STYLE_LIST, "Configure your Bullet", "Track Bullet\nCease Bullet\n{FFFF00}Toggle{FFFFFF} Battery Info", "Select", "SAMP 0.3.8");
			}	
		}	
	}

	if (dialogid == GPS_Bullet_Acquire)
	{
		if (response)
		{
			if (listitem == 0)
			{
				if (GetPlayerMoney(playerid) >= GPSB_SniperCost)
				{
					BPlayer[playerid][GPSBulletuser] = true;
					GivePlayerMoney(playerid, -GPSB_SniperCost);
			     	GivePlayerWeapon(playerid, 34, 1);
				}
				else SendClientMessage(playerid, -1, "You don't have a sufficient money.")	;
			}

			if (listitem == 1)
			{
				if (GetPlayerMoney(playerid) >= GPSB_PistolCost)
				{
					BPlayer[playerid][GPSBulletuser] = true;	
					GivePlayerMoney(playerid, -GPSB_PistolCost);
				    GivePlayerWeapon(playerid, 23, 1);
				}
				else SendClientMessage(playerid, -1, "You don't have a sufficient money.");	
			}	
		}
	}

	if (dialogid == GPS_Bullet_Configure)
	{
		if (response)
		{
			if (listitem == 0)
			{
				if (TrackBulletswitch[playerid] == 1)
				{
					TrackBulletswitch[playerid] = 0;
					KillTimer(GPSTick[playerid]);
					DisablePlayerCheckpoint(playerid);
					SendClientMessage(playerid, -1, "GPS bullet position undisplayed on radar.");
				}
				else
				{
					TrackBulletswitch[playerid] = 1;
				    GPSTick[playerid] = SetTimerEx("BulletPPos", UPDATE_BULLET_POS_SEC*1000, true, "i", playerid); // Don't tamper with the 1000 value
					SendClientMessage(playerid, -1, "GPS bullet position displayed on radar.");
				}	
			}

			if (listitem == 1)
			{
				ShowPlayerDialog(playerid, GPS_Bullet_CeaseMsg, DIALOG_STYLE_MSGBOX, "Cease Bullet Confirmation", "Are you sure you want to {FF0000}cease{FFFFFF} your bullet?", "Confirm", "SAMP 0.3.8");
			}

			if (listitem == 2)
			{
		         if (BatteryBulletswitch[playerid] == 1)
		         {
		         	BatteryBulletswitch[playerid] = 0;
		         	PlayerTextDrawHide(playerid, BulletTD[playerid]);
		         	HidePlayerProgressBar(playerid, Battery[playerid]);
		         	SendClientMessage(playerid, -1, "You have turned {FF0000}off{FFFFFF} your Battery Info Display.");
		         }
		         else
		         {
		         	BatteryBulletswitch[playerid] = 1;
		         	PlayerTextDrawShow(playerid, BulletTD[playerid]);
		         	ShowPlayerProgressBar(playerid, Battery[playerid]);
		         	SendClientMessage(playerid, -1, "You have turned on your Battery Info Display.");
		         }	
			}	
		}	
	}

	if (dialogid == GPS_Bullet_CeaseMsg)
	{
		if (response)
		{
			ResetVariables(playerid);
	    	KillTimer(BatteryTick[playerid]);
	    	KillTimer(GPSTick[playerid]);
	    	PlayerTextDrawHide(playerid, BulletTD[playerid]);
	    	HidePlayerProgressBar(playerid, Battery[playerid]);
	    	DisablePlayerCheckpoint(playerid);
		    SendClientMessage(playerid, -1, "You have successfully ceased your GPS bullet.");
		}
	}	
	return 1;
}

CMD:gpsb(playerid, params[])
{
	if (!IsLawEnforcer(GetPlayerSkin(playerid)))
		return SendClientMessage(playerid, -1, "You don't have an {FF0000}authority{FFFFFF}. (Law Enforcer is a must)");

	ShowPlayerDialog(playerid, GPS_Bullet_Menu, DIALOG_STYLE_LIST, "GPS Bullet Menu", "Acquire Bullet\nConfigure Bullet", "Select", "SAMP 0.3.8");
	return 1;
}

// CUSTOM FUNCTIONS

stock IsLawEnforcer(skinid) // Checks if a player is a law enforcer based from his/her skin.
{
    switch(skinid)
    {
        case 265..267, 280..288, 300..302, 306, 307, 309..311: return 1;
        default: return 0;
    }
    return 0;
}

ResetVariables(playerid)
{
	BPlayer[playerid][GPSBulletuser] = false;
    BPlayer[playerid][GPSBulletusedon] = -1;
    BPlayer[playerid][GPSBulletvictim] = false;
    BPlayer[playerid][GPSBulletactivated] = false;
    BatteryBulletswitch[playerid] = 0;
    TrackBulletswitch[playerid] = 0;
    return 1;
}

forward BulletPPos(playerid);
public BulletPPos(playerid)
{
	foreach(new i: Player)
	{
		if (BPlayer[i][GPSBulletvictim] == true) continue;
		if (BPlayer[playerid][GPSBulletusedon] == i)
		{
			new Float:X, Float:Y, Float:Z;
			GetPlayerPos(i, X, Y, Z);
			SetPlayerCheckpoint(playerid, X, Y, Z, 0);
		}
	}		
	return 1;
}

forward BatteryLife(playerid);
public BatteryLife(playerid)
{
	new Float: batterybar = GetPlayerProgressBarValue(playerid, Battery[playerid]);
	batterybar -= 1.0;
	SetPlayerProgressBarValue(playerid, Battery[playerid], batterybar);

	if (batterybar < 100.0)
	    SetPlayerProgressBarColour(playerid, Battery[playerid], RGY[floatround(batterybar)]);

	if (batterybar <= 0.0)
	{
		foreach(new i: Player)
		{
			if (BPlayer[i][GPSBulletvictim] == true) continue;
	     	if (BPlayer[playerid][GPSBulletusedon] == i)
	     	{
	     	    KillTimer(BatteryTick[playerid]);
		        HidePlayerProgressBar(playerid, Battery[playerid]);
		        BPlayer[i][GPSBulletvictim] = false;
		        PlayerTextDrawHide(playerid, BulletTD[playerid]); 
	         	ResetVariables(playerid);
		        KillTimer(GPSTick[playerid]);
		        DisablePlayerCheckpoint(playerid);
		        SendClientMessage(playerid, -1, "Your GPS Bullet ran out of battery.");
	     	}	
		}      
	}    	
	return 1;
}