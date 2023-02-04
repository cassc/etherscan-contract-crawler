// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hoffman 2000 Check
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    2000    //
//            //
//            //
////////////////


contract LSD is ERC721Creator {
    constructor() ERC721Creator("Hoffman 2000 Check", "LSD") {}
}