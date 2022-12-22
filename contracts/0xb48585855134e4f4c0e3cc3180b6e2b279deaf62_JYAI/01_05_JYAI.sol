// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JYAI Open Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//        _____  ____  ____     _       _____      //
//       |_   _||_  _||_  _|   / \     |_   _|     //
//         | |    \ \  / /    / _ \      | |       //
//     _   | |     \ \/ /    / ___ \     | |       //
//    | |__' |     _|  |_  _/ /   \ \_  _| |_      //
//    `.____.'    |______||____| |____||_____|     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract JYAI is ERC721Creator {
    constructor() ERC721Creator("JYAI Open Editions", "JYAI") {}
}