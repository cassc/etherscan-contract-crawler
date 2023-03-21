// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AKCR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    I make more money than you    //
//                                  //
//                                  //
//////////////////////////////////////


contract AKCR is ERC721Creator {
    constructor() ERC721Creator("AKCR", "AKCR") {}
}