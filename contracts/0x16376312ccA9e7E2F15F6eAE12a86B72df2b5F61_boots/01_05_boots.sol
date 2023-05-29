// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Boots
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    Every cowboy and cowgirl needs a good pair of boots.     //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract boots is ERC721Creator {
    constructor() ERC721Creator("Boots", "boots") {}
}