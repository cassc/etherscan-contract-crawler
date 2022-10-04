// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JihadFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    JIHADESMAIL    //
//                   //
//                   //
///////////////////////


contract JFT is ERC721Creator {
    constructor() ERC721Creator("JihadFT", "JFT") {}
}