// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HAYA Series Edition Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    HAYA SERIES    //
//                   //
//                   //
///////////////////////


contract HYSC is ERC721Creator {
    constructor() ERC721Creator("HAYA Series Edition Collection", "HYSC") {}
}