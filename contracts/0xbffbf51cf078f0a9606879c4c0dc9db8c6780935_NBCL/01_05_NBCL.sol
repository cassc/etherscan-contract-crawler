// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Noir et Blanc collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    enjoy    //
//             //
//             //
/////////////////


contract NBCL is ERC721Creator {
    constructor() ERC721Creator("Noir et Blanc collection", "NBCL") {}
}