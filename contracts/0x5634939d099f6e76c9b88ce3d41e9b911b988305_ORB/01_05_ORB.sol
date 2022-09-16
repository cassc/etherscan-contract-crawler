// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: O-R-B
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                .                //
//          .  .  .  .  .          //
//       .  .  .  .  .  .  .       //
//       .  .  .  .  .  .  .       //
//    .  .  o  .  r  .  b  .  .    //
//       .  .  .  .  .  .  .       //
//       .  .  .  .  .  .  .       //
//          .  .  .  .  .          //
//                .                //
//                                 //
//                                 //
/////////////////////////////////////


contract ORB is ERC721Creator {
    constructor() ERC721Creator("O-R-B", "ORB") {}
}