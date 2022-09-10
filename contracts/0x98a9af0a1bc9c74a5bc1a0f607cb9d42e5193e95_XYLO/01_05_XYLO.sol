// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XYLOPHONE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                               ;k0xoc:;,'.               .:oc,.......                 ..'',;ccllodddxxkkOOKK    //
//                                               .:xkdlc;,.               .oOxl:;,,'..               .....  ........'',;cloddd    //
//                                                .lkxdlc;'.             .c0Ol;',;,'..                .......'....''',;cccc:;,    //
//                                                ,k0kdlc;'.           ..'dKkl:;;;;,..                         .......'',,;;,'    //
//                                                .lOxc:;,..         ..,dkkkdc:::;;,..                                       .    //
//                                               .;k0kdl;..         ..,xxlloc::;;;,'.                                      ..,    //
//                                              ..:0X0Od,........;ccodk0kolc::'.,,'.                                    ....';    //
//                    .......                 .....oKXKkoodxko:;lOXXK0Okl::c::,','.                   .   .....      .........    //
//                   ............................,:oOOOOO0000000000Oxccl;';::::;''..                ..........................    //
//                   .................'',,,,,;coxxddddooxkO0K0Oxolllc::::::::::;,,..              ............................    //
//      .......       ...............'''',,;;:lool::lc;;:clool;,',,,,,,,,,,::;;;;,'..            .............................    //
//      .......       ...............'''',;;;;;,,,''.........,,;::c:cccc::::;,,,,,,..           .............'''''''''........    //
//    ................................'',;;;;;;,,,''.....,coO00OkO0K0xk00kl,,,;,'..           ..........'',,,,,,,,,''''.....'.    //
//    ..................................'',,;;;;;,,''',;:xXNXX0dx000OkkOOOxddoddllc:,''..  ....';,...''',,',;;;;;,,,''''...:dd    //
//    .......................................',,;,'',dKKKKKXXXKOOkkxxxdxxxdolc;,,,;;:ldxooodd:';cc;'',,,'''';;;;;;,,'.'';loOXX    //
//    ...................................... ...'''',dXK0OO0KXXKOkxocloooooll:,''.....';cldddc:dxxdl:,,,',,,,';;;;;;;,;coOK0kx    //
//    .''''''',,,,,''....'..''...........       ....'oKKOOkk0KXK0kxoccllllcclc;,''..........',;lkKX0dc:;;;;,,;;:::cllodxxkOkl'    //
//    ,;;;;::cccllccc:::;,,''.......                ..ldk00OO0XXKxooolccll:;ccc;,''.....     .;dkKXXKdcccccc:cccllodxxkkkOxc,.    //
//    cccloodxxxxddddddoc,..                          ..;lccdk0KKxllllccllc:clc:;,'''..      .;dkO0KKo:loddololcldxxkOOOOO0k:.    //
//    xxkO0KKKK00000000x;                                 .;dkk0Kkolcccllc:clllc::;,''........,codx00olddxkkxxdodxkkkkkO0KXk,     //
//    XXXXXXXXXK0kdoxkkd'                              ..,:oxxkkkxolcclll:;clllcc::,'''''',,,,;:cldxocoxxkO0OOOkkxxxoldO0KXk:.    //
//    olo0Kdclllcldkkxc.                               ..',;;:dOOkxdloooooolll:,;cc:;,'',;;;;::ccloxxdxkkkO0OOkxxdoodxk00Oxl,.    //
//    ...:c,'..';cllloc.                                    .,x00Okxddoool:cl:,,,;::::;;:::;,,;clloxOO000KK0OkxdddlldkOkd;.       //
//    .....'''''''',:dk,                                     .'oOOOOkxddoc:;,,,,'',:llc:::;,'';:clodkOkO0K0kkxdolllox00kc.        //
//    ........''''';ldl;.                                     .:0K00Oxoc;,'',,'.',:ldxdl:;,'',;:lodxkxdoddxkOOdlloddkO0KO;.       //
//    ........''',,:xOo;.                                    .'lOOkxoc;,''',,''',cdkkxxxdl:;;:clodxxxdoolc:cdxxollloxkOKk;.       //
//    ........',,;;,'.                                      .lOOkxxoc:,''',,'';:ldkkxxxkxdolllllooooolllc::clodxo:,;cok0x,.       //
//    ....',;,'...                                      .,clkOdokkkkxl:;::cclodxxddddxxdddddxdol::ccclc:,;:cccccl:'',cx0x;.       //
//    ',:co:..                                         'dKXXKOkkOO00OddkOkxxOOkxoclooddoooddxxo:,,;:::;,,,,,,,''','',cxKKk:.      //
//    ::c;..                                           :KXXXK0kO00000O000OkOOOkdl::clloooodddo:'.....................'cx00d,.     //
//    .                                                ,odOKOd:,,:cdO0kxxOOkkxdolc::::clloddo:.       .....  ..........;clc:'.    //
//                                                    .;lcc;.   .cdk0kdodkOkxdolccc:::::::cc:'.                ........'',,,,,    //
//                                             . .':cc::,.      'dOOxoodxOOkdolc::::;;;,,'...                   ........'''',,    //
//                                          .... 'xK0d,        .;oxdoodO0KOo::ccc:;,,,,,'..                      ........'''',    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XYLO is ERC721Creator {
    constructor() ERC721Creator("XYLOPHONE", "XYLO") {}
}