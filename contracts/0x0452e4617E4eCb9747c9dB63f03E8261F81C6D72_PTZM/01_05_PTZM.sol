// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PATZO MEMES
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMWWWWWWWWWWWWWWMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWMWWWWWWWWWMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMWWWWWWWWNNNNNNNNWWNNNNNNNNNNNNNNNNNNNNNNWWWWWWWMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNWWWWWWWWWWMMMMMMMMMMMMMMWWWWWWWWNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMWWWNNNNNWWWWMMMMMMMMWWNXK0OkkxxxdddooooooodddddxxkOO0KXNWWMMMMMMMWWWNNNNNNNWWWMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNWWMMMWWMMWNXKOxxolcc:;;;;::::::::::::::::::;;;;;;:clodxkOKNWWMMMMMMWWWNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNWWWMMWWWMWX0Oxolc:;;;:::::;;;::;;::::::;;::::::;;;::::::::;;;;:cldkOKNWWWWMWWWWWNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNWWMMMMMWNKOxoc:;;;;::::;:::::cccccccclllloooollcccccllccc:::;;;:::::;;;clox0XWWWMMMMWWNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMWWWNNWWWMMMMMWXOdl:;:;:::;;;;;:ccclccllloddlc::::oxxxoc:ccc:coxkxolccccccc:::;;:::;;;clx0XWMMWWMWWNNNNWWMWWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNWWMMWWWN0xl:;:::::;;;:cccclodoc::clc;:oxo::cldxkxdl::lxoc;:dkdc::cc:coxdolcc:;;;:::;;:cokKNWMWMMWWNNNWWWWWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNWWMMMMWX0dl:;;:::;;:ccllllcc:coddl::cdd:;lxdc::cclxxdl::oxolloxko::cxd:;cdkxcccldocc:;;:::;;:lxKNMMMMMWWNNNWWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMWWNNNWMMWMWNKxc;;:::;;;:cllloddoc::cddddoc::clccoxxl::lddkxdc;:oxdoodkxl::dkl::lxko:;cdkdlllolc:;:::;;:lkKWWMMMWWNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWWMMWWWXkl:;;:::;;:loolcc::cool:::ccldxl:::oxkxxxo:;loodddl::odc;:dkd:;cxdc;cxkdc::okko:;cdkollc:;;::;;coONWMMMWWWNNWMWWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWWMWMMNKxc;;::;;:clddolc::oo:;codl:::ldxxdl;:oxkkkxoccccldxdolcccccoxxl::ldl::okxl::okko:::cxxc;lxxoc:::::;:lkXWMMMMWNNNWWWWWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWWWMWWW0o:;:::;;:lodxxdolc::llcclxxol::cccodoccoxkxxxxddxxxxxxxxddddxxkxdollllloxxo::lxko:cc:coc:cxOOkOxoc;;::;;cdKWWWMWWNNNWWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWMMMWN0o:;:::;;codxxxxxxxdlc:::lxxxxdoccllldxddxxxdddxxxxxxxxxxxdxxxxddddxxxdxxxkxdlclxkd::dd::::lkO0OO0Okkdl:;::;;cdKWWWMMWNNWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWMMWMW0o:;::;;:ldxxxxxxxxxxxdoc::cdkkxxxdodxxdddxxxxxxxkkkkkkkxkkkxkkkkxxxxxxxxxddxxxxdxkxlcdko:::okOOOOOO00O0Oxl:;:::;cxXWWWMMWNNWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWWMMMWKd:;:::;:ldxkxkkxkkkkkxxxxdc::oxxdddoodxxxxkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkxxxxddooddxxkxl:cdOOOO0000000000Oxl:::::;ckXWWMMWNNWWWWWWWMWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWMWWMMWNNWMWWWNk:;;::;:ldkkxkkkkkkkkkkkkkkkdooddooodddxxxkkxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxddddddoxxdkOOOOO000000000000Oxl:;::;;lONMMMMWNNWWWWWMMWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNMMMMW0o:;::;;cdxxxkkkkkkkkkkkkkkkdoccloddddddxxxdolllllllloxkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxddxddddodxkOOOOOO000000000000Oxl;;::;:dXWMMMWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWMWNNWMMMWXxc;::;;coxkkkkkkkkkkkkkkkkkdl;'.'',coxxxxdc,'...''...''';codkkkkxkkkkkkkkkkkkkkkkkxxxxxxxxddxxddooxkO0OO00O00000000000Od:;::;;l0WWMMWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWNNWMMWWKo;;::;;lxxxkkkkkkkkkkkkkkxoc;,;;;;;'.':ol:'.';;;;::;::;;;,'',:dkxxkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxddddddxk00000000000000000ko;;::;:xNWWWWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWMWWWWWWNNWMMMW0c;::;;:oxxkkkkkkkkkkkkkkxo:,;;;:;;;;;;,'..',;;::;;:;;;;:;;;;;,.'cxkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxddddooxO0000000000000000Od:;::;;oKWWMMWNNWMMWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWMMMWNNWMMMWO:;::;;cdxkkxkkkkkkkkkkkxo:,;;;;:;;;;::;::..;:;;::;;;:;::;;:;;;;;,.;oxkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxddxxxddooxO0000000000000000kc;;::;lKWMMMWNNWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWNNNMMWMWk:;::;;lxkkkkkkkkkkkkkkxdc;;;;,,,'''''''',;,..;:;:;;::;;::;;:::;;::,..'okkkkxkkxkkkkxxxxxddxxxxxxxxxxxxddxxdddodxO000000000000000kl;;:;;l0WMMWWNNWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWMWWMWWWWNNWMMWNk;;::;:oxkxkkkkkkkkkkkkxl,..''''''''''''''''...',;:;;::;;;,,,,,,;;;;;;;'.ckkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxddddk000000000000000Oo;;::;c0WWMMWNNWMMWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWMMWWWNNWMMMNk:;::;:oxxkkkkkkkkkkkkkd;...,;::::::::::::;;;;;;,'..,'''''''''''''...'..'..ckkkkxkkxxxxxxxxxxxxxxxxxxxxxxxxxxxdxxxdoox0K0K0000KKKKK00Oo:;::;c0WWMMWNNWMWWMWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWMWWWNNWMMMWO:;::;;oxxkkkkkkkkkkkkxl,.';::;;;::;;;;;;;;:;;::;::;'...,;;::::::::;;;,,''...cxkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddoxO000K000KKK0000Oo:;::;lKWMWMWNWWMWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWMWWWNNWMMMW0c;::;:oxxkkkkkkkkkkkkxc,,;::::;;::;;:;;;;;;;;;;;:::;:;'.';;;;;:;;;;;;;;:::;;'.';lxkkxxxdxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddodk0K0KKK00000000Oo;;::;oXMWMWNNWWWWWMWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWMMWWNNMMWWKl;::;;lxkkkkkkkkkkkkkxc,;;;::::;;;:::::;;;;;;;;;::;;;::;;..,:;;::;;;::;;:::;;;;,'.'cdddxddxxxxxxxxdxxxxxxxxxxxxxxxxxxxxddook0KKK0000000000kl;::;:xNMMMWNNWWWMMWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWMMNNWMMMNd;;::;cxkkkkkkkkkkkkOxc,;;:::::;:::;:::;;;;;;;;;;;;;;;;:;;:'.,::;::;;;::;;::::;::::,.,lxxxxxxxxxdxxxxxxxxxxxxxxxxxxxxxxxdddookK000000000000Ox:;::;cOWMMMWXNMWWMWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWMWWWWXNMMMWO:;::;:dkkkOkkkOkkkkkkc,;;;::;,''''''''''''''''.......''''.','.,;;::;;;::;;,,''''''''...;oxxxxxxxxdxxxxxxxxxxxxxxxxxxxxxxxddddokKK00000000000Od:;::;oXWMMWNNWWWMWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWMMWWWNNWMMMXo;::;;okkOOkkOkOkkkOkl,;;;::,..',,,,,'..........'''''''',;;,'...;;::;:;:;,................,:oxdxxxddxxxxxxxxxxxxxxxxxxxdxddddoloO00000000000OOkl;::;;xWMMMWNNWMWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWMMWWWXWMMMWO:;::;cxkOOOOOOOOkkOOd;,;:;;'.',,'.''''''',,,,,,,'''',;;,..,::,..,;::;;:;'..''...........'....:dxdxxxxxxxxxxxxxxxxxxxxxxddddddooldO0000000O00OOOd:;::;lKMMMWNNWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNNWMMMXo;::;:okOOOOOOOOOOOOkc,;;;'.,,..',;:::::::::::::::::,'''',,'',;:,..;:;;'.',,''''''''''''..,,..;dxdxxxxxxxxxxxxxxxxddddddddddddoollx0000000O0OOOOkl;;c:;kWMMMWNNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNNMMMM0c;::;cxOOOOOOOOOOOOOo,,;:'.',..;;,''',','............,;'',,,'..';;..;:,,;,.  ...''''',,;;,....oxddxxxdddxxxxdddddddddddoodddddoooloO00000OO0OOOOkd:;::,lXMMMWNNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWXNMMMWx;;::;oOOOOOOOOOOOOOk:,;::;'''....'cdxkOo. ':.        ;OKNXXOl,'..'..;::,.  ...      .:c,'',. 'dkxddxxxxxdddddddoodddddddddddddooollx00O00OOOOOOOkxc;:c;:OWMMWNNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWNXWMMMXo;::;:xOOOOOOOOOOOOOd;,;:;;;:::;;,';:cdd.  .:.  .lkx, .kWMMWWWx',;..,:,';' .:d;   ';. :XXOdc;.'oxxxdddddddddddddoddddddddddddddddooloO0OOOOOOOOOOkxl;:c:;xWMMMNNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWNNWMMMKl;::;cxOOOOOOOOOOO0Ol,;;::;;;:::::,,;;'.   .;,  'kKx' .kWMWWMWNd','.,,'dk'  .,.  .xXo.'OWMMKc..oxdddddddddodddddddddddddddddddddddollxOOOOOOOOOOOkkd:;::;oNMMMNNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWNNWMMMO::c:;lkO0OOOOOOOOO0k:,;::;::::::::,'.';;,....    ..   cXMMWWMWN0;.',,.c0d.  ,c,   .'..cKN0o;..'ododdddddddddddddddddddddddddddddddolldO0OOOOOOOkkkkd:;::;lXMMMWXNWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWNNMMMMk;:c:;oOO0000O0000O0k:,;;:::::;;::::;,'.',;;;;,'...   .lxkkxxoc:;'..';,';,. .         .;c:,''.'cdddddddddddddddddddddddddddddddddooolldOOOOOOOkkkkkkd:;::;cKMMMWXNWMWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWMWNNMMMMk;::;;dOO00000000000x;,;;;;;:::;;;::;::;'...''',,,,,,''''',''',;;'..,::;,,,;;;,;;;,,,,,,,;;'.,loodddddddddddddddddddddddddddddddddooolokOOOOOkkkkkkkdc;::;c0MMMWXNWMWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWMWNNMMMWx;::;;dOO00000000000x;,;;;;::::;;;:::;;:::;,,'''''''''''''''''...',;:;;;,.....''''',::,''....:odddddddddddddddddddddddddddddddddddooolokOOOkkkkkkkkkxc;::;c0MMMWXNWMWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWMWNNMMMMx;::;;dO000000000000x;,;:;;;,,,;;;::::::;;:::::::::;:::;;;;;'..,;::::;;:::;,....,,,;:,''''',,.'lodddddddddddddddddddddddddddddddddooolokOkkkkkkkkkkkxc;::;c0MMMWXNWMWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWMWNNMMMMk;:c;;oO00000000000Kx;,;:,'''',;:::::::::;;;::::::;;;;:::;,'.,;:;;:;;;;;:;;:;,'..,;;;;,,;::;:;.'lddoddooddddddddddddddddddddddddddooolokOkkkkkkkkkkkdc;::;c0MMMWXNWMWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWMWNNMMMMO:;::;lO000000000000k;,::;;,,''',:::::::;;;::;;::::;;,,''..,;:::;;:::::::;::;:c:'.,:::;;::;;;:'..:odddddddooddddddddddddddddddddddoollokkkkkkkkkkkkkd:;::;lKMMMWNNWMWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWMWNNMMMM0c;::;lk000000000000Oc,,'.....'';::::;;;:::::;;,,,''''',,;;:;::;;::::::::::::;;;;;;;;:;;;:;;;:'...:odddddddoddddddddddddddddddddddoolldkkkkkkkkkkkkkd:;::,lXMMMWNNWMWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWMWNNWMMMXl;::;:x000000000000Oo'.''.'....''',,;:::::;;;,''',;;:::::::;;:;;::::::::;::;;::;;:;;;;;::;;:'..,..coooddoddddddddddddddddddddddddooloxkkkkkkkkkkkkko;;c:;dWMMMWNWWMWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWMWXNMMMNd;::;:dO000000000000x;,;..;;,''''....'''''',,;;::::::;;:::;:;;::;:::::::::::;;;::;;;::;:::;'..,..'lolooooooooddddddddddddddddddoooolokkkkkkkkkkkkkxl;::;:OWMMMNNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWMMWWWWWXNMMMWk:;::;lO00000000000KOc,;'..,,'....'',,''.........'',,,,;;;;::::::::::::::;;;:::::;;;::::;,..''..;lollllllllloooooddddddddddddddooooldkkkkkkkkkkkkkd:;::,cKMMMWNNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNNWMMMKl;:c;:x000000000K00Kd,,:;'..',,'.......'',;;,,,''.............''''''''',,,,,,,,,''''''...''..,lllollllllllllloooooooooddddddddooolokkkkkkkkkkkOOko;:c;;dNMMMWNNWMWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWMWWWNWMMMWk::::;oO00000000000KOl,;:;;,'....,,,''..........''''''',,,,,''..'''..................'',,....;oollllllllllllllllllllooooooodddoollxkkkkkOOkkOOOkxc;::;c0WMMWNNWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWMWWWXNWMMMKl;::;:x000K00KKK000Kk:,;;:;;;;,'...'',;,,,''...................''''''',,,'''',,'''''''...''.'lollllllllllllllllllllllllloooooolldkkkkkkkOkOOOOko;::;;xNMMMWNNWMWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWNXWMMMWk;;::;lO0000000K00000d;,;;;;:;;::;'....'',,,,,,,,,,;,,,,,''''.........................',,'..:ollllllllllllllllllllllllllllllllcokOkkOOkkOOOOOkd:;::;c0WMMWNNWMWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWMMWWNNWMMMXo;::;:oO00000000000K0o,,;;;:;;::;;:;;,'...'',,,,;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;,,..,coollllllllllllllllllllllllllllllccoxkOOkOOOOOOOOOxc;::;;xNMMMWNNWWWMWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWMMWMWXNMMMM0c;::;:dO00000000000K0l,;;;:;;::;;;;;;::;,'.........'',,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.....cllllllllllllllllllllllllllllllllccokOkOkOOOOOOOOOkl;;:;;oXWMMMWNWMWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWMMWWNXWMMMWk:;::;cx0000000O000Okko,,:;;;;;;;::;;;;:;;;;;;,,''''.................'...........'..';..:olollollllllllllllllllllllllllllcokxdkOkOOOOOOOOko;;::;c0WMMWNNNWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWMMWNNWMMMNx;;::;ck000000Okkdo:cxo,,;;::;;:;;;;;;;;;;;;;;;:::::::::::::;;;;;;;;;;;::::;,,,,::;;,.,lolllllllllllllllllllllllllllllccokklcxOOOOOOOOOOd:;::;:OWMWMWNNWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWMWWWNNMMWMXd;;::;ckOOOxdolc::::dOd;,;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::;::::::::;,''..'''..,,'.,colllllllllllllllllllllllllllllccxkxl:codkOOOO0Okd:;::;:kNMWWWNNWWWMWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWNNWMMMXo;:::;cxkdlc:::coxxxdddc;;;;:;;:;;;;;;;;;;;;;;;;;;;;;;;;;::;:::;:;,..'',;;::::,...;llllloolllllllllllllllllllllllcclxkxl::::ccldxk0Od:;::;;kWWMMWNXWWWWWWWMWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWMWWWWNNWMWWXd;;::;cdxl:coxkkdlc:;okd;,;:::;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;::;,..';::;;;;:::::,..,:lollllllllollllllllllllolcccldkkxodxdlcc::;:dkd:;::;:xNMMMWNNWWWWWWWMWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWNNWMMWMXd:;::,:ddxkkdoc:::;cdxddc;;;:;;;;;;;;;;;::;;;;;::;;::,,,,:;,,..,::;;:;;;;;;::;:;,''',:lollllllllllllllllllllccokkdlldO00Okdoc:oko;;::;:kNMMMWNNWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWMWWWWWMWWWNWMMMMNx::::;;lkxl::col::loc:lxdc,;;::;;;;;;;;;;;;;;;;;:;'.'''....''..'::::;'......';;,,;;''',clllllllllllllllllccokkdolcldxxdxOOOkxxl;;::;cOWMMMWNNNWMWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWNNWMMMMNOc;::;;cdocoxxc:c::coxkOkdc;,;;;;;;;;;;;;;;;::;;'.':::;..,c:,.';,....'..''..'.',;;;:,..;clllllllllllllcloxOOxc:lollc:::lk0Odc;;:;;lKWWMMWNNWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWMMWWKo;;::;:lxxdc:::cokOOkkkxooc;,;;;:::::;;;::::;;;..;::;,'.'...'.',;,'.';,. .';:;;::::;,'.;lllollollccldkkdoxxc::cccool:cxkl;;::;:xXMWWWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWMMMWXx:;::;;:lolcldkOkkOkxdl:cool:,,;;;::::;;::;;::;'.';;;:;,'..,;;'...,,...,;;;:;;;:::;;;,.'cllllccloxkkkoc:cdkxxxdolooldo:;::;;l0WMMMMWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWWMWWW0l;;::;;codxkkkkxxdoc::llcldoc:,,;;;;:::;::;;;;;..,;;;::'.''.'''.'',;;;;::;;;;;;::::;;..,ccloxkOxocldl:::lxOxocclddc;;;:;;dXWWMMWNNNWMMWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWMWWWMWNNWWWMMWNkc;:::;;ldkxxkxoc:::ldo:cdxolll:;,,;;;::::;;::;'.,::::,..';'..';:;;:::;'.';:::::::;;;.                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PTZM is ERC1155Creator {
    constructor() ERC1155Creator("PATZO MEMES", "PTZM") {}
}