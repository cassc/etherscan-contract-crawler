// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DOGEZA TOY BOX
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    DOGEZA TOY BOX    //
//                      //
//                      //
//////////////////////////


contract DGZTB is ERC721Creator {
    constructor() ERC721Creator("DOGEZA TOY BOX", "DGZTB") {}
}