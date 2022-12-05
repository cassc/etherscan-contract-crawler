// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FranklinARTNFTs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    FranklinARTNFTs    //
//    Minimalism art     //
//                       //
//                       //
//                       //
///////////////////////////


contract LANDS is ERC721Creator {
    constructor() ERC721Creator("FranklinARTNFTs", "LANDS") {}
}