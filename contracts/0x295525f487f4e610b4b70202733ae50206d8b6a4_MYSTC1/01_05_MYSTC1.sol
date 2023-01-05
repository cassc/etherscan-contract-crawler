// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PXLMYSTIC v1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    PXLMYSTIC v1    //
//                    //
//                    //
////////////////////////


contract MYSTC1 is ERC721Creator {
    constructor() ERC721Creator("PXLMYSTIC v1", "MYSTC1") {}
}