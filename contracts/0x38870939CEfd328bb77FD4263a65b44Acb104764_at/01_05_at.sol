// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Auction Test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    This is a test auction contract    //
//                                       //
//                                       //
///////////////////////////////////////////


contract at is ERC721Creator {
    constructor() ERC721Creator("Auction Test", "at") {}
}