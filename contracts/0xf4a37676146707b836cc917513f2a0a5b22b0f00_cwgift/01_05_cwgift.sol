// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoWagakki Gift
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    CryptoWagakki Gift NFTs    //
//                               //
//                               //
///////////////////////////////////


contract cwgift is ERC721Creator {
    constructor() ERC721Creator("CryptoWagakki Gift", "cwgift") {}
}