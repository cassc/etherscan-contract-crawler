// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ada Crow Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    Editions by Ada Crow minted on own smart contract via Manifold.    //
//                                                                       //
//    Art Historian & Surrealist NFT artist.                             //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract AC is ERC721Creator {
    constructor() ERC721Creator("Ada Crow Editions", "AC") {}
}