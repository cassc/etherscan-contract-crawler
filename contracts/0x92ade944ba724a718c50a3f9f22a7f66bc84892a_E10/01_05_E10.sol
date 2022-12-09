// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0EDIT 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//     ██████  ███████ ██████  ██ ████████     //
//    ██  ████ ██      ██   ██ ██    ██        //
//    ██ ██ ██ █████   ██   ██ ██    ██        //
//    ████  ██ ██      ██   ██ ██    ██        //
//     ██████  ███████ ██████  ██    ██        //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract E10 is ERC721Creator {
    constructor() ERC721Creator("0EDIT 1/1", "E10") {}
}