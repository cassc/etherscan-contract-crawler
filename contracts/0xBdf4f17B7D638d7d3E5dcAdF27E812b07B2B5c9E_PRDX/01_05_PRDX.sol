// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paradox
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    BOTTO - THIRD PERIOD - PARADOX    //
//                                      //
//                                      //
//////////////////////////////////////////


contract PRDX is ERC721Creator {
    constructor() ERC721Creator("Paradox", "PRDX") {}
}