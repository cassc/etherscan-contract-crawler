// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DARK AGE on Ça sent le sapin at NFT Factory Paris
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    DARK AGE    //
//                //
//                //
////////////////////


contract DARK is ERC721Creator {
    constructor() ERC721Creator(unicode"DARK AGE on Ça sent le sapin at NFT Factory Paris", "DARK") {}
}