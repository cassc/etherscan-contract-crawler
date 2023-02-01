// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CrimsonRider
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ;;;;;;,;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''.....                 ....'',,''''''''''''''''''''''''.''''..................    //
//    ;;;;;;;;;;;;;;;;;;,,,;;,,,,,,,,,,,,,,,'....                           ...',,,,,,,,,,,,,''''''''''''''''''''''...........    //
//    :::;;;;;:;;;;;;;;;;;;;;;;;;;;;,,;;,'......                               ..',,;;,,,,,,,,,,,,,'',,''''''''''''''''''''''.    //
//    ::::::::::::::::::::::::;;;;;;;;,'........                                  ..';;;;;;,,,,,,,,,,,,,,,,,,,,,''''''''''''''    //
//    cccccccccccccccc::::::::::::::;,..........                                    ..';;;;;;;;;;;;;;;;,,;;,,,,,,,,,,,,,,'''''    //
//    llllllllllllcccccccccccccccc:,............                                      ..,;:::::::;;;;;;;;;;;;;;;;;,,,,,,,,,,,,    //
//    oooooooooollllllllllllllllc:,.............                                       ..';cccccc:::::::::::::;;;;;;;;;;;;;;;,    //
//    dddddooooooooooooooooooool:'..............                                       ....;ccclccccccccccccc::::::::;;;;;;;;;    //
//    ddddddddddddddddddooooool:,'..............                                      ......;cllllllllllllccccccccccc:::::::::    //
//    xxxxxxxxdddddddddddddddo:,,''.............                                  .. ........;lloooooolllllllllllllccccccccccc    //
//    kkkkkkxxxxxxxxxxxxxdddoc;;,'''............                                  ............:oooooooooooooooolllllllllllllll    //
//    OOOOOOOOOkkkkkkkkkkxxdl:;;,,''''..........                                  ............'coddddddooooooooooooooollllllll    //
//    00000000OOOOOOOOOOOkkoc::;,,,,'''''.......          .....                  .............';ldxxxxddddddddddddoooooooooooo    //
//    00000000000000OOOOOdolcc::;;,,,,'''''.....         ..............          .............',cxkkkkkkkkkkkkxxxxxxdddddddddd    //
//    NNNNNNNNXXXXKKK000kolllc:::;;;,,,,''''......       ...............         ............'',:dkOOOOOOOOOOOOOOkkkkkxxxxxxxx    //
//    MMMMMMMMMWWWWNNXK0Oololcc::::;;;,,,,,''''....     ................         ..........''',;:oOKKKKKK0000OOOOOOOOOkkkkkkkx    //
//    MMMMMMWWNNNXXXKKK00xooolcc::::;;;,,,,,,,'........ ................        ..........''',,;:oONWWWWWWWWNNNXKK0OOOOOOOkkkk    //
//    MMMMMWWNNXXKKKKKK0KKkooollcc:::;;;;,,,,,'.........................        .........'',,,,;clo0WMWWWWWWWNNXXK0Okkkkkxxxxd    //
//    WWWWMMMMMMMWWWWWWNNNKkdoolccc:::;;;;;,,,'.........................       ......''''',,,;;:cccOWWWNXK000OOOkkxxxddddddddo    //
//    KKXXXXNNWWWWWWWMMMMWXOddoollcc:::;;;;;;;,...........'.............        .....''''',,,;;:ccoKWWWWNXXXKKK000OOkkkkxxxxxx    //
//    0000000000KKKXXXXNNWNOdddoollcc:::;;;;;;,..........''''...........       .....'''''',,,;;:coOXXKKXXXXXXNNNNNNNNNNXXXXXXX    //
//    000000000000000000KNNOddoollcc::::::;;;;,..........''''...........      ....''''''',,,,;;:ckKOOOkkOOOOOOO00KKKXXXNNNNNNN    //
//    OOOOOOOOOO000000000KXOdooolcc::;;;;;;;;;,,''''.....'''............  ........'''''''',,,;;:cdkkkkkkkkkkkkkkkkkkkkOOOOOOOO    //
//    kkkkkOOOOOOOOOOOOOO0Kkdoolcc::;;;,,,,,,,,,''''''''','''....................''...''''',,,;:coxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    kkkkkkkkkkkkkkkkkkkOOkdollc:::;;,,,,,,,,,''..........''............''''''''''.......''',;;codxxxxxxxxddddddddddddddddddd    //
//    xxxxxkkkkkkkkkkkkkkkkkxdocc::;;;,,,,;;,,,,''...',,'.........................'........'',,;coddddddddddddddddddddddoooooo    //
//    xxxxxxxxxxxxxxxxkkxxxxkkoc::;;;;,,,,;;,,,,''..',;;;,'''''............................'',,:coddddddddddddddddoooooooooooo    //
//    dxxxxxxxxxxxxxxxxxxxxxOkdlc:;;;,,,,,;;,,,,,''.',;,,,'..............'..................'';:lddddddddddddooooooooooooooool    //
//    dddddddxxxxxxxxxxxxxdxkOxlc:;;;;;,,,,;,,,,,,'.',,,;,'.............'''.................',;clddddodddooooooooooooollllllll    //
//    ddddddddddddddddxxdxddkOkoc:;;;;;;,,,;;,,,,,''',;;;,'.............',,'................',:coooooooooooooooooooollllllllll    //
//    ddddddddddddddddddddddxOOdc:;;,,,;;,,,;,,,,',',;;;;,'.............'''.................';:loooooooooooooooolllllllllccccc    //
//    dddddddddddddddddddddddkOxl:;,,',;;,,,,,,,,''',,;,,,'.............'''...........''...',;:looooooooooooollllllllcccccccc:    //
//    ddddddddddddddddddddddodkkoc;,,',;;,'',,,,,'''',,,,,'.............'''..........''...',,;loooooollllllllllllllcccccccc:::    //
//    ddddddddddddddddddddddolxkoc;,',,;,,''''''''....''''..............'''.........'.....,,,:llllllllllllllllccccccccc:::::::    //
//    ooooddddddddddddddddddolodoc;,,,,,,,'..'.................................. ..'''.....';clllllllllllccccccccccc::::::::::    //
//    ooooooooooooddddddddddolcodl:;;;;,,,,'.................................   ...','.....,cllllllllccccccccccc::::::::::;;;;    //
//    loooooooooooooooooooddolccoo:,,,,,,,,,'...................              ...'','.....':llcccccccccccccc::::::::::::;;;;;;    //
//    llllllooooooooooooooooooc:loc,'...'',,,'................            ......'';c,.....;ccccccccccccccc::::::::::;;;;;;;;;;    //
//    lllllllllloooooooooooooolc:c:;'''....',''''..........             .......'';;,. ...,:cccccccccc:::::::::::::;;;;;;;;;;,,    //
//    clllllllllllloooollollololc::;,''......''''''..........   ................,,..  ..,:ccccc::::::::::::::::;;;;;;;;;;;,,,,    //
//    ccccclllllllllllllllllllllc:;;,,'............''''''..................... ...    .,:ccc::::::::::::::;;;;;;;;;;;;,,,,,,,,    //
//    ccccccccllllllllllllllllc;''','''''..................................          .,:c:::::::::::::;;;;;;;;;;;;;;,,,,,,,,,,    //
//    ccccccccccccllllllllclc;.  ...'''''.....       ...............                .,::::c::::::::;;:;;;;;;;;;;;;,,,,,,,,,'''    //
//    ::ccccccccccccccccclcc;.      ...''....                                      ....';:;,,;;::::;;;;;;;;;;;;;;,,,,,,,''''''    //
//    :::::::::ccccllllccc:,'.       ........                                      ........ ....,;:cccc:::::;;;,,,,,,,,,''''''    //
//    :::::::cccc::::;,,'.....         ......                                       .....        ...',,;;:;;;;;;;,,,''''''''''    //
//    ::::::;;;;,'''..........           ....                                         ....                  .........'''''''''    //
//    ;:;,.........       ....             .                                                                         ..''.....    //
//    '..    ..           .'..                                                                                        ........    //
//                        ...                                                                                         ........    //
//                        ...                                                                                        .........    //
//                       ....                                                                                           ......    //
//                       ..                                                                                               ....    //
//                                                                                                                          ..    //
//                                                                                                                           .    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RDR is ERC1155Creator {
    constructor() ERC1155Creator("CrimsonRider", "RDR") {}
}