// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OE TEST
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    //////////////    //
//                      //
//                      //
//////////////////////////


contract OET is ERC721Creator {
    constructor() ERC721Creator("OE TEST", "OET") {}
}