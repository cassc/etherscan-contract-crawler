// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PBZ
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    __________ __________ __________     //
//    \______   \\______   \\____    /     //
//     |     ___/ |    |  _/  /     /      //
//     |    |     |    |   \ /     /_      //
//     |____|     |______  //_______ \     //
//                       \/         \/     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract PBZ is ERC721Creator {
    constructor() ERC721Creator("PBZ", "PBZ") {}
}