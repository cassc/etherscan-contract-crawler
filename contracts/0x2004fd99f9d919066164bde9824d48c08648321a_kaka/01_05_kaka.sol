// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kaka
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    kaka    //
//            //
//            //
////////////////


contract kaka is ERC721Creator {
    constructor() ERC721Creator("kaka", "kaka") {}
}