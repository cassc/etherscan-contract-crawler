// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEEKAY Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    DeeKay Open Edition           //
//                                  //
//    twitter.com/deekaymotion      //
//    instagram.com/deekaymotion    //
//                                  //
//                                  //
//////////////////////////////////////


contract DK5 is ERC1155Creator {
    constructor() ERC1155Creator("DEEKAY Open Edition", "DK5") {}
}