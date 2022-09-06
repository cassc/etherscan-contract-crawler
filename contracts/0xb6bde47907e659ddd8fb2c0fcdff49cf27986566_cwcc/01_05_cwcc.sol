// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoWagakki Cyber Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    CryptoWagakki Cyber Collection    //
//                                      //
//                                      //
//////////////////////////////////////////


contract cwcc is ERC721Creator {
    constructor() ERC721Creator("CryptoWagakki Cyber Collection", "cwcc") {}
}