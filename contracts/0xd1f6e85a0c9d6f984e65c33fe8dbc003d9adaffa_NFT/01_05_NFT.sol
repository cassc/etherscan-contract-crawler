// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NonFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Test NFT manifold    //
//                         //
//                         //
/////////////////////////////


contract NFT is ERC721Creator {
    constructor() ERC721Creator("NonFT", "NFT") {}
}