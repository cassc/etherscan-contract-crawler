// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tiny World OE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    ૮ ・ﻌ・ა    //
//              //
//              //
//////////////////


contract TW is ERC721Creator {
    constructor() ERC721Creator("Tiny World OE", "TW") {}
}