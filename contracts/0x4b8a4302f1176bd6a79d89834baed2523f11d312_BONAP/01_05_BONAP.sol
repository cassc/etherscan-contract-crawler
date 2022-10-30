// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bon Appétit
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Bon Appétit    //
//                   //
//                   //
///////////////////////


contract BONAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Bon Appétit", "BONAP") {}
}