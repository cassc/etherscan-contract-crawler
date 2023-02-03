// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Check Donald’s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    Check Donald’s, a ChecksVV (by Jack Butcher) derivative.     //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract CDSvv is ERC721Creator {
    constructor() ERC721Creator(unicode"Check Donald’s", "CDSvv") {}
}