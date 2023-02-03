// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Civilization
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Civilization by indie.    //
//                              //
//                              //
//////////////////////////////////


contract COCA is ERC1155Creator {
    constructor() ERC1155Creator("Civilization", "COCA") {}
}