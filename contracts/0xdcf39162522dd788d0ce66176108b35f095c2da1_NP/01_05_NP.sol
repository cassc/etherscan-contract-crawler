// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NaturePix
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    Nature on the blockchain.    //
//                                 //
//                                 //
/////////////////////////////////////


contract NP is ERC721Creator {
    constructor() ERC721Creator("NaturePix", "NP") {}
}