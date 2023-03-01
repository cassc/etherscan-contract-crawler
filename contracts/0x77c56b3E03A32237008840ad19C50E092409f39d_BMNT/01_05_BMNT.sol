// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BigMint
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Bigmint!    //
//                //
//                //
////////////////////


contract BMNT is ERC721Creator {
    constructor() ERC721Creator("BigMint", "BMNT") {}
}