// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VISIBLE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    SOLID.VISIBLE.TANGIBLE?    //
//                               //
//                               //
///////////////////////////////////


contract VSBL is ERC721Creator {
    constructor() ERC721Creator("VISIBLE", "VSBL") {}
}