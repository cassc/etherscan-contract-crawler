// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Onod's Weird Nights
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    (0,0)    //
//             //
//             //
/////////////////


contract OWN is ERC721Creator {
    constructor() ERC721Creator("Onod's Weird Nights", "OWN") {}
}