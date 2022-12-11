// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Light
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    LIGHT    //
//             //
//             //
/////////////////


contract LGT is ERC721Creator {
    constructor() ERC721Creator("Light", "LGT") {}
}