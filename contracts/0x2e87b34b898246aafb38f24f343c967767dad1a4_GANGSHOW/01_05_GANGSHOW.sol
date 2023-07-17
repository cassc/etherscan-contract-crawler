// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Welcome to Gangland by Eddie Gangland
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                               //
//                                                                                                                                                                                               //
//    This collection of NFTS was exclusively made for the artworks purchased at Eddie Gangland's first solo art show that took place at The Art Dept. gallery in West Hollywood, CA. in 2023    //
//                                                                                                                                                                                               //
//                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GANGSHOW is ERC721Creator {
    constructor() ERC721Creator("Welcome to Gangland by Eddie Gangland", "GANGSHOW") {}
}