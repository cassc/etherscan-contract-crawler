// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoRick
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    CryptoRick     //
//                   //
//                   //
///////////////////////


contract CryptoRick is ERC721Creator {
    constructor() ERC721Creator("CryptoRick", "CryptoRick") {}
}