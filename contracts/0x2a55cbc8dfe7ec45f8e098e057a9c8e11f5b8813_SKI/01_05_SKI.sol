// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SkullKids (1)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    SKULLKIDS    //
//    BADFROOT     //
//    2021         //
//                 //
//                 //
/////////////////////


contract SKI is ERC721Creator {
    constructor() ERC721Creator("SkullKids (1)", "SKI") {}
}