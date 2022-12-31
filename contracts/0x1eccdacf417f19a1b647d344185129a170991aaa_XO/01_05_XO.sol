// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SidXO#
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ||||||||    //
//    ||X O ||    //
//    || ## ||    //
//    ||||||||    //
//                //
//                //
////////////////////


contract XO is ERC721Creator {
    constructor() ERC721Creator("SidXO#", "XO") {}
}