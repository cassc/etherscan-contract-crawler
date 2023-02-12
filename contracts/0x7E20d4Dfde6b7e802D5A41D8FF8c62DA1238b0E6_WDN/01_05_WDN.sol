// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WOODEN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//                                //
//              . .               //
//              |_|_              //
//    .--. .-.  | |  .  . .--.    //
//    `--.(   ) | |  |  | `--.    //
//    `--' `-'`-`-`-'`--`-`--'    //
//                                //
//                                //
//                                //
//                                //
////////////////////////////////////


contract WDN is ERC721Creator {
    constructor() ERC721Creator("WOODEN", "WDN") {}
}