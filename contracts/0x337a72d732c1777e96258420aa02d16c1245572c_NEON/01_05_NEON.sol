// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: [BETA] - Cult of Neon - [BETA]
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//     ██████╗ ██╗   ██╗ ██╗   ████████╗     ██████╗  ███████╗    //
//    ██╔════╝ ██║   ██║ ██║   ╚══██╔══╝    ██╔═══██╗ ██╔════╝    //
//    ██║      ██║   ██║ ██║      ██║       ██║   ██║ █████╗      //
//    ██║      ██║   ██║ ██║      ██║       ██║   ██║ ██╔══╝      //
//    ╚██████╗ ╚██████╔╝ ███████╗ ██║       ╚██████╔╝ ██║         //
//     ╚═════╝  ╚═════╝  ╚══════╝ ╚═╝        ╚═════╝  ╚═╝         //
//                                                                //
//           ███╗   ██╗ ███████╗  ██████╗  ███╗   ██╗             //
//           ████╗  ██║ ██╔════╝ ██╔═══██╗ ████╗  ██║             //
//           ██╔██╗ ██║ █████╗   ██║   ██║ ██╔██╗ ██║             //
//           ██║╚██╗██║ ██╔══╝   ██║   ██║ ██║╚██╗██║             //
//           ██║ ╚████║ ███████╗ ╚██████╔╝ ██║ ╚████║             //
//           ╚═╝  ╚═══╝ ╚══════╝  ╚═════╝  ╚═╝  ╚═══╝             //
//                                                                //
//                       ~~~ [ BETA ] ~~~                         //
//                                                                //
//                     Top Secret Cult Lair                       //
//                                                                //
//            The light you gaze upon here doth hint              //
//              at schematics to come. Rejoice in                 //
//            the luminous alpha.. or beta? Whatever.             //
//                                                                //
//                       ~~~~~~~~~~~~~~~~                         //
//                                                                //
//          A Tokenized, Physical Neon Art Collection             //
//                 created by @Lux_Capacitor                      //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract NEON is ERC721Creator {
    constructor() ERC721Creator("[BETA] - Cult of Neon - [BETA]", "NEON") {}
}