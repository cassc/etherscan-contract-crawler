// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wildflower Delight
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//        _   __ ______ ____     //
//       / | / //_  __// __ \    //
//      /  |/ /  / /  / /_/ /    //
//     / /|  /  / /  / ____/     //
//    /_/ |_/  /_/  /_/          //
//                               //
//                               //
//                               //
///////////////////////////////////


contract NTP is ERC1155Creator {
    constructor() ERC1155Creator("Wildflower Delight", "NTP") {}
}