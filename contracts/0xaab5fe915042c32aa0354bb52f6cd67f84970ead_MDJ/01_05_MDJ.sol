// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VERA SULEIMANOVA
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//       _   _   _   _     _   _   _   _   _   _   _   _   _   _   _       //
//      / \ / \ / \ / \   / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \      //
//     ( V | E | R | A ) ( S | U | L | E | I | M | A | N | O | V | A )     //
//      \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/      //
//                                                                         //
//    No matter who you are today, what you do and what you believe in     //
//    - be kinder to yourself and to those around you.                     //
//    This nft was created to make the world a little better.              //
//    Be honest with its creator.                                          //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract MDJ is ERC1155Creator {
    constructor() ERC1155Creator("VERA SULEIMANOVA", "MDJ") {}
}