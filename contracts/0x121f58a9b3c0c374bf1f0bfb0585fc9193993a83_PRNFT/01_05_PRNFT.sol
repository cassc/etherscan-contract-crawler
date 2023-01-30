// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PRIVATENFTs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    LIFETIME MEMBERSHIP     //
//                            //
//                            //
////////////////////////////////


contract PRNFT is ERC721Creator {
    constructor() ERC721Creator("PRIVATENFTs", "PRNFT") {}
}