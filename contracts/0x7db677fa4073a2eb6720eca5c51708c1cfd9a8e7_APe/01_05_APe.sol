// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored Ape Yacht Club X Glowing Gold
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    Bored Ape Yacht Club X Glowing Gold    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract APe is ERC721Creator {
    constructor() ERC721Creator("Bored Ape Yacht Club X Glowing Gold", "APe") {}
}