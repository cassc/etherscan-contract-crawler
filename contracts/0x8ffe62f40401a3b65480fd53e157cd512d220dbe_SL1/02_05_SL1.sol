// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SarahLyndsay 1/1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    ooodddxxxxxddddddddddddddddddddddddddxxxxxxxxxxxxxxkkkkkkkkkOOOOOOOOOOOO0000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000000000000000000000000000000000000000OOOOOOOOOOOkkkkkkkkk    //
//    ooddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkOOOOOOOOOOOOOOOO0000000000000000000K000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKK0000000000000000000000OOOOOOOOOOOO00000000000000OOOOOOOOOkkkkkkkkkx    //
//    ddddxxxxxxxxxxkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkOOOOOOOOOOOOOOOOOO000000000000000000000KKKKKKKKKKKKKK0000KKKKKKKKKKKXXKKKKKKK000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkxxxxx    //
//    dxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxkkkkkkkkkkOOOOOOOOOOOOOO000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXKKKKK00000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkxxxxxxx    //
//    xkkkOOOOOOkkkkkkkkkOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOO000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000OOOOOOOOOOOkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkxxxxxxxxx    //
//    OOO0000KKKKKK00000KKKKXXXKK0OOOOOOOOOOOOOOOOkkkkkOOOOOO000KKKKKKKKKKKKKKXXXXXNNNXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000OOOOOOOOkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOkkkkkkkkkkxxxxxxxxxxxx    //
//    00OOO00000KK000000KKKKXKKKK00OOOOOOOOOOOOOOOOOOOOOOO000000KKKKKXXXXXXXXXXXNNNNNNNNNNXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXKKKKKK00000OOOOOOOkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOkkkkkkkkkkkxxxxxxxxxxxx    //
//    00OOO0000000OOOOOOOOOOOO000000000000000000000000000000000KKKKKKKKKKKKKKKXXXXXXNNNNXXNNXXXXXXKKKKKKKKKKK000000000000KKKKKKKKKKKKKKKKKK00000OOOOOOkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxx    //
//    OOOkOOO00000OOOOOOOOOOO000000000000000000000000KKKKKKKK0KKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXKKKKKKKKKK00000000000000000000000000KKKKK000000000OOOOOOOkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOkOOOOOkkkkkkkkkkxxxxxkkk    //
//    kkkkkkOO00000OOOOOOOOOO000000000000000000000KKKKKKKKKKKKKKKKKK00KKKKKKKXXXXXXXXXNNXXXXXXXXXKKKKKKKKKK0000000000000000000000000000000000OOOOOOOkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkk    //
//    kkkkkOOOOOOOOOOOO000000000000000000000000000000KKKKKKKKKKKKKKK000KKKXXXXNNNNNNNWWWWNNNNNNNNNNNNXXXXXXKKKKK000000000000000000000000000OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOkkkkkkkkkkkkxkkkk    //
//    kkkkkOOOOOOOOOOOOO000000000000000000000000000000000KKKKK000000000KKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNXXXXXXKKKKKKKK000000000000000OOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxxxxxkk    //
//    kkkkOOOOOOOOOOOOOOOO00000000000000000000000000000000000000000000KKXXXXXXXXXXNNNNNNNNNNNXXXXNNXNXXXXXXXXKKKKKKK00000000000000OOOOOOOkkkkOOOOOOOOOOkkkkkkkOOOkkkkkkkkkkkkOOOOOOOOOOOOOkkkkkkkkkkkkxxxxxkkk    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkxxxxdxxxxxkkOOkkkkOO0KXXNNNNNNNNNNXXXXXXXXXXXXXXXXXXXKKKKKK00000000000OOOOOkkxxxxxxkkkkOOOOOOOOkOOOOOOOOOOOkkkkkxxkkOOO000OOOOOOOOkkkkkkkxxxxxxxxxxkkk    //
//    OOOkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOkkkxxxddddooollllcccllllllcccllodxxkO00KKKKKXXXXXXXXXXXXXXXXXXXXKKKKKKK000000000OOOOkkxxxxxxxxxkkkOOOOOOOOOO00000OOOOkkkkxxxxkkOOO000OOOOOOOOOOkkkkkxxxxxxxxxxkkk    //
//    kkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOkkkkxxxxdddooolllcccccccccccccclllllllloddxxkkOO00000KKK0KKKK00000000OOOOOOkkkkkkkkxxxxxxddxxxxxkkkkOOOOOOO00000000OOOkkkkxxxkkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkk    //
//    kkkkkxxxxxxxxxxxkkkkkkOOOOOOOOOOOOkkkkkkkxxxxddddooolllcccccccccccccclllllllloooddxxxkkOOOOOOOOOOOOOkkkkkkkxxxxxxxxxddddddddddoddddxxxkkOOOOOO0000000000OOkkkxxxxkkkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkk    //
//    kkxxxxxxxxxxxxxxxkkkkkkOOOOkkkkkkkkkkkkxxxxxxdddddooolllccccccccccccccclllllllloooddxxxkkkkkkOOOOkkkkkkkkxxxxxxxxxxddddddddddddddxxkkkkOOOOO00000000000OOOkkkxxkkkkOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkk    //
//    kxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkxxxxxxxxxxddddddooolllcccccccccccccccclllllllloooddxxxxxxkkkkkkkkkkkkkkkxxxxxxxxxxxxxdddddddxxxkkOOOOOOOO00000000000000OOOkkkkkkkOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkk    //
//    xxxxxxxxxxxxxxxxxxkkkkkkkkkkkxxxxxxxxxxxxxxdddddoolllcccccccccccccclllllllllllooodddxxxxxxxxxxxxxxkxxxxxxxxxxxxxxxxxxxxxxxxxxkkOOOOOOOOOO000000000000000OOOOkkkkkOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkxx    //
//    kkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddoollllcccccccccccclllllllllllllooooddxxxxxxxxkkkkkkkkkkkxxxxxxkkkkxxxxxxxxxxxxkkkOOOOOOOOO0000000000000OOOOOOOOOOOOOOOkkkkkkkOOOkkkkkkkkkkkkkxxxxxxxxxxxxx    //
//    kkkkkkkkkkkkxxxxxxxxxxxxxxdddxxxxxxxxdddddoooollllcccccccccccllllllllllllooooooddxxxxxkkkkkkkkkkkkkxxxxxkkkkOOOkkkkkkkkxxxxxxkkkkkkOOOOOO0000000000OOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxx    //
//    kkkkkkkkkkkkxxxxxxxxxxxddddddddddddddddooollllllllllllllllllooooooooooooodddddddxxxxxxkkkkkkkkkkkkkxxxxkkOOOOOOOOOOOkkkkkkxxkkkkkkOOOO000000000000OOOOOOOOOOOOkkkkkkkkkkxxxxxxxxxxxxxdddxxdddxxxxxxxxddd    //
//    kkkkkkkkkkkkxxxxxxxxxxdddddddddddddddoooollllllllllollllllllllllllloooooooooodddddxxxxxxkkkkkkkkkkkkkkkkOO0000OOOOOOOOOOOkkkOOOOOOOOO000000000000OOOOOOOOOOOkkkkkxxxxxxdxdddddddxxxddooddoooodddddddoooo    //
//    kkkkkkkkkkkxxxxxxxxxxxxxdddddddddddddoooollllllllllllllccccllllllllllloooooooooddddxxxxxxxkkkkkkkkkkkkkkOO00000OOO000000OO000000OOO00000000000000000000OOOOOkkkxxxxdddddddooddddoooooloooooooooooooooooo    //
//    kkkkkkkkkkkxxxxxxkkxxxxxxxxxdxxxxxddddooollllloollllccccccccccccccclllllllloooddddddxxxxxkkkkkkkkkkkkkkkOO00000000000000000000000000KKKK00000000000000000OOOOkxxddoooolllllllllllllllllllllooooooooooooo    //
//    kkkkkxxxxkkkkkkkkkkkkxxxxxxxxxxxxxxddddooooooooollllllllllccccccccccccclllllloooooddddxxkkkkkkkkkkkkkkkkOO0000OOOOOOO0000000000000000KKKKKKKKKKKKKK000000OOkxdolllccccccccccllllllllllllllloooolooloolll    //
//    kkkxxxxxkkkkkkkkkkkkkkkxkkkkxxxxxxxxdddoooooddoooooloooolllllcccccccccccccclllllooooddxkkkkkkkkxxxxxxkkkOOOOOOkkkOOOOOOOOOOO0000000000000000KKKK000000OOkxdollcccccccllllllllllllllllllllllooollllllllll    //
//    kkxxxxxxkkkkkkkkkkOOOkkkkkkkkkkkkxxxxddddddddddddoooodooooollcccccccccccclllllloooddxxkkkkkkkkxxxxxxxxkkkkkOkkxxddxkkkOOOOOOO0000000000000000000000OOkxdollcccccllllllllllllooollllllllllllllllllllclllc    //
//    kkxxxkkkkkkkkkkkkOOOOOOOOOOkkkkkkkxxxxxxxddxxxxxddxxxxxxdddooooooollllllloooooooodddxkkkkkkkkxxxxxxxxkkkkxoc;,'...';cdkkkOOOO0000000000000000000OOkxdoollllllllllllllllllloolllllllllllllllllccccccccccc    //
//    kxxxxxxkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkxxxxxxxxxxxxxxkkkkkkkkxxxddddddooooodddddddddddxxxkkkkkkxxxxxxxkkkdc'....  .....'lxkkOOOOOO000000000000OOkxdoolllllllllllllllllcclollllllllllllllllllllcccccccccccc    //
//    xxxxxxxxxxkkkkkkOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkOOOOOOOkkxxxxxxxxxdddddddddxxdxxxxkkkOkkkkkkkkkkxko'..   .     ....:xkkOOOOOOOOOOOkkxxxdoolllllllllllllllllllllc::lllllllllllllllcccccccccclcccclccc    //
//    xxxxxxxxxxkkkOOOOOOOOOOOkkkOOOOOOOOOOOOkkkkkkkkkkOOOOOOOOOOOkkkkkkkkkkxxxxxxxxxxxkkkkOOOOOOOOOOOOOkkkx;.               .:xkkkxxxxdddoollllllllllllllllloooollllclllc;;:cllllllllllccccccccccccccccccccc:    //
//    xdddddxxxkkOOOOOOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkOO00000000000OOOOOkkkd'                 .ldollllllllllllllllllllooooooooooooollccllc:;::clllllllcccccccc::cccccccccc::::    //
//    dddddxxxkkOOOO0000000OOOOOOOOO000000000000000000000000000000OOOOOOOOOOOOOOOOOOOO0000KKKK000000OOOOkkkd'                  'lllllllllllllllllllloooooooooollloool:clc:;;;:clccllllcclllcc:;;:cc::::::;;;;;    //
//    ddxxxxxkkOOOO0000000000000000000000000000000000000000000000000000000000000000000000000000000OOOOOkkkkx:.                  ,llllllllllloooooooooooddooolllcclolc:cc:;;;;:cllcccccccccccc:,,;::::::::;;,,,    //
//    xxxxxxkkOOOO000000000000000000000KKKKKKKKKKKKKKKKKKKKK00000000000000000000000000000000000000OOOOOkkkxkd'                  .clllllllooooooooooddddddddollc::clc::cc:;;;;;ccccclllllcccc:;,,,;::::;;;;,,,,    //
//    xxxxkkkOOOO00000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000000000000000000OOOOkkkxxxx:.                 .,lllloooooooddddddddddoooolccc::cc::;:cc:;;;;::ccclclc:::::;,',,;;;;;,,;;,'''    //
//    kkkkkOOOOOO000000000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000000000000000OOOOkkkkxxxxo'                 ..,looooooodddddooooooooooolcc::::::;;:ccc:;;;::;::::::;;;;;;,,,;;;:::;,,,,'..    //
//    OOOOOOOOOO0000000000000000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000000000000000OOOOOkkkkxxxxxo'                 ..cooooooooddddoooooooollolc::::::::::cc::::::;,;;;;;;;;;;;::::;;;;;;,''''''.    //
//    OOOOOOOOOOO00000000000000000000000000000000000000000000KKK00KKKKKKKKKKK0000000000000000OkOOOOOOkkkkkkxxddl'.               ..:oddolllloooooooollolc:clcc:;:ccccc:::;:::::;;;;;;;;;;;,,:cc:;'',,''''.''''    //
//    OOOOOOOOOOOOOO00000000000000000000000000000000000000000000000000000000000000000000000OOOkkkOOOOOkkkkkxxdddo:'.             .';lolllllloolllllc:clc:;:ccc:::ccccc::;;,;;;:;;;;;;;;;;,',;;,''..'',,,,,,,''    //
//    OOOOOOOOOOOOOOOOOOOO000000000000000000000000000000000000000000000000000000000OOOOOOOOOOOOkxkkOOkxdddoooodxkxo:'             .,coooolloooolllc:;::;;;;;:c:;;:cc:;;::;;::;;;::;;:;;;,''',,''','..,;:;,;;;;    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00O0000000000000000000000000OOOOOOOOOOOOOOOOOOOOOkkkkkxdoooollc:lodxxxxxdlc;.            .,looooollllllc:;;;,,,,,,,;;;;;:cc,',;::cc:;;;;;;;,,''...,;;;;;::;,;:;;;::cc    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkxxxdoooolcc::;;::cdkOOxdxxdocll,             'clllllcccccc:;,,''''''',,,,;:;,'..';:;,''''',,,,......',;;;;;::;;;;;;::::c    //
//    kkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkxxxdddddollollcc:::::::::::;;;;:okkxxdxxxdlloo;.            .:l:;:ccccc:::;,'''.''''''',;;;'',,;:;;'.'',''..........'''',;;;;,'''',;;::    //
//    kkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkxxxxxddddoollllcccc:::;;;;;;;::;:::::;;,;lxddodxxddlloc'             .,;,',,;:::;;;,,''''''',,,,,,;,,,;;,,,,,,,''..........''....';:;;,',;;,;:;;    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxddddddooollccc::::::;;;;;;;;::::::::;;;;;;:llccdkxdooll;.             ..''..',,,,,,,'''''...''......'',;;;'..''............''',''',;;;;,,,;;:;;;;    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxkxxkxxxxxxxddddddddddooooollccccc::::;;;;;;:::;:::::::::c::::;;;;::;cxkddollc,.            ......'''''''',,,,''...''.....',''',,''''............''.';;;;;;,,,;,,,;;,'',    //
//    kkkkkkkkkkkkkkkxxxxxxxxxddxxxxxdddddddddooooolllllllllcc:;::;;;;:cc:;;;;;;;;;;;;;;;;;;:::::;;;;;,,;ccoxxdolll:'..           ..........'...'''''...'''',,'',;,',;;::;,.............'',;;;;;;;,,,,,',,,,,,    //
//    kkkkkkkkkkxxxxxxxdddddddddddddddoooooolllllcc::::ccc:;;,',,,,,,;;;;;;;;;;;;:;;;;;;;:;;::;;;;,;;;,,;ldxxdollc:'...            ......'.'''''''.....','.',,;;:::;;;,;,''.............',;;::;;;::;',,',;,,,'    //
//    xxxxxxxxxxxxxxddddddoooooodooooollllccc:::::;,,,,,,,,,,,,,,,;,,,,,,,;;;;;;;;;;;;;;:cc:;,,,,,,,,,',lxkxdoolc:,'''.             .''''',,,'.''.....',,,,;;:;;;,,'''..................',;;,,,,,;::,'',;;'',,    //
//    xxxxxxxxxxxdddddooooooolllllllccc:::;;;;;;;,,'''''''',,,,,,,,,,,,,,;::;;;;;;;;;;ldkOOOxoc::codl:cdkxxddollc;',;;'.           ..'''..'''........',,,;;;:;;,'''.......................,,,'',;;;;,',,;;'..'    //
//    xxxxxdddddddooooollllllccccc::::;;,;;;;,,,,,,,'',,,,,,,;;,,,,,;;;,,;;;;;;;;;,,;:dOO000KXKkkO00Okkxdlllllc:;',;::,.           ...............'',,,,,,,,,,'...........................,;;,,;:;,,'.',,,''''    //
//    dddddoooooolllllccccc:::;;;;;,,,''',''','',,,,,,,,,,,,;::;;;,,,,,,,,,;,,,,,''',ldodxkO000Okxxkkdlcccccc:;,,,:ccc;..          ........''...''''''',,''.............................',;::;;;,,,,'..''..',,    //
//    ooollllllcccccc:::;;;;,,,,''''''''''..'''''',,,,,,,;;;;,,,,,,,,'''''',,''''''':ooc:cdxkOOOkxoool:;,,,,,,';:c:ccc:'..         ......',;;,'''.........................................,;;;;,,'','......',,    //
//    llccccccc::;;;,,,,,''''''''''''.'......'''''',;;;,;;;;,,,,,,''''''''.........;odoc;,;cdxkOOkdooc;,'',,,;:clollllc,..       .....''',,,'....................................  .......',,,;;;,,,,......''.    //
//    ::::;;;;,,,,''''.''..''..''''''''.......''.',;;::;,,''''','''''''...........':lllc:'..:dxddddddollccllllooodooooc;;,. .   ....''...'''....................................  ............,,,,''''........    //
//    ''''''''''''''.....''',,',,,,,,,'.......'...'..''...''''''''''',,''',,,'....,cccc:,'..,oocloodddxoloddoodddddoolcccc'.....'............'................................................................    //
//    '..................'''',,,;;;,,,........'...........'''...........''',,,'''';::;;,.. .:ol:cllooodloxxdoddoooooooolll:,,'.:l:''..........................................................................    //
//    ,'''.....................'''''..........'........................'''',,,,',,:::;'... .:ol:ccclooolodxdddoooooollllooolccccxkd:'..........'..''................. ............................''''........    //
//    '''..................'',,,,,'...........,'....'''''.....''''.......'...'...'::;,.....'col::cccooooollloooooooolllooooddxxodkOko,'''''''........................   ......................................    //
//    .............''.''',,,,,,,,'..'...................''.......................;:;,......,ldl:;:c::oddollllllllcclccloolldxkkkxO00kc,''.............................   .....................................    //
//    ....'.......',,''..''.....................................................'cc;'.. ...,ldl:::cc::lolc:;;::::::::loolloooxkxkO000kl:,,,,'........''..''...........   .....................................    //
//    ..........................................................................,ccc:,.....;odol::ccclc:;;;;;;;;;:ccllcclloodkkkO0000ko,..';:;,'''''''''..'...........    ....................................    //
//    ..........................'................................''''...........cocc:;''''':oddol:lodddollllclllloooodddoxkxkkkO0OO0Ooc;....''',,,;;'.................    ..........................',,,'.....    //
//    ..........................................................''''''........'co;...''',:clodxdoodxxxkkkkkkkxxxxxxkkxxxxkkkkkO0OO0kxocl:'.......',,;,,,..............   .....'..''..',,''''''...',,,;,','''''    //
//    .................................................'......'''',,'........,::'...'';looccoxxxdkOOkOkkkxxxxddddddodkOOOOOOOO0OkOOxolcll:c:'.....','..;;'......','...........'''''''''''''''.''''',,',,,,,,;:    //
//    ....................................................'..'''.............,'...'''.:ollcoxxxxkOkkkkOOOOkkxxxkxooxOOOOOOOOkOOxdoc;;:cc:c:;;;.....'..,'.....'''''...'''...'..'''''.','''','....''',,,,,,,''''    //
//    ..............................'''..................'',;,,'.................'''.,ldodkOkxkkOOOkkkxxxxkkkkxolokOOOOO0OOkOkddo;,,,,:cc;,',,,;,'....',,,,;::;'.....'''''''''''',,'',,'''''''..'',,,,,'..''''    //
//    .....  .. .....  .........''.......................'''''..............'..',''..:ddodxkkxxk00OkkkkkxxxddollxOOOOOOkxoollc:;,;;,,;;:::,','',;::,.......;clll:,.....''''''''.'''''''''..'........'''...''',    //
//          ..          ..........''.........  .  .....'..''......''..''',,,,,''''...,ldddoloxddkOOkkxxxxddooxkOOOkxoc::;',;;,,,,;;,''''','..',;,,;:;......',;:::c:;,'.',;,'',,;,'..''''............','...''''    //
//                  ..........................       .......'',,,;;;,,,,;:;,,,,''......,;,'..:doloddddoollloxOkdlc;'.'',,,,,;;,,''''.....''..'','',;:,......',,,;clc;,'',,;;;,;:;,'..........''....'''',,...''    //
//                .....................  ........ ..........',,;c:,;;;,,,;;,,'''..............'clolcloooddoolc:,''''''''',,,;;,''''''........''''''';;'.....';;;::;;;;,,;;;;;;,,'''''...'...........''''''....    //
//      ..........','.................  ..................'',;',cc;;;;,;:::;,'.''...........   ..,;:;;;;;;;,,,,',;,...'''',;,'..''''                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SL1 is ERC721Creator {
    constructor() ERC721Creator("SarahLyndsay 1/1s", "SL1") {}
}