// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Little Fantasy World
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ██      ███████ ██     ██     //
//    ██      ██      ██     ██     //
//    ██      █████   ██  █  ██     //
//    ██      ██      ██ ███ ██     //
//    ███████ ██       ███ ███      //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract LFW is ERC721Creator {
    constructor() ERC721Creator("Little Fantasy World", "LFW") {}
}