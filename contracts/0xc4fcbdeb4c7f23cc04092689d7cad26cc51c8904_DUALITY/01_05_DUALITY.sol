// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Duality of Man
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


contract DUALITY is ERC721Creator {
    constructor() ERC721Creator("Duality of Man", "DUALITY") {}
}