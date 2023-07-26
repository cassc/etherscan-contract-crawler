// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wild Life by RB Robert's
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//      _____  ____                             //
//     |  __ \|  _ \                            //
//     | |__) | |_) |                           //
//     |  _  /|  _ <                            //
//     | | \ \| |_) |                           //
//     |_|__\_\____/_               _           //
//     |  __ \     | |             | |          //
//     | |__) |___ | |__   ___ _ __| |_ ___     //
//     |  _  // _ \| '_ \ / _ \ '__| __/ __|    //
//     | | \ \ (_) | |_) |  __/ |  | |_\__ \    //
//     |_|  \_\___/|_.__/ \___|_|   \__|___/    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract RBR is ERC721Creator {
    constructor() ERC721Creator("Wild Life by RB Robert's", "RBR") {}
}