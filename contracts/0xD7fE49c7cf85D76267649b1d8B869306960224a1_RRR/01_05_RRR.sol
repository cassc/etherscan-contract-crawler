// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rug Radio Rewards
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⣠⣶⣶⣶⣦⠀⠀                                             //
//    ⠀⠀⣠⣤⣤⣄⣀⣾⣿⠟⠛⠻⢿⣷⠀                                             //
//    ⢰⣿⡿⠛⠙⠻⣿⣿⠁⠀⠀⠀⣶⢿⡇                                             //
//    ⢿⣿⣇⠀⠀⠀⠈⠏⠀⠀⠀ We love our community.                          //
//    ⠀⠻⣿⣷⣦⣤⣀⠀⠀⠀⠀⣾⡿⠃⠀                                             //
//    ⠀⠀⠀⠀⠉⠉⠻⣿⣄⣴⣿⠟                                                //
//    ⠀⠀⠀⠀⠀⠀⠀⣿⡿⠟⠁⠀⠀⠀⠀                                             //
//                                                                //
//                                                                //
//                                                                //
//    The Rug Radio Rewards Program,                              //
//    created by Artemysia-X (Jessica Artemysia), is              //
//    designed to distribute abundance to our community           //
//    for the value they bring by being active and engaged.       //
//    We live in the attention economy, in which attention is     //
//    the new oil, so why shouldn't you be rewarded for           //
//    being the energy that drives this economy?                  //
//    We want to show you how much we value                       //
//    you and return the value back to you.                       //
//                                                                //
//    Thank you!                                                  //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract RRR is ERC721Creator {
    constructor() ERC721Creator("Rug Radio Rewards", "RRR") {}
}