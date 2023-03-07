// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hanafuda Girls
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    ((੭ ᐕ)੭~♡     //
//                  //
//                  //
//////////////////////


contract HFG is ERC721Creator {
    constructor() ERC721Creator("Hanafuda Girls", "HFG") {}
}