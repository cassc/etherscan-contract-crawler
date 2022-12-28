// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OZR Ones
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    :::lllcccllodddxxxxxkkOOOO00KKXXXNNNNWWMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNXXXXXNNNXK0Odooollccclllllooodddolc:::::::;;,,,;;;;;:::ccccccc:::;;;,,,,;;;;;;,,'',,,,;;;;;;:::ccccc::;;;,,'''..''',,''''''',    //
//    ::coolloodddddxxxxxxkkO000KKXXXXNNNNWWWMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNXXNNNNXK0Oxdooollllllooodddddxddolcccccccc:;;;;;;::::ccccc::::;;;,,,,;;;;;;;;,,,,,,;;;;;;::::ccc::::;;,,''....'',,,,,'''''',    //
//    llooooddxxxxxxxxxdxxkkOO0KKXXXXNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNWNNXK0Okxxdooooooooddxxxxxxxddolllllllcc:::::::::::::::::;;;,,,,;;;;;;;;;,,,,,;;;;;:::::ccc::::;;,,,''...'',,,,,,'''','',    //
//    dddooddxxxxxxdddxxxkkkOO0KXXXNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNWWWWWWNNXXXKKOkxddoddxxxxkkkkkxxdooooooollcc:::::::::::;;;;;,,,,,;;;::::;;;,,,,;;;;;::::ccccc::;;;,,,'''.''',,,,,,;,,'''''',    //
//    xddddxxxxxxxddddxkkkOO00KKXNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNX0Oxxxxxxkkkkkkkkxdddoddddolcc:::::::::;;;;;,,,,,;;;::::::;;,,,;;;;;::ccccccc::;;;,,,''''''',,;;,,,,;,,'''''',    //
//    dddddxxxxxxdddxxkOOO000KKXXNNNNWWWNNWWWWWWWWWWWWWWWWWWWNNWWWWMMMMMMMMMWWWWWWWWWWWWWWWWWWWWNXKOkkkxxkkkkOOOkxdddddxxxddolcccccc::::::;;;,,;;;::::::;;;;;;;;;:::cccccc:::;;;;,,'''''',,,;;;;,,,,,,,'''''',    //
//    ddddxxxxxxddxxxkOOO00KKKXXXNNWWWWWWNNNNWWWWWWWWWWWWWWWNNNNWWWMMMMMMMMMMMMMMWWWWWWWWWWWWWWWNNX0OkkkkkkkOOOOOkxxxxkkkkkxdooooolllcccccc::;;;:::::::;;;;;;;;::::cccccc:::;;;,,,''''',,;;;;;;,,,,,,,,'''''',    //
//    ddxxxkxxxddxxkkOOO0000KKKXXNNWWWWWWNNNNNNNNNNWWWWWWWWWNNNNWWWMMMMMMMMMMMMMMMMMMWMWWWWWWWWWNNX0OkkkkOOOOO000OkkOOOOOOOkxdddddooollllllcc:::::::::;;;;;;::::ccccccc:::;;;,,,'''',,,;;;;;;;;,,,,,;,,'''''',    //
//    dxxxxxxxxxxkkkOOOOOkkkkk0KXNNWWWWWWWNNNNNXXNNWWWWWWWWWNNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNX0OOOOOOOO000000OO000OOOOkkxxxxxddoooooollcc::cc:::;;;;:::::ccccccc::;;;;,,,'''',,,;;;;:;;;,,,,,,,,,,'''''',    //
//    xkkkxxxxxkkOOkdc;,'......',:lxKWWWWWWWNNNXKxlccccccccccc:ccccclllclloONMWOollooddddddooollcc:;;;:cldxk00000OOkOOkkkkkkxddddddoooooolcc:,...........;::cccclccc:;;;;,,,'''',,,;;;;:::;;;,,,;,,,,,,'''''',    //
//    kkkkxxxkkOOx:'.   ..',,,'..   .;xXWWWWWWNNk'     ................    .kWNd'..'.       ..'''''...    ..,okOOOkkkkkkkkkkxxdddxxdddddolcc;.           ':ccccccc:::;;,,''''',,,;;;;::::;;,,,;;;,,,,,,'''''''    //
//    kkkkxkkOOx:.   .cdkO0KKKK0Oxc.   'dXWWWWWNk'   :kKXNXXNXXXXNNX0l.   .oXMMWNXNNKl.   ,kKNNNNNX0Okxo;.    ;x000OOOOOOOOOOOOOOOOOOkxdolccc:;;;;,'.    'ccccccc::;;;,,'''',,,;;;;;::::;;;,,;;;;;,,,,,'''''''    //
//    kkkkkkOOd'   .lOKKKKKXXXXXNWWKl.   cKWWWWW0,  ,0WWMMMMMMMMMMXd,   .lKWMMMMMMMMM0'   oWMMMWWWNXKKKK0o,.   lKKKKKKKKKKKKKKKKKKKK0Okxolccccc:::::.    ,ccccc::;;,,,''''',,;;;;,,,,,,,;;,..',;;;,,;;,'..''''    //
//    kkkkOO0x'   .dKKKKKKKXXXXXNWWMWd.   lNMMMMO.  :XMMMMMMMMMWXd'   .oKWMMMMMMMMMMM0'   dWMMMMWWNXKKKKKkl.   lXXXXXXXXXXXXXXXXKKK0Okxdllcccc::::c:.    ;lcc:;;;,,''''',,;;,'..         ..  .,;;;,,;;,'...'..    //
//    kkOO00Oc   .l0KKKKKKXXXXXNNWWWMNc   .kMMMMx.  cNMMMMMMMWXd'   .oKWMMMMMMMMMMMMM0'   dWMMMMWWWXXXXKO:.   'kXXXXXXKKKKKK00000Okxddollllccc::cccc'   .;cc:;;,,,''''',;;;'.    .......     .,;;;;;;;,'......    //
//    kOO000k,   .xKKKKKKKXXXXXXNNWWWWx.   oWMMMXdcl0WWMMMMWKd'   'oKWMMMMMMWWWWMMMMM0'   :O000000Okdoc;.   .ckKXKKKKK000OOOOO000Oxdollllllcccccccll'   .;c::;;;;,,,',,;::'    .;;;:::;;,'   .,;;;,,,''',,,'..    //
//    OO0000x.   ,kKKKXXXXXXXXXNNNWWWMO.   cNMMMMMWWWWWWMWKo'   'dXWMWMMMMMMWWWWMMMMM0'    .......     .'cox0KKKK00KKKK00000KKKKK0Oxooollllccclllloo,   .:lc::::::;;;;;:::.    ,:::::;;;;,.  .,;,,,'',:lool:;,    //
//    O0000Kx'   ,OXXXXXXXXXXNNNNWWWWMk.   lNWWWWWWWWWWWKo.   'dXWWWMWMMMWWWWWWWMMMMM0'   'loooooool:;.  .':kKKK0000KXKOlcccccccc::loooolllclllloodd;   .collllccc::::::cc,.    ..'''''',;,'.',,,,;;:ldxxdoc:;    //
//    KKKKKKO;   .kNNNNNNNXNNNNNNNNWWNo   .dNWWWWWWNNN0o.   ,dXWWWWWWWWWk::oKWWWMMMMM0'   oWMMMMMMWNXXO;    ;OK00x:';xKd.         .'ldooollllooodddx:   .cddooolllcc::cccc:;'..          ...',;::cccloddolc:,'    //
//    XXXXXXXo.   cKNNNNNNNNNNNNNNNNNO'   ,0NNNNNNNXOl.   ,xXNNWWWWWWWWX:  .kWWWMMMMM0'   dWMMMMMWWNNXXo.   .xK0Ol.  :KKOkkkkkkxdoooddooooooodddxxxk:   .cxddoooollcccccc:'.,:c:;,'......     'cllllcc::;,,'..    //
//    XXXXXXX0:   .oXNNNNNNNNNWWWWWNO;   .xXNNNNNN0l.   ,dXNNNNNNNNNNNNXc  .kWWMMMMMM0'   dWMMMMMWWNXXXd.   .d0Okc.  :KNNNNNNNXK0Okxxddooddddxxxkkkk:   .cxxdddooollccccl,  .;cc:::::::c::'    ,llc:;;,''.....    //
//    XXXXXXXX0c.  .:OXNNNNNNWWWWWKd.   'xXXNNNN0l.   ,xXNNNNNNNNNNNNNNKc  'OWWMMMMMMO.   lWMMMMMMWNNNXd.   .o0Okc   cKNNNWWNNNXXXXK0OkxxddxxkkkOOkk;    cxxddddoolllclll;.  .;:::::cccccc:.   'c::;;,,'.....'    //
//    XXXXXXXXXKx,   .,lxO0KKK0Odc.   .l0XXNNNNk'   .cxOOOOOOOOOOOOkkxo;.  .kWWXOO00k;    .oOOOOKNWNNNNk'    'cl:.  .dXNNNWWNNNNNNWNNNX0Okkkxolllll;.    .:ccc::clollllll;.   ..',;;:::;,'.   .;::;;;;,'''''',    //
//    XXXXXXXXXXNXkc,.   ......    .:d0NNNNNNNNx.    ................      'OWNo................;0WNNNNXx;..      .;xXNNNNNNNNNNWWWWWWNXKOOk:.    .  .......    .;oolllll,    .            ..,:::;;;;;,,'',,',    //
//    XXXXXXXXXXNNNNX0xolc:::::coxOKXNXXNNNNNNNXOdolloodddxxdddddddddddooodONWWXkxkOO0KKKK00Okkk0NWNNNNNXK0kdlccldOXNNNNNNNNNWWWWWWWWWNXK000kolcccccoxxkkxdolc::codooollc;...;::,''...''',;:::::;;,,;;,,'',,''    //
//    XXXXXXXXXNNNNNNNNWWNNNNNWWWWWNXXKKKKXXNNNNXXXKXXXXXXXXKKKKKXXXXNNNNXXNNNWWWWWWWWWWWWWWMMMMMMWNNNNNXKK0Okxk0XNNNNNNNNNNWWWWWWWWWWNNKK000OkxdoodkO0KK00OOkkxxxdoolcc:::ccllllllllllllcc:::;;;;,,;;,,''',,'    //
//    XXXXXXNNNNNNNNNNNNNNNNNWWWWWWNX00000KXXNNXXXXXXXXXKKKKKKKKKKXXNNNNNNNNNNNWWWWWWWWWWWWWMMMMMWWNNNNNXKK0Okk0XNNNWNNNNNNWWWWWWWWWWNNNXKK00Oxdooodk0KKKK00Okkkxxdolc::;;:clllllllloollcc:::;;;;;;;;;;,''''''    //
//    XXXNNNNNNNNNNNNNNNNNNNWWWWWWWNXK0000KXXXXXXXKKKKKKKKKKKKKKKKXXNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWNNNNNXX00OkO0XNNNNNNNNNNWWWWWWWWWWWNNNXXK0Oxdoooodk0KKKK00OOkkxdolc:;;;:clooollllolllccc:::;;;;;;;;;;''.....    //
//    XXNNNNNNNNNNXNNNNNNNNNWWWWWWWNXKKKKKKKXXXXXKKKKKKKKKKXXXXKKKXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXKOOkOKXNNNNNNNNNNWWWWNNNWWWWWNNNXXK0Oxoooodxk0KKKKK0OOkxdolc:::::ccooooolllllccc::::;;;;:;;;;,'''.....    //
//    XXNXXXXNNNXXXNNNNNNNNWWWWWWWWNXXXXXXKKKXXXXXKKKKKKKKKXXXXKKXXXNNNNNNNNNNNNNNNNNNNXXXXXXXXXXXXXXXXK0OOOKXNNWWNNNNNNNWWWNNNNWWWWWWNNNXXKOxdooodxO0KKXKK0Okxdolc::::ccclooooolllccc:::;;;;;;;;;,,,,;::c:;,,    //
//    NNNNXXXNNNNNNNNNNNNWWWWWWWWWWNNXXXXXXXXXXXXXXKK0000000000000KXNNNNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXKK00KKXNNWWWNNNWWNNNNNNNNNNWWWWWWNNXXKOkxddddxO0KXKK0Okdollccccccccclloooollcc:::;;;;;;;;;;;;;;codxxol:;    //
//    NNNNNNNNNNNNNNNWWWWWWWWWWWWWWNNNNXXXXXXK0kxdoollloooollloooddxOXWWWWWWWNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXNNNWWWWWWWWWNNNNNNNNNNWWWWWWNNNXK0kxxxxxxO0KKK0Oxdollllllllccclloodoolcc::::;;;;;;:::ccccldxkkxol:;    //
//    NNNNNNNNNNWWWWWWWWWWWWWWWWWWWWNNNNXNX0xl:;;;;;;;::cccccccllllloxKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNWWWWWWWWWWNNNNNNNNWWWWWWWWWNNNXK0OkxxxxkO000Okxxdolloooolllloodddddolc:::::::::ccclooooooddollc;,'    //
//    NNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWNNNXOl;,,,,,,;;;;::ccccllllllllokNMMWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNWWWWWWWWWWWNNNXK0OkkkkkOOOOkkkkxxddoooooooodxxxxxdolc:::::cccloooooooollcc:;;,,''.    //
//    NNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWNNKo;,,,,;;;;;;::::ccllcccllllld0WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNWWWWWWWWWWWNNNNNXK0OkkOOOOOkxxkkOOkxdddddddxxkkkxdolccccccclloooooollcc::;;,,'''....    //
//    NNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWNNNk:,,;;;;;;;;;;::::cccccccclllokNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNWWWWWNNNNNWNNNNNNNXK0OOOOOOOkxdxk000Okxdddxxkkkkxxdolcccllooooooollcc::;;;,,,,'''''...    //
//    NNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWNNXd;,,;,,,;;;;;;::::cccclllllllldKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNWWWWNNNNNWWNNNNNNXXK00OOOkxxddxO0KK0OkxkkOOOkkxdollclloodoollccc::;;;;;;;;,,,''''''..    //
//    NNNNNNNNWNNNNNWWWWWWWWWWWWWWWWWNNN0o;,,,,;;;;;;;;:::::cccccccllllokNMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNWWWNNNNNNNNNNNWWWNNNNNXXK00OOkxxxxxk0KKK00OOOOOOkxdooooooodddolc::;;;;;;;;;;;;;,,,'''''''.    //
//    NNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWNNNk:;,,,;;;;;;;;;;;;;:::cccccclllldKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWWWNNNNNNNNNNNWWWWNNNNXXK0OkkxxxxkkO0KKKK0000Okxddooodddddoolc:;;;;;;;;;;;;,,,,,,,,''''''.    //
//    NNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWXd;,,,,,,,;;;;;;;;;:::::ccccccccclkNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNNNWWWWNNNXXK0OkkkkkkkkOO0KKKK00Okkxdooddxxddollc::;;,,,,;;;,,,,,,,,,,,''''''''    //
//    NNNNNNNNNNNNNNNNNNNNNXK0OOOOO00KXKo;;;;,,;;::ccccccllllooooooooollldKWWWWWWWWWWWWWNNNWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNWWWWWWNNNXKK0OkkkkkkkOO00KKKK0Okxddddddxxxdolcc:::;;,,,,,,,,,,,,,,,,,,,,'''''''    //
//    NNNNNNNNNNNNNNNNNNWNOl:;;;;;;:::cc::::::cclodxxxxxxkkkkkkkkkkkkkkkkkOKXXXXKK00Okxxk0XWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNWWWNWWWWWNNNXKK00OOOOOOOO00KKKKK0Oxdoodxxxxxdollc::::;;,,,,,,,,,,,,,,,,,,,,,,,,,,''    //
//    NNNNNNNNNNNNNNNNNNWKo,,,;;;;;;;;;,,,,,,;;;;:::cccllllllllooooooollllllllllcc::cok0XNWWNWWWWWWWWWWWWWWWWWWWWWNNNNNNWWWWWNNNNNNNNXKKKKKK0OOOO00KKKKKK0Oxdooodxxxxdolcc:::::;;;,,,,,,,,,,,,,,,,,,,,,,,,,,''    //
//    NNNNNNNXXXXXNNNNNNNXd;,,,,,,,,,,,',,,,,,;,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;;;;:lxKNWWWWWNNWWWWWWWWWWWWWWWWWWWWNNNNNWWWWWWNNNNNNXXK000KKXKK0000KKXKKK0kxdoooddxxddolcc:::::::;;;;;;;,,,,,,,,,,,,,,,,,,,;,,'.    //
//    NNNNXXXXXXXNNNNNNNNNKl,,,,,,,,,,,,,''.',;;;;,,,;;;;;;;;;;;;;,,,,;;;'';;;:cdOXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNWWWWNNNNNNNXXXK0OOO0KXXXKKKKKKKK0Okxdddddddddoolcc::::::::::;;;;;;;,,,,,,,,,,,,;,,,,;;;,'.    //
//    NNXXXXXXXXNNNNWNWWWWNKo,,,,,,,,,,;;'..',;;;;::ccclllcccccccc::cc:::,',:dOXNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNWWWWWNNNNNXXXXK00OOOO0KXXXXXXXKK0Okxddxxxxddoolllccc::;;;:cc::::;;;;;;,,,;,,,,,,;;;;;;;;,'..    //
//    XXXXXXXXXNNNNNNNNNWWWWXxc,,,,,,,',;;'';:ccllllllllllccccccccccccccc;'.c0WWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWWWWWNNNXXXXXKK00OOOO0KXXXXXXKK00Okkxxxxxxdoolllcccc::;;;;:ccc:::;;;;;;,,,;;,,,,,;;;;;,,,''.'    //
//    XXXXXXXXNNNNNNNNNNNWWWWNKxc;,,,,'';::loooollcclllccccccccccccccccccc,.,dXWNNWWWWWWWWWWWWWWWWNWWWWWWWWWWWWWWWWWNNNXXXXXXKKKK00000KXXXXXKK00OOOOOkkxxdoolllcccc::;;;;;;:ccc:::;;;;;;,,;;;;;;;,,,,,,''',:cl    //
//    XXXXXXXXXNNNNNNNNNWWWWWWWNXOo:,,;:looddoddddoooodolllllllllllloooddoc,'lKWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXXXXXXXXXXXKKKKKXXXXXKK0OOOO00OOkxddoolllccc::::;;;;;;:ccc:::;;;;;;;,;;;;;,,,,,,,,,;:ldxx    //
//    XXXXXXXXXNNNNNNNNNWWWWWWWWNWNKkoloddddddddddoooodddxxxxxxxkkxxdxxxxdo::kNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNXXXXXXXXXXXXXXXXXXXXKK0OkkOO00Okxddooolllcc::::::;;;;;;:ccc:::;;;;;;;;;;,,,,',,;;::ccodddd    //
//    XXXXXXXXNNNWWWNNNWWWWWWWWWWWN0xdddddddddoolloooddxxddddxxxxxkkxxxxxxdoxXWWWWNKOxxOXWWWWWWWWWWWWWWWWWWWWWWWNNNXXXXXXXXXXXXXXXXXXXKK0OkkkkOOOkxddooolllcccc::::::;;;;;;;:c:::;;;;;;;,,'',,,,;:cllllllllc:;    //
//    XXXXXXXXNNNWWNNNNNWWWWWWWWNXkdooodddooolllloooddddxxxxxxxxkkkkOOOOkkxkKWWWWNOc;;;:oKWWWWWWWNNNNWWWWWWWWWNNNXXXXXXXXXNNXXXXXXXXKK0OOkkkkkkxxddooolllcccccc::::::;;;;;;;:::::;;;;,,,,',;::cccloollc:;,'...    //
//    NNNXXXXXXNNNNNNNNWWWWWWWWN0xoooooooooolclloodxkkxxkOOOOOO0000000KKKK00KNNWWNx;,,,;lKWWWWWWNNNNNWWWWWWWNNNXXXXXXXXNNNNNXXXXKKKK0000OOOkxxdddooolllcccc::cc::::::;;;;;;;;:;;;;,,,,;;;;:llllllcc:;;,'......    //
//    NNNNXXXXXNNNNNNNNNWWWWWNXOxooooooooooooodxkkOOO000000000KKKKKKXXXXXXXXXXNNNXd,,'',lKWWWWWWNNNNWWWWWWNNNNXXXXXXNNNNNNNXXXKK00000000Okkxxddooollllccccc::cc::::::;;,;;;;;;;;,,;;::ccllllllc:;,'...........    //
//    XNNXXXXXNNNNNNNXNNNWWWNKkdooooddxkkOO00KKKKXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNXOoc:::l0NNNWWNNNNNWWWWNNNNXXXKKKXXNNNNNNXXK000000000Okkxxddooolllllcccccc::cc::::::;,,,,,,,;;;;:clllollcc:;,''..............    //
//    XXXXXXKXNNWWWNNXNNNNNN0kxxkkO0KKXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKkddllkKXXNNNNNNNNNNNNNXXXKKKKKXXNNNNXXKK00OOO0OOOkxxxddooollllllcccccccc:cc::::;;;;;;,,,,;::clllllc::;,'.................     //
//    KKXXXKKXNNWWWNNNNNNNNXKKXXNNNNNNNXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0kxooOXNNNNNNNNNNNNNXXXXXKKKKXXXXXXXXKK000OOOOkxxxdddooollllllllcccccccc::::;;;;:loolc:;::::ccc:;;,,'.................        //
//    0KKXXXXXNNWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOdolxKNNNNNNNNNNNNXXXXXXXXXXXXXXXKKKKK00OOkxxxdddooollllllllllllcc:::::::::::cldxkxdlc:::;;;;,,''...............             //
//    KKKKXXNNNWNNNXXNNNNNNNNNNNNNNNNNNNNNNNXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0xoloOXNNNNNNNNNNNXXXKKXXXXXXKKKKKKK000Okxddooooollllllllllllllcc:::::::cccllodxxxdoc:;,,,,'''...............                //
//    XXXXXXNNNNNNXXXNNXKKXNNNNNNNNNNNNNNNNXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXkoloxKNNNNXXXXNNNNNXXKKKKXKKK000000OOOkxdoollllllllllllllllcccc:::cccllooooooollc::;,'''''''..............                  //
//    XXXXXXNNNXXXKXXXKOxkKNNNNNNNNNNNNNNXXXXXXXXXXXXXXNNNNNNNNNNXXXXXXNXXNNNNNNNNNXXX0olld0XXXXXXXXXXXXXXXXKKKKKKK00OOOkkkkkkxdolllllllllllllllcccccclllooooooolc::;,,,'''''''''............                     //
//    XXXXXXK0000KXXKK0OkkKXNNNNNNNNNNNXXXKKKXXXXXXXXXXNNNNNNXXXKKKKKKXXXXXXXXXXXXXXXXKxllokKXXXXXXXXXXXK0OO0KK00KKK0OOkkkOOOOkxollllllllllllllllooddddooolllcc:;;,,'''''''''''............                       //
//    KKKKK0kkk0KKKK00Okxk0XNNNNNNNNNXXXKKKKXXXXXXXXXNNXXXXXXKK00000KKKXXXXXXXXXXXXXXXXklclx0KXXXKKXXKKKK00Oxk00000000OOOOO000Okdlllolllccllloodxxxxxdolcc:;;;,,,,'''''''''''............                         //
//    0000OkkkkO0K000OOkxk0XNNXXXXXXKKKKKKKXXXXXXXXXXXXXXXKK00OO00KKKKXXKKKXXXXXXXXXXXXOlccoOKKKKKKKKK0000K0kdxO00000OkkO00000Okdollllllloooddxxxxdolc:;;,,,,,,,''''''''''...........                             //
//    OOOkxkOOOO000OOOOkxxO0KKKKKXXKK000000KKKKKKKKKKKKKKKK0OO000KKKKKKKKKKKXXXXXXXXXKKOl::cxO000000000OO000Oxddk00O0OkdxOO000Okxooooodddddddooolc:;;,,,'''''''''''''''..........                                 //
//    kkddxO0OkOOkdddkOkxdxkkddodOKKKK00000KKKKKXXXK00OO00OOOO0KKKKKKKKKKKKKKKKKKKKKKKKOo:;:okkkOOOOOOOkxkkkOkdddkO0OOkdodxkOOOkxdooodddddolcc::;,,,,''''''''''''''............                                   //
//    xddxOOOxxkkdoodk0kddddlc::cdO000000KKXXXXXXX0Okxxk000OkOOO000KKKKKKKK00000KKKKK00Od:;;cdkkO000O000OkxkOkdlloxkOOkxdlodxkOkxoooooollc:;;;;;,,,,''''''''''''...............                                   //
//    odkkkkxdxkOkxddxOkxooolc::ldkOOOO0KKXXXXXK0kxddxkOO0000OOOkkkOO000000OO000OkOO000Odc;;:lxxkO0OOkOOOkxxxkxolldkO0kxxdoooxkkxoollc:;;;;;;;;;,,,,'''''''''...................                                  //
//    dxxxxdddxkOkxdooxkdololc::lxkkOO00KXXXXKOxdoodkOOOOOOO00OOOOOO000OOOkkkkkxxxkO00OOdc;,;cddxkOOkddkOkxxxxxdoodxO0Oxxxollodxxoolc:;;,,;;;;;;,,,'''''''''....................                                  //
//    xxdddoodkkkkxolloddllolc;:oxxkOO0KKKK0OxdoodxkOOOOOOOOOOOOOOOOOOkkOkxodxxxxxkOOOOkdc,,,:oddkOOxdodkkxdddxdooddxkkddddlcloddoolc:;;,,;;;;;,,,,'''''''.......................                                 //
//    dddoooldxkkxdollcclooll:;codkOO00KK0OxdllodxkOOOOkkkkOOOOOOOOOxddodxxddxxxxxkkOOkkdc,,,;lodxkxdoooxkxdooddololcoxddddocccooolc:;;,,;;;;;,,,,''''''........................                                  //
//    ooooolldxxxxolccccloolc;:cloxO0000OxolllodxkkOOkkkkkkkOOOOOkkxdoolodddooddxxxkkkkxdc,'',:lodxdoolodxkxoloolll:;lddooool::cllc::;;;;;;;;;,,,,''''''........................                                  //
//    lllllcldxxxdocccccllll:::cllodkOkxolcclodxxkkkkkkkkkkkkOOOOkxdollooodooooddxxxkkxxdc,''';clodoolllloddollllcc::clloolol:::ccc::;;;;;;;;;,,,''''''.........................                                  //
//    llllcclodddolc::cclllc::ccccccclcc:ccloddxxxxxxxxxxkkkkkOkkdoolllooooooddddddxxxxddc,'..,:lloollllccloolcllc:;:clllolllc;;;:c:::::;;;;;;,,,'''''..........................                                  //
//    cccc:clodddoc:::::colc:::ccc:::;:::clooddxddddxxxxxxxkkkkxdolllllolllloodddddddxddoc,'..';cllllllc:::cllccc:;;;ccllllccc;;;;:c                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ozr1s is ERC721Creator {
    constructor() ERC721Creator("OZR Ones", "ozr1s") {}
}