// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: miring8
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                _)       _)                 _ )      //
//      __ `__ \   |   __|  |  __ \    _` |   _ \      //
//      |   |   |  |  |     |  |   |  (   |  (   |     //
//     _|  _|  _| _| _|    _| _|  _| \__, | \___/      //
//                                   |___/             //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract miri8 is ERC721Creator {
    constructor() ERC721Creator("miring8", "miri8") {}
}