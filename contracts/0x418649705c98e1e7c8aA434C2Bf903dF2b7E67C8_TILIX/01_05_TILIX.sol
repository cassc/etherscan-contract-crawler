// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TiliX
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//     / \     //
//    |\ /|    //
//     \|/     //
//             //
//    TILIX    //
//             //
//             //
/////////////////


contract TILIX is ERC721Creator {
    constructor() ERC721Creator("TiliX", "TILIX") {}
}