// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks Culture
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    CHECKS CULTURE    //
//                      //
//                      //
//////////////////////////


contract CHECKSCULTURE is ERC721Creator {
    constructor() ERC721Creator("Checks Culture", "CHECKSCULTURE") {}
}