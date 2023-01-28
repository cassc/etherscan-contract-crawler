// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Are you sure that was only catnip?
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    ██    ██  ██████  ██ ██████      //
//    ██    ██ ██    ██ ██ ██   ██     //
//    ██    ██ ██    ██ ██ ██   ██     //
//     ██  ██  ██    ██ ██ ██   ██     //
//      ████    ██████  ██ ██████      //
//                                     //
//                                     //
/////////////////////////////////////////


contract CATNIP is ERC721Creator {
    constructor() ERC721Creator("Are you sure that was only catnip?", "CATNIP") {}
}