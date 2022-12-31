// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEEKAY edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    DeeKay Edition                //
//                                  //
//    twitter.com/deekaymotion      //
//    instagram.com/deekaymotion    //
//                                  //
//                                  //
//////////////////////////////////////


contract DK2 is ERC1155Creator {
    constructor() ERC1155Creator("DEEKAY edition", "DK2") {}
}