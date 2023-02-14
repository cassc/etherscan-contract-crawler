// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WHAT WE SEE IN THE DARK
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//     __      __  __      __  _________________        //
//    /  \    /  \/  \    /  \/   _____/\______ \       //
//    \   \/\/   /\   \/\/   /\_____  \  |    |  \      //
//     \        /  \        / /        \ |    `   \     //
//      \__/\  /    \__/\  / /_______  //_______  /     //
//           \/          \/          \/         \/      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract WWSD is ERC721Creator {
    constructor() ERC721Creator("WHAT WE SEE IN THE DARK", "WWSD") {}
}