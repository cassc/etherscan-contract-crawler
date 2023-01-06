// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Killer Sisters
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//     r(^ω^*)))    //
//                  //
//                  //
//////////////////////


contract SISTERS is ERC721Creator {
    constructor() ERC721Creator("Killer Sisters", "SISTERS") {}
}