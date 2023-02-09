// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phat Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//        _       ____      _____      //
//    U  /"\  uU |  _"\ u  |" ___|     //
//     \/ _ \/  \| |_) |/ U| |_  u     //
//     / ___ \   |  _ <   \|  _|/      //
//    /_/   \_\  |_| \_\   |_|         //
//     \\    >>  //   \\_  )(\\,-      //
//    (__)  (__)(__)  (__)(__)(_/      //
//                                     //
//                                     //
/////////////////////////////////////////


contract PC is ERC1155Creator {
    constructor() ERC1155Creator("Phat Checks", "PC") {}
}