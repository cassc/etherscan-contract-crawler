// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Portals x Dino
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    DOORS <> PORTALS <> DOORS    //
//                                 //
//                                 //
/////////////////////////////////////


contract DOOR is ERC721Creator {
    constructor() ERC721Creator("Portals x Dino", "DOOR") {}
}