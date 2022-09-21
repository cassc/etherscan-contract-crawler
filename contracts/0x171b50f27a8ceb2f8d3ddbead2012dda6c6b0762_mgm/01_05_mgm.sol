// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: marooned OE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    marooned gm    //
//                   //
//                   //
///////////////////////


contract mgm is ERC721Creator {
    constructor() ERC721Creator("marooned OE", "mgm") {}
}