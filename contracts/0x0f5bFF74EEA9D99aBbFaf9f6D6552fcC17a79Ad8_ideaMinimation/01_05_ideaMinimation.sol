// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimations
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Minimation  - idertist.xyz    //
//                                  //
//                                  //
//////////////////////////////////////


contract ideaMinimation is ERC721Creator {
    constructor() ERC721Creator("Minimations", "ideaMinimation") {}
}