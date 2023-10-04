// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Geodetic World
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWNNWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMWWWNNNXXXXXXNNNNWWWWWWNNXXNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXXXXNNNWWWWWWWNXKKKXNNWNXXNWWWWMWNXKKKKKKXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0xx0XKK00KXXKKXNXXXKKKKKKKXXNXXXKKO0XWN00OkkkO0OOO0KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0OOK0kxxxkOkkOO00KKKXXNNNNNNXKKKKKKK0OkdoldxxkxdlcldxkkkkkOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWXOxxdxO0OO0KKKKOO0OxxO0KKKKKXXNNNKOkO00KK00OOkxdllodddlc:lxOkkkxxxO0NWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWKxlldk0KK0OOKXNWXKKK0OOkkkkkOOkk0KK0kkO0KXKOkkkkkOOxddlc:;;:okkdoooooodk0NMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWXkoldk0XXKOOOKXNWWWNXKK0OkdoodOKK00OkkO00000KOkxxxdxkkkkdc,'';::ccccll;,,,:okXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMW0xxxkO0XNNNXKKXNWWWWWNXXKK0kdolk0OOkxdodO0000OOOkOK0xooxkkdolc;....,cooc:;'...':xXWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKkddxkKNWWWNNWNXK00KNWNNNXK0OOkdxkxkOkxkO0KK0Okddddx0OxdddkOOOkdoc;;:lloxxdl:,.  .,cxXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNxlooodOXNNNWWWWNXKKKXNNNNXKOOOO00OddKX0KXXNNXX0kxOOkdxxo:,;cldkOOOkxxxxdddxxdoc;....;:ckNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWKddx:,lxxxOKNWWWNNNXXXOKNNXXK00K000OkOKXXXXKXXXKKOOOxdc,'...'c;';cdxkOxc;:coddlllc:'...,;;oXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNkcoOl',lddx0XWWWNXKXNXOkKNWWNNXXXOkOOKKXNNX0OKKK0xollodo'  ..'::;::;;:c;...'col:;,,,,...'.':dKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMXd:;::,;oOXXKKXNWNXKKNNX00KNNNXXXX0OO0KNWNX0OxddkOdlclxOkx;  .,;..',;;'.......;cc,,,'........:ld0WMMMMMMMMMMM    //
//    MMMMMMMMMMKl;;,,:oOXXXKKKXNWWWXKKXNNNNNXKK0OO0KXXNXK0kxxdxxdlc;:oxOkl'......         ....';,.....    ...,cloOWMMMMMMMMMM    //
//    MMMMMMMMMKc,,',lO0kxdxkO00NNNWNXNWWWWWWXKK0KKXX0OOkkkdxkOOxooc;:lddl;........       ....';;'... ..     ..:lolOWMMMMMMMMM    //
//    MMMMMMMMXl,''';loc::lxO0O0XXXNOkKNNKXNNXXXXXXK0kkkkkdlxOOOxdxxolc::;'.....;;,.       ...,,...GEODETIC  ..;oolo0WMMMMMMMM    //
//    MMMMMMMNkl;.',::;;;:dxxO00XXKKOxONNX0XWNXKKKK0OkxxO00xk0KKOxkkxdoc;;;'.  .....       ......      WORLD  .,loooxKWMMMMMMM    //
//    MMMMMMW0Od;';okdc;;cllllodkK0O0dd0NNKO0KOkOOxddxxdx0K0O0KX0kkxdolc:c:,........       ......             .'clodxkNMMMMMMM    //
//    MMMMMMKOkl,';oOk:,;::ccllodkkx0Odx0XOdxkxooddxkO0kxkO0000KK00Okxollcc:;,,,..          ....               .;ldxxkKWMMMMMM    //
//    MMMMMNkxOl;,,co:,;;::cclloddxdxOdokOxoxkddxO000OOxlloddkkkkkOOkxxdolclloll:'.         ....              ..'cdodxOXMMMMMM    //
//    MMMMW0lx0dllcc;,,;:ccccllodooodddoooooodkO00Okkkxl;;;;;;cllloddodolcccllllc;,'.       .....      .........';ccclx0WMMMMM    //
//    MMMMWxcddool;'.',;:cllccloolloddoloolooldkOkxdooccclccclollooolodllolooodoc,.....     ....       ...'......',;,;lkXMMMMM    //
//    MMMMNxddcloc;'';::;:clooloolllddoooollccdkxooddddddk0Okxdoc:;;;:cclc:;;:lol;'....    ......      ..'....'....'.,:lOWMMMM    //
//    MMMM0llc;dXKdc::c:;::clcclllllddoolllc::coddddxxollxkxoc:;,,,;:cldo:;;;:cccc:;...      .........',;,.   ....',',;cxNMMMM    //
//    MMMWk;,;l0WOol::cc:;:ccccllllodooolloollclodxkOOxddxxoc:::::c:cdxkxlccccoollc:'....   . ......',,,'..   ......',:lxXMMMM    //
//    MMMWk:';x0dccxd:::::cccccclodxxddookKXK0OOkxxdoodxdddoolccoooolldxdoooodxdlcc:;,,::,..   ...';,''..............,:oxKMMMM    //
//    MMMW0l,cxl,:oOKklc:clol::codddoddxO0XNNXXK0Odc::codoooodoloolllcccccclooodoccoddddxo:'....,;;;;'.....';,,,,,'..';coKMMMM    //
//    MMMW0l;;;,',;lONXkdoc:::lddolllodxOO0KNNX0kkdlllllcccc:::::clododxkkkkxdddddxdoooooodc;,,'''',,'....'..........',;lKMMMM    //
//    MMMWx,';,,,,',lxxolllcclolc:::ccccccldxkkdlloxkkxdl:clccoollllcldxxxxddxkxddoc::::,;;;;,'......................',;oXMMMM    //
//    MMMMk,.,,,,,,''',,,;;::;;;:;;::::::::::clloolooodxdoooodxdlc:::c::;;,,;::clcc;,''''...','..          ........'',:cdXMMMM    //
//    MMMM0c,''',,,;,,,,,,,,,,,;;;;;;:::;;;:::cccllcc::;,;;:lol:;;;;;;,,'...'...,;'..........''....               .,;:clkNMMMM    //
//    MMMMNd,,,,'...':c::;;,,,,,,;;;;:::;;;:cllc:cccc::::ccloo:',;;;',,'''......''...........................     .;:cclOWMMMM    //
//    MMMMWO:;:,...',lxdl:;,;:::::::::;;;;,;;::;,,,;;;;::;;ldl;,,,,,,;,'''..'......''.''...........'''',,......   .;cccoKMMMMM    //
//    MMMMMKocdc''',;oxo:,,,;:cc:cc:cc:;,,,,,''''..'.''',,;dkc;;,;;;::,'...............'''..'',,'',,,,,,'..  ..  .':cookNMMMMM    //
//    MMMMMWOddl:;;:llccc:,,:llc::;;:;,,''''''''...........:doc,',,,,''....................'',,,,,;;,,''.     ....;cooxKMMMMMM    //
//    MMMMMMXxxko:;:ldodo:;::ccc:;;;,,'....',''.............;loc,',''''.......'''.....''...'',,,',,,,,'..    ....':lodOWMMMMMM    //
//    MMMMMMM0lldl;:llooc;:lccddc;,,,'...'''''''........... .'col;,',,',,'...'',,,.',,,'.',,;;,,,,,'''.... ....',;cllxNMMMMMMM    //
//    MMMMMMMWx,;cc:c:;:::lxl:lll:;;,,'':;,'.'''','''...     ..;lolcc::c;..''''';c:;;;,,,,;;,,;,,;,,'.........';:loldKMMMMMMMM    //
//    MMMMMMMMNd,';clc:;::oxc;:;;:::;,..''''.'.........       ..,:lllool;'''','',:;,,,;;;;;;,,;;;;;;,.......'',:loloKWMMMMMMMM    //
//    MMMMMMMMMNd,';cool::ldoc;;,'''''...''............    .........';lolc:;,,;,'''',,;;;;,,,;;,,,;,'......''';loldKMMMMMMMMMM    //
//    MMMMMMMMMMWx,',;cododdxdl:;,''''''.'.............   .....      .'oxdol:,''''''',,,,,,,,,,,,,'..... ...';cooxXMMMMMMMMMMM    //
//    MMMMMMMMMMMWO;.'';codddolllcc:;,,''............... ....         .lkxdl:,'''''',,,,,,,,,,,,'....    ..';cookNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMW0:...';::::;;;::::::;;'..................          .okddl,',,'''',,'''''''''...........,:lod0WMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNd'..',::;;;;:::;;;;::;,''...........'..........  ,dxddl:;;:::;;;;,''''''.........'',;lookXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMW0l'.',:ccll::cc:;;,,,;;;;,,''...'.','.',''.....'oxddollllllcccc::::::;;,,,''',',;:codkKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWOc,';clll:,:::;,,,'''',,;::;;::;::::;,'......,ododolllollllcc:::,''''',;;,,,;:ldxkKNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWOl,';:;',clc:;'''''.''',;,',:ccc::;,.....',;lollllllllccc::;,'......,::::codxkKNWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMW0o;,,'.,col:,''''.',,'''..';::;,,'.....,cloolllllllc:;;'.........,::clodxOKNWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWXkl,..':ccc;,',,''''..''',;;,','...';:cccllllcc:;;,'.....''''';:clodx0XWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNOoc;,;:c:;;;:;;'''..,,,;;;:::;,,;;:c::cclcc:;'.......',''';clodOKNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkoc:ccc:;;;,''''''',;,;;;:::::lolllc:::::;,,','',,;;:coxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxoc:;;,,,''''',,,,,,;;codddollllllooodollllldxkO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Okxollcc::;;,,'',,,;:cllollloodddxxkkOO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXKK0OkxddoooooodddxkOOkOO0KKXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWNWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WORLD is ERC721Creator {
    constructor() ERC721Creator("Geodetic World", "WORLD") {}
}