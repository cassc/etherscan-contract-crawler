// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ASHF
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     _   _   _   _       ___   __   _      //
//    | | | | | | | |     /   | |  \ | |     //
//    | |_| | | | | |    / /| | |   \| |     //
//    |  _  | | | | |   / / | | | |\   |     //
//    | | | | | |_| |  / /  | | | | \  |     //
//    |_| |_| \_____/ /_/   |_| |_|  \_|     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract ASHF is ERC721Creator {
    constructor() ERC721Creator("ASHF", "ASHF") {}
}