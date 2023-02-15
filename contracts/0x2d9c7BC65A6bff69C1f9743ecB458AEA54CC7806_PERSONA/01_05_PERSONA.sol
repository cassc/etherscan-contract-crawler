// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Personal Gallery
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    We are all living in different stories with one another...    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract PERSONA is ERC721Creator {
    constructor() ERC721Creator("Personal Gallery", "PERSONA") {}
}