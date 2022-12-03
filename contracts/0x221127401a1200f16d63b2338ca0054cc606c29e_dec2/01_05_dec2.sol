// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: December 2, 2019
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//          o                  //
//          |                  //
//    o-o  -o-  o-O-o  o-o     //
//    | |   |   | | |  |       //
//    o-o   o   o o o  o       //
//                             //
//                             //
/////////////////////////////////


contract dec2 is ERC721Creator {
    constructor() ERC721Creator("December 2, 2019", "dec2") {}
}