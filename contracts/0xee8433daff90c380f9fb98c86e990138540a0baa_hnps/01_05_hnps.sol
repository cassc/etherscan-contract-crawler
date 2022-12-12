// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Heroes never panic.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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
//                         //
/////////////////////////////


contract hnps is ERC721Creator {
    constructor() ERC721Creator("Heroes never panic.", "hnps") {}
}