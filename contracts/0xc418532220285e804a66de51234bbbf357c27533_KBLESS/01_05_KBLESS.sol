// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brainless
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ********    //
//                //
//                //
////////////////////


contract KBLESS is ERC721Creator {
    constructor() ERC721Creator("Brainless", "KBLESS") {}
}