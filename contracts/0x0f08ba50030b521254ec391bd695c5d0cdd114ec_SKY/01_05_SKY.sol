// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GlasSky
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ...............';,..................................................................................    //
//    ............''''''...............................,;::,..............................................    //
//    ...........',,,'..............',;;;;;;;,.........,:cc;'........''''''''''''''''..''''........',;;'..    //
//    ........';:;'.................:dxxxxxxxo;.........''''........',,,,,,,,,,,,,,,''.,::;'.....',:kNXd;,    //
//    .....',;,,,,'.,lxd:........;cloddoccccc:,.....................'''''''''',;;;;;;;;;,,,'.....'',ldoc;;    //
//    ..''',;:;'....;kX0c.....',,cxxdll:,.'''''''''''''''''''''''''''''''''''',;;;;;;::;'........'''''',;;    //
//    ..,::;'''.....',;;'....':dxdool:;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,;ccc;,,,,,,;;;:::;;,'.......',,,,,,,;;    //
//    ,,;::;,'''''''''''''''',lkkdolc;;;;;;;;;;;;;;,,,,,,;;;;;,,',,;;:c:;',,',;;;;;;;;,,'....''',:::;;;;;;    //
//    ::;;,,,,,,,,,,,,,,,,,,,;lxxdolc;,,;;;;,;,,,;;,'''',;;,;;,'.',,,,,,'..''';::,''',,,'....',;;cll:;;,,,    //
//    '''''''''''''''''''''''':ooool:''',;;,,,''',,;,,,,,;;;;;,,,,'''''',,,;:;;;;;,,,;;,,,,,,,,;;;:;;;,,''    //
//    .....''''''''''''''''''';cclllc;;,,,,,,''..',,,,,,,,,,,,,,,''....';cc:::;;;;;;;;;;;;;;;;;;,,,,,;,,''    //
//    .....',;;;;;,,,,;;;;;;;;;;;:lllll:,..'''.......................'.,ldoc;;;,,;;;,,;;;;;;;,;;,'.',;;;;;    //
//    ,,,,,,;;;;;,''',;;;;;;;;;;;;::clllc:::::;,,,,,,,,,,,,'........,:lccc:,'''''''''''ck0x;'',;,,,,,;;;;;    //
//    ,,,,,,,,,;;,''',;,,,,,,,,;;,,,;:cccccccc;;;;;;;;;;,;;,'''''',;:lol:;,,'''''''''''cO0x;.'',,,,,,,,,,,    //
//    '....'''',;;;;,,;,'..'..,,,,'..'''''',;;;;;,;;;;;;;;;;,,,,;:odo:;;;;;;;,,,,,,,,,,;;;,'...'..........    //
//    ,,,,,cxko:,;;;;;;,,,,,,,;::;,,,,,,',,,;;;::;;;;;;;;;;;;;:lolcc:;;;;;;;;;;;,,'''''''''..'',''........    //
//    ;;;;;o0Xkc;;;,;;;;;;;;;;;:::;;;;;;;;;;;;:::;;;;;;;;;;;;;codl;,,,,,,,,,,,,,,''''''''''''',;,'''''''''    //
//    ;;:llcc:::::;;;;;;:::;;;;;;;;;;;;;;;;,;;;;;;;;;;;;;;;;;;,,,''''''''''''''''',,,,,,,,,,,,;;;,,,,,,,,,    //
//    ;;;:::::::::::;;;;;::;;;:ccccclool;;;;;;;;;;;,,',,,;;;;;,,'''...........'',,;;;;;,,',,;;;;;;;,,'''''    //
//    ;;;;;;:::;;;:c:;;;;;;;;;coddddxO0xl:::::;;;;;;,''',,;;;;,,,,'.........'',;;;;;;;;,''',;;;;,,,,'.....    //
//    ;;;;;;;;;:::ccc::clllloooodxOOO000KKKKKOl,;:::;,,,,;;;;;,'''........'',,,;;:cl:;;,,,,,;;;;,'''......    //
//    ;;;;;;;;;:cccccclloddddddxxk00000KNWWWWXkdoc:::;;;;;;,,,''''........',;;;;;:cc:;;;;;;;;,,,,,,,,,,,,,    //
//    c:cc::;;;:cccccoododddddkO0000000KNNNWWWWWXd;::c::;;;,''',,,'..''''.',;,,,,,;;;;;;;;;;;,''';cccccccc    //
//    ;;::c:::::cclooodddddxkOO000O00000KKXNWWWWNK0Odcc::::;,,,,;,,,,;;;,,,'''''',;;;::::::::::;::ccccccll    //
//    ;;::cccccclloddddddxxkkkO000000KKKKKXNWWWWWNXKxcccccc:;;;;;;;;;:::;;;,''',,,;;;:ccccclooooooooccccll    //
//    cccccccccoooodddodkOOxddkO0000KNNNWWWWWWWWNK0Odccccccccccccc:c:;;;:c:;;;::::;;::ccccok0000000koccccc    //
//    cccccccclodddddddddxxkkkO00KXXXKKXNWWWWWWWNK0Okxxxxxxxxxxxxdccc::::cc::::cc::::ccldxOKXXXXXXXKOxxocc    //
//    cccccccclodoollllllloxOOO00KXXK00KXNNNNNNNX0OOOOOO0000KKKKKOdooollcccccccccccccccdO0KXNNNWWWWNXK0xol    //
//    oooooooooddo:;;;:;;;:lddkO00000000000000000xdddddkOO0KNNNNNNNNX0OkoccccclllccclooxO0000KNWWWWWNNNKOO    //
//    dddddocccccc:;:clc:;;lodk00OkxkO0000000OkxxdddxkkOO00KNWWWWWWWWNXKkddlcccclllloodxO00000KKKKKXNWNNXX    //
//    ddddol:::;;;;;:ldoc::lodxOOkddxO00OOOOOkxdodddkO00000KNNNWWWMMMMMWK0OdllcccloooddxOOOOOO000000XNNNWW    //
//    OOkddoool:;;;;:lddoooooddddxOOO00Oxdddddddddddk00000000000KXWMMMMWK0OOOkocc:::codddddddxO0000000KXNW    //
//    kkxdodddl:;;;;;cccccccclooddkkkkkxdddoddddddddxkkOO00000000KXXXXXXXXXK0OdccloollccclcccoxkkkkkO00KXX    //
//    ddddddddo::;::;;;;;;;;;;coooooooddodoooooooodddddxOOOOOOOOOOOOOO0KNWNK0OdcldOOd:;;;:;;:coddddxO00000    //
//    OOOOOOOOxolllll:;;;;;;;;::::::coddddoc::::clodddddxxxxxxxxxxxxxO00KKK000OkkxxxdolllllllokOOKXNNNNK00    //
//    00000000Okxdollcccccccccccc:;;coddddocc:;;;cllllllllloodddddxxkO0OOkkkkkkkkxdddxxxxxxxxkO00XNNNNXK00    //
//    00000000000kc;:ldoooooooddol:;coddddoodo:;;;;;;;;;;;;coddddxOOOOOOxdddddddddddxO00000000000000000000    //
//    00000000000kolloddodddddxkkkxxxkkxdooddoolllll:;;;;;;codxkkkxxxxxxdddxkkkkkkkkO00000000000000Okxxxxx    //
//    00000OOkkkkkddddddddddxxk000000KK0xxdddddddddol::::::clldkkkxxddoddxxO000000KKKKKKKK000000OOOkxddddd    //
//    00O0OkddddddddddoodddkOOO00000KNNX0Okxddddddddoooooool:;codxOOkxodkOO000000XNNNWWWWNX00000Oxdddddddd    //
//    xxxxxdccloddddddddxkkO00000KXXXKKKXXKOkkkkkkkkxdddodol:;codxO0OkkkO00KXXXXXNWWWWWWWWNXXXXXKOkkkkkxdd    //
//    ddoool::clooooooddkOOO00000KXNXK0KXNXKK0KKK0K0kdddddol::codxkOO00000KXNWWWWNNNNNNNNNNWWWWWNK0000Oxdo    //
//    dol::clol::::::ldddddkO0000000KNNXK0KXNNNNNNNNKOOxdddoooodddddxO00XNNNWWWWNX00000000XWMMMMWK0000Oxdd    //
//    ddolcccccccccclodddddxkkkkkkkkOKXK00KNWWWWNXXKOkkxddddddddddddxO00XWNXXXXXXK00000000KWMMMMWNXXXXXOkk    //
//    oooodl::clooooooddoooodddddooodkOO00KXNNNNNK0OkdddddddddddddddxO00XNXK00000000000000KNWWMMMMMMWWNK00    //
//    ::codoool:::::codoc::lddddol::lddxO00000000000OOOOOOOOOOOOOkddxO0OkxkO00000000KXNX000KKXWMMMMWXKK000    //
//    ccclllodoccccccodolccldddxxdooooddxkkO000000000000000OkkO00kddxO0OkxkO00000000KNNNXKK00KNWWNNNXXXXXX    //
//    ddl::codddddddddddddddddkO0000kdddddxkOO000000000000OkddxOOkdoxO00000000000000KNNNWWNK0KNWNK00NWWWWW    //
//    kkkxxxdodkOOOkkkkkkkkkkOO00000OOkkOkkxxxO00000000000OkdddxxdddxO000000000000000KKXNWNNXNNNNK00KKKKKK    //
//    00000kdoxO00000000000000000000000000Oxodk00000000000OkddddddddxO00000000000000000KNWWWWWWWNK00000000    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKY is ERC721Creator {
    constructor() ERC721Creator("GlasSky", "SKY") {}
}