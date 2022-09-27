// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Melancholia
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ;:::::::::::::::::::::ccccccccccccccc:::::::::::::;;;;;;;;;;;;;;;;;;;;,,,,,,,,'''''.........'',,,,,,,,,;;;;;;;;;;;;;;;;:;;;;;:;;;;;;;;;;;;;;;;,,,,,,,,    //
//    ::::::::::::::::::::ccccccccccccccccccc:::::::::::::::;;;;;;;;;;;;;;;;,,,,,,,,,'''''........',,,,;;;,;;;;;;;;;;;;:::::::;;;:::;;;;;;;;;;;;;;;;;;;,,,,,    //
//    ::::::::::::::::::ccccccccccccccllcllcc::::::::::::::::;;;;;;;;;;;;;;;;,,,,,,,,,''''.......'',,;;;;;;;;;;;;;;;:::::::::::::::;;;;;;;;;;;;;;;;;;;;,,,,,    //
//    :::::::::::ccccccccccccccccccclllllllccc::::::::::::::::;;;;;;;;;;;;;;;;;;,,,,,,'''''......'',,;;;;;;::::::;::::::::::::::::::::::;;::;;;;;;;;;;;;;,,,    //
//    ::::::::::ccccccccccccccllllllllllllcccc:::::::::;;:::::::;;;;;;;;;;;;;;,,,,,,,,'''''......',,;;;;;;::::::::::::::ccc::cccc:::::::::::;;;;;;;;;;;;;;,,    //
//    ::::::::::cccccccllllllllllllllllllcccccc:::::::::::::::::::;;;;;;;;;;;;,,,,,,,,,''''......',;;;;;;::::::::::::cccccccccccc:::ccc:::::::::;;;;;;;;;;;;    //
//    :::::::::cccccclllllllllllllllllllllccccccc:::::c::::::::::;;;::;;;;;;;;,,,,,,,,,,''''....'',;;;;;;::::::cc::ccccccccccccc::cccccc:::::::::;;;;;;;;;,;    //
//    ::::::cccccccllllllllllllooooolllllllllccccccccccc::::::::::::::;;;;;;;;,,,;,,,,,,''''....',;;::;;;:::::cccccccclllllllcccccccccccc::::::::::;;;;;;;;;    //
//    ::::::cccccccllllllllllloooooolllllllllccccccccccccccc::::::::::;;;;;;;;,,;;,,,,,,''''....',;;:::::::::ccccccccclllllllccccllllccccc::::::::::;;;;;;;;    //
//    :::ccccccclllllllllllllooooooolllllllllclllccccccccccccc::::::::;;;;;;;;;;;;;,,,,,''''....',;;:::::::ccccccccllllllllllccllllllccccccc:::::::::::;;;;;    //
//    ::cccccccllllllllllllllooooooooooollllllllllllllcccccccccc::::::;;;;;;;;;;;;;,,,,,''''....',;;::::::ccclccclllllllllllllllllllllcccccccccc::::::::::;;    //
//    ::ccccccclllllllllllllllooooooooollllllllllccclllcccccccccc::::::;;;;;;;;;;,,,,'''''''....',;:::cccccllllllllllllllllllllllllllllclcccccccc::::::::::;    //
//    ::ccccccllllllllllllllllllloooooooollllllllllllccccccccccccc::::::;;;;;;;;;,,,,,',''''....';;:::ccccllllllllllooooolllllollllllllllccccccc::::::::::::    //
//    cccccccccllllllllllllllllooooooooooooolloolllllccccccccccccc:::::;;;;;;;;;;,,,,,,,''''....,;::ccccclllllooooolooooooloolollcclllllllccccccccc:::::::::    //
//    :cccccccccllllllllllllloooooooooolooooolloollllcccccccccccccc::::;;;;;;;;;;;,,,,,,,'''....,;::cccllllllooooooooooooooooooollllllllllllccccccc:::::::::    //
//    ::cccccccclllllllllllloooooooooollloooolllllllllccccccccccccc::::;;;;;;;;;;;;;,,,,,,,''...,;::cccllllllloooooooooooooooooollllllllllllcccccccc::::::::    //
//    ::cccccccllllllllllooooooooooooooooooooolllllllllcllcccccccc::::::;;;;;;;;;;;;;:ccllllc:;,,'';cllllllllloooooooolloooooooooolllllllllllcccccccc:::::::    //
//    ::cccccclllllllllloooooooooooooooooooooooollllllllllcccccccc::::::;;;;;;;;:ccloooodooooooolc,'',clllllllloooooooooooooooooooolllllllllllcccccccc::::::    //
//    cccccclllllllllllllloooooooooooooooooooooollllllllllcccccccc:::::;;;;;;:cloddoddodooddoooooool:'.,cllllllloooooooooodoooodoooollllllllllcccccccccc::::    //
//    ccccccllllllllllloooooooooooooooooooooooolllllllllllllccccccc:::;;;;;;coddddddddddddddooooooodxxc..;cllllloooooooooooooddoooooollllllllccccccccccc::::    //
//    cccccccllllllllloooooooooooooooooooooooooollllllllllccccccccc::::;;;:lddddddddddddddooooddddxkOOOd'.':llllllloooooooooooooooollllllllccccccccccccc::::    //
//    ::ccccccllllllllllooooooooooooooooooooooooollllllllcccccccccc::::;:codddddddddddddddodoodkkOOOOOOOd, .;ccccllllllllllloooooolllllllllllcccccccccc:::::    //
//    ::cccccccccllllllllloooollooollooooooooooollllllllcccccccccc::::;:ldddddddddddddddddddodxOOOOOOOOOOx, .,:::cccccccccclooooollllllllllllccccccccc::::::    //
//    ::cccccccccccllllllllllllllllllllllllooollllllllllccccccccc:::::codddddddddddddddddddddxkOOOOOOOOOOOd' .,;;::::::ccccclllllllllllllllllllccccccc::::::    //
//    ::cccccccccccccclllllllllllllllllllllllllllllllccccccccc:::::::codddddddddddddddddddddxkkkkOOOkkkkkkkl. .,;;;;;;;::::cccllllllllllccccclcccccc::::::::    //
//    :::ccccccccccccllllllllllllllllllllllllllllcllcccccccccc::::::codddddddddddddddddxxkkkxxxkkkkkkkkkkkkx:...,,,,,,,,;;;::cccccclllllccccccccccc:::::::;;    //
//    :::::ccccccccccllllllccllccccccccllllllllllllcccccccccccc:::::odddddddddddxxxxkkkxkkkkkkkOOOOkkkkkkkkko' ..'''',,,,,,;;::::ccclllccccccccccc::::::::;;    //
//    ::::::ccccccccccccccllcccccccccccllllllllllllcccccccccccc::::ldxxxddddddxxxkkkOOOOOOOOOOOOOOOOkkkkkkkkx:...''''''',,,,;;::::ccccccccccccc::::::::::;;;    //
//    :::::::::::ccccccccccccccccccccccllccllllllllccccccccc::cc::ldxxxxxxxxxxxxxxkkkOOOOOOOOOOOOOOOOkkkkkkxxl....''''''',,,;;;;:::ccccccccccc::::::::::;;;;    //
//    ::::::::::::ccccccccccccccccccccccccccllllcccccccccccc::cc:cdxxxxxxkkOOOOkxdxxxxkkOOOOOOOOOOkkkkkxxxxxxd,.......''''',,,;;;:::ccccccc::::::::::::;;;;;    //
//    ;;:::::::::::ccccccccccccccccccccccccccccccccccccccccc:::::oxkkkkOOO0000Okxxxddxxxxxxkkkkkkkkkxxxxxxxxxd:..........'''',,;;;::::cc::::::::::::;;;;;;;;    //
//    ;;;:::::::::::cccccccccccccccccccccccccccccccccccccc::::::cxkO0000000000Okxxxxxxxxxxddxdxxxxxxxxxxdxxxxdc...........''',,,;;;;::::::::::::::::;;;;;,,,    //
//    ;;;;;::::::::::::ccccccccccccccccccccccccccccccccccc::::::dO00000000000000Okkxxxkkkkxxdddddddxxxxxxxxkkxl'...........'''',,;;;;::::::::::;;;;;;;;;,,,,    //
//    ;;;;;:::::::::::::::cccccccccccccccccccccccccccccc:::::::lk000KKKK00000000000O000000OkxxddddddxxkOOOOOOOo'............'''',,;;;;::::::::;;;;;;;;;;,,,,    //
//    ;;;;;;:::::::::::::::ccccccccccccccccccccccccccc:::::::::oO00000K0000000000000000000OOkxxdxxdddxxkkOOOOOd'..............''',,;;;;;;:;;;;;;;;;;;;;,,,,,    //
//    ;;;;;;;:::::::::::::::::ccccccccccccccccccccc::::::::::;:x000000000000OOOOOOOOOOOOOOkkkkxdddddddddxxxxxko'..............''',,,;;;;;;;;;;;;;;;;;,,,,,,,    //
//    ;;;;;;;::::::::::::::::::::::cc:::::::::::::::::::cloddolokOOO00000OOOOOOOOOOOkkkOOOkkxolcldkOOxddddddddl'...............''',,,;;;;;;;;;;;;;,,,,,,,,,,    //
//    ,;;;;;;;;::::::::::::::::::::::::::::::::::::::::oOKNNNXkc:okkkkkkkkkkkkkkkkkkkkkkkkkko:;lkXNWNKxdddddddl. ...............'',,,,;;;;;;;,,,,,,,,,,,,,,'    //
//    ,,;;;;;;;;;;;;::;;::::::::::::::::::::::::::::::o0NWWNNKkl;;okkkkkkkxxxxxxxxxxxxxxxxxxc,;lOXWWWN0xdxddddc.  ..............''',,,;;;;;;;,,,,,,,,,,,,,,'    //
//    ,,,,,,;;;;;;;;;;;;;;;;::::::::::::::::::::;;::;:kNWNWN0xdl;;okkkkkxxxxxxxxxxxxxxxxxxxxl;:odx0KK0kddxxxdd:.  ...............'',,,,;;;;,,,,,,,,,,,,,,,''    //
//    ,,,,,,,;;;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;;;;:dKNNX0kdlcccoxkkkkkkxxxxxxxxxxxxxxxxxxdldxoldkxxoodxxxxd,   ...............''',,,,,,,,,,,,,,,,,,,,''''    //
//    ,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:cdkkxxlclodxkxxkkkkkkxkxxxxxxxxxxxxxdddxxkkkOkxddxxxxxo'  ................'''',,,,,,,,,,,,,,,,'''''''    //
//    '',,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,:oO0dlodoxOkkkkkkkkkkkkxxxxxxxxdloddxOOOxdxxxxxxxxxdc.  ................''''',,,,,,,,,'''''''''''''    //
//    '''',,,,,,,,,,,,,,,,;;;;;,;;;;;;;;;;;;,,,,,;;;;;;,,,ckkolooodkkk0OkkkkkkkkxddxdddlclddookKkdodxxxxxxxxd,   .................'''''','''''''''''''''''''    //
//    '''''',,,,,,,,,,,,,,,,,,,,,,;;;;;;;;;;,,,,,;;;;;,,,:x0xlclooodkOOOkkkxxxxxxxdoolccodoloxkkocoxxxxxxxxxl.   .. ..............''''''''''''''''''''''....    //
//    '''''''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:ddc;,;lk00kkkkxdoxxocloollc::lxkdoox0OxoodkOkxxxxxd;         .............''''''''''''''''''.......    //
//    '''''''''''''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;cl:,'',:oOXOkkkxo:coxo:cllllc:cdxddddxkxkxxddkOkxxxxl.          ............''''''''''''''...........    //
//    '''''''''''''''''',,,,,,,,,,,,,,,,,,,,,,,'',',cdkx:'''',:lxkdxOkxl:codc::;:ol::lddoodddx0X0xooodxO0Ox,            .............''''''.................    //
//    .....''''''''''''''''''''''''''''''''''''''',lOK0d;'';lddddxddxxdoccolcl:,:l:;cooolloolodxo:cdxxxOkxc.            ...............''...................    //
//    ...........................'''''''''''',,,,;lkko;..,:xKXOl:ododdooooolcll:::;coddolcddlcccc::oxkKOdl.             ....................................    //
//    ..............''''''',,,,,,,;;;;;;:::::ccldO0kdlc,.,dOOxc'':ooddddxollclll:;:ododdddxxl:coloooxO0kd'               ...................................    //
//    ..''''',,,,,;;;;;;:::::ccccclllloooooooddk000xddxo,'loooc;'':dkkxkoclolcodccldloddxxxkxdolodoox0Ox;   ..            ..................................    //
//    ;;;;;;:::cccccccllllloooooooddddddxxxxxxxk0Oxdxkkko;cdoodo:,;d0Okoc:colcdxddxxoloxkkxxkxoldkdox0k:  ........          ................................    //
//    ::ccccclllllllloooooooooodddddddxxxxxxxxxkOxodxkkkxxxdddxxdl,cxxlodcclclk0OOOxl:cxOxodddloxkxxkd,  ...................................................    //
//    ccccclllllllllloooooodoooddddddddxxxxxxxxkkdoxxkkkkOdloxkkxdllc:lOklcllx00000xl:cxxooxdodkOOkko. .....................................................    //
//    ccccllllllllllooooooooooooddddddddxxxxxxxOOddxxxxkOOxooxxxxxkd:ckKklldkOOOOOkoc;collxOkkOOOOxl. .....''''''''''''''''''''.............................    //
//    cccllllllllooooooloooodddoooddddddddddxxxxxxkOOkxxkxdoclxdllkKdcx0kooddxOkdolc:;cccdkOOkkkko,......''''''''''',,,,,,,,,,,,'''......... ...............    //
//    cclllllllllllllooooooodddooooddddddddddddddxoolodxdodl;;ldooxKOc,cddl;,lkxl:;,,,c:;:cllloo:...''''''''''',,,,,,,,,,,,,,,,,,'''''.........     ........    //
//    ccllllllllllllooooooooooooooodddddddddddxolol:coxdlloo;.,oxkoc:,'','..;dkkl;,...''.........',,,,,,,,,,,,,,,,;;;;,,,,,,,,,,,,,''''''........          .    //
//    cccccllllllllllooooooooooodooodddddddddddolccloodl:cll:;;:ll:;:c;,,'.,lxkkxdl'..........',;;;;;;;,,;;;;;;;;;;;;;;;;;,,,,,,,,''''''''...........           //
//    ccccccllllllllllllooooooooooooodddddddddoodocllooccloodoolc,';cc:;,..',:cloooc,...'',,;:::::;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,''''''''..............       //
//    cccccccclllllllllllooooooooooodddddoodol:lollloxdclddddoool:;;::;'...',;;:::::::::c:ccc:::::::::::::::;;;;;;;;;;;;;;;,,,,,,,,,'''''''.................    //
//    cccccccccclllllllllloooooooooooooooodoc,',::cldxdclollllllllllc:;;;;:ccccllllccccccccccccccccc::c::::::::;;;;;;;;;;,,,,,,,,,,'''''''..................    //
//    :ccccccccclllllllllllooooooooooooollc:;;;:clodxko;:::cllooooooooooooooooollllllllllccccccccccccccc::::::::;;;;;;;;,,,,,,,,''''''''''..................    //
//    cccccccclllllllllllllloooooooooolc::cllooodddddl;'',clodddddddddoddooooooolllllllllllllccccccccccc::::::::;;;;;;;,,,,,,,,''''''''''...................    //
//    :cccccccccllcclllllllllooooollllclllooooddocc:;;,;:cooddddddddddddooooooooooollloollllllllccccccccc:::::::;;;;;;;,,,,,,,,'''''''''....................    //
//    ::ccccccccccccccclllllolloooloooooooooolcc:::::cclooddddddddddddooooooooooooolllollllllllccccccccc::::::::;;;;;;;;,,,,,,,,'''''''''...................    //
//    ::ccccccccccccccccclllllloooooooooooooolllcccllooooddddddddddddoodoooooooooooolllllllllllcccccccc:::::::::;;;;;;;;,,,,,,,,'''''''''...................    //
//    :::cccccccccccccclllllllllooooooooooooooooolooooooooodddddddooooooooooooooooooollllllllcccccccccccc:::::::;;;;;;;,,,,,,,,'''''''''....................    //
//    :::::::::ccccllllllllllllllllooooooooooooooooooooooooooooooooooooooooooolloolllllllllccccccccccccc::::::::;;;;;;,,,,,,,,''''''''......................    //
//    :::::::::ccccccclcclllllllllllooloooooooooooooooooooooooooooooooooollllllllllllllcccccccccccc:::::::::::;;;;;,,,,,,,,,,,''''''''......................    //
//    ;;::::::::cccccccccccclllllllllllooooooooooooooooooooooooooooooooolllllllllllllcccccccccc::::::::::;;;;;;;;;;,,,,,,,,''''''''''.......................    //
//    ;;;::::::::ccccccccccccllllllllllllllloooolllllloooooooooooolllllllllllllllllccccccccc:::::::::;;;;;;;;;;;;;;,,,,,,,''''''''''........................    //
//    ;;;:::::::::ccccccccccccccllllllllllllllllllllllllllllllllllllllllllllllllccccccccc:::::::;;;;;;;;;;;;;;;;;;;,,,,,,,''''''''''........................    //
//    ;;;;:::::::::::ccccccccccccccclllllllllllllllllllllllllllllllllllllllllllccccccccc:::::::;;;;;;;;;;;;;;;;;;;;,,,,,,,'''''''''.........................    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKLTN is ERC721Creator {
    constructor() ERC721Creator("Melancholia", "SKLTN") {}
}