// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lil Beebo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    LIL BEEBO    //
//                 //
//                 //
/////////////////////


contract BEEBO is ERC721Creator {
    constructor() ERC721Creator("Lil Beebo", "BEEBO") {}
}