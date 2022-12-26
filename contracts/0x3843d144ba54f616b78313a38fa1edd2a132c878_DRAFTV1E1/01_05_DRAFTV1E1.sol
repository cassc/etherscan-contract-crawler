// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Draft Publication
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    DRAFT PUBLICATION NFT    //
//                             //
//                             //
/////////////////////////////////


contract DRAFTV1E1 is ERC721Creator {
    constructor() ERC721Creator("Draft Publication", "DRAFTV1E1") {}
}