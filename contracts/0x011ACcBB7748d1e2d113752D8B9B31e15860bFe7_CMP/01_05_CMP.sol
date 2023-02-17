// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoMADONNE Pachamama
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    CryptoMADONNE Pachamama was created exclusively for "ARTERiA".     //
//    It represents the Mother Earth deity in Inca culture.              //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract CMP is ERC721Creator {
    constructor() ERC721Creator("CryptoMADONNE Pachamama", "CMP") {}
}