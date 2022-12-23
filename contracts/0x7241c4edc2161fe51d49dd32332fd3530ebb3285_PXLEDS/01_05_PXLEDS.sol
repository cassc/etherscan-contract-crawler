// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PXLMYSTIC Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    PXLMYSTIC    //
//                 //
//                 //
/////////////////////


contract PXLEDS is ERC721Creator {
    constructor() ERC721Creator("PXLMYSTIC Editions", "PXLEDS") {}
}