// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MoMo1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//      _   _   _   _   _      //
//     / \ / \ / \ / \ / \     //
//    ( M | o | M | o | 1 )    //
//     \_/ \_/ \_/ \_/ \_/     //
//                             //
//                             //
//                             //
/////////////////////////////////


contract MoMo1 is ERC1155Creator {
    constructor() ERC1155Creator("MoMo1", "MoMo1") {}
}