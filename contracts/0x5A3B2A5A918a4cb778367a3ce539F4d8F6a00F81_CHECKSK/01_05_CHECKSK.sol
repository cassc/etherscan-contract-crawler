// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - KNOT Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    CHECKS-K    //
//                //
//                //
////////////////////


contract CHECKSK is ERC721Creator {
    constructor() ERC721Creator("Checks - KNOT Edition", "CHECKSK") {}
}