// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Escaping Perspective
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    bleep    //
//             //
//             //
/////////////////


contract SCAPE is ERC721Creator {
    constructor() ERC721Creator("Escaping Perspective", "SCAPE") {}
}