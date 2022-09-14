// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PXLTILES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    pxltiles by pxlmystic    //
//                             //
//                             //
/////////////////////////////////


contract PXLTL is ERC721Creator {
    constructor() ERC721Creator("PXLTILES", "PXLTL") {}
}