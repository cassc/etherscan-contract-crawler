// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArtOnNFTs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ARTOnNFTs    //
//                 //
//                 //
/////////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("ArtOnNFTs", "ETH") {}
}