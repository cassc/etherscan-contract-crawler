// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Doge attack NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Game NFT collection    //
//                           //
//                           //
///////////////////////////////


contract DAN is ERC721Creator {
    constructor() ERC721Creator("Doge attack NFT", "DAN") {}
}