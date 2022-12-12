// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Heroes never panic
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//    H ro sn v rp ni .    //
//     X  X  X X  X  .     //
//     X  X  X X  X  .     //
//     X  X  X X  .  .     //
//     X  X  X X  .  .     //
//     X  X  X X  .  .     //
//     .  .  . .  .  .     //
//                         //
//    Heroesneverpanic.    //
//                         //
//                         //
//                         //
/////////////////////////////


contract HNP is ERC1155Creator {
    constructor() ERC1155Creator("Heroes never panic", "HNP") {}
}