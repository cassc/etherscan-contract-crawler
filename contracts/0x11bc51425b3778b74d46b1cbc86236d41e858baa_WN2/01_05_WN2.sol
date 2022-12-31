// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Just a simple girl     //
//                           //
//                           //
///////////////////////////////


contract WN2 is ERC721Creator {
    constructor() ERC721Creator("WN", "WN2") {}
}