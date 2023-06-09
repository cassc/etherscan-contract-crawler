// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Feelings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    FEELINGS    //
//                //
//                //
////////////////////


contract FEEL is ERC721Creator {
    constructor() ERC721Creator("Feelings", "FEEL") {}
}