// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hares Odyssey: Archetypes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    (\_/)     //
//    (o.o)     //
//    (")(")    //
//              //
//              //
//              //
//////////////////


contract HOA is ERC721Creator {
    constructor() ERC721Creator("Hares Odyssey: Archetypes", "HOA") {}
}