// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: list
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    list    //
//            //
//            //
////////////////


contract list is ERC721Creator {
    constructor() ERC721Creator("list", "list") {}
}