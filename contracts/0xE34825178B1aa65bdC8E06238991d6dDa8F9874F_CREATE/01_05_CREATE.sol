// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CREATING SPACE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKK000KKKKKK0000000O00000000OOOOOOOOkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkOOOOOOOOOkkkkkkkkkkkk      //
//    XXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000000000000OOOOOOOOOkkkkkxxxxxxxxxxxxxxxxxxxxxxxdddddxxxxxxxxkkkkkkkkkkkkkkOOkkkkkkkkkkkkkkkkk      //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKXXXXXXKKKKKKKKKKKKKKKKKKKKKKKK0000000000000OOOOOOOOOOOOOOOOkkkkkkxxxxxxxxxxxxxxxxxxdddxddddddxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk      //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXKKKXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0KKKK000000000OOOOOOOOOOOOOOOOOOkkkkkkkkkxxxxxxxxxxxxxxxxddddddddddddxxxxxxxxkkkkkkkkkkkkkkkkkkkkxxkkxxxxxxxx      //
//    -------------------      _/_/_/                                  _/      _/                            _/_/_/                                         -------------------------      //
//    -------------------    _/        _/ _/_/    _/_/      _/_/_/  _/_/_/_/      _/_/_/      _/_/_/      _/        _/_/_/      _/_/_/    _/_/_/    _/_/    -------------------------      //
//    -------------------  _/        _/_/      _/_/_/_/   _/    _/    _/      _/  _/    _/  _/    _/        _/_/    _/    _/  _/    _/  _/        _/_/_/_/  -------------------------      //
//    -------------------  _/        _/        _/        _/    _/    _/      _/  _/    _/  _/    _/            _/  _/    _/  _/    _/  _/        _/         -------------------------      //
//    -------------------   _/_/_/  _/          _/_/_/     _/_/_/      _/_/  _/  _/    _/   /_/_/_/      _/_/_/    _/_/_/      _/_/_/    _/_/_/    _/_/_/   -------------------------      //
//                                                                                             _/                _/                                                                        //
//                                                                                           __/                                                                                           //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx      //
//    XXXKKXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKXXXXXXXXXKKKKKKKKKKKKKK0KKKKKKKKK0000K00000OOOOOOOOOOOOOOOOkkkkkkkkkxxxxxxxxxxddddddddddxxdddddddddxxxxxxxxxkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxx      //
//    XXXXXXXXKKKKKKKKKXXXXXKXXKXXKKKKKXXXXXKKKKKKKKKKKKKK000000000000000000000000000OOOOOOOOOOOOOOOOOOOkkkkkkkkkxxxxxxxddddddddddddddddddddddddddxxxxxxxxxxxxkkkkxxxxxxxxxxxxxxxxxxx      //
//    XXKKKKXKXXKKKKKKKKKKKKKXKKKKKKKKKKKKKKKKKKKKKKKK0000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOkkkkkkkkxxxxxxxxdddddddddddooodddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx      //
//    KKKKKKKKKKKKKKKKKKKKKKKKKK0000000KKKKKKKKKKKKKKKK00000000000000000000OO00000OOOOOOOOOOOOOOOOOkkkkkkkkkkxxxxxxxxxdddddddddddddoodddooodddddddddddxddxxxxxxxxxxxxxxxxxxxxxxxxxxxx      //
//    KKKKKKKKKKKKKKKKKKKKKKK0000000000000000KKKKKKKKK00000000000000000000000OOOOOOOOOOOOOOOOOOkkkkkkkkkkkkxxxxxxxxxxxdddddddddddooooddddoooooodddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx      //
//    KKKKKKKKKKKKKKKKKKKKKKK000000000000000KKKKKKKKKKKKKK00000000000000000000OOOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxddddddddooooooooooooooooooddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx      //
//    KKKKKKKK00KKKKKKKKKKK000000000000000000KKKKKKKKKKKK00000OOOOO0OOOO000000OOOOOOOOOOOOOkkkkkkkkkxxkkkxxxxxxxxxdddddddddooooooooooooooooooooodddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxx      //
//    000000KKKK00KKKKKKKKKKKKK0000000000000000000000000000OOOOOO0000O000000OOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxxxxxdddddddddoooooooooooooooooooooodddddddddddddddddddxxxxxxxxxdxxxxxxddd      //
//    00KKKKKKKKKKKKKKKKKKKK00000000OOO000000000000000000000OOOO000000000OOOOOOkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxddddddddoooooooooooooooooooooooddddddddddddddddddddddddddddddddddddd      //
//    0000000000000KKKKK00000000OOOOO0O0000000000000000000000000000000OOOOOOOOOkOkkkkkkkkkkkkkkkkkkkxxxxxxxxxddddddddoooooooooooooooooooooooooooooooddddddddddddddddddddddddddddddddd      //
//    0000000000000000K000000000OOOOOOOOOOOOO00000000000000000OOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkxxxxxxdddddddddddooooooooooooooooooooooooooooooooooooodddddddddddddddddddddddddddd      //
//    0000000000000000000000000000OOOOOOOOOOOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxxddddddddooooooooooooooooooooooooolloooooooooooooooddddddddddddddddoooooooooddd      //
//    000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOkkkkkOOOkkkOOOOOOOOOOkkkkkkkkxxxxxkxxxxxxxxxxxdddddddddoooooooooooooollloooooolllllllllloooooooooooooddddddddddooooooooooooood      //
//    OOOOO0000000000000000OOOOOOOOOOOOOOOOOOkkkkkkkOOkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxddddddddddoooooolllllllllllllllllllllllllllllooooooooooooooooooooooooooooooooooooo      //
//    OOOOOOOOO0000000OOO0OOOOOkkkOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxkxxxxxxxxxxxxxxxxdxxxddddddddddddoooooooolllllllllllllllllllllccccllllllooooooooooooooooooooooooooooooollll      //
//    OOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxdxxxxxxxxddddddddddddddddddooooollllllllllllllccccccccccccccclllllllllllooooooooooooooooooooollllllllll      //
//    OOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddddddddoooooooollllllllccccccccccccccccccccccccclllllllllllloollllllllllllllllllllllll      //
//    OOOOkkkkkkkkkkkkkkOOkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddooooodooooooooooooollllllllcccccccccccccccccccccccccccllllllllllllllllllllllcllllllllllcccc      //
//    kkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddoooooooooooooooooooooooooolllllllddooolc:::::cccccc:::ccc::cccccccclllllllllllllllccccccccccccccc       //
//    kkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddooodoooooolllllllllllllllldxkkxxxxddoc:::::::::::::cc::cccccccccllllllllllccccccccccccccccccc      //
//    kkkkkkkkxkkkkkkkkxxkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddooooooooooooolllllllllllllldkkxxxxxxddxdc::::::::::::::::::::cccccccccccccccccccccccccccccc:::c      //
//    kkkkkkxxxxxxxxkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddxxxxxxxxxxxxxxxxxxxxdddddddddoooooooooooooooooolllllllllclxOOkkkxxddxxxl:::::::::::::::::::::::cccccccccccccccccccccccc:::::::      //
//    kkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddxxxdddxxxxxdddddddddddooooooooooooooooollllllllccccokkkkkxddddxo:;;;;;;;;;;;;::::::::::::::::cccccccc::cc:::::::::::;;:      //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddddddddddddddooooooooolooollllllllllcccccc::coxxxddodddl:;;;;;;;;;;;;;;;;:::::::::::::::::::::::::::::::::;;;;;;      //
//    xxdddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddddddddoooooooooooooooooolllllllllcccccccccc::::::clllccc:;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::::::::::::::;;;;      //
//    xxddddxxxxxxxxxxxxxxxxxxxxxxxddddxxxxxxxdddddddddddddddddddddddddddddddddooooooooooollllllllcccccccc:::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;      //
//    xxxxdddddddddddddddddddddddddddddddddddddddddxxxddddddddddddddddddoooooooooooooooolllllllcccccccc::::::::::;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      //
//    xxdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoooooooooooollllllllllccccccccccc::::::::;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;;;,,;;;,,,,,,,,,,,,,,,,,,      //
//    dddddddddddddddddddddddddddddddddddddddddddddddddoooooooooooooooooooooooollllllllllccccccccccc:::::::;;;;;,,,,,,,,,,,,,,,,,,,,',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,      //
//    ddddddddddddddddddddddddddddooodddddoooooddoooooooooooooooooooooooooooollllllllllccccccccccc:::::;;;;;;,,,,,,,,,,,,,,,,,,,'',,,,,'''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'      //
//    dddddddddddddddddddddoooooooooooooooooooooooooooooooooooooooooolllllllllllcccccccccccc:::::::::;;;;;;;,,,,,,,,,,,,''''''''''''''''''''''''''',,',,,,,,,,,,,,,,,,,',,'''''''''''      //
//    dddddddddddddddddooooooooooooooooooooooooooooooooooolllllllllllllllllllccccccc:c::::::::::;;;;;;;;;,,,,,,,,,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''      //
//    oodddddddodddodddoooooooooooooooooooooooooooooooollllllllllllllllccccccccccccccc:::::::::;;;;;;;,,,,,,,,'''''''''''''''''...............'''''''''''''''''''''''''''''''''''''''      //
//    oooooooooooooooooooooooooooooooooooloooooolllllllllllllllllllccccccccccccccc:::::::::;;;;;;;,,,,,,,,,,,''''''''..............................''''''''''''''''''''''''..........      //
//    ooooooooooooooooooooooooolllllllllllllllllllllllllllccccccccccccccc:::::::::::;;;;;;;;,,,,,,,,,,,,''''''''..........................................'.....''''.................      //
//    oooooooooollolllllllllllllllllllcccccclllllllllllcccccccccccccc::::::::::;;;;;;;;;;;;;,,,,,,,,,,''''''''''.....................................................................      //
//    olllllllllllllllllllllllllllllllllccccllllccccccccccccc:::::::::::::::;;;;;;;;;,,,,,,,,,,'''''''''.............................................................................      //
//    llllllllllllllllllllllccccccccccccccccccccccccccccccccc:::::::::::;;;;;;;,,,,,,,,,,,,,,,,''''''''''............................................................................      //
//    llllllllccccccccccccccccccccccc::::::::::::::::::::::::::;;;;;;;;;,,,,,,,,,,,,,,,'''''''''''''.................................................................................      //
//    ccccccccccc:ccccccccccc::::::::::::::::::::::;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,'''''''''''''''''...................................................................................      //
//    ccc:::::::::::::::::::::::::::::::::::::;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,'''''''''''''''..........................................................................................      //
//    :::::::::::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,'''''''''.................................................................................................      //
//    ::::;;;;:::::::;;;;;;;;;;;;,;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,''''',,'''''''''''..................................................................................................      //
//    ;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''''........................................................................................................      //
//    ;;;;;;;;;;;;,,,,,,,,;;,,,,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''''''.....................................................................................................             //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''''''''''''''''''''''''''''''.......................................................................      .  ............                             //
//    ,,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''''''''.............................................................................. ..              ..                                       //
//    ,,,,,'''''''''''''''''''''''''''''''''''''..........................................................................                                                                 //
//    '''''''''''''''''''''''''''''............................................................................ ....                                                                       //
//    '''....''...'''''''......................................................................................                                                                            //
//    '''''''''...'''''''...................................................................................                                                                               //
//    '..........'....''...........................................................................                                                                                        //
//    .......................................................................................  ...                                                                                         //
//    .......................................................................................                                                                                              //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CREATE is ERC721Creator {
    constructor() ERC721Creator("CREATING SPACE", "CREATE") {}
}