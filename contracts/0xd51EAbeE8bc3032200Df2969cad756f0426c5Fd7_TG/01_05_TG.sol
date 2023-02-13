// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Taylor's Shrine⛩️
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//     __   ___  __   ___      //
//    |/"| /  ")|/"| /  ")     //
//    (: |/   / (: |/   /      //
//    |    __/  |    __/       //
//    (// _  \  (// _  \       //
//    |: | \  \ |: | \  \      //
//    (__|  \__)(__|  \__)     //
//                             //
//                             //
/////////////////////////////////


contract TG is ERC721Creator {
    constructor() ERC721Creator(unicode"Taylor's Shrine⛩️", "TG") {}
}