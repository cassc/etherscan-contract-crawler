// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marlon Portales NFT Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Marlon Portales NFT Art    //
//                               //
//                               //
///////////////////////////////////


contract MP is ERC721Creator {
    constructor() ERC721Creator("Marlon Portales NFT Art", "MP") {}
}