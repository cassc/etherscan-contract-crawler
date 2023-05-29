// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WALL by KEVIN ABOSCH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    // WALL BY KEVIN ABOSCH (2022)    //
//                                      //
//                                      //
//////////////////////////////////////////


contract WALL is ERC721Creator {
    constructor() ERC721Creator("WALL by KEVIN ABOSCH", "WALL") {}
}