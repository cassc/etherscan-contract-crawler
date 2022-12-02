// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Teleperformance
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                                                      //
//       _   _   _   _   _   _   _   _   _   _   _   _   _   _   _      //
//      / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \     //
//     ( T | E | L | E | P | E | R | F | O | R | M | A | N | C | E )    //
//      \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/     //
//                                                                      //
//                TELEPERFORMANCE x INFINITE OBJECTS 2022               //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract TELEPERFORMANCE is ERC721Creator {
    constructor() ERC721Creator("Teleperformance", "TELEPERFORMANCE") {}
}