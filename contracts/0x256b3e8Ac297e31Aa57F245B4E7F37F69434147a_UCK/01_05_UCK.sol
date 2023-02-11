// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WTF Unchecks
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


contract UCK is ERC721Creator {
    constructor() ERC721Creator("WTF Unchecks", "UCK") {}
}