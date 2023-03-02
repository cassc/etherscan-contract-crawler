// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Main collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    beqa    //
//            //
//            //
////////////////


contract color is ERC721Creator {
    constructor() ERC721Creator("Main collection", "color") {}
}