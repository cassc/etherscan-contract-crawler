// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Acid Impressionism
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    ◡‿◡✿    //
//            //
//            //
////////////////


contract ACID is ERC721Creator {
    constructor() ERC721Creator("Acid Impressionism", "ACID") {}
}