// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Personalised Song Token
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//     __                     _____      _                  //
//    / _\ ___  _ __   __ _  /__   \___ | | _____ _ __      //
//    \ \ / _ \| '_ \ / _` |   / /\/ _ \| |/ / _ \ '_ \     //
//    _\ \ (_) | | | | (_| |  / / | (_) |   <  __/ | | |    //
//    \__/\___/|_| |_|\__, |  \/   \___/|_|\_\___|_| |_|    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract Song is ERC1155Creator {
    constructor() ERC1155Creator("Personalised Song Token", "Song") {}
}