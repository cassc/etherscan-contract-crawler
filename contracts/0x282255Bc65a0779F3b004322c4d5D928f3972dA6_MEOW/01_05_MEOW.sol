// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meowieverse
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MEOWIEVERSE (C) 2023 MELLOWMANN SENSORAMA MELLOW NOIIZ PAWLICIOUS ENTERPRISE        //
//    ''''''',,,,,,;clllc:;,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:cclllc::;;;;;;;;;    //
//    ''',,,,,,,,,:lodxxxxdl:;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::lodddolc:::::::::::    //
//    ,,,,,,,,,,,;clodkkkkkxdoc;;;;;;;;;;;;;;;;;;;;;;;;;;;::::;:codddxxddlc:;:::::::::    //
//    ,,,,,,,,,,,;clodkkOOOkkxdoc::clooolc:::::::::::::::cccccloddddxxxdolc:::::::::::    //
//    ,,,,,,,,,,,;clodxkOOOkkxxdoodxkO000OOOOOOOOOkkOOOOOO00kdlclloddddollooc:::::::::    //
//    ,,,,,,,,,,,;codddxkkkkxxdllllxOKXXXXNNNNXXNNXNNXXXXXXOo:;;::clooolodkxlc::::::::    //
//    ,,,,,,,,,,,;cdkxxddddooll::::ldOXXXXXNNNNXXNXNNXXXXXOolc:;,,;;:cclxO0kl:ccccc:::    //
//    ,,,,,,,,,,;,:x00Okdlcc::::ccloxOKXXXXNNXXXXXXXXXXXXKOdoc:,'.'',;cdOKKklccccccccc    //
//    ,,,,,,,;;;;;;d0KKOkdlc::codxkO00KXXNNNXXXXXXXXXXK000kdoolc:;,',;lx0K0xlccccccccc    //
//    ,,,,,,;;;;;;;o00OOkdolldkO000KKKKXXKKXXXKXXK0KKOkkxdoolodddol;,;lkOxkxlccccccccc    //
//    ,,;;;;;;;;;;;lOOO0kdlcoOKKKKKKKXXKKKKK00000kk0Oxxkxoolloodooc,';oOOO0xlccccccccc    //
//    ;;;;;;;;;;;;;:d0NNOkkxk0KKKXXXXXXXXXXK00000kk00kkOkxxddxddlc;,:okKKKOocccccccccc    //
//    ;;;;;;;;;;;;;;cxKX00XXXXXXXXXNNNNNXXXXKKKKKOOKK00K0OOOO0OOxocldO0K0xollccclllccc    //
//    ;;;;;;;;;;;;;;;:lxOKKXNNNNNNNXXXXXXKKKXXKKOkk00OO0OkkO0000OkxdxkOkocllllllllllll    //
//    ;;;;;;;;;;;;;;;;cdOKXXNNNXXXKKKKK00OOOOOkkxddxxddoodkkxdolodxxxxxdolllllllllllll    //
//    ;;;;;;;;;;;;;;::;:lx0KXXX0koccc::cdddoodddxxxdoc:::c:;'....,lxdlllllllllllllllll    //
//    ;;;;;;;;;;;;::::::::oOKXKOd::;...',;:coxxkOOOxl:;,..... .;,'cxocllllllllllllllll    //
//    ;;;;;;;;;;;:::::::::cd0KKKOxoc;,:c:;:ok00KXXX0dl:'..,:;;:c;;odlcllllllllllllllll    //
//    ;;;;;;;;;::::::::::::okO0KK0xdoooddxxkOKKXNNNXOdc:looooolccodl:lllllllllllllllll    //
//    ;;;;;;;;:::::::::::::cdkkOO00OkkkO0KKKKKXXXNXX0kddkO0OOkxxdl::clllllllllllllllll    //
//    ;;;;;;;:::::::::::::::ldxddddxkk0KXNNXXKKKKXXKOkxkO00Okdl:;,;:llllllllllllllooll    //
//    ;;;;;::::::::::::::::::coolccldOKXNNNNKOxoodxo:;cx000Od:,,,,:clllllllllllooooool    //
//    ;;;;:::::::::::::::cll:,;clc::lOXXXNNNXOxo:;,'.,lk00OOd:,,;cllllllllllllllllooll    //
//    ;;:::::::::::::::::lol:,',:cc:lOXXXXXXXKKK0o;cdkOOOkkxl:;:lllllllllllloooooooool    //
//    :::::::::::::::::::ldoc:;,,:c:lk0000000OOOxl:codxddolc::cllllllllllllooooooooooo    //
//    :::::::::::::::::::lodoc;,,,,,;:coooollc::;,;;;;;,;;;,;llllllllllllloooooooooooo    //
//    ::::::::::::::::ccccloooc;,''....',;;:;;;;::;;,,,,'....,cllllllllooooooooooooooo    //
//    ::::::::::::::cooddolclooc:,'........',;;;::;;;,'.......,coolloooooooooooooooooo    //
//    ::::::::::::cldxxxdool:::cc:;,..........................,collloooooooooooooooooo    //
//    :::::::::::oO0kkkkxolllc::;;;;;,'......................,cloooooooooooooooooooooo    //
//    :::::::::cxKXXX0Okxxdlc:clc:;,,,''.....................,looooooooooooooooooooooo    //
//    :;;;::::cxKXXXKKK0Oxxddlc:::cc:;,''....................,cooooooooooooooooooooooo    //
//    ;;:;;;:lkKXXXXK0OKX0kxdool:,;;:::;;,...................':clloolooooooooooooooooo    //
//    ;;;;::oOKXXXXXXKOO0XK0kddollc;,''',,,''''................',;;clloooooooooooooooo    //
//    ;;;;cx0KXXXXXXKKK0O0KXK0kxoooolc;'......'.................''..,;cloooooooooooooo    //
//    ;;;lx0KXXXXKKXKKKK0O0KKKK0kdoloollc;,'..........................';cloooooooooooo    //
//    ;;lk0XXXXXXXKKKKKKK0kO0KKKK0Oxoccccc::;,,'.......................',:looooooooool    //
//    :lxOXXXKXXXXXKKKKKK0OkkO000K000kdl;,''''''',''.................''',,:loooollllll    //
//    lodOXXXXXXXXKKKKKKKK0OxxkO0000000Oxoc;'........................'',,;:cllllllllll    //
//    olodOXXXXXXKKKKKKKKKK0xodkOO000000OOkxoc;,'................''...,;;::cloolllllll    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MEOW is ERC1155Creator {
    constructor() ERC1155Creator("Meowieverse", "MEOW") {}
}