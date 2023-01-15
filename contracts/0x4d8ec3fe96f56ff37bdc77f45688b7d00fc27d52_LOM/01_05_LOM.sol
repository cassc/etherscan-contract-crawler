// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Layers of Moments
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    DOANK    //
//             //
//             //
/////////////////


contract LOM is ERC721Creator {
    constructor() ERC721Creator("Layers of Moments", "LOM") {}
}