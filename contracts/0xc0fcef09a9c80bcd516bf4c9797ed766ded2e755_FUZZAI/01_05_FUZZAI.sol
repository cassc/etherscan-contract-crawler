// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FUZZ.AI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    FuZzyy AI journey    //
//                         //
//                         //
/////////////////////////////


contract FUZZAI is ERC1155Creator {
    constructor() ERC1155Creator("FUZZ.AI", "FUZZAI") {}
}