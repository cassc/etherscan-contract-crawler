// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tuggy’s first contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    This is tuggy’s first contract    //
//                                      //
//                                      //
//////////////////////////////////////////


contract tug is ERC721Creator {
    constructor() ERC721Creator(unicode"tuggy’s first contract", "tug") {}
}