// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FVCK NFTs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    a fuck nfts project    //
//                           //
//                           //
///////////////////////////////


contract FVCK is ERC1155Creator {
    constructor() ERC1155Creator("FVCK NFTs", "FVCK") {}
}