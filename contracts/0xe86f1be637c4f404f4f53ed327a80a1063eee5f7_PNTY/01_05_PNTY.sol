// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PantyNectar NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Web3 Vision of Love    //
//                           //
//                           //
///////////////////////////////


contract PNTY is ERC721Creator {
    constructor() ERC721Creator("PantyNectar NFT", "PNTY") {}
}