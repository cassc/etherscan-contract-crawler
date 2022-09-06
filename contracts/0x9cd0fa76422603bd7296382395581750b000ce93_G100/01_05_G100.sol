// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Guardians Century
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                          .....................  ... .........................................   .                              //
//                         .........................................................................   ...                        //
//               ....   ....................................................................................                      //
//             ...............................................................................................    ...             //
//         ...........................................................................................................            //
//    .......................................................'''''''''................................  ................          //
//    ...................................................''',,,,;;;;,,''''.................................................       //
//    ................................................''''',;::clddlc:;,,''''................................................     //
//    ...........................................'''''''',;:clld0NN0olc:;,,,'''...'..........................................     //
//    ........  ................................''''',,;;:cllox0NNNN0dolc:;;,,''''...........................................     //
//    ........................................''''',,,;:cloodx0XNNNNX0dolc:;;;,,,''''.........................................    //
//    ....................................''''''',,,,;:looddx0XXXXXXNXOdolc::;;;,,,'''''''....................................    //
//    ...................................''.''',,,,;;clodddk0XXXXNNNNNXOxdolc::;;,,,,,''''....................................    //
//    .....................................''',,;;;;cloddxk0XNXXXNNNNNWXOxdolcc::;;,,,,,'''...................................    //
//    ....................................'',,,,;;:cloddxk0XNNNXXNNNNNNWXOkxdolc::;;,,,,,''''.................................    //
//    ...................................''',,,;;:cloddxkOXNNNNXNNNNNNNNNXOkxdolcc:;;,,'''''''................................    //
//    ..................................'',,,,;;:cloddxkOKNNNNNNNNNNNNNNNNX0kxdollc:;;,,''''''................................    //
//    ...............................'''',,,;;;:cllodxkOKNNXXNNNNNNNNNNNNWWKOkxdolc::;;,,''''''...............................    //
//    ..............................'''''',,;;:clooddxOKNNXXXXNNNNNNNNNNNNWNKOxxdolc::;;,,,''''...............................    //
//    .............................''''''',,;::cloddxk0NNXXXXNNNKKXNNNNNXNWWNKkxxdllc::;,,,,''''..............................    //
//    .........................'''''''''',,;;::loodxk0NNXXXXNNNKOOOKNNNXXNNWWNKOxdolcc:;;;,,,'''..............................    //
//    .......................''''''''''',,;;::clodxk0NNNNNNNNXKOOOkOKNNNNNNNWNX0kxdoc::;;;;,,''''.............................    //
//    ......................''''.''''''',,;;::clodk0XNNNNNNNNKOOOOOkOXNNNNNNNXNN0xolcc::;;;,''''''............................    //
//    .....................'''''''''',,,,,,;;:cldxOXNXNXXNNNKOOOOOOkO0XNWNNNXXNWXkollc::;;;,,''''''...........................    //
//    ....................''''''''''',,,,,,;::loxOXNXXXXXNXK0OOkkkkkOO0XNNXXKXWWWKxllc::;;;;,,'''''...........................    //
//    ...................'''''',''''',,,,,;;:cldkXNNNNNNXXKOOOkxxkkOOkk0XXKKXNWWWN0dlc::;;;,,,''''''..........................    //
//    ...................''''''',,,''',,,,;;:clxKNNXNNNNXKOkOOkkxk00O0OO0K00XNNWWNKdlc:::;;,''''''''..........................    //
//    ...................'''''''''''',,,,,;;:coOXXXXXXXNKkkkkOO000K0000OO000KNNNWNXOoc:::;,,'''''''''.........................    //
//    .................'''''''''''''',,,,;;:clkKKKKKXXX0kxxkkOKOoodOKKK00O00XNNNNNNKklc::;,,,,,,,,,'''''''..''................    //
//    ...............'''''''''''''''',,,;;::cd0KKKKK0KK0kkkOO00c...:0XXXK00KNWNNNNWWKdc:;;,,,,,,,,,'''''''''''................    //
//    ...............''''''''''''''',,,,,;:cok000KKKKKKKOOOO0XXd..'lKXXXXKKXNNNNNWWNXKkl:;,,,,,,,,,''''''''''''''''''''.......    //
//    ..........''''''''''''''''',,,,,,,;;:oxO0KKKKKXKKKXXXXNXOl::lodkKXKK00KNNNNWWWNNKkl:;;,,,,,,,'''''''''''''''''''''......    //
//    '''''''.'''''''''''''''''',,,,,,,;;;cdkO0XNXXXXKXXXXXNXx:,;;;;;;ck00KKXNNNNNWWWNX0dc:;;;;,,,,,,,,'',,,,''''''''''''''''.    //
//    '''''''''''''''''''',,,'',,,,,,,;;;cd0XNWWWWWNNXXXXXXXkl,''','..'lOO00XNNNNNNNNWNXkl::;;;;;,,,,,,,,,,,,,,,''''''''''''''    //
//    '''''''''''''''''',,,,,,,,,,,,;;:ldk0XNWWWWWNXXXXXXXKOo;'...'''.':xOOOO0KXXNNNNNNNX0xoc:;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,'    //
//    '',,,,,,,,,,,,,,,,,,,,,,,,,,,,,;lk0XXNNWNNNNXXXXXK0dc:c,......'',;cdxkOO00KXNNNNNNXXK0kl:;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;,;lx0XNNWNNNNNXXK0Oko:;:;,.''...',,',cooxkkOO0KXXXNNNX0xoc::;;;;;;;;;;;;;;,,;;;;;,,;;;;;;,    //
//    ,,;;;,,,,;;;;;;;;;;;;;;;;;;;;;;:lxKNWNNNNNXK00kxdl::::;''''...',,'';llloxkO000KKKKKXX0xl:::::;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::lkKNNNNNNNXK0Okdlcc:c:;,'''''.'',,,',:clllodkOO0KKK00KXKkl::::c::::::;:::::::::::::::::::    //
//    ;;;:::::::::::::::::::::::::ccoOKXNNNNNNXK0kdlc:cc:::;,',',,''',;,'',,;clllodxO0000OOK0Okdlcccccc:::::cc::cc:::::::ccccc    //
//    :::::::::::::::::::::::ccccclokKXNNXXXK0xdoll::ccc::;,,,,,,,,,',;;,,,,,,:cclllodkO0OOOOO00xocccccccccccccccccccccccccccc    //
//    :::::::ccccccccccccccccclllodxkO000OOOkxlcclllllcccc:,',,,,;;,,,;;::;;;;::cccccccldxkxkOO0kxdlcclccccccccclllllllcclllll    //
//    ccccccccccccccllllllllllodxkkxddxkkxdlclolllllllllol;',,,,,;:;,,;;:cc;;::c:cclllccclodxO0OOOOxollllllllllllllllllllllooo    //
//    ccclllllllllllllooooooddxkOOkkxxddoccccloooolooooxxl;,;;;;;coc;,;;:clc:cccccccloolllllodxkO0O0Odoooooooooooooooooooooooo    //
//    llllooooooooooooooddddxkOOkkkxdooollolloooodddxkkxoc;;::::coxoc::;;cloollllcllooooooollllodk0XX0kddddodddddddddddddddddd    //
//    oooooodddddddddddddxxk0K0kxxxoooooddddxddoooxkkdlc:clllllloxkdoolllclodxxdooddddxxdddooollooxO0XKOxddddddddddxxxdddddddd    //
//    oddddddddddxxxxxxxkk0K0kxdddddddddddxxxxxxxddoc::clokkddddxkkkddxkkxoclodddxxxxxxkxxxxddoooodddk0K0kxxxxxxxxxxxxxxxxxxxd    //
//    ddddxxxxxxxxxxxkkk0K0Oxddddddxkxxxxkkkxxdolc:;;;;:coxOOOkOkO00O0KKkdlcccllodxkkkkOOOOkkxxxxxxxddxkKKOkkkkkkkkkkkkkxxxxxx    //
//    xxxxxxkxxxkkkkkkOKNXK00000K00KKKKKKKKK00OOOOOOkxxxxxk0KXXNNNNNNNX0kkOOOOOOO0KKXXXXXXKKKKKKKKKKKKKKKK0OOOOkkkkkOOOOOkkxxx    //
//    xxkkkkkkkkkkOOOOOKXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNNNNNNNNNXXXXXKK0OOOOOkxxkkOOkkkkkkkx    //
//    xxxxxxxkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOO00OO0000000000KK00000KKKKK0000000000000000OOOOOOOOOOOOOOOkkkxkkkkkkkkkxxxx    //
//    lllllloooodddooooddddddddddddddddddddddddddddxxxxxddddxxxxxxxxxxxxxxxxkkxxxxxxxxdddddddddodddddddddxxdddooooooodoooooooo    //
//    ::::::::cccccccccclcccccc:cccccclccccllcccllllllolcccclllolcccclllcclllllcccccccccccc:ccccccc:::ccccccccccccc::::::::::;    //
//    ,,,,,,,,,;;,,;;;;;;;;;;;;;;;;;;:;::::::;;;;;;;;;:;;;;;;;;;;,,;;,;;;,;;;;::::::;;;;;;;;;;;;;;;;;;;;,,;;;;;,,,,,,,,,,'',''    //
//    '''''''''''''',,,,,,,,,,'',,,,;;;,;,'',,,''''''''','''''''.''''......''''',,,,,,,,,,,'''',;;;,,,;;,',,,,''''''''''''....    //
//    ................''''..........''''....................................''..................'......'...'.......''''.......    //
//    ........................................................................................................................    //
//          ............. ....................................................................................................    //
//          .... ................  ....................................................      .......          .......             //
//         ....                                  .....      ........................                         . ..  ....           //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract G100 is ERC721Creator {
    constructor() ERC721Creator("Guardians Century", "G100") {}
}