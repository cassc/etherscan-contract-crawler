// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Limbo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    Limbo    //
//             //
//             //
/////////////////


contract LIM is ERC721Creator {
    constructor() ERC721Creator("Limbo", "LIM") {}
}