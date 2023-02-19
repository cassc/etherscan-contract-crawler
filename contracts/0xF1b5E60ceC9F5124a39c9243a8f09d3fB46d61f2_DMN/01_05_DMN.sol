// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Demon
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Demon x Mintfun NFT    //
//                           //
//                           //
///////////////////////////////


contract DMN is ERC721Creator {
    constructor() ERC721Creator("Demon", "DMN") {}
}