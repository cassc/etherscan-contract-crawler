// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abyss
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    bummy    //
//             //
//             //
/////////////////


contract ABS is ERC721Creator {
    constructor() ERC721Creator("Abyss", "ABS") {}
}