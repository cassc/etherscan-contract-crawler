// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brazley
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    BBBBB       //
//    BB  BBB     //
//    BB  BB      //
//    BBBBBB      //
//    BBBBBB      //
//    BB  BBBB    //
//    BB  BBBB    //
//    BB  BBB     //
//    BBBBBB      //
//    BBBBB       //
//                //
//                //
////////////////////


contract Braz is ERC721Creator {
    constructor() ERC721Creator("Brazley", "Braz") {}
}