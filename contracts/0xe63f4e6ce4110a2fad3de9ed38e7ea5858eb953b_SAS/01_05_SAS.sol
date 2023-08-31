// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seize And Share
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ''''''.                                                    .''''''''''''''''''''    //
//    ''''''.                                                    .''''''''''''''''''''    //
//    ''''''.                                                    .''''''''''''''''''''    //
//    ...................................................................'''''''''''''    //
//          ;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc.      .'''''''''''''    //
//          ;xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxkc       .'''''''''''''    //
//          ;kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkc       .'''''''''''''    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cxkkkkkkxc;;;;;;;;;;;;;'        .......''''''    //
//    kkkkkk;                            .dkkkkkkd.                            .''''''    //
//    kkkkkx;                            .dkxkkkkd.                            .''''''    //
//    xxxxxx,                            .oxxxxxxo.                            .''''''    //
//    ......       .colloooolloool'       ........       'lolooooolllloc.      .''''''    //
//                 'xOOOOOOOOOOOOk;                      :OOOOOOOOOOOOOd.      .''''''    //
//                 'xOOOOOOOOOOOOk;                      :OOOOOOOOOOOOOd.      .''''''    //
//    ......       'xOOOOOOOOOOOOk;       ........       :OOOOOOOOOOOOOd.       ......    //
//    xxxxxx,      'xOOOOOOOOOOOOk;      .oxxxxxxo.      :OOOOOOOOOOOOOd.                 //
//    kkkkkx;      'xOOOOOOOOOOOOk;      .dkxkkkkd.      :OOOOOOOOOOOOOd.                 //
//    kkkkkx;      'xOOOOOOOOOOOOO;      .dkkkkkkd.      :OOOOOOOOOOOOOx.                 //
//    kkkkkx;      .,:;;;;;;;;;;;;.      .dkkkkkkd.      .;;;;;;;;;;;;:,.                 //
//    kkkkkx;                            .dkkkkkkd.                                       //
//    kkkkkx;                            .dkkkkkkd.                                       //
//    kkkkkx;                            'dkkkkkkd'                                       //
//    kkkkkkdlllllllllllllllllllllllllllloxkkkkkkxollllllllllllllllllll:.                 //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxkd.                 //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkd.                 //
//    ddddddxkkkkkkkkkkkkkkkkkkkkkkkkkkkkdllllllllllllllldkkkkkkkkkkkkkd.                 //
//    ccccccokkkkkkkkkkkkkkkkkkkkkkkkkkkkl.              ;kkkkkkkkkkkkkd.                 //
//    c:cc:cokkkkkkkkkkkkkkkkkkkkkkkkkkkkc.              ;kkkkkkkkkkkkkd.                 //
//    c:cc:cokkkkkkkkkkkkkkkkkkkkkkkkkkkkc.              ;kkkkkkkkkkkkkd.                 //
//    c:::::loooooodxkkkkkkkkkkkkkkkkkkkkd:;;;;;;;;;;;;;;okkkkkkxooooooc.                 //
//    cc::c::::::::lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdc::::c;.                 //
//    cc::c:ccc::c:lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdc::c:c;.                 //
//    cc::c:::cc:::lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc:c::c;.                 //
//    cc:::::::c:cccllllllllllllllllllllllllllllllllllllllllllllcc::::c;.                 //
//    cc:::::c::cccc:c::::::::::::::::::::::::::::::::::::::::::cc:cc:c;.                 //
//    cc:::::::ccc::cc::::::::::::::::::::::::::::::::::::::::::c::c::c;.                 //
//    c:::::::cc:::cc:::::::::::::;,;;;;;;;;;;,;;;;;::;;;:::::::::c:::c;.                 //
//    c:::::::::::::::::::::::::::'.....'.......,'''''...,::::::::::::c;.                 //
//    cc::::::::::::::c:::::::::::'..Seize the memes.....;::::::::::::c;.                 //
//    c:::::::::::::::::::::::::c:,.......of production.';::::::::::::c;.                 //
//    ooooool:::c::::c:::::,,,,,,,,;;,,,,,,,,,,,;;;;;,,,,;::c::ccccc::c;.                 //
//    kkkkkkoc::c:::ccc::c;'.6..5.,:c::ccccccc:::::::::::::::::c::ccc:c;.                 //
//    kkkkkkoc::cc:cccc::::'.2..9.,:c:::::::::::::::::::::::::::::::::c;.                 //
//    kkkkkkocccccccc:c::c:'......,::::::::::::::::::::::::::::::::::::;.                 //
//    kkkkkkxxddddxoc:c:::::;;;;;;:::::::::::::::::::::::::::::c,......         ......    //
//    kkkkkkkkkkkkkdc:c::::::::::::::::::::::::::::::::::::::::c'              .''''''    //
//    kkkkkkkkkkkkkdc::::::ccccccccccccccccccccccccccccccccccc:c'              .''''''    //
//    kkkkkkkkkkkkkxollllll;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.              .......    //
//    kkkkkkkkkkkkkkkkkkxkd.                                            .'''''..          //
//    kkkkkkkkkkkkkkkkkkkkd.                                            .''''''.          //
//    kkkkkkkkkkkkkkkkkkkkd.                                            .''''''.          //
//    kkkkkkkkkkkkkkkkkkkkd.                       .............................''''''    //
//    kkkkkkkkkkkkkkkkkkkkd.                      .''''''''''''''''''''.       'llllll    //
//    kkkkkkkkkkkkkkkkkkkkd.                      .''''''''''''''''''''.       'cccccc    //
//    kkkkkkkkkkkkkkkkkkkkd.                      .......................      'cccccc    //
//    kkkkkkkkkkkkkkkkkkkkd.              ........                     .,:;;;;;:cccccc    //
//    kkkkkkkkkkkkkkkkkkkkd.              .''''''.                      ;lcccccccccccc    //
//    kkkkkkkkkkkkkkkkkkkkd.              .''''''.                      ;lcccccccccccc    //
//    kkkkkkkkkkkkkkkkkkkkd.              .''''''.                      ;lcccccccccccc    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract SAS is ERC721Creator {
    constructor() ERC721Creator("Seize And Share", "SAS") {}
}