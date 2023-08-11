// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: joelle does art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//               ..                       //
//       ..    dF                         //
//      888>  '88bu.                      //
//      "8P   '*88888bu         u         //
//       .      ^"*8888N     us888u.      //
//     u888u.  beWE "888L [email protected] "8888"     //
//    `'888E   888E  888E 9888  9888      //
//      888E   888E  888E 9888  9888      //
//      888E   888E  888F 9888  9888      //
//      888E  .888N..888  9888  9888      //
//      888E   `"888*""   "888*""888"     //
//      888E      ""       ^Y"   ^Y'      //
//      888E                              //
//      888P                              //
//    .J88" "                             //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract jda is ERC721Creator {
    constructor() ERC721Creator("joelle does art", "jda") {}
}