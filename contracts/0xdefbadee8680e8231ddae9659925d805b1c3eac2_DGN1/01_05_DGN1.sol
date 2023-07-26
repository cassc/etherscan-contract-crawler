// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Degen Station Exit 1 🚇
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ....;c',,,'';ccccccccccc:;:c::ccccccc:::c:ccc:::cllc::loooooollllodxxxxxol;.....    //
//    ....;c,,,,'';cccccccccc::;;::::::cccc::::::ccccccccc::looooooollloodxxxxol,.....    //
//    ....:c,',''';::::::::::::;;::::::ccccccclccllllc::clccllllloollllldxxdxxol,.....    //
//    ....:c'',''';:::::::::::::::;:::::::cccccclllll:;:llcccllllllllllloddxxxol,.....    //
//    ....:c'''''';:::,;:::::c:::;,';:cc:::::::ccccllc:ccclllllllllllllloddxxxdo:'....    //
//    ...'::',,''';cc:,,::::::::::;,'',;::c:;:::cclc:cclllllllllllllllllllooodooxo;...    //
//    ..',;,',,,,,;:::;;:;;;;;;;;;;;;'..';;,.',;cc:;:cccccccccccccccccccllooodllddo:'.    //
//    .....  ........................,;'..'..',,,;:c;.................................    //
//    .               ..... ....     .,;,.....'';cl:.        .............       .  ..    //
//    .        .....'..''''.'''........,:;,'';;:cl:'. .....',,,;;;;;;;;;,,.....     ..    //
//    .      ..............'''''''.....,:::::llodo,....',;;;,,,,;,,,,,,,,;;;,'...   ..    //
//    .       ..'','',,,,'''''.........;ccccldddxd;''...''',,;;;;;;;,,,,,,'''....   ..    //
//    .     .....''''',,;;;:ccc:;,'.''';ccccoxxxxd:,'.',;:ccc:;;,,,,''',,;;;;;'..   ..    //
//    .      ....'''........'...',,,,,,:ccccoxxxxd:,,',,''...'',,''''',;,''''.....  ..    //
//    .      ..............',,'.....',,:ccccoxxxxd:,'.......'''''.....''..',,'..    ..    //
//    .         .',,...','..........',,:ccccoxxxkd:,'.........,,;,...,c:,'. ....    ..    //
//    ..       ..:lllollllo:.      .',,:ccccoxxxkd:,'.... ...,odolllloooo:...  ...  ..    //
//    ..    ... ..;:llllcc,.........''';ccccoxxxxd:,'.',,'.....:looddddl,.......... ..    //
//    .     ..........'........'''..''';ccccoxxxkd:,'...,;,'''..',;:;;'...,;;:;,... ..    //
//    .     ............',,,,''''''''.';c:::oxxxxdc,,'',;;;;,,,;;,,,;;;;:cccc:;,... ..    //
//    ..   ...........'',;,,,,,,,,'''..;::::oxxxxdc,,,,;;;:::;:::;;::cccccllcc;,... ..    //
//    ..   .......'',,,,,,,'',;;;;'.''';::::oddxxxl:;,,;;::::::::::cccllccclcc;,......    //
//    .....    ..................',,;:::::::oxxkkkkxdl:,..............................    //
//    .....                   ..';:c:cccccccdkkkkkkkkkxd:.............................    //
//    .........................';:ccccccccccxOkOkkkkkkxxl,',,,,,,;;;;;;,''',,;'.......    //
//    ............''''''''',,,,;:ccccccccc:cxkkkkkkkkkkxo:;:::::::::::::::::cc,.......    //
//    ......''''',,,,,',,;;;;;;;:ccccccccc:cxkkkkkkkkkkxo:cccccc:::cc::cllclll;.......    //
//    ......',',,,,,,,,,;;:::::::ccccccccc:cxkkkkkkkkkkkoccllllcc::::::coolooo;.......    //
//    ......',,,,;;;;;;;;:::::::ccccccccccccxkkkkkkkkkkkocclllllcc:::::lodlloo;.......    //
//    ......',,,;;;;;;;;;::cccc:cccccccccccldkkkkkkOOkkxoclllllllcccccclddolol'.......    //
//    ......',,,;;;:::::::::::::cccloooooollxkkkkkkkkkkxoccccllcllllllloddooo:........    //
//    .......,,,;;::::cc::::;;,;::ccc:,.';:clooc;,;coxxxoclccclloddooododdool,........    //
//    .......';;;:::cccccccc:::::c:;'...  .........'cxkxoooollooddddddxdoool:.........    //
//    ........,;;;:::ccccccc:c:::cc::;,'.....'',;:lodxkxoodooooodddddddddoo:..........    //
//    .........;;;:::::::::::::::cccccc:;,,,:looddxxkkxxdoddodooooddddooodl'..........    //
//    ..........,::::::::::::::::cccccccc:::oxxxxkkkkkxxdoddddddddddddoodo,...........    //
//    ...........,::::ccc::::::::cccccccloloxkkkkkkkkxxxddddddoddoooddddl,............    //
//    ............,::::::::::::::cccclllccclolllldxkkkkxdooooddddddddddl,.............    //
//    .............,:::::ccc::::ccc::;,..........';:cdxxdodddddddddxxdc'..............    //
//    ..............';:ccccccc::cc:,...',,'.',,,;:;'';oxddxxxxxxxddxo;................    //
//    ................,::::ccc:::cc:;'.',;;;;:c:;;:codxxddxxxxxxdxdc'.................    //
//    ..................,::::::::cc::;,..........,ldxxxxdddxxxxxdl,...................    //
//    ....................,:::::::cc:::;,'.....';ldxdxxxddxxxxdl,.....................    //
//    ......................',;;:::cc:::::;;::cloddxxxxxdxxdl:,.......................    //
//    .....................  ...,;::cc::c:::ldddddxxxxxdlc;'..........................    //
//    ......................     ...',,;:::coddddoolc;,'....'''.......................    //
//    ...........................      ......'...........',;;;:;......................    //
//    ..................;;,,''............ .........',,;::cccccc:'....................    //
//    ...............;:;;::;;,,,''',,,''.....''',,;::ccllooooool,.....................    //
//    ...........,:codol:::::;;;,,,;;;;,,,,';:;::ccllloodddddoc;:lol;'................    //
//    .......';cldolc;cll:;;;:;;;;;;;;;;;;;;:llllllooooddxxdl:::coooodxo:,............    //
//    ....';:lddol::;';cc:::;,,;;;;;;;;;;:;:loooooodddxxdol:;;::::;,;loxkxol;'........    //
//    ...;odollcll:,;:;,,::;;,''',,;::::::::looooooddolc:;;;;;:llcc:;;:c::lxkd:.......    //
//    ...,oddl:::l;',;,,,,,,;;,''...',,,;;;:cllcc:;;,,,,,;,,,;:llll:clcc;;:;cd:.......    //
//    ....'cl:,;::;,'';cccc:::,''',''............'',;;;,,;:::;;;::;:dOkxoll;;,........    //
//    ......,,,,,;::,:lc;:dd:,,',,,,,,,,,,,,,,;;;:::::;,,:clc;,,,,',okkOOkl,..........    //
//    ........,'..;o;:lc,;odc;;:;;;:;,,;;;::::::;;::;;,,,;c:;;;;;cllodddxo:...........    //
//    ..........',cl;,;:loo:;::;;:::;'';:clllc:;,;:::;,,::;;:cllcllllc:::,. .........     //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract DGN1 is ERC721Creator {
    constructor() ERC721Creator(unicode"Degen Station Exit 1 🚇", "DGN1") {}
}