main(phase, register)
{
    switch(phase) {
        case "init": _init(register); break;
        case "load": _load(); break;
    }
}

_init(register)
{
    if(isDefined(level.modmmccbycato1))
        return;
    level.modmmccbycato1 = true;

    // Add your own CoDaM takeover/threads etc here
    // ...
}

_load()
{
    if(isDefined(level.modmmccbycato2))
        return;
    level.modmmccbycato2 = true;

    // Example: custom commands
    commands(150, level.prefix + "buyserver"  , ::cmd_buyserver    , "Want to buy a server? ["+ level.prefix + "buyserver]");
    commands(155, level.prefix + "maplist"    , ::cmd_maplist      , "List maps on the server. ["+ level.prefix + "maplist]");

    // Example: command override
    commands( 24, level.prefix + "unban"      , ::cmd_unban        , "Unban player. [" + level.prefix + "unban <ip>]");
}

commands(id, cmd, func, desc)
{
    if(!isDefined(level.commands[cmd]))
        level.help[level.help.size]["cmd"] = cmd;

    level.commands[cmd]["func"] = func;
    level.commands[cmd]["desc"] = desc;
    level.commands[cmd]["id"]   = id;
}

message_player(msg)
{
    codam\_mm_commands::message_player(msg);
}

message(msg)
{
    codam\_mm_commands::message(msg);
}

cmd_buyserver(args)
{
    message_player("You can ^2easily ^7buy a ^3server^7!");
    message_player("^1Public ^7& ^1Private ^7servers are ^2available^7!");
    message_player("Payment: ^2PayPal");
    message_player("");
}

cmd_unban(args)
{
    if(args.size != 2) {
        message_player("^1ERROR: ^7Invalid number of arguments.");
        return;
    }

    if(level.banactive) {
        message_player("^1ERROR: ^7Database is already in use. Try again.");
        return;
    }

    bannedip = args[1]; // IP
    if(!isDefined(bannedip)) {
        message_player("^1ERROR: ^7Invalid argument.");
        return;
    }

    if(!codam\_mm_commands::valid_ip(bannedip)) {
        message_player("^1ERROR: ^7Invalid IP address.");
        return;
    }

    banindex = codam\_mm_commands::isbanned(bannedip);
    if(banindex != -1) {
        message_player("^5INFO: ^7You unbanned IP: " + bannedip);
        message(level.bans[banindex]["name"] + " ^7got unbanned by " + codam\_mm_mmm::namefix(self.name) + "^7.");
        codam\_mm_mmm::mmlog("unban;" + bannedip + ";" + level.bans[banindex]["name"] + ";" + level.bans[banindex]["time"] + ";" + level.bans[banindex]["srvtime"] + ";" + level.bans[banindex]["by"] + ";" + codam\_mm_mmm::namefix(self.name));

        filename = level.workingdir + "unbans.dat";
        if(fexists(filename)) {
            file = fopen(filename, "a"); // append
            if(file != -1) {
                line = "";
                line += level.bans[banindex]["ip"];
                line += "%%" + level.bans[banindex]["by"];
                line += "%%" + level.bans[banindex]["name"];
                line += "%%" + level.bans[banindex]["time"];
                line += "%%" + level.bans[banindex]["srvtime"];
                line += "%%" + level.bans[banindex]["reason"];
                line += "\n";
                fwrite(line, file);
            }
            fclose(file);
        }

        level.bans[banindex]["ip"] = "unbanned";

        level.banactive = true;
        filename = level.workingdir + level.banfile;
        if(fexists(filename)) {
            file = fopen(filename, "w");
            if(file != -1) {
                for(i = 0; i < level.bans.size; i++) {
                    if(level.bans[i]["ip"] == "unbanned")
                        continue;
                    line = "";
                    line += level.bans[i]["ip"];
                    line += "%%" + level.bans[i]["by"];
                    line += "%%" + level.bans[i]["name"];
                    line += "%%" + level.bans[i]["time"];
                    line += "%%" + level.bans[i]["srvtime"];
                    line += "%%" + level.bans[i]["reason"];
                    line += "\n";
                    fwrite(line, file);
                }
            }
            fclose(file);
        } else
            message_player("^1ERROR: ^7Ban database file doesn't exist.");

        level.banactive = false;
    } else
        message_player("^1ERROR: ^7IP not found in loaded banlist.");
}

cmd_maplist(args)
{
    mapRotation = getCvar("sv_mapRotation");
    if(mapRotation == "") {
        message_player("^1ERROR: ^7No maps in mapRotation.");
        return;
    }

    for(i = 1; /*!*/; i++) {
        _cvar = getCvar("sv_mapRotation" + i);
        if(_cvar == "")
            break;
        mapRotation += " " + _cvar;
    }

    mapRotation = codam\_mm_mmm::strTok(mapRotation, " ");
    if(mapRotation[0] != "gametype" || mapRotation.size % 2 != 0) {
        message_player("^1ERROR: ^7Error in mapRotation.");
        return;
    }

    maps = []; gametypes = [];
    for(i = 0; i < mapRotation.size; i += 2) {
        if(mapRotation[i] == "gametype") {
            gametype = mapRotation[i + 1]; // gametype <gametype>
            if(!codam\_mm_mmm::in_array(gametypes, gametype))
                gametypes[gametypes.size] = gametype;
        } else {
            if(!isDefined(maps[gametype]))
                maps[gametype] = [];
            index = maps[gametype].size;
            maps[gametype][index] = mapRotation[i + 1]; // map <map>
        }
    }

    color[0] = "2"; color[1] = "3"; color[2] = "4"; color[3] = "6";
    color = codam\_mm_mmm::array_shuffle(color); color = color[0];
    for(i = 0; i < gametypes.size; i++) {
        gametype = gametypes[i];
        message_player("^5-------------------------^1" + toupper(gametype) + "^5-------------------------");
        message = "";
        for(m = 0; m < maps[gametype].size; m++) {
            message += maps[gametype][m];
            if((m + 1) % 7 == 0) {
                message_player("^" + color + message);
                message = "";
            } else
                message += " ";
        }

        if(m % 7 != 0)
            message_player("^" + color + codam\_mm_mmm::strip(message));
    }
}