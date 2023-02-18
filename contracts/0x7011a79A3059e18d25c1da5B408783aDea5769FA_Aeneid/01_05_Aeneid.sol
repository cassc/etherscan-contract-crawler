// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oil Acrylic Paintings by Aeneas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    [\\👑//]    //
//                //
//                //
////////////////////


contract Aeneid is ERC721Creator {
    constructor() ERC721Creator("Oil Acrylic Paintings by Aeneas", "Aeneid") {}
}