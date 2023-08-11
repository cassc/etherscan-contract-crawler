// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tradium Podcast - Portugal
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    NFT Collection of Tradium [COMMUNITY] for Podcasts    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract TPP is ERC1155Creator {
    constructor() ERC1155Creator("Tradium Podcast - Portugal", "TPP") {}
}