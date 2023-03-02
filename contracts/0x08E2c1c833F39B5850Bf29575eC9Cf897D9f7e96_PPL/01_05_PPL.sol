// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Purple
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//    01110000 01110101 01110010 01110000 01101100 01100101      //
//    01100010 01111001  01000011 01001000                       //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract PPL is ERC721Creator {
    constructor() ERC721Creator("Purple", "PPL") {}
}