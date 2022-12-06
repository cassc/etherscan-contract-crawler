// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Who are we?
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    this is just the beginning...    //
//                                     //
//                                     //
/////////////////////////////////////////


contract WHO is ERC721Creator {
    constructor() ERC721Creator("Who are we?", "WHO") {}
}