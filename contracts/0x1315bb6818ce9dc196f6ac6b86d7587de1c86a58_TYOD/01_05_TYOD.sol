// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TOKYO_D
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    TYOD    //
//            //
//            //
////////////////


contract TYOD is ERC721Creator {
    constructor() ERC721Creator("TOKYO_D", "TYOD") {}
}