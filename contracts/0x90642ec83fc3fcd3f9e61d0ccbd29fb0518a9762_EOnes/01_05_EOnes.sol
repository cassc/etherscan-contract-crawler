// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Exotic Ones
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    EOnes    //
//             //
//             //
/////////////////


contract EOnes is ERC721Creator {
    constructor() ERC721Creator("Exotic Ones", "EOnes") {}
}