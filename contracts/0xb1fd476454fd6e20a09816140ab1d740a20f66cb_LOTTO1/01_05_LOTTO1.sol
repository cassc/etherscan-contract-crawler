// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Open Edition Lotto 1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Open edition lotto #1.    //
//                              //
//                              //
//////////////////////////////////


contract LOTTO1 is ERC721Creator {
    constructor() ERC721Creator("Open Edition Lotto 1", "LOTTO1") {}
}