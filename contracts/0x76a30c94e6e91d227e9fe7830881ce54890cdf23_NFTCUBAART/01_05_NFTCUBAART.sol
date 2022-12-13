// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT Cuba ART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     _  _  ___  ___    __  _ _  ___  _     _   ___ ___     //
//    | \| || __||_ _|  / _|| | || o )/ \   / \ | o \_ _|    //
//    | \\ || _|  | |  ( (_ | U || o \ o | | o ||   /| |     //
//    |_|\_||_|   |_|   \__||___||___/_n_| |_n_||_|\\|_|     //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract NFTCUBAART is ERC721Creator {
    constructor() ERC721Creator("NFT Cuba ART", "NFTCUBAART") {}
}