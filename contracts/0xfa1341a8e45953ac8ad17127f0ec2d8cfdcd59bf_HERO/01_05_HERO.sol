// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 360
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                .                //
//          .  .  .  .  .          //
//       .  .  .  .  .  .  .       //
//       .  .  .  .  .  .  .       //
//    .  .  3  .  6  .  0  .  .    //
//       .  .  .  .  .  .  .       //
//       .  .  .  .  .  .  .       //
//          .  .  .  .  .          //
//                .                //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract HERO is ERC721Creator {
    constructor() ERC721Creator("360", "HERO") {}
}