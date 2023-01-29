// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    ass n tits    //
//                  //
//                  //
//////////////////////


contract ntits is ERC721Creator {
    constructor() ERC721Creator("ass", "ntits") {}
}