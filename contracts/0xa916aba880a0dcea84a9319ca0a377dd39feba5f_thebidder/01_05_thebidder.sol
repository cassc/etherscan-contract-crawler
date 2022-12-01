// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The bidder edition
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//      _   _          _    _    _    _             //
//     | |_| |_  ___  | |__(_)__| |__| |___ _ _     //
//     |  _| ' \/ -_) | '_ \ / _` / _` / -_) '_|    //
//      \__|_||_\___| |_.__/_\__,_\__,_\___|_|      //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract thebidder is ERC721Creator {
    constructor() ERC721Creator("The bidder edition", "thebidder") {}
}