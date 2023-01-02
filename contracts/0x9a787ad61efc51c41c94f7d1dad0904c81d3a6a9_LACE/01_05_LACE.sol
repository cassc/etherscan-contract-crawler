// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LACE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//                   //
//    |_ /\ ( [-     //
//                   //
//                   //
//                   //
//                   //
///////////////////////


contract LACE is ERC721Creator {
    constructor() ERC721Creator("LACE", "LACE") {}
}