// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unbroken Samurai
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                   ..                                               //
//                        .                                           //
//                ..... ..........                                    //
//               ..''.''....':col;......     ....                     //
//               .:c:c:,,'',,;okOdlllc;.   ........                   //
//              .cOkxxoc:;;:cclxOKXNNXk,  .,,;,'....                  //
//              ,xXKKKkolllllllxKWMMMM0,.,::::;,'.'.                  //
//              'oKNXKkollolcclxKWMMMWOc:cccl:;,..''                  //
//              .:dO0OxdollolloOKNMMMN0kdllolc:,'...                  //
//               .'lkxoolccooodO0KWMM0kOdodocc:;'...                  //
//                ..',;::ccldxk0K0XXXOk0xxdlc::,'..                   //
//             ..  ...',;:cloxO0KKK0OOK0kxolc:;'....                  //
//             .. ... ...',;:codxkkkxxkxoc:,,'...  .                  //
//                .... ...',,;:cllcccllllc:,'...  .                   //
//                .';'....',,',,;;;;,;;;;;:;'......                   //
//                 .,lxxdol:::;,''..'',;:cc;,'....                    //
//                ...'::ccc:cc::,.....,ccc:;'..... ..                 //
//                 ..      ......     ......      ..                  //
//                  ...                         ...                   //
//                  .....       ..,:;.     ...',,.                    //
//                   .         .,lk0Ol.   ......                      //
//                   ..    ... .';okx:..  ...          .;cc;.         //
//              .,:;.....     .cd:coo;.,..             .,ll:,.        //
//            ..'dXO;....    ...:odoo:'....               .,'.        //
//            ..;KM0,        ..   ...   ..             .   .;,        //
//              ;KXo.                                       .'        //
//       ..     .:xc.                               ... ..   .        //
//    ...,o:.     ...                               .......  ..       //
//    ,,:xXNl...    ..       ...  .....'..          .............     //
//    oxdkKN0c''..                 ..  ..       .    ..;lc';:;'...    //
//    dkkxxO0Ollxl'                            .    .:x00olxxdlcc:    //
//    ddkkxxk00xxxc,.                      .  .    .l0N0ooOKKK00Od    //
//    odxkO00KXNOc;cl;.                    ..    .:xK0d:lxkO0KK0OO    //
//    cokOOOOkOKXOc;:odc,.                .....:dOKKOoclol:::cclkx    //
//    o:;clc;;lkkdc,'.,:;'..             .....;lol;,',,'......';;:    //
//    '.   ...,lkkoc;'.  .',,..   ....  ...;ld:.  .;odddl:'......;    //
//              .cddddo:.  'lo,. .ldo:.....;:,. .cx0KXKd;..           //
//                'lOKOxo.  .,,..'ldl:.. ...   .lk0XN0;               //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract US is ERC721Creator {
    constructor() ERC721Creator("Unbroken Samurai", "US") {}
}