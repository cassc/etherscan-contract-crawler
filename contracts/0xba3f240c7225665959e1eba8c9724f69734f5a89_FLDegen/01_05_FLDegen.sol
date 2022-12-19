// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Degen Caricature
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    R. B.    //
//             //
//             //
/////////////////


contract FLDegen is ERC721Creator {
    constructor() ERC721Creator("Degen Caricature", "FLDegen") {}
}