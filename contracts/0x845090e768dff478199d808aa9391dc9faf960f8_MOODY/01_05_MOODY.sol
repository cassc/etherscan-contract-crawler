// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moody
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    We look moody but we are happy    //
//                                      //
//                                      //
//////////////////////////////////////////


contract MOODY is ERC721Creator {
    constructor() ERC721Creator("Moody", "MOODY") {}
}