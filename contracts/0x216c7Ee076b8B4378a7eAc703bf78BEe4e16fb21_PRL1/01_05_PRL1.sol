// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pipe Race - Level 1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    / \   /  __// \ |\/  __// \     /  _ \/ \  /|/  __/    //
//    | |   |  \  | | //|  \  | |     | / \|| |\ |||  \      //
//    | |_/\|  /_ | \// |  /_ | |_/\  | \_/|| | \|||  /_     //
//    \____/\____\\__/  \____\\____/  \____/\_/  \|\____\    //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract PRL1 is ERC721Creator {
    constructor() ERC721Creator("Pipe Race - Level 1", "PRL1") {}
}