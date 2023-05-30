// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nightstar
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//    .  .    .   ,     ,                                                                    //
//    |\ |* _ |_ -+- __-+- _.._.                                                             //
//    | \||(_][ ) | _)  | (_][                                                               //
//         ._|                                                                               //
//            // kissing stars, making dreams ;                                              //
//                1/1 graphic designs by Kirie Star / Nightstar Studio. \\                   //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract NIGHTSTAR is ERC721Creator {
    constructor() ERC721Creator("Nightstar", "NIGHTSTAR") {}
}