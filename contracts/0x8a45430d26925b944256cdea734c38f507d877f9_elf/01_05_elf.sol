// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: elfelf
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//           .__   _____     //
//      ____ |  |_/ ____\    //
//    _/ __ \|  |\   __\     //
//    \  ___/|  |_|  |       //
//     \___  >____/__|       //
//         \/                //
//                           //
//                           //
///////////////////////////////


contract elf is ERC721Creator {
    constructor() ERC721Creator("elfelf", "elf") {}
}