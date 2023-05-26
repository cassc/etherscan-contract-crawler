// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Thread
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    T     H     R     E     A    D    //
//                                      //
//                                      //
//////////////////////////////////////////


contract Thread is ERC721Creator {
    constructor() ERC721Creator("Thread", "Thread") {}
}