// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptolessNFT Twitter Profile
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    https://cryptolessnft.com    //
//                                 //
//                                 //
/////////////////////////////////////


contract CRYPTOLESS is ERC721Creator {
    constructor() ERC721Creator("CryptolessNFT Twitter Profile", "CRYPTOLESS") {}
}