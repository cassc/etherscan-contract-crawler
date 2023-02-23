// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Doge Couch
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//      .--------------.--------------.      //
//      |              |              |      //
//      |      **      |      **      |      //
//      |              |              |      //
//      |______________|______________|      //
//      /                             \      //
//     /                               \     //
//    /_________________________________\    //
//    |                                 |    //
//    |_________________________________|    //
//    []                               []    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract COUCH is ERC1155Creator {
    constructor() ERC1155Creator("The Doge Couch", "COUCH") {}
}