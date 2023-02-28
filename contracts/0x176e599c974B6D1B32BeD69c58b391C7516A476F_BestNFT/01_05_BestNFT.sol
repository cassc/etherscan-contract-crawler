// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Best NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    BestNFT    //
//               //
//               //
///////////////////


contract BestNFT is ERC721Creator {
    constructor() ERC721Creator("Best NFT", "BestNFT") {}
}