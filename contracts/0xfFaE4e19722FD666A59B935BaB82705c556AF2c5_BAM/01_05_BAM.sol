// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Burn After Minting
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    A TAD Bit Stupid    //
//                        //
//                        //
////////////////////////////


contract BAM is ERC721Creator {
    constructor() ERC721Creator("Burn After Minting", "BAM") {}
}