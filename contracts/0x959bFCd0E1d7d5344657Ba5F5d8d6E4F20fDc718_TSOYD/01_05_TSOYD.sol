// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Sound Of Your Demise
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


contract TSOYD is ERC721Creator {
    constructor() ERC721Creator("The Sound Of Your Demise", "TSOYD") {}
}