// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    Shan    //
//            //
//            //
////////////////


contract SHAN is ERC721Creator {
    constructor() ERC721Creator("Shan", "SHAN") {}
}