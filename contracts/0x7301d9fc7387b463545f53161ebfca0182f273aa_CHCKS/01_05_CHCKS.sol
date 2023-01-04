// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks At Home
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    "Mom, can we mint Checks??"            //
//                                           //
//    "No honey, we have Checks at home!"    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract CHCKS is ERC721Creator {
    constructor() ERC721Creator("Checks At Home", "CHCKS") {}
}